## Secure access to RDS and Secrets Manager from a Lambda function using Terraform

In this project, I'll be exploring how to deploy entire CRUD Spring Boot applications using AWS Lambda + API Gateway +
RDS Proxy with Terraform.

### Deploy

```bash
$ cd spring-boot-lambda-vpc/terraform
$ terraform init
$ terraform fmt -recursive
$ terraform validate
$ terraform plan -var-file="terraform.tfvars" -no-color -out=TFplan.JSON
$ terraform apply -var-file="terraform.tfvars" -auto-approve
```

### Test the function

**Test Function with REST API Gateway**

Requests go to `<invoke_url>/{any-path}`, which routes through API Gateway's Lambda proxy integration to the Spring Boot
app via `StreamLambdaHandler`.

```
$ curl <invoke_url>/health
```

### Cleanup

***

To destroy all resources, run ```terraform destroy -var-file="terraform.tfvars" -auto-approve```
