# CKEditor Collaboration Server On-Premises Helm chart

Use this Helm chart to provision CKEditor Collaboration Server on your
Kubernetes cluster.

## Minimum requirements
- 2 CPU Core
- 1024MB RAM
- One of the following SQL databases:
  - MySQL 5.6/5.7
  - PostgreSQL min. 12.0
- External Redis cluster 3.2.6 or newer
- Kubernetes 1.19+
- Helm v3

Default configuration of running this service requires reservation of 2 CPU
cores and 1GB of RAM in cluster. For more information about resources usage look
here:
https://ckeditor.com/docs/cs/latest/onpremises/cs-onpremises/requirements.html#docker

## Installation

For installation instructions follow [here](../README.md#quick-start).
