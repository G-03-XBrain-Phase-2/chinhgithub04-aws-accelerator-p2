module "vpc" {
  source = "../../modules/vpc"

  project_name          = var.project_name
  vpc_cidr              = var.vpc_cidr
  public_subnets        = var.public_subnets
  private_subnets       = var.private_subnets
  database_subnets      = var.database_subnets
  nat_gateways          = var.nat_gateways
  private_route_tables  = var.private_route_tables
  database_route_tables = var.database_route_tables
}

module "telemetry_lambda" {
  source = "../../modules/lambda"

  project_name  = var.project_name
  function_name = var.lambda_function_name
  description   = var.lambda_description

  package_type = "Zip"
  runtime      = var.lambda_runtime
  handler      = var.lambda_handler
  source_dir   = "${path.module}/src/telemetry_collector"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = values(module.vpc.private_subnet_ids)

  timeout = 300

  environment_variables = {
    TELEMETRY_BUCKET    = module.telemetry_bucket.bucket_id
    RAW_CUR_BUCKET      = module.raw_cur_bucket.bucket_id
    ATHENA_DATABASE     = module.athena.database_name
    ATHENA_WORKGROUP    = module.athena.workgroup_name
    ATHENA_RESULTS_URI  = "s3://${module.athena_results_bucket.bucket_id}/results/"
    IDEMPOTENCY_TABLE   = module.idempotency_table.table_name
    FEATURE_STORE_TABLE = module.feature_store_table.table_name
    AI_ENGINE_URL       = "http://${module.ai_engine_alb.alb_dns_name}/v1/detect"
    TENANT_ID           = "a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d"
    ANOMALY_QUEUE_URL   = module.anomaly_queue.queue_id
  }

  iam_policy_document_json = data.aws_iam_policy_document.telemetry_lambda_custom_policy.json
}

module "ai_engine_alb" {
  source = "../../modules/alb"

  project_name = var.project_name
  alb_name     = var.ai_engine_alb_name
  internal     = var.ai_engine_alb_internal

  vpc_id     = module.vpc.vpc_id
  subnet_ids = values(module.vpc.private_subnet_ids)

  listener_port     = var.ai_engine_alb_listener_port
  target_group_port = var.ai_engine_alb_target_group_port

  ingress_rules = var.ai_engine_alb_ingress_rules

  health_check_path = "/health"
}

module "ai_engine_ecs" {
  source = "../../modules/ecs"

  project_name          = var.project_name
  service_name          = var.ai_engine_ecs_service_name
  vpc_id                = module.vpc.vpc_id
  subnet_ids            = values(module.vpc.private_subnet_ids)
  alb_security_group_id = module.ai_engine_alb.security_group_id

  container_image  = "${module.ai_engine_ecr.repository_url}:latest"
  container_port   = var.ai_engine_ecs_container_port
  cpu              = var.ai_engine_ecs_cpu
  memory           = var.ai_engine_ecs_memory
  desired_count    = var.ai_engine_ecs_desired_count
  target_group_arn = module.ai_engine_alb.target_group_arn

  environment_variables = [
    {
      name  = "FINOPS_ENVIRONMENT"
      value = "production"
    },
    {
      name  = "FINOPS_AWS_REGION"
      value = var.aws_region
    },
    {
      name  = "AWS_REGION"
      value = var.aws_region
    },
    {
      name  = "FINOPS_PORT"
      value = tostring(var.ai_engine_ecs_container_port)
    },
    {
      name  = "FINOPS_ENABLE_DYNAMODB"
      value = "true"
    },
    {
      name  = "FINOPS_DYNAMODB_IDEMPOTENCY_TABLE"
      value = module.idempotency_table.table_name
    },
    {
      name  = "DYNAMODB_IDEMPOTENCY_TABLE"
      value = module.idempotency_table.table_name
    },
    {
      name  = "FINOPS_DYNAMODB_FEATURE_STORE_TABLE"
      value = module.feature_store_table.table_name
    },
    {
      name  = "DYNAMODB_FEATURE_STORE_TABLE"
      value = module.feature_store_table.table_name
    },
    {
      name  = "FINOPS_ENABLE_S3"
      value = "true"
    },
    {
      name  = "FINOPS_S3_TELEMETRY_BUCKET"
      value = module.telemetry_bucket.bucket_id
    },
    {
      name  = "S3_TELEMETRY_BUCKET"
      value = module.telemetry_bucket.bucket_id
    },
    {
      name  = "FINOPS_ENABLE_LLM_ANALYSIS"
      value = "false"
    },
    {
      name  = "BEDROCK_REGION"
      value = var.aws_region
    },
    {
      name  = "DYNAMODB_TABLE"
      value = module.idempotency_table.table_name
    },
    {
      name  = "RCA_MODE"
      value = "bedrock"
    }
  ]
}

module "lambda_two" {
  source = "../../modules/lambda"

  project_name  = var.project_name
  function_name = var.lambda_two_function_name
  description   = var.lambda_two_description

  package_type = "Zip"
  runtime      = var.lambda_two_runtime
  handler      = var.lambda_two_handler
  source_dir   = "${path.module}/src/lambda_two"

  create_role = false
  role_arn    = aws_iam_role.lambda_two_role.arn

  vpc_id     = module.vpc.vpc_id
  subnet_ids = values(module.vpc.private_subnet_ids)

  policy_depends_on = [
    aws_iam_role_policy_attachment.lambda_two_basic.id,
    aws_iam_role_policy_attachment.lambda_two_vpc.id,
    aws_iam_role_policy_attachment.lambda_two_sqs_policy_attach.id,
  ]

  environment_variables = {
    AI_ENGINE_URL       = "http://${module.ai_engine_alb.alb_dns_name}/v1/decide"
    TENANT_ID           = "a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d"
    ANOMALY_STATE_TABLE = module.anomaly_state_table.table_name
  }

  event_source_mappings = {
    sqs_trigger = {
      event_source_arn = module.anomaly_queue.queue_arn
      batch_size       = 1
    }
  }
}

module "telemetry_schedule" {
  source = "../../modules/eventbridge"

  project_name        = var.project_name
  schedule_name       = var.hello_world_schedule_name
  schedule_expression = var.hello_world_schedule_expression
  target_arn          = module.telemetry_lambda.arn
}

module "anomaly_queue" {
  source = "../../modules/sqs"

  project_name = var.project_name
  queue_name   = var.anomaly_queue_name
  fifo_queue   = var.anomaly_queue_fifo
  create_dlq   = var.anomaly_queue_create_dlq
}

module "idempotency_table" {
  source = "../../modules/dynamodb"

  project_name  = var.project_name
  table_name    = var.idempotency_table_name
  hash_key      = var.idempotency_table_hash_key
  hash_key_type = "S"
  ttl_enabled   = true
  ttl_attribute = var.idempotency_table_ttl_attribute
}

module "feature_store_table" {
  source = "../../modules/dynamodb"

  project_name   = var.project_name
  table_name     = var.feature_store_table_name
  hash_key       = var.feature_store_table_hash_key
  hash_key_type  = "S"
  range_key      = var.feature_store_table_range_key
  range_key_type = "S"
  ttl_enabled    = true
  ttl_attribute  = "ttl_expiry"
}

module "anomaly_state_table" {
  source = "../../modules/dynamodb"

  project_name  = var.project_name
  table_name    = var.anomaly_state_table_name
  hash_key      = var.anomaly_state_table_hash_key
  hash_key_type = "S"
  ttl_enabled   = false
}

module "athena_results_bucket" {
  source = "../../modules/s3"

  project_name              = var.project_name
  bucket_name               = var.athena_results_bucket_name
  lifecycle_expiration_days = 7
}

module "athena" {
  source = "../../modules/athena"

  project_name                 = var.project_name
  database_name                = var.athena_database_name
  workgroup_name               = var.athena_workgroup_name
  athena_results_bucket_s3_uri = "s3://${module.athena_results_bucket.bucket_id}/results/"
}

module "telemetry_bucket" {
  source = "../../modules/s3"

  project_name       = var.telemetry_bucket_project_name
  bucket_name        = var.telemetry_bucket_name
  versioning_enabled = true
}

module "raw_cur_bucket" {
  source = "../../modules/s3"

  project_name       = var.raw_cur_bucket_project_name
  bucket_name        = var.raw_cur_bucket_name
  versioning_enabled = true
}

resource "aws_s3_object" "cur_data" {
  bucket = module.raw_cur_bucket.bucket_id
  key    = "cur/cur_line_items.csv"
  source = "${path.module}/data/cur_line_items.csv"
  etag   = filemd5("${path.module}/data/cur_line_items.csv")
}

resource "aws_s3_object" "cost_explorer_data" {
  bucket = module.raw_cur_bucket.bucket_id
  key    = "cost-explorer/cost_explorer_daily.csv"
  source = "${path.module}/data/cost_explorer_daily.csv"
  etag   = filemd5("${path.module}/data/cost_explorer_daily.csv")
}

resource "aws_s3_object" "resource_utilization_data" {
  bucket = module.raw_cur_bucket.bucket_id
  key    = "utilization/resource_utilization_metrics.csv"
  source = "${path.module}/data/resource_utilization_metrics.csv"
  etag   = filemd5("${path.module}/data/resource_utilization_metrics.csv")
}

data "aws_iam_policy_document" "telemetry_lambda_custom_policy" {
  statement {
    sid    = "S3Access"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
      "s3:DeleteObject",
      "s3:GetBucketLocation",
      "s3:ListBucketMultipartUploads",
      "s3:ListMultipartUploadParts",
      "s3:AbortMultipartUpload"
    ]
    resources = [
      module.raw_cur_bucket.arn,
      "${module.raw_cur_bucket.arn}/*",
      module.telemetry_bucket.arn,
      "${module.telemetry_bucket.arn}/*",
      module.athena_results_bucket.arn,
      "${module.athena_results_bucket.arn}/*"
    ]
  }

  statement {
    sid    = "DynamoDBAccess"
    effect = "Allow"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:GetItem",
      "dynamodb:BatchGetItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:BatchWriteItem"
    ]
    resources = [
      module.idempotency_table.arn,
      module.feature_store_table.arn
    ]
  }

  statement {
    sid    = "AthenaAccess"
    effect = "Allow"
    actions = [
      "athena:StartQueryExecution",
      "athena:GetQueryExecution",
      "athena:GetQueryResults",
      "athena:StopQueryExecution",
      "athena:GetWorkGroup"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    sid    = "GlueAccess"
    effect = "Allow"
    actions = [
      "glue:GetDatabase",
      "glue:GetTable",
      "glue:GetPartitions",
      "glue:CreateTable",
      "glue:DeleteTable",
      "glue:UpdateTable",
      "glue:GetTables"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    sid    = "CostExplorerAccess"
    effect = "Allow"
    actions = [
      "ce:GetCostAndUsage"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    sid    = "SQSSendMessage"
    effect = "Allow"
    actions = [
      "sqs:SendMessage"
    ]
    resources = [
      module.anomaly_queue.queue_arn
    ]
  }
}

resource "aws_iam_role_policy" "ai_engine_ecs_custom_policy" {
  name   = "ai-engine-ecs-custom-policy"
  role   = element(split("/", module.ai_engine_ecs.task_role_arn), 1)
  policy = data.aws_iam_policy_document.telemetry_lambda_custom_policy.json
}

module "ai_engine_ecr" {
  source = "../../modules/ecr"

  project_name    = var.project_name
  repository_name = "ai-engine"
}

resource "aws_iam_role" "lambda_two_role" {
  name               = "${var.lambda_two_function_name}-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_generic.json

  tags = {
    Name = "${var.project_name}-lambda-role-${var.lambda_two_function_name}"
  }
}

data "aws_iam_policy_document" "lambda_assume_role_generic" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "lambda_two_basic" {
  role       = aws_iam_role.lambda_two_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "lambda_two_sqs_policy" {
  name        = "${var.lambda_two_function_name}-sqs-policy"
  description = "SQS access policy for lambda two"
  policy      = data.aws_iam_policy_document.lambda_two_sqs_policy_document.json
}

data "aws_iam_policy_document" "lambda_two_sqs_policy_document" {
  statement {
    sid    = "SQSReceive"
    effect = "Allow"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes"
    ]
    resources = [
      module.anomaly_queue.queue_arn
    ]
  }

  statement {
    sid    = "SSMGetParameter"
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters"
    ]
    resources = [
      "arn:aws:ssm:*:*:parameter/finops-watch/*"
    ]
  }

  statement {
    sid    = "DynamoDBAccess"
    effect = "Allow"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:GetItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem"
    ]
    resources = [
      module.anomaly_state_table.arn
    ]
  }
}

resource "aws_iam_role_policy_attachment" "lambda_two_sqs_policy_attach" {
  role       = aws_iam_role.lambda_two_role.name
  policy_arn = aws_iam_policy.lambda_two_sqs_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_two_vpc" {
  role       = aws_iam_role.lambda_two_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

module "slack_webhook_finance" {
  source = "../../modules/ssm"

  name        = "/${var.project_name}/finance/slack-webhook"
  value       = var.slack_webhook_finance
  description = "Slack Webhook URL for the Finance team"
}

module "slack_webhook_engineer" {
  source = "../../modules/ssm"

  name        = "/${var.project_name}/engineer/slack-webhook"
  value       = var.slack_webhook_engineer
  description = "Slack Webhook URL for the Engineer team"
}



