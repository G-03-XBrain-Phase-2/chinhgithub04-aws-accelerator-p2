terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.tags
  }
}

# Cấu hình Provider thứ hai (Kubernetes) động từ thông tin chứng chỉ lấy qua SSH
provider "kubernetes" {
  host                   = "https://${aws_instance.k8s_host.public_ip}:6443"
  client_certificate     = base64decode(data.external.kubeconfig.result.cert)
  client_key             = base64decode(data.external.kubeconfig.result.key)
  cluster_ca_certificate = base64decode(data.external.kubeconfig.result.ca)
}
