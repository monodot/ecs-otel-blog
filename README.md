# Blog: Observing ECS Fargate workloads with OpenTelemetry and Grafana Cloud

This repository contains a sample Node.js application to demonstrate how to instrument an ECS Fargate workload with OpenTelemetry and ship traces, metrics, and logs to an OpenTelemetry (OTLP) endpoint, e.g. Grafana Cloud.

## Getting Started

### Prerequisites

To deploy the included example to AWS:

- Terraform 
- AWS CLI
- Docker
- Grafana Cloud account (for receiving telemetry data)

To run the example locally:

- Docker and Docker Compose
- Node.js 18+ (if you want to _develop_ on this locally)

### Deployment to ECS Fargate

This application is intended to be deployed as an ECS Fargate task to demonstrate how to observe ECS Fargate workloads with OpenTelemetry.

When deploying to ECS Fargate:

1. Build and push the Docker image to ECR
2. Configure task definitions with the same environment variables given in the compose.yaml definition.
3. Set up the necessary IAM roles and security groups to run your task.
4. Deploy the task to your ECS cluster

There is a Terraform configuration included with this repo. To create ECS resources in AWS, and build and push the included demo app, run these commands:

```shell
terraform -chdir=terraform init

# Set up your authentication to AWS (or however you do it)
export AWS_ACCESS_KEY_ID=xxxxx
export AWS_SECRET_ACCESS_KEY=xxxx

terraform -chdir=terraform apply

# Build and push the app to the image repository
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $(terraform -chdir=terraform output image_registry_hostname)

export IMAGE="$(terraform -chdir=terraform output -raw image_repository_url):latest"

docker build -t $IMAGE app/

docker push $IMAGE
```

Now you can send some test requests to the app. First get the IP of the task that's currently running:

```shell
export TASK_ARN=$(aws ecs list-tasks --cluster ecs-otel-demo --service-name ecs-otel-holidayapp --query 'taskArns[0]' --output text --region us-east-1)

# Get the IP address of the task
aws ecs describe-tasks --cluster ecs-otel-demo --tasks $TASK_ARN --query 'tasks[0].attachments[0].details[?name==`networkInterfaceId`].value' --output text --region us-east-1 | xargs -I {} aws ec2 describe-network-interfaces --network-interface-ids {} --query 'NetworkInterfaces[0].Association.PublicIp' --output text --region us-east-1

curl http://<ip>:8080/packages
```

### Running locally

#### Environment setup

If you want to ship telemetry to Grafana Cloud then you need to configure a couple of settings first:

1. Copy the sample environment file:
   ```shell
   cp .env.sample .env
   ```

2. Update the `.env` file with your Grafana Cloud credentials:
   ```shell
   OTEL_EXPORTER_OTLP_ENDPOINT=https://otlp-gateway-{region}.grafana.net/otlp
   OTEL_EXPORTER_OTLP_HEADERS=Authorization=Basic <base64-encoded-credentials>
   ```

#### Run the app

Start the application with Docker Compose and ship telemetry to Grafana Cloud:

```shell
docker compose up
```

**OR**, if you don't have a Grafana Cloud account yet (why not?), and you would rather start the application and ship to a local Loki, Tempo & Mimir stack, and visualise in Grafana, run this:

```shell
docker compose --profile local --env-file .env.local up
```

The API will be available at http://localhost:8080, and if you chose the "local" profile option then Grafana will be running at http://localhost:3000. Try hitting one of the endpoints:

```sh
curl -X GET --location "http://localhost:8080/packages" \
    -H "Accept: application/json"
```

You can also run a k6 script to simulate some load on the service. Install Grafana k6 and then run:

```sh
k6 run script.js
```

## About the example app

The demo app is a Holiday API. It is a simple RESTful service that manages holiday packages. It uses:

- **Node.js** and **Express** for the API
- **Winston** JavaScript library for logging
- **PostgreSQL** for data storage
- **Docker** and **Docker Compose** for containerization
- **OpenTelemetry** for observability instrumentation

The full list of endpoints for the service is:

- `GET /packages` - List all holiday packages
- `GET /packages/:id` - Get a specific package
- `POST /packages` - Create a new package
- `PUT /packages/:id` - Update a package
- `DELETE /packages/:id` - Delete a package
- `GET /health` - Health check endpoint

## Observability details

### OpenTelemetry configuration

This application is configured with zero-code OpenTelemetry, which automatically instruments:

- HTTP requests and responses
- Database queries
- Runtime metrics
- Application logs (as this application uses the Winston logging package)

### Logs

Logs are written using the Winston logging library and automatically forwarded to OpenTelemetry. The application uses the `@opentelemetry/winston-transport` package to integrate Winston with OpenTelemetry and logging is configured in app/logger.js.

## License

AGPL

