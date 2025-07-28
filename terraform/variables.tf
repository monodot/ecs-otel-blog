variable "environment_id" {
  description = "Unique identifier for the environment, e.g., 'demo', 'acme123', etc."
  type        = string
  default     = "demo"
}

variable "service_namespace" {
  type    = string
  default = "ecs-otel"
}

variable "otel_exporter_otlp_endpoint" {
  description = "OTLP endpoint to ship telemetry to. e.g. https://otlp-gateway-prod-gb-south-0.grafana.net/otlp"
  type        = string
}

variable "otel_exporter_otlp_headers" {
  description = "Set this to 'Authorization=Basic <base64-encoded auth>' if using Grafana Cloud"
  type        = string
  sensitive   = true
}
