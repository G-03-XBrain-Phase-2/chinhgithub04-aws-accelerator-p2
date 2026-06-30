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
