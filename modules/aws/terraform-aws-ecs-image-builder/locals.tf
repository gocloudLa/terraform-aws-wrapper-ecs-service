locals {
  create = var.create

  # Every file goes through S3 (no Image Builder component size limit on content).
  all_files = merge(
    {
      for path, file in var.files : path => {
        content = file.content
        source  = file.source
        mode    = file.mode
      }
    },
    merge([
      for dest, dir in var.directories : {
        for rel in fileset(dir, "**") : "${trimsuffix(dest, "/")}/${rel}" => {
          content = null
          source  = "${dir}/${rel}"
          mode    = "0644"
        }
      }
    ]...)
  )

  has_files = length(local.all_files) > 0

  component_steps = concat(
    # range() instead of ?: because the steps have different shapes
    flatten([for _ in range(local.has_files ? 1 : 0) : [
      {
        name   = "CreateDirectories"
        action = "ExecuteBash"
        inputs = { commands = [for dir in distinct([for path in keys(local.all_files) : dirname(path)]) : "mkdir -p '${dir}'"] }
      },
      {
        name   = "DownloadFiles"
        action = "S3Download"
        inputs = [for path in keys(local.all_files) : {
          source      = "s3://${var.bucket_name}/${var.image_tag}/${trimprefix(path, "/")}"
          destination = path
        }]
      },
      {
        name   = "SetFileModes"
        action = "ExecuteBash"
        inputs = { commands = [for path, file in local.all_files : "chmod ${file.mode} '${path}'"] }
      },
    ]]),
    [for _ in range(length(var.commands) > 0 ? 1 : 0) : {
      name   = "RunCommands"
      action = "ExecuteBash"
      inputs = { commands = var.commands }
    }],
    # Image Builder rejects components without steps
    [for _ in range(!local.has_files && length(var.commands) == 0 ? 1 : 0) : {
      name   = "Noop"
      action = "ExecuteBash"
      inputs = { commands = ["true"] }
    }],
  )

  component_data = yamlencode({
    schemaVersion = "1.0"
    phases = [{
      name  = "build"
      steps = local.component_steps
    }]
  })

  dockerfile_template = coalesce(var.dockerfile_template, join("\n", concat(
    [
      "FROM {{{ imagebuilder:parentImage }}}",
      "{{{ imagebuilder:environments }}}",
      "{{{ imagebuilder:components }}}",
    ],
    length(var.entrypoint) > 0 ? ["ENTRYPOINT ${jsonencode(var.entrypoint)}"] : [],
    length(var.cmd) > 0 ? ["CMD ${jsonencode(var.cmd)}"] : [],
    [""],
  )))
}
