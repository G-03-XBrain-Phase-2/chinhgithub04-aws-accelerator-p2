locals {
  attributes = concat(
    [
      {
        name = var.hash_key
        type = var.hash_key_type
      }
    ],
    var.range_key != null ? [
      {
        name = var.range_key
        type = var.range_key_type
      }
    ] : []
  )
}

resource "aws_dynamodb_table" "this" {
  name         = "${var.project_name}-${var.table_name}"
  billing_mode = var.billing_mode
  hash_key     = var.hash_key
  range_key    = var.range_key

  dynamic "attribute" {
    for_each = local.attributes
    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }

  dynamic "ttl" {
    for_each = var.ttl_enabled ? [1] : []
    content {
      attribute_name = var.ttl_attribute
      enabled        = true
    }
  }

  tags = {
    Name = "${var.project_name}-${var.table_name}"
  }
}
