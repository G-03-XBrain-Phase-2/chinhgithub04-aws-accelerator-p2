variable "function_name" {
  type        = string
  description = "Tên của AWS Lambda function"
}

variable "description" {
  type        = string
  default     = "Lambda function phục vụ hệ thống FinOps Watch"
  description = "Mô tả chức năng của Lambda"
}

variable "handler" {
  type        = string
  default     = null
  description = "Điểm khởi chạy (entry point) của Lambda function (ví dụ: index.handler) - Chỉ cần cho package_type = Zip"
}

variable "runtime" {
  type        = string
  default     = null
  description = "Môi trường thực thi (runtime) của Lambda function - Chỉ cần cho package_type = Zip"
}

variable "package_type" {
  type        = string
  default     = "Zip"
  description = "Kiểu đóng gói của Lambda function (Zip hoặc Image)"
}

variable "image_uri" {
  type        = string
  default     = null
  description = "Đường dẫn URI của container image trong ECR - Chỉ cần cho package_type = Image"
}

variable "timeout" {
  type        = number
  default     = 30
  description = "Thời gian thực thi tối đa của Lambda (giây)"
}

variable "memory_size" {
  type        = number
  default     = 128
  description = "Dung lượng RAM cấp phát cho Lambda (MB)"
}

variable "source_dir" {
  type        = string
  default     = null
  description = "Đường dẫn thư mục cục bộ chứa mã nguồn của Lambda để tự động nén ZIP - Chỉ cần cho package_type = Zip"
}

variable "environment_variables" {
  type        = map(string)
  default     = {}
  description = "Bản đồ các biến môi trường cấu hình cho Lambda"
}

variable "iam_policy_document_json" {
  type        = string
  default     = ""
  description = "Chuỗi JSON định nghĩa IAM Policy custom gán riêng cho Execution Role của Lambda này"
}

variable "create_function_url" {
  type        = bool
  default     = false
  description = "Quyết định có tạo Public Function URL cho Lambda này hay không (dùng để expose API)"
}

variable "log_retention_in_days" {
  type        = number
  default     = 14
  description = "Số ngày lưu trữ logs trong CloudWatch Log Group để tối ưu chi phí FinOps"
}

variable "project_name" {
  type        = string
  description = "Tên của dự án (ví dụ: finops-watch)"
}

variable "vpc_id" {
  type        = string
  default     = ""
  description = "ID của VPC, bắt buộc cung cấp nếu muốn Lambda chạy trong VPC (subnet_ids != []) để tạo tự động Security Group"
}

variable "subnet_ids" {
  type        = list(string)
  default     = []
  description = "Danh sách Subnet IDs nếu muốn Lambda chạy trong VPC"
}

variable "security_group_ids" {
  type        = list(string)
  default     = []
  description = "Danh sách các Security Group IDs bổ sung nếu muốn gắn thêm vào Lambda (không bắt buộc, module sẽ tự tạo 1 SG mặc định nếu có vpc_id)"
}

variable "role_arn" {
  type        = string
  default     = ""
  description = "ARN of the IAM role to use for the Lambda function. If provided, the module will not create a new IAM role."
}

variable "event_source_mappings" {
  type = map(object({
    event_source_arn  = string
    batch_size        = optional(number)
    enabled           = optional(bool, true)
    starting_position = optional(string)
  }))
  default     = {}
  description = "Map of event source mappings (triggers) for the Lambda function."
}

variable "create_role" {
  type        = bool
  default     = true
  description = "Whether to create the IAM execution role inside the module. Set to false if role_arn is provided."
}

variable "policy_depends_on" {
  type        = list(string)
  default     = []
  description = "Danh sách policy attachment IDs bên ngoài để đảm bảo event source mapping chờ đủ quyền IAM trước khi được tạo."
}
