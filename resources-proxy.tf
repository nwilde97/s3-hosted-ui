resource "aws_api_gateway_resource" "app" {
  rest_api_id = aws_api_gateway_rest_api.RestApi.id
  parent_id = aws_api_gateway_rest_api.RestApi.root_resource_id
  path_part = "app"
}

resource "aws_api_gateway_resource" "Item" {
  rest_api_id = aws_api_gateway_rest_api.RestApi.id
  parent_id = aws_api_gateway_resource.app.id
  path_part = "{proxy+}"
}

resource "aws_api_gateway_method" "itemGetMethod" {
  rest_api_id = aws_api_gateway_rest_api.RestApi.id
  resource_id = aws_api_gateway_resource.Item.id
  http_method      = "GET"
  authorization    = "NONE"
  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "itemGetMethodIntegration" {
  rest_api_id = aws_api_gateway_rest_api.RestApi.id
  resource_id = aws_api_gateway_resource.Item.id
  http_method = aws_api_gateway_method.itemGetMethod.http_method

  type                    = "AWS"
  integration_http_method = "GET"
  credentials             = aws_iam_role.s3_api_gateyway_role.arn
  uri                     = "arn:aws:apigateway:us-west-2:s3:path/${data.aws_s3_bucket.www.bucket}/branches/${var.branch}/{proxy}"
  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }

  depends_on = [aws_api_gateway_method.itemGetMethod]
}

resource "aws_api_gateway_integration_response" "itemGetMethod-IntegrationResponse" {
  rest_api_id = aws_api_gateway_rest_api.RestApi.id
  resource_id = aws_api_gateway_resource.Item.id
  http_method = aws_api_gateway_method.itemGetMethod.http_method
  status_code = aws_api_gateway_method_response.itemGetMethod200Response.status_code

  response_parameters = {
    "method.response.header.Timestamp" = "integration.response.header.Date"
    "method.response.header.Content-Length" = "integration.response.header.Content-Length"
    "method.response.header.Content-Type" = "integration.response.header.Content-Type"
  }
}

resource "aws_api_gateway_method_response" "itemGetMethod200Response" {
  rest_api_id = aws_api_gateway_rest_api.RestApi.id
  resource_id = aws_api_gateway_resource.Item.id
  http_method = aws_api_gateway_method.itemGetMethod.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Timestamp" = true
    "method.response.header.Content-Length" = true
    "method.response.header.Content-Type" = true
  }

  depends_on = [aws_api_gateway_method.itemGetMethod]
}