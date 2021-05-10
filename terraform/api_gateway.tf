resource "aws_api_gateway_rest_api" "lw_ingestion" {
  name        = "lw-ingestion-terraform"
  description = "Terraform Lacework Event Ingestion"
}

resource "aws_api_gateway_resource" "ingestion" {
  rest_api_id = aws_api_gateway_rest_api.lw_ingestion.id
  parent_id   = aws_api_gateway_rest_api.lw_ingestion.root_resource_id
  path_part   = "ingestion"
}

resource "aws_api_gateway_resource" "sns" {
  rest_api_id = aws_api_gateway_rest_api.lw_ingestion.id
  parent_id   = aws_api_gateway_resource.ingestion.id
  path_part   = "sns"
}

resource "aws_api_gateway_resource" "gchat" {
  rest_api_id = aws_api_gateway_rest_api.lw_ingestion.id
  parent_id   = aws_api_gateway_resource.ingestion.id
  path_part   = "gchat"
}

resource "aws_api_gateway_method" "sns" {
  rest_api_id   = aws_api_gateway_rest_api.lw_ingestion.id
  resource_id   = aws_api_gateway_resource.sns.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "gchat" {
  rest_api_id   = aws_api_gateway_rest_api.lw_ingestion.id
  resource_id   = aws_api_gateway_resource.gchat.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "sns" {
  rest_api_id = aws_api_gateway_rest_api.lw_ingestion.id
  resource_id = aws_api_gateway_method.sns.resource_id
  http_method = aws_api_gateway_method.sns.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lw-ingestion.invoke_arn
}


resource "aws_api_gateway_integration" "gchat" {
  rest_api_id = aws_api_gateway_rest_api.lw_ingestion.id
  resource_id = aws_api_gateway_method.gchat.resource_id
  http_method = aws_api_gateway_method.gchat.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lw-ingestion.invoke_arn
}

resource "aws_api_gateway_deployment" "lw_ingestion" {
  depends_on = [
    aws_api_gateway_integration.sns,
    aws_api_gateway_integration.gchat,
  ]

  rest_api_id = aws_api_gateway_rest_api.lw_ingestion.id
  stage_name  = "test"
}

output "base_url" {
  value = aws_api_gateway_deployment.lw_ingestion.invoke_url
}

