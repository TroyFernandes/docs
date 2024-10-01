# Setup Gitea Actions

Guide to setting up Gitea Actions under docker

## Why?
1. Replicate Github Actions locally
2. It's annoying to verify Github Actions by making a push to a repo. Gitea actions are supposed to be a drop in replacement for Github Actions.
3. You can assign way more hardware to the runner

## Goals at the end of the day
We should have runners setup and available to execute the actions within our repos.

## Resources
- [Gitea Actions](https://docs.gitea.com/usage/actions/overview)
- [Gitea Actions Quickstart](https://docs.gitea.com/usage/actions/quickstart/)
- [Gitea Act Runner](https://docs.gitea.com/usage/actions/act-runner)

## Requirements
1. A gitea server
2. A machine with docker installed as well as docker-compose

## How-To

### Installing Act Runner

1. We need to get the registration token from our gitea server. Within the gitea server, go into the terminal and run: `gitea --config /etc/gitea/app.ini actions generate-runner-token`. We'll get a token looking similar to this: `4ALVqHi8lx8Yk34RIJCn9pyqgafFDjEMpNQxHEpi`
    - Note: You can't run the above command as root. Make sure you're logged into an account that isnt root. e.g: `su - gitea`

2. Create the `docker-compose.yml` file. The Gitea docs have a standard template, I'll show you what I used:
```yaml
version: "3.8"
services:
  runner:
    image: gitea/act_runner:nightly
    environment:
      CONFIG_FILE: /config.yaml
      GITEA_INSTANCE_URL: "http://192.168.1.232:3000/"
      GITEA_RUNNER_REGISTRATION_TOKEN: "4ALVqHi8lx8Yk34RIJCn9pyqgafFDjEMpNQxHEpi"
      # GITEA_RUNNER_NAME: "${RUNNER_NAME}"
      # GITEA_RUNNER_LABELS: "${RUNNER_LABELS}"
    volumes:
      - ./config/config.yaml:/config.yaml
      - ./data:/data
      - /var/run/docker.sock:/var/run/docker.sock
```
3. `docker-compose up -d` and the runner should register with your gitea instance.

4. Go to your gitea dashboard and do: `Settings -> Actions -> Runners` and you should see the runner you just created.

5. The runner is setup now. Lets clone a repo and add an action.

6. To add an action, within the root dir, create directory `.gitea/workflows/`

7. Add your action file. Name it whatever you like with the extension `.yml`. Lets use the example from Gitea.

```yaml
name: Gitea Actions Demo
run-name: ${{ gitea.actor }} is testing out Gitea Actions
on: [push]

jobs:
  Explore-Gitea-Actions:
    runs-on: ubuntu-latest
    steps:
      - run: echo "The job was automatically triggered by a ${{ gitea.event_name }} event."
      - run: echo "This job is now running on a ${{ runner.os }} server hosted by Gitea!"
      - run: echo "The name of your branch is ${{ gitea.ref }} and your repository is ${{ gitea.repository }}."
      - name: Check out repository code
        uses: actions/checkout@v4
      - run: echo "The ${{ gitea.repository }} repository has been cloned to the runner."
      - run: echo "The workflow is now ready to test your code on the runner."
      - name: List files in the repository
        run: |
          ls ${{ gitea.workspace }}
      - run: echo "This job's status is ${{ job.status }}."
```

8. Now push the repo. You should see a little yellow dot next to your username, above the topmost folder on the Gitea dashboard. You can click into it to check the status of the action.
## End

Our Gitea server should now have runners available to execute actions within our repos.

## Final Thoughts / Learnings

My initial assumption was that gitea had the capability to execute actions out of the box, but this isn't the case and the reason makes sense.

It's better to have "Ephemeral" runners. Which esentilally means they're created when needed, then destroyed after. This allows you to not worry about having a cleanup script after the action has completed, ensuring the action is always run in a repetable, clean state.

You'll notice within the docker compose file we bind the docker sock. This allows the runner to create seperate containers that are destroyed after the action has completed.