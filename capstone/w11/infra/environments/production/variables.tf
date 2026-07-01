variable "aws_region" {
  type        = string
  description = "AWS Region triển khai hạ tầng"
}

variable "project_name" {
  type        = string
  description = "Tên của dự án (ví dụ: finops-watch)"
}

variable "tags" {
  type        = map(string)
  description = "Các tag được áp dụng cho tài nguyên"
}

variable "vpc_cidr" {
  type        = string
  description = "Dải CIDR block cho VPC"
}

variable "public_subnets" {
  type = map(object({
    cidr_block        = string
    availability_zone = string
  }))
  description = "Bản đồ các Public Subnets"
}

variable "private_subnets" {
  type = map(object({
    cidr_block        = string
    availability_zone = string
    route_table_key   = string
  }))
  description = "Bản đồ các Private Subnets kèm theo key của Private Route Table tương ứng"
}

variable "database_subnets" {
  type = map(object({
    cidr_block        = string
    availability_zone = string
    route_table_key   = string
  }))
  default     = {}
  description = "Bản đồ các Database Subnets kèm theo key của Database Route Table tương ứng"
}

variable "nat_gateways" {
  type = map(object({
    public_subnet_key = string
  }))
  default     = {}
  description = "Cấu hình NAT Gateways (Key là tên định danh NAT, public_subnet_key là subnet đặt NAT)"
}

variable "private_route_tables" {
  type = map(object({
    nat_gateway_key = optional(string)
  }))
  default     = {}
  description = "Cấu hình Private Route Tables (Key là tên định danh RT, nat_gateway_key là NAT Gateway tương ứng nếu có)"
}

variable "database_route_tables" {
  type        = map(object({}))
  default     = {}
  description = "Cấu hình Database Route Tables"
}

variable "lambda_function_name" {
  type        = string
  description = "Tên của lambda function"
}

variable "lambda_description" {
  type        = string
  description = "Mô tả cho lambda function"
}

variable "lambda_runtime" {
  type        = string
  description = "Runtime môi trường chạy của lambda function"
}

variable "lambda_handler" {
  type        = string
  description = "Hàm xử lý chính (handler) của lambda function"
}

variable "ai_engine_alb_name" {
  type        = string
  description = "Tên định danh cho ALB của AI Engine"
}

variable "ai_engine_alb_internal" {
  type        = bool
  description = "Xác định ALB của AI Engine là internal hay internet-facing"
}

variable "ai_engine_alb_listener_port" {
  type        = number
  description = "Port cho Listener của ALB AI Engine"
}

variable "ai_engine_alb_target_group_port" {
  type        = number
  description = "Port cho Target Group của ALB AI Engine"
}

variable "ai_engine_alb_ingress_rules" {
  type = list(object({
    from_port       = number
    to_port         = number
    protocol        = string
    cidr_blocks     = optional(list(string))
    security_groups = optional(list(string))
  }))
  description = "Danh sách Ingress rules cho ALB AI Engine"
}

variable "ai_engine_ecs_service_name" {
  type        = string
  description = "Tên service của AI Engine trong ECS"
}

variable "ai_engine_ecs_container_image" {
  type        = string
  description = "URI image của AI Engine"
}

variable "ai_engine_ecs_container_port" {
  type        = number
  description = "Port mà AI Engine container lắng nghe"
}

variable "ai_engine_ecs_cpu" {
  type        = number
  description = "CPU allocation cho AI Engine Fargate task"
}

variable "ai_engine_ecs_memory" {
  type        = number
  description = "Memory allocation cho AI Engine Fargate task"
}

variable "ai_engine_ecs_desired_count" {
  type        = number
  description = "Số task Fargate mong muốn chạy"
}

variable "lambda_two_function_name" {
  type        = string
  description = "Tên của Lambda function thứ hai"
}

variable "lambda_two_description" {
  type        = string
  description = "Mô tả cho Lambda function thứ hai"
}

variable "lambda_two_runtime" {
  type        = string
  description = "Runtime cho Lambda function thứ hai"
}

variable "lambda_two_handler" {
  type        = string
  description = "Handler cho Lambda function thứ hai"
}

variable "hello_world_schedule_name" {
  type        = string
  description = "Tên EventBridge Schedule cho Hello World Lambda"
}

variable "hello_world_schedule_expression" {
  type        = string
  description = "Biểu thức cron/rate của EventBridge Schedule (chạy mỗi 2h sáng)"
}

variable "anomaly_queue_name" {
  type        = string
  description = "Tên của SQS Queue nhận danh sách bất thường"
}

variable "anomaly_queue_fifo" {
  type        = bool
  description = "Xác định SQS Queue nhận danh sách bất thường là FIFO hay Standard"
}

variable "anomaly_queue_create_dlq" {
  type        = bool
  description = "Quyết định có tạo Dead Letter Queue cho anomaly queue hay không"
}

variable "idempotency_table_name" {
  type        = string
  description = "Tên bảng DynamoDB để lưu idempotency key"
}

variable "idempotency_table_hash_key" {
  type        = string
  description = "Partition Key cho bảng idempotency"
}

variable "idempotency_table_ttl_attribute" {
  type        = string
  description = "Thuộc tính TTL cho bảng idempotency"
}

variable "feature_store_table_name" {
  type        = string
  description = "Tên bảng DynamoDB để lưu trữ feature vectors"
}

variable "feature_store_table_hash_key" {
  type        = string
  description = "Partition Key cho bảng feature store"
}

variable "feature_store_table_range_key" {
  type        = string
  description = "Sort Key (Range Key) cho bảng feature store"
}

variable "anomaly_state_table_name" {
  type        = string
  description = "Tên bảng DynamoDB để lưu trữ trạng thái của containment action"
}

variable "anomaly_state_table_hash_key" {
  type        = string
  description = "Partition Key cho bảng anomaly state"
}

variable "athena_results_bucket_name" {
  type        = string
  description = "Tên S3 Bucket lưu kết quả query Athena"
}

variable "athena_database_name" {
  type        = string
  description = "Tên Glue Catalog Database cho Athena"
}

variable "athena_workgroup_name" {
  type        = string
  description = "Tên Athena Workgroup"
}

variable "telemetry_bucket_project_name" {
  type        = string
  description = "Prefix dự án cho Telemetry bucket (để tuân thủ format company-cdo)"
}

variable "telemetry_bucket_name" {
  type        = string
  description = "Tên định danh của Telemetry bucket (ví dụ: {account_id}-telemetry)"
}

variable "raw_cur_bucket_project_name" {
  type        = string
  description = "Prefix dự án cho Raw CUR bucket"
}

variable "raw_cur_bucket_name" {
  type        = string
  description = "Tên định danh của Raw CUR bucket (ví dụ: {account_id}-raw-cur)"
}

variable "slack_webhook_finance" {
  type        = string
  sensitive   = true
  default     = "https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX"
  description = "Slack Webhook URL cho team Finance (#finops-alert-finance)"
}

variable "slack_webhook_engineer" {
  type        = string
  sensitive   = true
  default     = "https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX"
  description = "Slack Webhook URL cho team Engineer (#finops-alert-engineering)"
}

