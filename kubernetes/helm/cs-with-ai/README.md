# Collaboration Server with CKEditor AI Service On-Premises Helm chart

Use this Helm chart to run CKEditor Collaboration Server On-Premises and
CKEditor AI Service On-Premises side by side on **one shared data layer** — the
compatible mode. Both services connect to the same SQL database and
the same Redis instance, which means:

- **Shared environments** — every environment and access key created in the
  Collaboration Server management panel is available to the AI Service
  automatically.
- **A single management panel** — the AI Service's own panel is disabled, and
  both services are configured from the Collaboration Server panel.
- **A single token endpoint** — one JWT carries `auth.collaboration` for
  collaboration roles and `auth.ai.permissions` for AI access.

There is nothing to switch on: the AI Service detects the Collaboration Server
through the shared database by itself. The only thing that matters is that the
`DATABASE_*` and `REDIS_*` values are identical on both sides, so this chart
defines them once and merges them into both components.

> :warning: Compatible mode requires Collaboration Server On-Premises **5.0.0
> or newer**. The two services are released together, and keeping them on the
> same version is strongly recommended — upgrade them at the same time.

See
[Integration with Collaboration Server On-Premises](https://ckeditor.com/docs/cs/latest/onpremises/ckeditor-ai-onpremises/deployment.html#integration-with-collaboration-server-on-premises)
for the product-side description of this setup.

## Charts used as dependencies
- [`ckeditor-cs`](../ckeditor-cs) — Collaboration Server and, optionally, the
  collaboration worker
- [`ai-service`](../ai-service) — CKEditor AI Service
- [`misc/mysql`](../misc/mysql) — optional, disabled by default
- [`misc/redis`](../misc/redis) — optional, disabled by default

## Requirements
- One of the following SQL databases, shared by both services:
  - MySQL 8.0 or newer
  - PostgreSQL 12.0 or newer
- External Redis 3.2.6 or newer, shared by both services
- At least one configured LLM provider
- Two license keys — one for the Collaboration Server, one for CKEditor AI
  Server — and the download token(s) for both images
- Kubernetes 1.19+
- Helm v3

## Installation

- create imagePullSecret for pulling images from the CKEditor container
  registry, replacing `xxx` with your download token from the
  [CKEditor Customer Portal](https://portal.ckeditor.com/)

```sh
kubectl create secret docker-registry docker-cke-cs-com \
    --docker-username "cs" \
    --docker-server "https://docker.cke-cs.com" \
    --docker-password="xxx"
```

If your Collaboration Server and AI Service download tokens are different,
create a second secret for the AI Service and point `ai-service.imagePullSecrets`
at it:

```sh
kubectl create secret docker-registry docker-cke-cs-com-ai \
    --docker-username "ai-service" \
    --docker-server "https://docker.cke-cs.com" \
    --docker-password="xxx"
```

- fill in the shared values. `PROVIDERS` is a stringified JSON object, so a
  values file is easier than `--set`. Note that the two `LICENSE_KEY` values are
  **different keys**, one per subscription. Helm deep-merges your file over the
  chart defaults, so you only need to list what actually changes — the anchors
  below are just a convenient way to keep the two copies of the shared
  connection details from drifting apart.

```yaml
# cs-with-ai.values.yaml
sharedDatabase: &sharedDatabase
  DATABASE_DRIVER: mysql
  DATABASE_HOST: mysql.databases.svc.cluster.local
  DATABASE_USER: cs_app
  DATABASE_PASSWORD: xxx
  DATABASE_DATABASE: cs-on-premises
sharedRedis: &sharedRedis
  REDIS_HOST: redis-master.databases.svc.cluster.local

ckeditor-cs:
  server:
    secret:
      data:
        <<: [*sharedDatabase, *sharedRedis]
        ENVIRONMENTS_MANAGEMENT_SECRET_KEY: xxx
        LICENSE_KEY: xxx
    ingress:
      enabled: true
      hosts:
        - host: ckeditor-cs.example.com
          paths:
            - path: /

ai-service:
  secret:
    data:
      <<: [*sharedDatabase, *sharedRedis]
      ENVIRONMENTS_MANAGEMENT_SECRET_KEY: xxx
      LICENSE_KEY: xxx
      PROVIDERS: '{"openai":{"type":"openai","apiKeys":["your-api-key"]}}'
  ingress:
    enabled: true
    hosts:
      - host: ckeditor-ai.example.com
        paths:
          - path: /
            pathType: 'Prefix'
```

- install the chart

>:warning: The release has to be named `cs-with-ai`. The default
>`AI_API_BASE_URL` is derived from that release name; installing under a
>different name means updating it to match.

>:warning: By default, the chart installs both services with the "latest" tag.
>For a production environment it is strongly recommended to pin both
>`ckeditor-cs.server.image.tag` and `ai-service.image.tag` to the same numeric
>version.

```sh
cd cs-with-ai
helm repo update
helm dependency update
helm install cs-with-ai . --values cs-with-ai.values.yaml
```

> :warning: **If you want to store configuration**: make sure your environment
> variables are secure before saving them in an external service. You can use
> [SOPS](https://github.com/getsops/sops) for encrypting specific parts of the
> yaml file.

- open the Collaboration Server management panel, sign in with your
  `ENVIRONMENTS_MANAGEMENT_SECRET_KEY`, and create an environment and an access
  key there. They apply to both services.

## Trying it out locally

Setting `mysql.enabled` and `redis.enabled` to `true` deploys a throwaway MySQL
and Redis in the cluster and gives you a complete compatible-mode stack in one
command. The database hostnames are then `cs-with-ai-mysql` and
`cs-with-ai-redis-master`.

>:warning: **Not for production purposes!** Those two charts are insecure and
>not persistent — their purpose is testing only.

## AI_API_BASE_URL

The Collaboration Server management panel proxies AI API calls, and the address
it uses defaults to the Collaboration Server's own port. That default is correct
only when both services run inside a single process, which is not the case here
— they are two separate deployments. This chart therefore sets `AI_API_BASE_URL`
on the Collaboration Server to the AI Service's in-cluster address
(`http://cs-with-ai-ai-service:8080`). Change it if you rename the release or
the AI Service's `service.port`.

## Storage

The AI Service defaults to `STORAGE_DRIVER=database` here, so its files live in
the SQL database that both services already share and compatible mode needs no
additional storage. The Collaboration Server keeps its own Easy Image storage
configuration — the two are independent, and sharing a data layer does not mean
sharing a storage driver.

## Deleting

```sh
helm delete cs-with-ai
```
