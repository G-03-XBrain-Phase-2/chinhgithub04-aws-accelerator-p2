resource "aws_glue_catalog_database" "this" {
  name = "${var.project_name}_${var.database_name}"
}

resource "aws_athena_workgroup" "this" {
  name          = "${var.project_name}-${var.workgroup_name}"
  force_destroy = var.workgroup_force_destroy

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = var.athena_results_bucket_s3_uri

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }

  tags = {
    Name = "${var.project_name}-athena-${var.workgroup_name}"
  }
}
