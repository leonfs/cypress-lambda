provider "aws" {
  region                  = "us-west-2"
  shared_credentials_file = "~/.aws/credentials"
  profile                 = "default"
}

resource "aws_s3_bucket" "cypress_lambda" {
  bucket = "cypress-lambda-leonfs"
  acl    = "private"
}

data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "lambda/"
  output_path = "lambda.zip"
}

resource "aws_s3_bucket_object" "lambda" {
  bucket = "${aws_s3_bucket.cypress_lambda.id}"

  key    = "lambda.zip"
  source = "${data.archive_file.lambda.output_path}"
  etag   = "${data.archive_file.lambda.output_base64sha256}"
}

resource "aws_lambda_function" "cypress_runner" {
  function_name    = "cypress_runner"
  s3_bucket        = "${aws_s3_bucket.cypress_lambda.id}"
  s3_key           = "${aws_s3_bucket_object.lambda.key}"
  role             = "${aws_iam_role.lambda.arn}"
  handler          = "index.handler"
  runtime          = "nodejs8.10"
  memory_size      = 3008
  source_code_hash = "${data.archive_file.lambda.output_base64sha256}"
  timeout          = 90
}

resource "aws_iam_role" "lambda" {
  name = "lambda"

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

resource "aws_iam_role_policy" "lambda" {
  name = "lambda_init"
  role = "${aws_iam_role.lambda.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
		{
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "local_file" "lambda_arn" {
  content  = "${aws_lambda_function.cypress_runner.arn}"
  filename = "deployed_lambda_arn"
}
