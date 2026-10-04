output "image_uri" {
  description = "Image URI (repository:tag) once the build has finished."
  value       = local.create ? "${var.repository_url}:${var.image_tag}" : null

  # Consumers (task definitions) must wait for the image to exist in ECR.
  depends_on = [aws_imagebuilder_image.this]
}
