# HarperDB Multi-Cloud Terraform Deployment

[Article Link](https://medium.com/geekculture/global-multi-cloud-terraform-deployment-for-low-latency-applications-worldwide-b02c65c859ca)

## Introduction

This repository contains the code and Terraform files required for the Multi-Cloud deployment project I wrote about in this article over on Medium. An ECS container is spun up in India and an Azure Container Instance is created in France. We also use Route53 to setup a DNS record to route the request to the User's closest server.

## Requirements

* [Terraform CLI](https://learn.hashicorp.com/tutorials/terraform/install-cli)
* [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
* [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

## Deployment

To spin up the resources, it can be done in a few simple commands:

```shell
cd deployment
terraform init
terraform apply
```

To destroy the resources at a later date:
```shell
terraform destroy
```