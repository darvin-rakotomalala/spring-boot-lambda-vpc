## Secure access to RDS and Secrets Manager from a Lambda function using Terraform

This repository contains the Terraform code and CI/CD pipelines to deploy a Spring Boot AWS Lambda function and an RDS
PostgreSQL database inside a private VPC. The function reads its database credentials from Secrets Manager through a
VPC Interface Endpoint, so no traffic ever needs a route to or from the internet.

### The problem

***

You put the database password in Secrets Manager, then moved the Lambda into the database VPC, and everything broke.
By default, a Lambda function runs in an AWS-managed network with internet access. Once you attach it to your VPC, it
can reach your private resources (RDS), but it can no longer reach public AWS services like Secrets Manager.

You have two options to fix it:

```
Lambda (private subnet) → NAT Gateway → internet → Secrets Manager (extra cost, slower, less secure)
Lambda (private subnet) → VPC Interface Endpoint → Secrets Manager (private, no NAT cost, lower latency)
```

This project uses the second option. Interface Endpoints keep traffic on AWS's internal network and remove NAT Gateway
processing fees.

### Architecture overview

***

**Core components**

* **Lambda**: Serverless compute, running in the VPC.
* **RDS (PostgreSQL) + RDS Proxy**: Managed database and connection pooling.
* **Secrets Manager**: Stores the database credentials, encrypted with KMS.
* **VPC**: Private network where Lambda, RDS and the endpoints live. This is the focus of the project.
* **KMS**: One customer-managed key to encrypt secrets, database storage and logs.
* **API Gateway**: REST entry point for users (see diagram).
* **CloudWatch**: Logs, metrics and alarms.
* **GitHub Actions + OIDC**: CI/CD pipeline that runs Terraform and deploys the app.

![spring-boot-lambda-vpc.png](spring-boot-lambda-vpc.png)

**Request flow:** Users → API Gateway → Lambda (private subnet) → RDS Proxy → RDS.
Lambda → VPC Interface Endpoint → Secrets Manager. Secrets Manager, RDS and CloudWatch use a KMS key for encryption.

### Technology Stack

***

* Application: Java 21, Spring Boot, Maven
* AWS Cloud: Lambda, API Gateway, RDS PostgreSQL, RDS Proxy, Secrets Manager, KMS, IAM, CloudWatch
* Infrastructure as Code: Terraform
* CI/CD Automation: GitHub Actions with GitHub OIDC

### Prerequisites

***

* AWS Account
* Terraform CLI (~> 1.14)
* Java 21
* Apache Maven

### Implementation

***

Provisions the infrastructure described in the technical spec:

1. Networking
2. Encryption (KMS)
3. Security groups
4. VPC endpoints
5. Database and secrets
6. IAM
7. Lambda configuration
8. Monitoring

![1-Outputs.png](Screenshot%20verification/1-Outputs.png)

### Deployment Workflow

***

The infrastructure must be created before the application can be deployed.

* **Deploy Infrastructure**: Commit and push a change to the `terraform/` directory on the master branch. The
  infrastructure pipeline (`deploy_infra.yaml`) provisions the AWS resources.
* **Deploy Application**: Push a change to the Java source code in `src/` to the master branch. The application pipeline
  (`deploy_app.yaml`) builds the JAR and deploys it to the Lambda function created in the previous step.

GitHub Actions authenticates to AWS through OIDC, so no long-lived credentials are stored in the repository.

### Verification and Testing the Lambda Function on AWS

***

1. Open the AWS Console → Lambda → select the function → Configuration → VPC, and confirm the subnets and the
   `LambdaSG` security group with its inbound and outbound rules.
2. Invoke the function through API Gateway and confirm it reads the secret and connects to the database.
3. Confirm the database is not publicly accessible and that function logs and VPC Flow Logs appear in CloudWatch.

**Test REST endpoints API Gateway using Postman**

Requests go to `<invoke_url>/{any-path}`, which routes through API Gateway's Lambda proxy integration to the Spring Boot
app via `StreamLambdaHandler`.

`$ GET <invoke_url>/health`

* Health Check ```GET https://vtbw44nt3c.execute-api.us-east-1.amazonaws.com/dev/health```
* POST ```https://vtbw44nt3c.execute-api.us-east-1.amazonaws.com/dev/tutorials``` — create new Tutorial
* GET ```https://vtbw44nt3c.execute-api.us-east-1.amazonaws.com/dev/tutorials``` — retrieve all Tutorials
* GET ```https://vtbw44nt3c.execute-api.us-east-1.amazonaws.com/dev/tutorials/:id``` — retrieve a Tutorial by ```:id```
* PUT ```https://vtbw44nt3c.execute-api.us-east-1.amazonaws.com/dev/tutorials/:id``` — update a Tutorial by ```:id```
* DELETE ```https://vtbw44nt3c.execute-api.us-east-1.amazonaws.com/dev/tutorials/:id``` — delete a Tutorial by ```:id```
* DELETE ```https://vtbw44nt3c.execute-api.us-east-1.amazonaws.com/dev/tutorials``` — delete all Tutorials
* GET ```https://vtbw44nt3c.execute-api.us-east-1.amazonaws.com/dev/tutorials/published``` — find all published
  Tutorials
* GET ```https://vtbw44nt3c.execute-api.us-east-1.amazonaws.com/dev/tutorials?title=[keyword]``` — find all Tutorials
  which title contains keyword

### Key Takeaways

* **Putting the Lambda in the VPC**: Without it, the function can only reach RDS over the public internet, which is
  slower and forces you to expose the database. Network isolation plus password authentication is **defense in depth**.
* **Adding a VPC Endpoint**: Secrets Manager is a public service outside your VPC. Once the Lambda is in your VPC it
  can't reach it unless you add a NAT Gateway (traffic goes over the internet: slower, costlier, less secure) or a VPC
  Interface Endpoint, which gives Secrets Manager a private IP inside your VPC over AWS's internal network.
* **Security Groups**: Restricting `DatabaseSG` to the proxy/Lambda groups blocks the internet and also other resources
  inside the VPC. Note that access is granted to any resource carrying the security group, not to one specific function.
* **IAM Roles**: Access is denied by default. Start from what the function needs ("read this secret, connect to this
  database"), find the specific permissions, and grant only those (least privilege) so a compromised function can't
  reach the rest of your account.

### Summary

***

* **Lambda in the VPC**: Keeps the database off the internet and the connection short. Network isolation plus password
  authentication gives you defense in depth.
* **VPC Endpoint**: Gives Secrets Manager a private IP inside your VPC, so the function reaches it without a NAT
  Gateway or the public internet.
* **Security groups**: Allow only the Lambda path into the database.
* **IAM least privilege**: Grants the function only the permissions it actually needs.
