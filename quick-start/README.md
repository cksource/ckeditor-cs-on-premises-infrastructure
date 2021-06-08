### Collaboration Server On-Premises Quick-Start guide

Collaboration Server On-Premises Quick-Start allows you to quickly set up the infrastructure needed to use CKEditor 5 with Real-Time Collaboration and Collaboration Server On-Premises. After running one setup command you can jump into working CKEditor 5 instance and start testing our solution, while the Collaboration Server is running locally, on your machine.

**Infrastructure created with Collaboration Server On-Premises Quick-Start can be only used for testing purposes during local development and it cannot be used in production.** For details about production-grade architecture please refer to [our guide.](https://ckeditor.com/docs/cs/latest/onpremises/cs-onpremises/architecture.html)


## Prerequisites

To successfully run Collaboration Server On-Premises Quick-Start you need the following tools:
- **Docker Desktop** for Windows or Mac (or Docker tools for Linux)
- **node** version 10 and above
- **npm** version 6 and above
- **git**

If you do not have those tools installed on your machine, then refer to the following guides:
- [Docker Desktop on Win10 installation guide](https://docs.docker.com/docker-for-windows/install/)
- [Docker Desktop on Mac installation guide](https://docs.docker.com/docker-for-mac/install/)
- [Node.js download page](https://nodejs.org/en/)
- [Git installation guide](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)


On-Premises Quick-Start installation will download few docker images with about 2GB in size. Similar space on your disk is also required.


## Setup steps
1. Make sure that Docker Desktop is running. You can check Docker tray icon to see the current status.

2. Verify if you have all needed tools installed by running this command in your terminal:
```
docker -v && docker-compose -v && node -v && npm -v && git --version
```
You should see all version numbers of those tools. If there is a message `command not found`, then please install the missing tool before proceeding to the next step.

3. Clone this repository and install packages with the following commands:
```
git clone https://github.com/cksource/ckeditor-cs-on-premises-infrastructure.git

cd ckeditor-cs-on-premises-infrastructure/quick-start && npm install
```

4. Run On-Premises Quick-Start, replacing credentials placeholders with your credentials:
```
node setup.js --license_key="YOUR_LICENSE_KEY" --docker_token="YOUR_DOCKER_DOWNLOAD_TOKEN" --env_secret="YOUR_ENVIRONMENT_SECRET"
```
Where:
- `license_key` can be found in CKEditor Ecosystem Dashboard inside your CKEditor Collaboration Server On-Premises subscription.
- `docker_token` can be found in CKEditor Ecosystem Dashboard inside your CKEditor Collaboration Server On-Premises subscription in the *Download token* section. If you do not see any tokens, you can create it with the *Create new token* button.
- `env_secret` is your password, that will be used to access the [Management panel](https://ckeditor.com/docs/cs/latest/onpremises/cs-onpremises/management.html)


**Running this setup process for the first time may take several minutes.** It has to pull few docker images from the web, install packages and build the editor bundle. Further command runs will be much shorter. After successful installation you should see a message `Visit http://localhost:3000 to start collaborating`. Open this page in your browser. 
When your testing session is over you can simply stop running the process in the terminal with Ctrl+C and created containers will be removed from your machine.


## setup.js arguments

Only 3 arguments are needed to successfully run our On-Premises Quick-Start. Here is a list of all possible arguments:
```
--license_key=""      - required,
--docker_token=""     - required,
--env_secret=""       - required,
--docker_endpoint=""  - optional, default is "docker.cke-cs.com", use it to change docker registry url
--cs_port=""          - optional, default is "8000", port for Collaboration Server On-Premises
--node_port=""        - optional, default is "3000", port for Frontend part of Quick-Start
--keep_containers     - optional, use it to preserve created containers on exit
```

**Note:** If you use different ports, then please remember to update URL endpoints after opening editor page.
