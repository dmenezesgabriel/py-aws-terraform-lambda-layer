locals {
  lambda_function_zip = "lambda_function.zip"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_lambda_${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "archive_file" "lambda_function" {
  type        = "zip"
  source_file = "../lambda_function.py"
  output_path = local.lambda_function_zip
}

resource "aws_lambda_function_url" "lambda_function" {
  function_name      = aws_lambda_function.lambda_function.function_name
  authorization_type = "NONE"
}

resource "aws_lambda_function" "lambda_function" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename         = local.lambda_function_zip
  function_name    = "lambda_function_${var.environment}"
  handler          = "lambda_function.lambda_handler"
  layers           = [aws_lambda_layer_version.lambda_layer.arn]
  role             = aws_iam_role.iam_for_lambda.arn
  runtime          = "python3.11"
  source_code_hash = data.archive_file.lambda_function.output_base64sha256

  environment {
    variables = {
      foo = "bar"
    }
  }

  tracing_config {
    mode = "Active"
  }
}

# Cloudwatch logs
resource "aws_cloudwatch_log_group" "lambda_function" {
  name              = "/aws/lambda/${aws_lambda_function.lambda_function.function_name}"
  retention_in_days = 30
}
