resource "aws_sns_topic" "this" {
  name              = "${var.project_name}-${var.topic_name}"
  kms_master_key_id = var.kms_master_key_id

  tags = {
    Name = "${var.project_name}-sns-${var.topic_name}"
  }
}

resource "aws_sns_topic_subscription" "this" {
  for_each   = var.subscriptions
  topic_arn  = aws_sns_topic.this.arn
  protocol   = each.value.protocol
  endpoint   = each.value.endpoint
}
