terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_lambda_function" "lw-ingestion" {
  function_name = "lw-ingestion-terraform"

  # The bucket name as created earlier with "aws s3api create-bucket"
  s3_bucket = "two-bees-in-a"
  s3_key    = "v1.0.0/function.zip"

  # "main" is the filename within the zip file (main.js) and "handler"
  # is the name of the property under which the handler function was
  # exported in that file.
  handler = "main.handler"
  runtime = "go1.x"

  role = aws_iam_role.lambda_exec.arn

  # environment variables
  environment {
    variables = {
      GCHAT_WEBHOOK = "https://chat.googleapis.com/v1/spaces/AAAAAH1X_3o/messages?key=AIzaSyDdI0hCZtE6vySjMm-WEfRq3CPzqKqqsHI&token=7RvBsAkd6s6_f0YX1W4_br5679Q1jUVKwOWK2jlBXUA%3D",
      SNS_TOPIC = "arn:aws:sns:us-east-1:148091754571:lw-events"
    }
  }
}

# IAM role which dictates what other AWS services the Lambda function
# may access.
resource "aws_iam_role" "lambda_exec" {
  name = "lw-ingestion-terraform"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lw-ingestion.function_name
  principal     = "apigateway.amazonaws.com"

  # The "/*/*" portion grants access from any method on any resource
  # within the API Gateway REST API.
  source_arn = "${aws_api_gateway_rest_api.lw_ingestion.execution_arn}/*/*"
}