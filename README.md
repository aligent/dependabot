# Dependabot Bitbucket Pipe
This pipe will execute dependabot-core against a bitbucket repository. It will scan your dependencies and create pull requests to update them. 

### Environment Variables
| Variable Name               | Default                         | Notes                                                                                                                                                                                      |
|:----------------------------|:--------------------------------|:-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `DIRECTORY_PATH `           | `/`                             | Directory where the base dependency files are.                                                                                                                                             |
| `PACKAGE_MANAGER`           | `composer`                       | Valid values: `bundler`, `cargo`, `composer`, `dep`, `docker`, `elm`,  `go_modules`, `gradle`, `hex`, `maven`, `npm_and_yarn`, `nuget`, `pip` (includes pipenv), `submodules`, `terraform` |
| `BITBUCKET_APP_USERNAME`    | N/A (Required)                  |                                                                                                                                                                                            |
| `BITBUCKET_APP_PASSWORD`    | N/A (Required)                  |                                                                                                                                                                                            |
| `BITBUCKET_API_URL`         | `https://api.bitbucket.org/2.0` |                                                                                                                                                                                            |
| `BITBUCKET_HOSTNAME`        | `bitbucket.org`                 |                                                                                                                                                                                            |
| `BITBUCKET_REPO_FULL_NAME`  | N/A (Required)                  | Path to repository. Usually in the format `<namespace>/<project>`. When running in bitbucket pipelines this is automatically provided.                                                                                                                         |
| `BITBUCKET_BRANCH         ` | N/A (Optional)                  | Branch to fetch manifest from and open pull requests against. When running in bitbucket pipelines this is automatically provided.                                                                                                                            |
| `GITHUB_ACCESS_TOKEN`       | N/A                             | An Github personal access token with the `pulic_repo` to increase API rate limits.                                                                                                         |

### Configuration File
You can add a `dependabot.yml` file to the root of your repository with a list of package versions to ignore. PRs for these versions will not be created.

Example:
```yaml
package_manager: npm_and_yarn

ignored_versions:
  - { name: "@types/node", versions: [">= 17.0.0"] }
  - { name: "@types/aws-lambda", versions: [">= 8.10.100"] }

```

### Setup

1. Add the below to a `bitbucket-pipelines.yml` in the root of your repository
```yml
pipelines:
  custom:
    dependabot:
      - step:
          name: "Dependabot Scan"
          script:
            - pipe: docker://aligent/dependabot-pipe:latest
              variables:
                PACKAGE_MANAGER: "npm_and_yarn" # Replace as needed
                BITBUCKET_APP_USERNAME: "$BITBUCKET_APP_USERNAME"
                BITBUCKET_APP_PASSWORD: "$BITBUCKET_APP_PASSWORD"
                GITHUB_ACCESS_TOKEN: "$GITHUB_ACCESS_TOKEN"
```

1. Create a Bitbucket App password [here](https://bitbucket.org/account/settings/app-passwords/new) with the below permissions
  <p align="center">
    <img src="/doc/dependa_bot_permissions.png" alt="Dependabot Permissions" style="width:500px;"/>
  </p>

1. Create a Github Access token [here](https://github.com/settings/tokens/new) with just the `public_repo` permission

1. Add the credentials as repository variables see [here](https://support.atlassian.com/bitbucket-cloud/docs/variables-and-secrets/)

1. Head to `Pipelines > Schedules > New Schedule` and select the Branch you want to monitor, the `dependabot` pipeline and how often to run
  <p align="center">
    <img src="/doc/dependa_bot_schedule.png" alt="Dependabot Permissions" style="width:500px;"/>
  </p>


## Notes
The `BITBUCKET_APP_USERNAME` and `BITBUCKET_APP_PASSWORD` variables are currently required as dependabot-core does not currently support using the bitbucket pipeline authentication proxy (http://host.docker.internal:29418).