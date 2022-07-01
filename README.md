# Dependabot Bitbucket Pipe
This pipe will execute dependabot-core in bitbucket. 

### Environment Variables
Variable Name             | Default          | Notes
:------------             | :--------------- | :----
`DIRECTORY_PATH `         | `/`              | Directory where the base dependency files are.
`PACKAGE_MANAGER`         | `bundler`        | Valid values: `bundler`, `cargo`, `composer`, `dep`, `docker`, `elm`,  `go_modules`, `gradle`, `hex`, `maven`, `npm_and_yarn`, `nuget`, `pip` (includes pipenv), `submodules`, `terraform`
`PULL_REQUESTS_ASSIGNEE`  | N/A (Optional) | User to assign to the created pull request.
`BITBUCKET_APP_USERNAME` | N/A (Required) | 
`BITBUCKET_APP_PASSWORD` | N/A (Required) | 
`BITBUCKET_API_URL`      | `https://api.bitbucket.org/2.0` |
`BITBUCKET_HOSTNAME`     | `bitbucket.org` |
`BITBUCKET_REPO_FULL_NAME`            | N/A (Required) | Path to repository. Usually in the format `<namespace>/<project>`.
`BITBUCKET_BRANCH         `         | N/A (Optional) | Branch to fetch manifest from and open pull requests against. D
`GITHUB_ACCESS_TOKEN` | N/A | An Github personal access token with the `pulic_repo` to increase API rate limits.