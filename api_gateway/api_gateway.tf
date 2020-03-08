
resource "aws_api_gateway_rest_api" "activity_tracker" {
    name        = "activity-tracker"
}

 resource "aws_api_gateway_resource" "client" {
    rest_api_id = aws_api_gateway_rest_api.activity_tracker.id
    parent_id   = aws_api_gateway_rest_api.activity_tracker.root_resource_id
    path_part   = "client"
}

resource "aws_api_gateway_method" "client_post" {
    rest_api_id   = aws_api_gateway_rest_api.activity_tracker.id
    resource_id   = aws_api_gateway_resource.client.id
    http_method   = "POST"
    authorization = "NONE"
 }

 resource "aws_api_gateway_method" "client_options" {
    rest_api_id   = aws_api_gateway_rest_api.activity_tracker.id
    resource_id   = aws_api_gateway_resource.client.id
    http_method   = "OPTIONS"
    authorization = "NONE"
}

resource "aws_api_gateway_method_response" "options_200" {
    rest_api_id   = aws_api_gateway_rest_api.activity_tracker.id
    resource_id   = aws_api_gateway_resource.client.id
    http_method   = aws_api_gateway_method.client_options.http_method
    status_code   = "200"
    response_models = {
         "application/json" = "Empty"
    }
    response_parameters = {
        "method.response.header.Access-Control-Allow-Headers" = true,
        "method.response.header.Access-Control-Allow-Methods" = true,
        "method.response.header.Access-Control-Allow-Origin" = true
    }
    depends_on = [aws_api_gateway_method.client_options]
}

#resource "aws_api_gateway_integration" "client-api-lambda" {
#    rest_api_id   = aws_api_gateway_rest_api.activity-tracker.id
#    resource_id   = aws_api_gateway_resource.client.id
#    http_method   = aws_api_gateway_method.proxy.client-post

 #  integration_http_method = "POST"
 #  type                    = "AWS_PROXY"
 #  uri                     = aws_lambda_function.lambda_function.invoke_arn
 #}