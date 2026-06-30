data "aws_iam_policy_document" "assume_role" {
  count = var.create_role ? 1 : 0
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "scheduler" {
  count              = var.create_role ? 1 : 0
  name               = "${var.project_name}-scheduler-role-${var.schedule_name}"
  assume_role_policy = data.aws_iam_policy_document.assume_role[0].json

  tags = {
    Name = "${var.project_name}-scheduler-role-${var.schedule_name}"
  }
}

data "aws_iam_policy_document" "scheduler_policy" {
  count = var.create_role ? 1 : 0
  statement {
    effect    = "Allow"
    actions   = var.target_iam_actions
    resources = [var.target_arn]
  }
}

resource "aws_iam_role_policy" "scheduler" {
  count  = var.create_role ? 1 : 0
  name   = "${var.project_name}-scheduler-policy-${var.schedule_name}"
  role   = aws_iam_role.scheduler[0].id
  policy = data.aws_iam_policy_document.scheduler_policy[0].json
}

resource "aws_scheduler_schedule" "this" {
  name        = "${var.project_name}-schedule-${var.schedule_name}"
  description = var.description
  group_name  = "default"

  schedule_expression          = var.schedule_expression
  schedule_expression_timezone = var.schedule_expression_timezone
  state                        = var.is_enabled ? "ENABLED" : "DISABLED"

  flexible_time_window {
    mode                      = var.flexible_time_window_mode
    maximum_window_in_minutes = var.maximum_window_in_minutes
  }

  target {
    arn      = var.target_arn
    role_arn = var.create_role ? aws_iam_role.scheduler[0].arn : var.role_arn
    input    = var.target_input

    retry_policy {
      maximum_event_age_in_seconds = var.retry_policy_maximum_event_age_in_seconds
      maximum_retry_attempts       = var.retry_policy_maximum_retry_attempts
    }
  }
}
