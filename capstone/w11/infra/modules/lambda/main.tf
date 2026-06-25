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

resource "aws_iam_role" "lambda_role" {
  name = "${var.function_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-lambda-role-${var.function_name}"
  }
}

resource "aws_iam_role_policy_attachment" "basic_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "custom_policy" {
  count       = var.iam_policy_document_json != "" ? 1 : 0
  name        = "${var.function_name}-custom-policy"
  description = "Custom policy for Lambda function ${var.function_name}"
  policy      = var.iam_policy_document_json
}

resource "aws_iam_role_policy_attachment" "custom_policy_attach" {
  count      = var.iam_policy_document_json != "" ? 1 : 0
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.custom_policy[0].arn
}
resource "aws_lambda_function" "this" {
  function_name    = var.function_name
  description      = var.description
  timeout          = var.timeout
  memory_size      = var.memory_size
  role             = aws_iam_role.lambda_role.arn
  package_type     = var.package_type

  handler          = var.package_type == "Zip" ? var.handler : null
  runtime          = var.package_type == "Zip" ? var.runtime : null
  filename         = var.package_type == "Zip" ? data.archive_file.lambda_zip[0].output_path : null
  source_code_hash = var.package_type == "Zip" ? data.archive_file.lambda_zip[0].output_base64sha256 : null

  image_uri        = var.package_type == "Image" ? var.image_uri : null

  dynamic "environment" {
    for_each = length(var.environment_variables) > 0 ? [1] : []
    content {
      variables = var.environment_variables
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
