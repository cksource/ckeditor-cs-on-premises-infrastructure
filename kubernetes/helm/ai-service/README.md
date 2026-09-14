# CKEditor AI Service On-Premises Helm chart

Use this Helm chart to provision CKEditor AI Service On-Premises on your
Kubernetes cluster. The chart deploys the AI service in its **standalone**
variant — with its own SQL database, Redis and management panel.

> :bulb: If you already run Collaboration Server On-Premises 5.0.0 or newer and
> want both services to share a single data layer, point `DATABASE_*` and
> `REDIS_*` at the same instances the Collaboration Server uses. In that setup
> the AI management panel is disabled and everything is managed from the
> Collaboration Server management panel. See
> [Integration with Collaboration Server On-Premises](https://ckeditor.com/docs/cs/latest/onpremises/ckeditor-ai-onpremises/deployment.html#integration-with-collaboration-server-on-premises).

## Requirements
- One of the following SQL databases:
  - MySQL 8.0 or newer
  - PostgreSQL 12.0 or newer
- External Redis 3.2.6 or newer (single instance or Redis Cluster; Redis
  Sentinel is not supported)
- At least one configured LLM provider (OpenAI, Anthropic, Google, Azure
  OpenAI, Amazon Bedrock, Google Vertex AI or any OpenAI API-compatible
  provider)
- File storage: AWS S3, Azure Blob Storage, filesystem or the SQL database
- Kubernetes 1.19+
- Helm v3

The documentation does not prescribe fixed CPU and memory figures, so this
chart leaves `resources.requests` empty — monitor your deployment and adjust
them to your traffic. Running at least 3 replicas is recommended for high
availability, which is the default of this chart. For more information look
here:
https://ckeditor.com/docs/cs/latest/onpremises/ckeditor-ai-onpremises/requirements.html

The database has to exist before the service starts, and the database user
needs at least the `ALTER`, `CREATE`, `DELETE`, `DROP`, `INDEX`, `INSERT`,
`SELECT`, `TRIGGER`, `UPDATE`, `LOCK TABLES` and `REFERENCES` privileges. See
the [Deployment guide](https://ckeditor.com/docs/cs/latest/onpremises/ckeditor-ai-onpremises/deployment.html)
for ready-to-use database creation scripts.

## Installation

- create imagePullSecret for pulling images from the CKEditor container
  registry, replace `xxx` with the download token from the
  [CKEditor Customer Portal](https://portal.ckeditor.com/)

```sh
kubectl create secret docker-registry docker-cke-cs-com \
    --docker-username "ai-service" \
    --docker-server "https://docker.cke-cs.com" \
    --docker-password="xxx"
```

- install chart in the cluster

>:warning: By default, the chart installs CKEditor AI Service On-Premises with
>the "latest" tag. If you are using this chart for a production environment, it is
>strongly recommended to change the container image tag to a numeric
>representation of the version you want to install.

The `PROVIDERS` variable is a stringified JSON object, so it is easiest to keep
it in a values file instead of passing it with `--set`:

```yaml
# ai.values.yaml
secret:
  data:
    LICENSE_KEY: "xxx"
    ENVIRONMENTS_MANAGEMENT_SECRET_KEY: "xxx"
    DATABASE_DRIVER: "mysql"
    DATABASE_HOST: "mysql.databases.svc.cluster.local"
    DATABASE_USER: "ai_service"
    DATABASE_PASSWORD: "xxx"
    DATABASE_DATABASE: "ai-service-on-premises"
    REDIS_HOST: "redis-master.databases.svc.cluster.local"
    PROVIDERS: '{"openai":{"type":"openai","apiKeys":["your-api-key"]}}'
    STORAGE_DRIVER: "database"
ingress:
  enabled: true
  hosts:
    - host: ai-service.example.com
      paths:
        - path: /
          pathType: 'Prefix'
```

```sh
helm install ai-service ./ai-service \
    --set image.tag="latest" \
    -f ai.values.yaml
```

> :warning: **If you want to store configuration**: make sure your environment
> variables are secure before saving them in an external service. You can use
> [SOPS](https://github.com/getsops/sops) for encrypting specific parts of the
> yaml file.

Environment variables listed in `values.yaml` are the absolute minimum to run
the service. Visit the documentation for the whole list of configuration
options, including custom models, storage drivers, content moderation, web
search and OpenTelemetry:

https://ckeditor.com/docs/cs/latest/onpremises/ckeditor-ai-onpremises/configuration.html

- validate the installation by opening the management panel at the address the
  service is exposed on and signing in with your
  `ENVIRONMENTS_MANAGEMENT_SECRET_KEY`. Create an environment and an access key
  there — you will need both for your token endpoint. The remaining steps are
  described in the
  [Deployment guide](https://ckeditor.com/docs/cs/latest/onpremises/ckeditor-ai-onpremises/deployment.html#running-the-service).

## Deleting

```sh
helm delete ai-service
```
