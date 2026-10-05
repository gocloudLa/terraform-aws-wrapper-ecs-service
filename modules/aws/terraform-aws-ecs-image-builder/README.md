# terraform-aws-ecs-image-builder

Builds a container image with EC2 Image Builder and pushes it to an existing ECR repository.
Used by the wrapper when a container defines `image_builder`.

## Behavior

- Inside the build, in order: `files` and `directories` are copied (staged through S3), then `commands` run, then `entrypoint` / `cmd` are written to the Dockerfile.
- A build runs only when `image_tag` (semver `x.y.z`) changes. Changes to commands, files or parent image without a new tag are ignored.
- The image is pushed as `<repository_url>:<image_tag>`; the `image_uri` output waits for the build to finish.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| create | Set to create resources. | `bool` | `true` | no |
| name | Name used for Image Builder resources. | `string` | n/a | yes |
| tags | Tags applied to created resources. | `map(string)` | `{}` | no |
| vpc_id | VPC ID where the build instance runs. | `string` | n/a | yes |
| subnet_id | Subnet ID of the build instance (needs outbound internet). | `string` | n/a | yes |
| repository_name | Existing ECR repository name. | `string` | n/a | yes |
| repository_arn | Existing ECR repository ARN (IAM is scoped to it). | `string` | n/a | yes |
| repository_url | Existing ECR repository URL. | `string` | n/a | yes |
| image_tag | Image tag and version (`x.y.z`). | `string` | n/a | yes |
| parent_image | Base image of the build. | `string` | n/a | yes |
| commands | Bash commands executed in the build. | `list(string)` | `[]` | no |
| files | Files written into the image (`content` or `source`, `mode`). | `map(object)` | `{}` | no |
| directories | Local directories copied into the image. | `map(string)` | `{}` | no |
| entrypoint | Dockerfile ENTRYPOINT (exec form). | `list(string)` | `[]` | no |
| cmd | Dockerfile CMD (exec form). | `list(string)` | `[]` | no |
| dockerfile_template | Full Dockerfile template; overrides entrypoint and cmd. | `string` | `null` | no |
| bucket_name | S3 bucket that stages the files. | `string` | `null` | no |
| instance_type | Build instance type. | `string` | `"t3.medium"` | no |
| image_tests_enabled | Run Image Builder tests. | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| image_uri | `repository:tag` once the build has finished. |
