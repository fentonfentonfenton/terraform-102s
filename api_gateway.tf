

resource "aws_api_gateway_rest_api" "default" {
  name = var.name
}

resource "aws_api_gateway_rest_api_policy" "default" {
  rest_api_id = aws_api_gateway_rest_api.default.id
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": "*",
            "Action": "execute-api:Invoke",
      "Resource": "${aws_api_gateway_rest_api.default.execution_arn}"
        }
    ]
}
EOF

}


### List of api gateway paths which terraform loops over. Any added resources should go through this.
variable "resource_paths" {
  type = map
  default = {
    "test" = "test"
  }
}

// ## Resources

resource "aws_api_gateway_resource" "default" {
  for_each    = var.resource_paths
  rest_api_id = aws_api_gateway_rest_api.default.id
  parent_id   = aws_api_gateway_rest_api.default.root_resource_id
  path_part   = each.value
}

// ## Methods

resource "aws_api_gateway_method" "default" {
  for_each      = var.resource_paths
  rest_api_id   = aws_api_gateway_rest_api.default.id
  resource_id   = aws_api_gateway_resource.default[each.key].id
  http_method   = "POST"
  authorization = "NONE"
}


## Integrations

resource "aws_api_gateway_integration" "default" {
  for_each                = var.resource_paths
  rest_api_id             = aws_api_gateway_rest_api.default.id
  resource_id             = aws_api_gateway_resource.default[each.key].id
  http_method             = aws_api_gateway_method.default[each.key].http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.default.invoke_arn
}



resource "aws_api_gateway_deployment" "default" {
  depends_on = [
    aws_api_gateway_integration.default
  ]

  rest_api_id = aws_api_gateway_rest_api.default.id
  stage_name  = "prod"
}


resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.default.function_name
  principal     = "apigateway.amazonaws.com"

  # The "/*/*" portion grants access from any method on any resource
  # within the API Gateway REST API.
  source_arn = "${aws_api_gateway_rest_api.default.execution_arn}/*/*"
}


output "base_url" {
  value = aws_api_gateway_deployment.default.invoke_url
}
