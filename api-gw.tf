data "aws_route53_zone" "Zone" {
  name = var.zone_name
}

data "aws_s3_bucket" "www" {
  bucket = var.bucket
}

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

resource "aws_iam_role" "s3_api_gateyway_role" {
  name = "${var.subdomain}-s3-api-gateyway-role"

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

resource "aws_iam_role_policy_attachment" "s3_policy_attach" {
  role = aws_iam_role.s3_api_gateyway_role.name
  policy_arn = aws_iam_policy.s3_policy.arn
}

resource "aws_api_gateway_rest_api" "RestApi" {
  name = "${var.subdomain}.${var.zone_name}"
  binary_media_types = var.media_types;
}

resource "aws_api_gateway_deployment" "S3APIDeployment" {
  depends_on = [aws_api_gateway_integration.itemGetMethodIntegration]
  rest_api_id = aws_api_gateway_rest_api.RestApi.id
  stage_name = var.stage_name
  variables = {
    ui_pointed_at = "${var.bucket} ${var.prefix}"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_domain_name" "api_domain_name" {
  domain_name = "${var.subdomain}.${var.zone_name}"
  certificate_arn = var.ssl_certificate_arn
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

