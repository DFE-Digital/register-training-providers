# Support Playbook

## Enable/Disable API

If the API needs to be quickly disabled/enabled do the following

### Run the workflow

- Go to the [Set API Access workflow](https://github.com/DFE-Digital/register-training-providers/actions/workflows/api_access.yml)
- Click `Run workflow`
- Choose the environment where the API needs to be disabled/enabled
- Set the API flag setting
- Go to [https://register-of-training-providers.education.gov.uk/sha](https://register-of-training-providers.education.gov.uk/sha) and copy the SHA
- Add the SHA to the Docker Image tag field
- Click `Run workflow`
