############################################
# API GATEWAY OUTPUTS
############################################

output "api_invoke_url" {
  description = "Base URL for invoking the API Gateway stage"
  value       = aws_api_gateway_stage.this.invoke_url
}

output "api_gateway_rest_api_name" {
  description = "Name of the API Gateway REST API fronting the Spring Boot Lambda"
  value       = aws_api_gateway_rest_api.this.name
}

output "api_gateway_stage_name" {
  description = "Name of the API Gateway stage the REST API is deployed to"
  value       = aws_api_gateway_stage.this.stage_name
}
