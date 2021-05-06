This repository contains a set of easy to use scripts that helps to provision recommended infrastructure for CKEditor Collaboration Server On-Premises. You can use the script as a reference or set up a production-ready service.

Regardless of the infrastructure provider, we're recommending to use layered architecture for the separation of data from the application layer.
Another key point is to run multiple instances and a load balancer to spread the traffic across them.
By implementing the infrastructure in this way the service will be easily scalable and more resilient.

- [Read more about Collaboration Server](https://ckeditor.com/docs/cs/latest/onpremises/cs-onpremises/overview.html)
- [Read more about recommended architecture for infrastructure](https://ckeditor.com/docs/cs/latest/onpremises/cs-onpremises/architecture.html)

## Providers
- [AWS ECS](/aws/ecs)
- [Kubernetes Helm chart](/kubernetes/helm)