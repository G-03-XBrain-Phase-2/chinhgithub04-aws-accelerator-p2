data "archive_file" "lambda_zip" {
  count       = var.package_type == "Zip" ? 1 : 0
  type        = "zip"
  source_dir  = var.source_dir
  output_path = "${path.module}/files/${var.function_name}.zip"
}

resource "aws_cloudwatch_log_group" "lambda_log" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.log_retention_in_days

  tags = {
    Name = "${var.project_name}-lambda-log-${var.function_name}"
  }
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  count              = var.create_role ? 1 : 0
  name               = "${var.function_name}-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = {
    Name = "${var.project_name}-lambda-role-${var.function_name}"
  }
}

resource "aws_iam_role_policy_attachment" "basic_execution" {
  count      = var.create_role ? 1 : 0
  role       = aws_iam_role.lambda_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "vpc_access" {
  count      = (var.create_role && length(var.subnet_ids) > 0) ? 1 : 0
  role       = aws_iam_role.lambda_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_security_group" "lambda_sg" {
  count       = length(var.subnet_ids) > 0 ? 1 : 0
  name        = "${var.project_name}-lambda-sg-${var.function_name}"
  description = "Security group automatically created for lambda ${var.function_name}"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-lambda-sg-${var.function_name}"
  }
}

resource "aws_iam_policy" "custom_policy" {
  count       = (var.create_role && var.iam_policy_document_json != "") ? 1 : 0
  name        = "${var.function_name}-custom-policy"
  description = "Custom policy for Lambda function ${var.function_name}"
  policy      = var.iam_policy_document_json
}

resource "aws_iam_role_policy_attachment" "custom_policy_attach" {
  count      = (var.create_role && var.iam_policy_document_json != "") ? 1 : 0
  role       = aws_iam_role.lambda_role[0].name
  policy_arn = aws_iam_policy.custom_policy[0].arn
}
resource "aws_lambda_function" "this" {
  function_name = var.function_name
  description   = var.description
  timeout       = var.timeout
  memory_size   = var.memory_size
  role          = var.create_role ? aws_iam_role.lambda_role[0].arn : var.role_arn
  package_type  = var.package_type

  handler          = var.package_type == "Zip" ? var.handler : null
  runtime          = var.package_type == "Zip" ? var.runtime : null
  filename         = var.package_type == "Zip" ? data.archive_file.lambda_zip[0].output_path : null
  source_code_hash = var.package_type == "Zip" ? data.archive_file.lambda_zip[0].output_base64sha256 : null

  image_uri = var.package_type == "Image" ? var.image_uri : null

  dynamic "environment" {
    for_each = length(var.environment_variables) > 0 ? [1] : []
    content {
      variables = var.environment_variables
    }
  }

  dynamic "vpc_config" {
    for_each = length(var.subnet_ids) > 0 ? [1] : []
    content {
      subnet_ids = var.subnet_ids
      security_group_ids = compact(concat(
        length(var.subnet_ids) > 0 ? [aws_security_group.lambda_sg[0].id] : [],
        var.security_group_ids
      ))
    }
  }

  tags = {
    Name = "${var.project_name}-lambda-${var.function_name}"
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda_log,
    aws_iam_role_policy_attachment.basic_execution
  ]
}

# Tùy chọn tạo Function URL để expose REST API trực tiếp cho Lambda
resource "aws_lambda_function_url" "this" {
  count              = var.create_function_url ? 1 : 0
  function_name      = aws_lambda_function.this.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = true
    allow_origins     = ["*"]
    allow_methods     = ["*"]
    allow_headers     = ["date", "keep-alive"]
    expose_headers    = ["keep-alive"]
    max_age           = 86400
  }
}

resource "terraform_data" "policy_trigger" {
  input = var.policy_depends_on
}

resource "aws_lambda_event_source_mapping" "this" {
  for_each          = var.event_source_mappings
  event_source_arn  = each.value.event_source_arn
  function_name     = aws_lambda_function.this.arn
  batch_size        = each.value.batch_size
  enabled           = each.value.enabled
  starting_position = each.value.starting_position

  depends_on = [
    aws_lambda_function.this,
    terraform_data.policy_trigger
  ]
}
