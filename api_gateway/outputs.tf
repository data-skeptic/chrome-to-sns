output "rest_api_id" {
  value = aws_api_gateway_rest_api.activity_tracker.id
}

output "rest_api_execution_arn" {
  value = aws_api_gateway_rest_api.activity_tracker.execution_arn
}

output "resource_id" {
  value = aws_api_gateway_resource.client.id
}

output "http_method" {
  value = aws_api_gateway_method.client_post.http_method
}
