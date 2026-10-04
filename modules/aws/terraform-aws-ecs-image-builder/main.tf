################################################################################
# Container image build — Image Builder pushes into an existing ECR repository.
# One build per image_tag; nothing is rebuilt unless the tag changes.
################################################################################

resource "aws_security_group" "this" {
  count = local.create ? 1 : 0

  name_prefix = "${substr(var.name, 0, 50)}-imagebuilder-"
  description = "Egress-only SG for the Image Builder build instance"
  vpc_id      = var.vpc_id
  tags        = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_egress_rule" "all" {
  count = local.create ? 1 : 0

  security_group_id = aws_security_group.this[0].id
  description       = "Allow all egress for package managers and AWS API calls"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  tags              = var.tags
}

resource "aws_iam_role" "this" {
  count = local.create ? 1 : 0

  name_prefix = "${substr(var.name, 0, 30)}-ib-"
  tags        = var.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each = local.create ? toset([
    "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilder",
    "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilderECRContainerBuilds",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
  ]) : toset([])

  role       = aws_iam_role.this[0].name
  policy_arn = each.value
}

# ECR push/pull comes from EC2InstanceProfileForImageBuilderECRContainerBuilds
resource "aws_iam_role_policy" "this" {
  count = local.create ? 1 : 0

  name = "image-builder-extra"
  role = aws_iam_role.this[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [{
        Effect = "Allow"
        Action = [
          "ecr-public:GetAuthorizationToken",
          "ecr-public:BatchCheckLayerAvailability",
          "ecr-public:GetDownloadUrlForLayer",
          "ecr-public:BatchGetImage",
        ]
        Resource = "*"
      }],
      local.has_files ? [{
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = ["${aws_s3_bucket.this[0].arn}/*"]
      }] : [],
    )
  })
}

resource "aws_iam_instance_profile" "this" {
  count = local.create ? 1 : 0

  name_prefix = "${substr(var.name, 0, 30)}-ib-"
  role        = aws_iam_role.this[0].name
  tags        = var.tags
}

resource "aws_s3_bucket" "this" {
  count = local.create && local.has_files ? 1 : 0

  bucket        = var.bucket_name
  force_destroy = true
  tags          = var.tags
}

resource "aws_s3_bucket_public_access_block" "this" {
  count = local.create && local.has_files ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  count = local.create && local.has_files ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Files are staged under <image_tag>/ so every version keeps its own copy.
resource "aws_s3_object" "files" {
  for_each = local.create ? local.all_files : {}

  bucket  = aws_s3_bucket.this[0].id
  key     = "${var.image_tag}/${trimprefix(each.key, "/")}"
  content = each.value.content
  source  = each.value.source
  etag    = each.value.content != null ? md5(each.value.content) : filemd5(each.value.source)
  tags    = var.tags
}

resource "aws_imagebuilder_component" "this" {
  count = local.create ? 1 : 0

  name     = var.name
  version  = var.image_tag
  platform = "Linux"
  data     = local.component_data
  tags     = var.tags

  # Only a new image_tag produces a new build.
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [data]
  }
}

resource "aws_imagebuilder_container_recipe" "this" {
  count = local.create ? 1 : 0

  name              = var.name
  version           = var.image_tag
  container_type    = "DOCKER"
  parent_image      = var.parent_image
  platform_override = "Linux"
  tags              = var.tags

  component {
    component_arn = aws_imagebuilder_component.this[0].arn
  }

  target_repository {
    repository_name = var.repository_name
    service         = "ECR"
  }

  dockerfile_template_data = local.dockerfile_template

  # Only a new image_tag produces a new build.
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [parent_image, dockerfile_template_data, component]
  }
}

resource "aws_imagebuilder_infrastructure_configuration" "this" {
  count = local.create ? 1 : 0

  name                          = var.name
  instance_types                = [var.instance_type]
  instance_profile_name         = aws_iam_instance_profile.this[0].name
  subnet_id                     = var.subnet_id
  security_group_ids            = [aws_security_group.this[0].id]
  terminate_instance_on_failure = true
  tags                          = var.tags
}

resource "aws_imagebuilder_distribution_configuration" "this" {
  count = local.create ? 1 : 0

  name = var.name
  tags = var.tags

  distribution {
    region = data.aws_region.current.region

    container_distribution_configuration {
      container_tags = [var.image_tag]

      target_repository {
        service         = "ECR"
        repository_name = var.repository_name
      }
    }
  }
}

resource "aws_imagebuilder_image" "this" {
  count = local.create ? 1 : 0

  container_recipe_arn             = aws_imagebuilder_container_recipe.this[0].arn
  infrastructure_configuration_arn = aws_imagebuilder_infrastructure_configuration.this[0].arn
  distribution_configuration_arn   = aws_imagebuilder_distribution_configuration.this[0].arn
  tags                             = var.tags

  image_tests_configuration {
    image_tests_enabled = var.image_tests_enabled
  }

  # The instance profile does not reference the policy attachments; the build
  # must not start before they exist.
  depends_on = [
    aws_iam_role_policy_attachment.this,
    aws_iam_role_policy.this,
    aws_s3_object.files,
  ]

  lifecycle {
    replace_triggered_by = [
      aws_imagebuilder_container_recipe.this[0],
    ]
  }
}
