data "aws_caller_identity" "current" {}

resource "aws_quicksight_data_source" "athena" {
  data_source_id = "${var.project_name}-athena-ds"
  name           = "${var.project_name}-athena-ds"
  type           = "ATHENA"

  parameters {
    athena {
      work_group = var.athena_workgroup_name
    }
  }

  permission {
    principal = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
    actions = [
      "quicksight:DescribeDataSource",
      "quicksight:DescribeDataSourcePermissions",
      "quicksight:UpdateDataSource",
      "quicksight:UpdateDataSourcePermissions",
      "quicksight:DeleteDataSource",
      "quicksight:PassDataSource"
    ]
  }

  tags = {
    Name = "${var.project_name}-quicksight-athena-ds"
  }
}
