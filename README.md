## Collaboration Server On-Premises
This repository contains a set of easy-to-use scripts that help to provision the recommended infrastructure for CKEditor Collaboration Server On-Premises. You can use these scripts as a reference or to set up a production-ready service.

Regardless of the infrastructure provider, we recommend using a layered architecture for the separation of data from the application layer. Another key point is to run multiple instances and a load balancer to spread the traffic across them. By implementing the infrastructure in this way, the service will be easily scalable and more resilient.

- [Read more about the Collaboration Server](https://ckeditor.com/docs/cs/latest/onpremises/cs-onpremises/overview.html)
- [Read more about the recommended architecture for the infrastructure](https://ckeditor.com/docs/cs/latest/onpremises/cs-onpremises/architecture.html)

## Providers
- [AWS ECS](/aws/ecs)
- [Kubernetes Helm charts](/kubernetes/helm)

## Collaboration Server On-Premises Quick-start
The Collaboration Server On-Premises Quick-Start guide lets you quickly set up the infrastructure needed to use CKEditor 5 WYSIWYG editor with Real-Time Collaboration and Collaboration Server On-Premises. After running a single setup command, you can run a working CKEditor 5 instance and start testing our solution with the Collaboration Server running locally on your machine. Check out the [On-Premises Quick-start](/quick-start) guide.
