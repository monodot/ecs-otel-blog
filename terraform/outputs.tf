output "image_registry_hostname" {
  value       = "${aws_ecr_repository.holidayapp.registry_id}.dkr.ecr.${data.aws_region.current.id}.amazonaws.com"
  description = "Registry hostname of the published image, for use in a login command"
}

output "image_repository_url" {
  value       = aws_ecr_repository.holidayapp.repository_url
  description = "URL for the image repository"
}

output "task_arn" {
  value = aws_ecs_task_definition.holidayapp.arn_without_revision
}
