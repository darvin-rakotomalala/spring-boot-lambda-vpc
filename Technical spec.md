## Project: Secure access to RDS and Secrets Manager from a Lambda function using Terraform

### Scenario

You've deployed a database in RDS and a Lambda function that needs to talk to it. You stored the database password in
Secrets Manager, then put the Lambda in the database VPC, and everything broke: the function can no longer reach
Secrets Manager (a public AWS service). This project fixes that with private networking, tight security groups, a KMS
key and least-privilege IAM, all provisioned with Terraform.

**Objective**: Deploy AWS Lambda (Spring Boot, Java 21) and RDS PostgreSQL in a VPC using Terraform, with Secrets
Manager access over a VPC Interface Endpoint and no route to or from the internet.

### Services

* **Lambda**: Serverless compute, running in the VPC.
* **RDS (PostgreSQL) + RDS Proxy**: Managed database and connection pooling.
* **Secrets Manager**: Stores the database credentials, encrypted with KMS.
* **VPC**: Private network where Lambda, RDS and the endpoints live. This is the focus of the project.
* **KMS**: One customer-managed key to encrypt secrets, database storage and logs.
* **API Gateway**: REST entry point for users (see diagram).
* **CloudWatch**: Logs, metrics and alarms.
* **GitHub Actions + OIDC**: CI/CD pipeline that runs Terraform and deploys the app.

### Architecture overview

![spring-boot-lambda-vpc.png](spring-boot-lambda-vpc.png)

**Request flow**: Users → API Gateway → Lambda (private subnet) → RDS (via RDS Proxy). Lambda → Interface Endpoint →
Secrets Manager. Secrets Manager, RDS and CloudWatch use KMS for encryption.

---

### Implementation

#### 1. Networking (VPC)

| Setting                | Value                                                                    |
|------------------------|--------------------------------------------------------------------------|
| `vpc_cidr`             | `18.25.15.0/25`                                                          |
| `subnet_cidr_private`  | `["18.25.15.0/27", "18.25.15.32/27", "18.25.15.64/27"]`                  |
| Availability Zones     | `us-east-1a`, `us-east-1b`, `us-east-1c` (one private subnet each)       |
| `enable_dns_support`   | `true`                                                                   |
| `enable_dns_hostnames` | `true` (required for Interface Endpoint private DNS)                     |
| `enable_flow_log`      | `true`, delivered to a CloudWatch Log Group (encrypted with the KMS key) |

* Use **private subnets only**: no Internet Gateway route and no NAT Gateway.
* Create a DB subnet group for RDS spanning the private subnets.

#### 2. Encryption (KMS)

1. Create one KMS key (with rotation enabled) to encrypt all resources in the project.
2. In the key policy, allow Secrets Manager, CloudWatch Logs and RDS to use the key. Allow the Lambda role to decrypt
   only what it needs.

#### 3. Security Groups

Use one consistent set of groups (replaces the duplicate `lambda-sg` / `endpoint_sg` naming):

| Group              | Attached to                                     | Inbound rule                                            |
|--------------------|-------------------------------------------------|---------------------------------------------------------|
| `LambdaSG`         | Lambda function                                 | None required (Lambda is invoked, not connected to)     |
| `SecretsManagerSG` | Secrets Manager (and other) Interface Endpoints | TCP 443 from `LambdaSG`                                 |
| `RdsProxySG`       | RDS Proxy                                       | TCP 5432 from `LambdaSG`                                |
| `DatabaseSG`       | RDS instance                                    | TCP 5432 (PostgreSQL; 3306 for MySQL) from `RdsProxySG` |

* `LambdaSG` outbound: TCP 443 to `SecretsManagerSG` (and the other endpoints), TCP 5432 to `RdsProxySG`.
* Reference security groups as sources instead of CIDR ranges, so access follows the resource, not the IP.

#### 4. VPC Endpoints

* **Interface Endpoints** (private DNS enabled, placed in the private subnets, attached to `SecretsManagerSG`):
  Secrets Manager, CloudWatch Logs, SNS, SQS, EventBridge.
  CloudWatch Logs is needed because there is no internet route for log delivery.
* **Gateway Endpoints** (free, attached to the private route tables): S3 and DynamoDB.

#### 5. Database (RDS + RDS Proxy)

1. Create the RDS PostgreSQL instance, primary in `us-east-1a`, encrypted with the KMS key, not publicly accessible,
   attached to `DatabaseSG`.
2. Create the RDS Proxy in the private subnets, attached to `RdsProxySG`, using the database secret for authentication.
3. Keep the Lambda subnets and RDS primary aligned so most invocations stay in the same AZ (lower latency and no
   cross-AZ data charges).

#### 6. Secrets Manager

1. Create the secret for the database credentials, encrypted with the KMS key.
2. Reference it from Lambda via `environment` (secret ARN/name only, never the password itself).

#### 7. IAM

1. Create the Lambda execution role and attach `AWSLambdaVPCAccessExecutionRole`
   (network interface management plus CloudWatch Logs basics).
2. Add a **least-privilege** inline policy scoped to specific resources:

* `secretsmanager:GetSecretValue` on the database secret ARN only.
* `kms:Decrypt` on the project KMS key only.
* `rds-db:connect` on the specific RDS Proxy / DB user (if using IAM database authentication).
* CloudWatch Logs write access on the function's log group.

3. Do **not** use `RDSFullAccess`: the function only needs to read one secret and connect to one database.
4. For the CI/CD pipeline, create the GitHub OIDC identity provider and a deploy role that GitHub Actions assumes.

#### 8. Compute (Lambda)

1. Deploy the function with `vpc_config` (all three private subnet IDs plus `LambdaSG`) and `environment`.
2. Runtime: Java 21 with Spring Boot, built with Maven.
3. Create a CloudWatch Log Group for the function, encrypted with the KMS key.
4. Expose the function through an API Gateway REST API.

#### 9. Performance and Release

* Enable **SnapStart** for the Java function.
* Publish a version and update an alias to the new version on each deploy.
* Use **Provisioned Concurrency** on the alias for latency-sensitive APIs.
* Use **Application Auto Scaling** on the provisioned concurrency (`--min-capacity 5`, `--max-capacity 50`).
* Monitor memory usage and right-size the function.

#### 10. Monitoring

* Metric filter on the Lambda log group; API Gateway metrics from namespace `AWS/ApiGateway`.
* CloudWatch alarms:
    * API Gateway `4XXError` and `5XXError`.
    * API availability/success rate.
    * Lambda `Errors` and `Throttles` (set early to adjust limits before users are affected).
* A composite alarm `critical-lambda-issues`:
  `ALARM(high-error-rate) OR ALARM(high-throttles) OR ALARM(low-success-rate)`

#### 11. Deployment Workflow (CI/CD)

1. Push changes under `terraform/` to the main branch: the infrastructure pipeline provisions AWS resources.
2. Push changes under `src/`: the application pipeline builds the JAR and deploys it to the Lambda function.
3. GitHub Actions authenticates to AWS through OIDC (no long-lived keys).

#### 12. Verification

* AWS Console → Lambda → Configuration → VPC: confirm subnets and security groups.
* Invoke the function and confirm it reads the secret and connects to the database.
* Confirm the database has no public access and that logs and flow logs reach CloudWatch.

---

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
