# Support Playbook

## Enable/Disable API

If the API needs to be quickly disabled/enabled do the following

### Find DOCKER_IMAGE_TAG

- Go to the `Build and deploy` workflow
- Find the most recent deploy to `main`
- Select the `Deploy environments (production)` job
- search for the `DOCKER_IMAGE_TAG` and copy it

### Run the workflow

- Go to the Set API Access workflow
- Click `Run workdlow`
- Choose the environment where the API needs to be disabled/enabled
- Set the API flag setting
- Add the Docker Image tag
- Click `Run workflow`
