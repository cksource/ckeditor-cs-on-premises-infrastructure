# Collaboration Server On-Premises Quick-Start guide

The Collaboration Server On-Premises Quick-Start guide lets you quickly set up the infrastructure needed to use CKEditor 5 with Real-Time Collaboration and Collaboration Server On-Premises. With a single setup command you can run a working CKEditor 5 instance and start testing our solution, with the Collaboration Server running locally on your machine.

**The infrastructure created with the Collaboration Server On-Premises Quick-Start can be only used for testing purposes during local development and it cannot be used in production.** For details about production-grade architecture please refer to the [Collaboration Server On-Premises Architecture](https://ckeditor.com/docs/cs/latest/onpremises/cs-onpremises/architecture.html) guide.


## Prerequisites

To successfully run Collaboration Server On-Premises Quick-Start you need the following tools:
- **Docker Desktop** for Windows or Mac (or Docker tools for Linux)
- **node** version 10 and above
- **npm** version 6 and above
- **git**

If you do not have these tools installed on your machine, refer to the following installation guides:
- The [Docker Desktop on Win10 installation guide](https://docs.docker.com/docker-for-windows/install/)
- The [Docker Desktop on Mac installation guide](https://docs.docker.com/docker-for-mac/install/)
- The [Node.js download page](https://nodejs.org/en/)
- The [Git installation guide](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)


The On-Premises Quick-Start installation will download several docker images about 2GB in size. Appropriate free space on your disk is hence required.

## Setup steps
1. Make sure that Docker Desktop is running. You can check the Docker tray icon to see the current status.

2. Verify that you have all the necessary tools installed by running this command in your terminal:
```
docker -v && docker-compose -v && node -v && npm -v && git --version
```
You should see version numbers of all these tools. If you see a `command not found` message, please install the missing tool before proceeding with the next step.

3. Clone this repository and install the packages with the following commands:
```
git clone https://github.com/cksource/ckeditor-cs-on-premises-infrastructure.git

cd ckeditor-cs-on-premises-infrastructure/quick-start && npm install
```

4. Run the On-Premises Quick-Start, replacing the credentials placeholders with your own credentials:
```
node setup.js --license_key="YOUR_LICENSE_KEY" --docker_token="YOUR_DOCKER_DOWNLOAD_TOKEN" --env_secret="YOUR_ENVIRONMENT_SECRET"
```
Where to find your own credentials:
- The `license_key` can be found in [CKEditor Ecosystem Dashboard](https://dashboard.ckeditor.com/) in your CKEditor Collaboration Server On-Premises subscription page.
- The `docker_token` can be found in CKEditor Ecosystem Dashboard in your CKEditor Collaboration Server On-Premises subscription page in the *Download token* section. If you do not see any tokens, you can create them with the *Create new token* button.
- The `env_secret` is your password, that will be used to access the Collaboration Server On-Premises [management panel](https://ckeditor.com/docs/cs/latest/onpremises/cs-onpremises/management.html)


**Running this setup process for the first time may take several minutes.** The script needs to pull several docker images from the web, install the packages and build the editor bundle. The following command runs will be much shorter. After the successful installation, you should see a message stating `Visit http://localhost:3000 to start collaborating`. Open this page in your browser.

When your testing session is over you can simply stop running the process in the terminal with the `Ctrl+C` keystroke and the containers created will be removed from your machine.


## setup.js arguments

Only the 3 arguments mentioned above are required to successfully run our On-Premises Quick-Start. There are, however, other optional arguments to customize the setup process. Here is a list of all possible arguments:

```
--license_key=""      - required,
--docker_token=""     - required,
--env_secret=""       - required,
--docker_endpoint=""  - optional, the default is "docker.cke-cs.com", use it to change the docker registry url
--version=""          - optional, the default is "latest", use it to specify a different version of the docker image
--cs_port=""          - optional, the default is "8000", a port for Collaboration Server On-Premises
--node_port=""        - optional, the default is "3000", a port for the frontend part of Quick-Start
--keep_containers     - optional, use it to preserve the created containers on exit
```

**Note:** If you use different ports than the default ones, please remember to update the URL endpoints after opening a sample page.
