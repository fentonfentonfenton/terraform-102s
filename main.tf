provider "aws" {
  region = "eu-west-1"
}


data "archive_file" "lambda_zip_file_int" {
  type        = "zip"
  output_path = "/tmp/lambda_zip_file_int.zip"
  source {
    content  = file("lambda_function.py")
    filename = "lambda_function.py"
  }
}



resource "aws_lambda_function" "default" {
  filename      = data.archive_file.lambda_zip_file_int.output_path
  function_name = var.name
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  source_code_hash = data.archive_file.lambda_zip_file_int.output_base64sha256

  runtime = "python3.6"
  timeout = 12
}

resource "aws_cloudwatch_log_group" "example" {
  name = var.name
}

resource "aws_iam_role" "lambda_role" {
  name = var.name

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

resource "aws_iam_role_policy_attachment" "log" {
  role       = var.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

