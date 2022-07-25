# This script is designed to loop through all dependencies in a Bitbucket repository creating PRs where necessary.

require "dependabot/file_fetchers"
require "dependabot/file_parsers"
require "dependabot/update_checkers"
require "dependabot/file_updaters"
require "dependabot/pull_request_creator"
require "dependabot/omnibus"
require 'yaml'
require "awesome_print"
require_relative "config_schema"

credentials = []
bitbucket_hostname = ENV["BITBUCKET_HOSTNAME"] || "bitbucket.org"

unless ENV.has_key?("BITBUCKET_APP_USERNAME")
  raise 'BITBUCKET_APP_USERNAME has not been set.'
end 

unless ENV.has_key?("BITBUCKET_APP_PASSWORD")
  raise 'BITBUCKET_APP_PASSWORD has not been set.'
end 

credentials << {
    "type" => "git_source",
    "host" => bitbucket_hostname,
    "username" => ENV["BITBUCKET_APP_USERNAME"],
    "password" => ENV["BITBUCKET_APP_PASSWORD"]
  }

if ENV.has_key?("GITHUB_ACCESS_TOKEN")
  credentials << {
    "type" => "git_source",
    "host" => "github.com",
    "username" => "x-access-token",
    "password" => ENV["GITHUB_ACCESS_TOKEN"] # A GitHub access token with read access to public repos
  }
else 
  puts "No GITHUB_ACCESS_TOKEN found, you may run into issues with github API rate limits."
end

# Full name of the repo you want to create pull requests for.
repo_name = ENV["BITBUCKET_REPO_FULL_NAME"] # namespace/project

# Directory where the base dependency files are.
directory = ENV["DIRECTORY_PATH"] || "/"

# Branch to look at. Pulled from default Bitbucket env vars, defaults to repo's default branch
branch = ENV["BITBUCKET_BRANCH"]

# Load configuration from mounted repository
unless ENV.has_key?("REPOSITORY_PATH")
  raise 'REPOSITORY_PATH has not been set.'
end 

configuration_path = ENV["REPOSITORY_PATH"] + '/dependabot.yml'

if File.file?(configuration_path)
  configuration = YAML.load_file(configuration_path)

  # Validate configuration against schema
  errors = DependabotConfigurationSchema.call(configuration).errors(full: true).to_h
  
  unless errors.empty?()
    puts "Invalid Configuration: "
    ap errors, options = {index: false}
    raise "Invalid Configuration."
  end

  puts "dependabot.yml found, configuration loaded."
else
  configuration = {}
  puts "dependabot.yml not found, falling back to default configuration."
end

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
package_manager = configuration.has_key?('package_manager') ? configuration['package_manager'] : (ENV["PACKAGE_MANAGER"] || "composer")

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

ignored_versions = configuration["ignored_versions"] || {}

dependencies.select(&:top_level?).each do |dep|
  puts "Checking for updates to #{dep.name} (Current Version: #{dep.version})..."

  # Check if there are any versions of this package to ignore
  ignored = ignored_versions.find { |package| package['name'] == dep.name}

  if !ignored.nil? && !ignored.empty?
    puts "Ignoring versions: #{ignored['versions'].join(',')}"
  end

  #########################################
  # Get update details for the dependency #
  #########################################
  checker = Dependabot::UpdateCheckers.for_package_manager(package_manager).new(
    dependency: dep,
    dependency_files: files,
    credentials: credentials,
    ignored_versions: !ignored.nil? ? ignored['versions'] : []
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
  
  updated_deps.select(&:top_level?).each do |updated_dep|
    puts "Updating #{updated_dep.name} to #{updated_dep.version}..."
  end

  #####################################
  # Generate updated dependency files #
  #####################################
  updater = Dependabot::FileUpdaters.for_package_manager(package_manager).new(
    dependencies: updated_deps,
    dependency_files: files,
    credentials: credentials,
  )

  updated_files = updater.updated_dependency_files

  ########################################
  # Create a pull request for the update #
  ########################################
  pr_creator = Dependabot::PullRequestCreator.new(
    source: source,
    base_commit: commit,
    dependencies: updated_deps,
    files: updated_files,
    credentials: credentials,
    author_details: { name: "Dependabot", email: "no-reply@github.com" },
    label_language: true,
  )
  pull_request = pr_creator.create
  puts " submitted"

  next unless pull_request
end

puts "Done"
