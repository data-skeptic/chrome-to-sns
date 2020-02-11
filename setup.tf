
variable "REGION" { }
variable "STAGE" {
    default = "dev"
 }
variable "TOPIC_NAME" {
    default = "chrome-activity"
}

provider "aws" {
  region     = var.REGION
}

resource "aws_sns_topic" "chrome-activity-topic" {
  name = "${var.TOPIC_NAME}-${var.STAGE}"
}

resource "null_resource" "lambda_buildstep" {
  triggers = {
    handler      = "${base64sha256(file("code/activity_tracker/handler.py"))}"
    requirements = "${base64sha256(file("code/activity_tracker/requirements.txt"))}"
    build        = "${base64sha256(file("code/activity_tracker/build.cmd"))}"
    snsService   = "${base64sha256(file("code/activity_tracker/snsService.py"))}"
  }

  provisioner "local-exec" {
    command = "${path.cwd}/${path.root}/code/activity_tracker/build.cmd"
  }
}

data "archive_file" "lambda_function_with_dependencies" {
  source_dir  = "${path.module}/code/activity_tracker/"
  output_path = "${path.module}/code/lambda_function_with_dependencies.zip"
  type        = "zip"

  depends_on = [null_resource.lambda_buildstep]
}

resource "aws_lambda_function" "lambda_function_with_dependencies" {
  function_name    = "activity-tracker-${var.STAGE}"
  handler          = "handler.lambda_handler"
  role             = aws_iam_role.lambda_function_role.arn
  runtime          = "python3.8"
  timeout          = 60
  filename         = data.archive_file.lambda_function_with_dependencies.output_path  
  source_code_hash = data.archive_file.lambda_function_with_dependencies.output_base64sha256
}

data "aws_iam_policy_document" "assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_function_role" {
  name               = "instance_role"
  path               = "/system/"
  assume_role_policy = data.aws_iam_policy_document.assume-role-policy.json
}

resource "aws_iam_policy" "policy" {
  name = "activity-policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
          "sns:*"
          ],
            "Resource": "arn:aws:sns:*:*:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:*"
            ],
            "Resource": "arn:aws:logs:*:*:*"
        }
  ]
}
EOF
}

# Attached IAM Role and the new created Policy
resource "aws_iam_role_policy_attachment" "test-attach" {
  role       = aws_iam_role.lambda_function_role.name
  policy_arn = aws_iam_policy.policy.arn
}
