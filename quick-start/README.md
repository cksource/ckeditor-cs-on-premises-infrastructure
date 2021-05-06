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


On-Premises Quick-Start installation will download few docker images with about 2GB in size. Similar space on your disk is also needed.


## Setup steps

1. Verify if you have all needed tools installed by running this command in your terminal:
```
docker -v && docker-compose -v && node -v && npm -v && git --version
```
You should see all version numbers of those tools. If there is a message `command not found`, then please install the missing tool before proceeding to the next step.

2. Clone this repository and install packages with the following commands:
```
git clone https://github.com/cksource/ckeditor-cs-on-premises-infrastructure.git

cd ckeditor-cs-on-premises-infrastructure

git checkout quick-start && cd quick-start && npm install
```

3. Run On-Premises Quick-Start, replacing credentials placeholders with your credentials:
```
node setup.js --license_key="YOUR_LICENSE_KEY" --docker_token="YOUR_DOCKER_DOWNLOAD_TOKEN" --env_secret="YOUR_ENVIRONMENT_SECRET"
```
Where:
- `license_key` can be found in CKEditor Ecosystem Dashboard inside your CKEditor Collaboration Server On-Premises subscription.
- `docker_token` can be found in CKEditor Ecosystem Dashboard inside your CKEditor Collaboration Server On-Premises subscription in the *Download token* section. If you do not see any tokens, you can create it with the *Create new token* button.
- `env_secret` is a password, that will be used to access the [Management panel](https://ckeditor.com/docs/cs/latest/onpremises/cs-onpremises/management.html)


This is it. After a while, you should see a message `Visit http://xx.xx.xx.xx:port to start collaborating`. Open this page in your browser. Anyone from your network will be able to connect and collaborate.
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

**Note:** By default ports 3000 and 8000 are used. The setup process is checking if those ports are available and if they are not, then the next available port will be used. Port checking mechanism will not be used if ports are specified as arguments using `--cs_port` and `--node_port`.
