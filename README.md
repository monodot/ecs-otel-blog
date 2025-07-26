# Blog: Observing ECS Fargate workloads with OpenTelemetry and Grafana Cloud

This repository contains a sample Node.js application to demonstrate how to instrument an ECS Fargate workload with OpenTelemetry and ship traces, metrics, and logs to an OpenTelemetry (OTLP) endpoint, e.g. Grafana Cloud.

## About the example app

The Holiday API is a simple RESTful service that manages holiday packages. It uses:

- **Node.js** and **Express** for the API
- **Winston** JavaScript library for logging
- **PostgreSQL** for data storage
- **Docker** and **Docker Compose** for containerization
- **OpenTelemetry** for observability instrumentation

## Getting Started

### Prerequisites

- Docker and Docker Compose
- Node.js 18+ (for local development)
- Grafana Cloud account (for receiving telemetry data)

### Environment Setup

1. Copy the sample environment file:
   ```shell
   cp app/.env.sample app/.env
   ```

2. Update the `.env` file with your Grafana Cloud credentials:
   ```
   OTEL_EXPORTER_OTLP_ENDPOINT=https://otlp-gateway-{region}.grafana.net/otlp
   OTEL_EXPORTER_OTLP_HEADERS=Authorization=Basic <base64-encoded-credentials>
   ```

### Running Locally

Start the application with Docker Compose:

```shell
docker compose up
```

The API will be available at http://localhost:3000. Try hitting one of the endpoints:

```sh
curl -X GET --location "http://localhost:3000/packages" \
    -H "Accept: application/json"
```

The full list of endpoints is:

- `GET /packages` - List all holiday packages
- `GET /packages/:id` - Get a specific package
- `POST /packages` - Create a new package
- `PUT /packages/:id` - Update a package
- `DELETE /packages/:id` - Delete a package
- `GET /health` - Health check endpoint

## Observability setup

### OpenTelemetry Configuration

This application is configured with zero-code OpenTelemetry, which automatically instruments:

- HTTP requests and responses
- Database queries
- Runtime metrics
- Application logs (as this application uses the Winston logging package)

### Logs

Logs are written using the Winston logging library and automatically forwarded to OpenTelemetry. The application uses the `@opentelemetry/winston-transport` package to integrate Winston with OpenTelemetry and logging is configured in app/logger.js.

### Deployment to ECS Fargate

This application is designed to be deployed as an ECS Fargate task to demonstrate how to observe ECS Fargate workloads with OpenTelemetry.

When deploying to ECS Fargate:

1. Build and push the Docker image to ECR
2. Configure task definitions with the same environment variables given in the compose.yaml definition.
3. Set up the necessary IAM roles and security groups to run your task.
4. Deploy the task to your ECS cluster

## License

ISC
