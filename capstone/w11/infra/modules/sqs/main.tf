locals {
  actual_queue_name = var.fifo_queue ? "${var.project_name}-${var.queue_name}.fifo" : "${var.project_name}-${var.queue_name}"
  actual_dlq_name   = var.fifo_queue ? "${var.project_name}-${var.queue_name}-dlq.fifo" : "${var.project_name}-${var.queue_name}-dlq"
}

resource "aws_sqs_queue" "dlq" {
  count = var.create_dlq ? 1 : 0

  name                        = local.actual_dlq_name
  fifo_queue                  = var.fifo_queue
  content_based_deduplication = var.fifo_queue ? true : false

  tags = {
    Name = local.actual_dlq_name
  }
}

resource "aws_sqs_queue" "this" {
  name                        = local.actual_queue_name
  fifo_queue                  = var.fifo_queue
  content_based_deduplication = var.fifo_queue ? true : false
  visibility_timeout_seconds  = var.visibility_timeout_seconds
  message_retention_seconds   = var.message_retention_seconds
  delay_seconds               = var.delay_seconds
  max_message_size            = var.max_message_size
  receive_wait_time_seconds   = var.receive_wait_time_seconds

  redrive_policy = var.create_dlq ? jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq[0].arn
    maxReceiveCount     = var.max_receive_count
  }) : null

  tags = {
    Name = local.actual_queue_name
  }
}
