variable "REGION" { }
variable "STAGE" {
    default = "dev"
 }
variable "TOPIC_NAME" {
    default = "chrome-activity"
}


module "api_gateway" {
  source = "./api_gateway"
  #aws_region = var.REGION
}

provider "aws" {
  region     = var.REGION
}

resource "aws_sns_topic" "chrome-activity-topic" {
  name = "${var.TOPIC_NAME}-${var.STAGE}"
}

resource "null_resource" "lambda_buildstep" {
  triggers = {
    handler      = "${base64sha256(file("../code/activity_tracker/handler.py"))}"
    requirements = "${base64sha256(file("../code/activity_tracker/requirements.txt"))}"
    build        = "${base64sha256(file("../code/activity_tracker/build.sh"))}"
    snsService   = "${base64sha256(file("../code/activity_tracker/snsService.py"))}"
  }

  provisioner "local-exec" {
    command = "${path.cwd}/${path.root}/../code/activity_tracker/build.sh"
  }
}

data "archive_file" "lambda_function_with_dependencies" {
  source_dir  = "${path.module}/../code/activity_tracker/"
  output_path = "${path.module}/../code/lambda_function_with_dependencies.zip"
  type        = "zip"

  depends_on = [null_resource.lambda_buildstep]
}

resource "aws_lambda_function" "lambda_function" {
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
  name                 = "instance-role-${var.REGION}"
  path                 = "/system/"
  assume_role_policy   = data.aws_iam_policy_document.assume-role-policy.json
  force_detach_policies= true 
}

resource "aws_iam_policy" "policy" {
  name = "activity-policy-${var.REGION}"

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

resource "aws_iam_role_policy_attachment" "test_attach" {
  role       = aws_iam_role.lambda_function_role.name
  policy_arn = aws_iam_policy.policy.arn
}

##### API Gateway & Lambda integration #####
resource "aws_lambda_permission" "lambda_permission" {
  statement_id  = "AllowMyAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api_gateway.rest_api_execution_arn}/*/*/*"
}

resource "aws_api_gateway_integration" "client_api_lambda" {
    rest_api_id   = module.api_gateway.rest_api_id
    resource_id   = module.api_gateway.resource_id
    http_method   = module.api_gateway.http_method_object.http_method
    integration_http_method = "POST"
    type                    = "AWS"
    uri                     = aws_lambda_function.lambda_function.invoke_arn
    passthrough_behavior    = "NEVER"
    request_templates = {
      "application/json" = <<EOF
      {  "body": $input.json('$') }
      EOF
    }    
    depends_on    = [module.api_gateway.http_method_object]
 }

resource "aws_api_gateway_integration_response" "response_200_integration" {
  rest_api_id   = module.api_gateway.rest_api_id
  resource_id   = module.api_gateway.resource_id
  http_method   = module.api_gateway.http_method_object.http_method
  status_code = 200
  # Transforms the backend JSON response to XML
  response_templates = {

    "application/json" = <<EOF
#set($inputRoot = $input.path('$'))
    $inputRoot.body
EOF
  }

  depends_on = [aws_api_gateway_integration.client_api_lambda]
}

resource "aws_api_gateway_deployment" "api_deployment" {
  depends_on = [aws_api_gateway_integration.client_api_lambda, module.api_gateway.http_method_object, module.api_gateway.http_options_method_object]
  rest_api_id = module.api_gateway.rest_api_id
  stage_name  = "dev"
}