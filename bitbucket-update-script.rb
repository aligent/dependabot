# This script is designed to loop through all dependencies in a Bitbucket repository creating PRs where necessary.

require "dependabot/file_fetchers"
require "dependabot/file_parsers"
require "dependabot/update_checkers"
require "dependabot/file_updaters"
require "dependabot/pull_request_creator"
require "dependabot/omnibus"

unless ENV.has_key?("BITBUCKET_APP_USERNAME")
  raise 'BITBUCKET_APP_USERNAME has not been set.'
end 

unless ENV.has_key?("BITBUCKET_APP_PASSWORD")
  raise 'BITBUCKET_APP_PASSWORD has not been set.'
end 

bitbucket_hostname = ENV["BITBUCKET_HOSTNAME"] || "bitbucket.org"

credentials = [
  {
    "type" => "git_source",
    "host" => bitbucket_hostname,
    "username" => ENV["BITBUCKET_APP_USERNAME"],
    "password" => ENV["BITBUCKET_APP_PASSWORD"]
  }
]

# Full name of the repo you want to create pull requests for.
repo_name = ENV["BITBUCKET_REPO_FULL_NAME"] # namespace/project

# Directory where the base dependency files are.
directory = ENV["DIRECTORY_PATH"] || "/"

# Branch to look at. Defaults to repo's default branch
branch = ENV["BRANCH"]

# Name of the package manager you'd like to do the update for. Options are:
# - bundler
# - pip (includes pipenv)
# - npm_and_yarn
# - maven
# - gradle
# - cargo
# - hex
# - composer
# - nuget
# - dep
# - go_modules
# - elm
# - submodules
# - docker
# - terraform
package_manager = ENV["PACKAGE_MANAGER"] || "composer"

source = Dependabot::Source.new(
  provider: "bitbucket",
  hostname: bitbucket_hostname,
  api_endpoint: ENV["BITBUCKET_API_URL"] || "https://api.bitbucket.org/2.0/",
  repo: repo_name,
  directory: directory,
  branch: branch,
)


##############################
# Fetch the dependency files #
##############################
puts "Fetching #{package_manager} dependency files for #{repo_name}"
fetcher = Dependabot::FileFetchers.for_package_manager(package_manager).new(
  source: source,
  credentials: credentials,
)

files = fetcher.files
commit = fetcher.commit

##############################
# Parse the dependency files #
##############################
puts "Parsing dependencies information"
parser = Dependabot::FileParsers.for_package_manager(package_manager).new(
  dependency_files: files,
  source: source,
  credentials: credentials,
)

dependencies = parser.parse

dependencies.select(&:top_level?).each do |dep|
  #########################################
  # Get update details for the dependency #
  #########################################
  checker = Dependabot::UpdateCheckers.for_package_manager(package_manager).new(
    dependency: dep,
    dependency_files: files,
    credentials: credentials,
  )

  next if checker.up_to_date?

  requirements_to_unlock =
    if !checker.requirements_unlocked_or_can_be?
      if checker.can_update?(requirements_to_unlock: :none) then :none
      else :update_not_possible
      end
    elsif checker.can_update?(requirements_to_unlock: :own) then :own
    elsif checker.can_update?(requirements_to_unlock: :all) then :all
    else :update_not_possible
    end

  next if requirements_to_unlock == :update_not_possible

  updated_deps = checker.updated_dependencies(
    requirements_to_unlock: requirements_to_unlock
  )

  #####################################
  # Generate updated dependency files #
  #####################################
  print "  - Updating #{dep.name} (from #{dep.version})…"
  updater = Dependabot::FileUpdaters.for_package_manager(package_manager).new(
    dependencies: updated_deps,
    dependency_files: files,
    credentials: credentials,
  )

  updated_files = updater.updated_dependency_files

  ########################################
  # Create a pull request for the update #
  ########################################
  assignee = (ENV["PULL_REQUESTS_ASSIGNEE"])&.to_i
  assignees = assignee ? [assignee] : assignee
  pr_creator = Dependabot::PullRequestCreator.new(
    source: source,
    base_commit: commit,
    dependencies: updated_deps,
    files: updated_files,
    credentials: credentials,
    assignees: assignees,
    author_details: { name: "Dependabot", email: "no-reply@github.com" },
    label_language: true,
  )
  pull_request = pr_creator.create
  puts " submitted"

  next unless pull_request
end

puts "Done"
