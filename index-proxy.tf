resource "aws_api_gateway_method" "rootGetMethod" {
  rest_api_id = aws_api_gateway_rest_api.RestApi.id
  resource_id = aws_api_gateway_rest_api.RestApi.root_resource_id
  http_method      = "GET"
  authorization    = "NONE"
}

resource "aws_api_gateway_integration" "rootGetMethodIntegration" {
  rest_api_id = aws_api_gateway_rest_api.RestApi.id
  resource_id = aws_api_gateway_rest_api.RestApi.root_resource_id
  http_method = aws_api_gateway_method.rootGetMethod.http_method

  type                    = "AWS"
  integration_http_method = "GET"
  credentials             = aws_iam_role.s3_api_gateyway_role.arn
  uri                     = "arn:aws:apigateway:us-west-2:s3:path/${data.aws_s3_bucket.www.bucket}/${var.prefix}/index.html"
  depends_on = [aws_api_gateway_method.rootGetMethod]
}

resource "aws_api_gateway_integration_response" "rootGetMethod-IntegrationResponse" {
  depends_on = [aws_api_gateway_method.rootGetMethod]
  rest_api_id = aws_api_gateway_rest_api.RestApi.id
  resource_id = aws_api_gateway_rest_api.RestApi.root_resource_id
  http_method = aws_api_gateway_method.rootGetMethod.http_method
  status_code = aws_api_gateway_method_response.rootGetMethod200Response.status_code

  response_parameters = {
    "method.response.header.Timestamp" = "integration.response.header.Date"
    "method.response.header.Content-Length" = "integration.response.header.Content-Length"
    "method.response.header.Content-Type" = "integration.response.header.Content-Type"
  }
}

resource "aws_api_gateway_method_response" "rootGetMethod200Response" {
  rest_api_id = aws_api_gateway_rest_api.RestApi.id
  resource_id = aws_api_gateway_rest_api.RestApi.root_resource_id
  http_method = aws_api_gateway_method.rootGetMethod.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Timestamp" = true
    "method.response.header.Content-Length" = true
    "method.response.header.Content-Type" = true
  }

  depends_on = [aws_api_gateway_method.rootGetMethod]
}


/*
Everything duplicated with the proxy
*/

resource "aws_api_gateway_resource" "rootProxy" {
  rest_api_id = aws_api_gateway_rest_api.RestApi.id
  parent_id = aws_api_gateway_rest_api.RestApi.root_resource_id
  path_part = "{proxy+}"
}

resource "aws_api_gateway_method" "rootGetMethod2" {
  rest_api_id = aws_api_gateway_rest_api.RestApi.id
  resource_id = aws_api_gateway_resource.rootProxy.id
  http_method      = "GET"
  authorization    = "NONE"
}

resource "aws_api_gateway_integration" "rootGetMethodIntegration2" {
  rest_api_id = aws_api_gateway_rest_api.RestApi.id
  resource_id = aws_api_gateway_resource.rootProxy.id
  http_method = aws_api_gateway_method.rootGetMethod2.http_method

  type                    = "AWS"
  integration_http_method = "GET"
  credentials             = aws_iam_role.s3_api_gateyway_role.arn
  uri                     = "arn:aws:apigateway:us-west-2:s3:path/${data.aws_s3_bucket.www.bucket}/${var.prefix}/index.html"
  depends_on = [aws_api_gateway_method.rootGetMethod2]
}

resource "aws_api_gateway_integration_response" "rootGetMethod-IntegrationResponse2" {
  depends_on = [aws_api_gateway_method.rootGetMethod2]
  rest_api_id = aws_api_gateway_rest_api.RestApi.id
  resource_id = aws_api_gateway_resource.rootProxy.id
  http_method = aws_api_gateway_method.rootGetMethod2.http_method
  status_code = aws_api_gateway_method_response.rootGetMethod200Response2.status_code

  response_parameters = {
    "method.response.header.Timestamp" = "integration.response.header.Date"
    "method.response.header.Content-Length" = "integration.response.header.Content-Length"
    "method.response.header.Content-Type" = "integration.response.header.Content-Type"
  }
}

resource "aws_api_gateway_method_response" "rootGetMethod200Response2" {
  rest_api_id = aws_api_gateway_rest_api.RestApi.id
  resource_id = aws_api_gateway_resource.rootProxy.id
  http_method = aws_api_gateway_method.rootGetMethod2.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Timestamp" = true
    "method.response.header.Content-Length" = true
    "method.response.header.Content-Type" = true
  }

  depends_on = [aws_api_gateway_method.rootGetMethod2]
}
