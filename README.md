# terraform-cloud-connect

## Purpose
I use the following example to integrate my Gitlab CICD pipelines to my Terraform Cloud workspaces. I keep all the more complicated building jobs running in Gitlab CICD, and I delegate all the intricacies of deploying and managing Terraform code to the Terraform Cloud, keeping my deployments as friction free as possible.

In other words, this script triggers an [API-driven run](https://www.terraform.io/docs/cloud/run/api.html) in Terraform Cloud.

It handles;
- Tarring and pushing your terrform configuration
- Creating workspaces
- Apply and destroy workflows
- Setting of terrform and environment vars from env vars.
- Downloading the state file after a run.

### Note
- In the context of this readme, TFE, TFC and Terraform Cloud are used interchangeably.
- This script is a combination of the following scripts, packaged in an docker container, with a few additions to make it easier to consume from a gitlab pipeline. Any and all credit should be sent here.
  -  github.com/hashicorp/terraform-guides/blob/master/operations/automation-script/loadAndRunWorkspace.sh
  -  github.com/hashicorp/terraform-guides/blob/master/operations/variable-scripts/set-variables.sh
  -  github.com/hashicorp/terraform-guides/blob/master/operations/variable-scripts/delete-variables.sh
- This script has the bare minimum of steps to push some terraform code to TFC and trigger a run, there is very limited error handling. If you are looking for a more complete solution, take a look at [go-tfe](https://github.com/hashicorp/go-tfe) and [terrasnek](https://github.com/dahlke/terrasnek).

## Usage
All of the following environment variables are required. There are no default values provided.
| VAR | Values | Description |
|---|---|---|
| TFE_TOKEN | qi1Ss... | User API Token from Terraform Cloud | 
| TFE_ORG | my-organisation | Name of your organisation from Terraform Cloud |
| TFE_ADDR | app.terraform.io | Address of the Terraform Cloud API. Should not include 'http(s)://'|
| TFE_WORKSPACE_NAME | my-workspace| Name of the workspace from Terraform Cloud. Should not contain spaces |
| TFE_CONFIG_DIR | config | Path to the directory that contains your terraform code. | 
| TFE_VARIABLES_FILE | variables.csv | Exists for backward compatiblilty of setting default vars in repo. | 
| TFE_ACTION | apply\|destroy | Request a terraform apply or destroy |
| TFE_SET_VARIABLES_FORCE | true\|false | Delete all variables in the workspace initially. |
| TFE_SAVE_PLAN | true\|false | Save the plan file |
| TFE_SLEEP_INTERVAL | 5s | `man time` |
| TFE_VARIABLES_FILE_DELIMITER | ; | |
| TFE_AUTO_APPROVE | yes\|no | Automatically approve the run |
| TFE_TERRAFORM_VERSION | 0.14.5 | Version of terrform in the workspace |

### Example 1
The the following `.gitlab-ci.yaml` file will; 
- Create a Terraform Cloud workspace called `<gitlab-project>-<gitlab-repo>-<gitlab-branch>` 
- Upload the contents of the directory `./deploy` to the workspace.
- Set the terraform variable `EXAMPLE` with the value of `example` in the workspace.
- Set the environment variable `EXAMPLE_ENV` with the value of `example-env` in the workspace.
- Queue a terraform apply with a manual approval required in Terraform Cloud. 

This gitlab project has the environment variable `TFE_TOKEN` set in order to keep the sensitive value out of the repo itself.

Example `.gitlab-ci.yml` file.
```
variables:

  # Terraform-cloud-connect configuration
  TFE_CLOUD_CONNECT_IMAGE: "jamiewri/terraform-cloud-connect"
  TFE_CLOUD_CONNECT_TAG: "0.1-11"
  TFE_ORG: "devopstower"
  TFE_ADDR: "app.terraform.io"
  TFE_WORKSPACE_NAME: "${CI_PROJECT_NAMESPACE}-${CI_PROJECT_NAME}-${CI_COMMIT_REF_SLUG}"
  TFE_CONFIG_DIR: "${CI_PROJECT_DIR}/deploy"
  TFE_VARIABLES_FILE: "${CI_PROJECT_DIR}/variables.csv"
  TFE_ACTION: "apply"
  TFE_SET_VARIABLES_FORCE: "true"
  TFE_SAVE_PLAN: "false"
  TFE_SLEEP_INTERVAL: "5"
  TFE_VARIABLES_FILE_DELIMITER: ";"
  TFE_AUTO_APPROVE: "no"
  TFE_TERRAFORM_VERSION: "0.14.5"

  # Example TFC Terraform Vars
  TFE_VAR_EXAMPLE: "example"

  # Example TFC ENV Vars
  TFE_ENV_VAR_EXAMPLE_ENV: "example-env"

default:
  image: "${TFE_CLOUD_CONNECT_IMAGE}:${TFE_CLOUD_CONNECT_TAG}"

stages:
  - deploy
  - destroy

deploy:
  stage: deploy
  script: "echo Running terraform apply..."

destroy:
  stage: destroy
  variables:
    TFE_ACTION: "destroy"
  script: "echo Running terraform destroy..."
  when: manual
```
