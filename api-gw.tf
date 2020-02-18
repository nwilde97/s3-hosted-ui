/*
========================================================================================

DON'T CHANGE ANYTHING BELOW THIS LINE

========================================================================================
*/

provider "aws" {
  alias = "useast1"
  region = "us-east-1"
}

data aws_acm_certificate cert {
  domain = var.cert_domain
  provider = aws.useast1
}

data "aws_route53_zone" "Zone" {
  name = var.zone_name
}

data "aws_s3_bucket" "www" {
  bucket = var.bucket
}

# Create S3 Full Access Policy
resource "aws_iam_policy" "s3_policy" {
  name = "${var.subdomain}-s3-policy"
  description = "Policy for allowing all S3 Actions"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": ["s3:GetObject"],
            "Resource": ["${data.aws_s3_bucket.www.arn}/*"]
        }
    ]
}
EOF
}

# Create API Gateway Role
resource "aws_iam_role" "s3_api_gateyway_role" {
  name = "${var.subdomain}-s3-api-gateyway-role"

  # Create Trust Policy for API Gateway
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
  EOF
}

# Attach S3 Access Policy to the API Gateway Role
resource "aws_iam_role_policy_attachment" "s3_policy_attach" {
  role = aws_iam_role.s3_api_gateyway_role.name
  policy_arn = aws_iam_policy.s3_policy.arn
}

resource "aws_api_gateway_rest_api" "RestApi" {
  name = "${var.subdomain}.${var.zone_name}"
}

resource "aws_api_gateway_deployment" "S3APIDeployment" {
  depends_on = [aws_api_gateway_integration.itemGetMethodIntegration]
  rest_api_id = aws_api_gateway_rest_api.RestApi.id
  stage_name = var.stage_name
  variables = {
    api_pointed_at = var.api_url
    ui_pointed_at = "${var.bucket} ${var.branch}"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_domain_name" "api_domain_name" {
  depends_on = [data.aws_acm_certificate.cert]
  domain_name = "${var.subdomain}.${var.zone_name}"
  certificate_arn = data.aws_acm_certificate.cert.arn
}

resource "aws_api_gateway_base_path_mapping" "base_path" {
  api_id      = aws_api_gateway_rest_api.RestApi.id
  stage_name  = var.stage_name
  domain_name = aws_api_gateway_domain_name.api_domain_name.domain_name
}

resource "aws_route53_record" "route_alias" {
  depends_on = [aws_api_gateway_domain_name.api_domain_name]
  zone_id = data.aws_route53_zone.Zone.zone_id
  name = aws_api_gateway_domain_name.api_domain_name.domain_name
  type = "A"
  alias {
    name = aws_api_gateway_domain_name.api_domain_name.cloudfront_domain_name
    zone_id = aws_api_gateway_domain_name.api_domain_name.cloudfront_zone_id
    evaluate_target_health = false
  }
}

