resource "aws_cloudwatch_event_rule" "this" {
  name                = "${var.project_name}-rule-${var.rule_name}"
  description         = var.description
  schedule_expression = var.schedule_expression
  state               = var.is_enabled ? "ENABLED" : "DISABLED"

  tags = {
    Name = "${var.project_name}-rule-${var.rule_name}"
  }
}

resource "aws_cloudwatch_event_target" "this" {
  rule      = aws_cloudwatch_event_rule.this.name
  target_id = "${var.project_name}-target-${var.rule_name}"
  arn       = var.target_arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  count         = var.lambda_function_name != "" ? 1 : 0
  statement_id  = "AllowExecutionFromEventBridge-${var.rule_name}"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.this.arn
}
