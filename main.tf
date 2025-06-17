# main.tf

# --- Terraform Configuration ---
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.74.0" # Lock to a specific version for consistency
    }
  }
}

# --- AWS Provider Configuration ---
provider "aws" {
  region     = "ap-south-1"
  access_key = "paste-your-access-key"     # 👈 paste your access key
  secret_key = "paste-your-secret-key"     # 👈 paste your secret key 
}

# --- IAM Role for Lambda Functions ---
# This single IAM role will be assumed by both Lambda functions.
# It grants necessary permissions for Lambda execution and interacting with EC2.
resource "aws_iam_role" "ec2_scheduler_lambda_role" {
  name = "EC2SchedulerLambdaRole" # Unique name for the IAM role

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    ManagedBy = "Terraform"
    Purpose   = "EC2 Scheduler"
  }
}

# --- IAM Policy for Lambda Role ---
# This policy defines the specific actions the Lambda functions are allowed to perform.
# It includes permissions for EC2 (describe, start, stop) and CloudWatch Logs.
resource "aws_iam_role_policy" "ec2_scheduler_lambda_policy" {
  name = "EC2SchedulerLambdaPolicy" # Unique name for the IAM policy
  role = aws_iam_role.ec2_scheduler_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:DescribeInstances", # Required to find instances
          "ec2:StartInstances",    # Required to start instances
          "ec2:StopInstances",     # Required to stop instances
          "logs:CreateLogGroup",   # Required for CloudWatch Logs
          "logs:CreateLogStream",  # Required for CloudWatch Logs
          "logs:PutLogEvents"      # Required for CloudWatch Logs
        ]
        Effect   = "Allow"
        Resource = "*" # For simplicity. In production, consider scoping down to specific instance ARNs or resources.
      }
    ]
  })
}

# --- Lambda Code Packaging for Start Function ---
# This zips the Python code for the 'start' Lambda into a deployment package.
data "archive_file" "start_ec2_lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/python/start_ec2_instances.py" # Path to your start script
  output_path = "${path.module}/python/start_ec2_instances.zip" # Output zip file
}

# --- Lambda Code Packaging for Stop Function ---
# This zips the Python code for the 'stop' Lambda into a deployment package.
data "archive_file" "stop_ec2_lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/python/stop_ec2_instances.py" # Path to your stop script
  output_path = "${path.module}/python/stop_ec2_instances.zip" # Output zip file
}

# --- Lambda Function: Start EC2 Instances ---
# Defines the AWS Lambda function responsible for starting EC2 instances.
resource "aws_lambda_function" "start_ec2_function" {
  function_name    = "StartEC2Daily" # Name of the Lambda function
  role             = aws_iam_role.ec2_scheduler_lambda_role.arn
  handler          = "start_ec2_instances.lambda_handler" # File.function_name
  runtime          = "python3.9"
  timeout          = 60 # 1 minute timeout for testing
  memory_size      = 128

  filename         = data.archive_file.start_ec2_lambda_zip.output_path
  source_code_hash = data.archive_file.start_ec2_lambda_zip.output_base64sha256

  tags = {
    ManagedBy = "Terraform"
    Purpose   = "EC2 Scheduler Start"
  }
}

# --- Lambda Function: Stop EC2 Instances ---
# Defines the AWS Lambda function responsible for stopping EC2 instances.
resource "aws_lambda_function" "stop_ec2_function" {
  function_name    = "StopEC2Daily" # Name of the Lambda function
  role             = aws_iam_role.ec2_scheduler_lambda_role.arn
  handler          = "stop_ec2_instances.lambda_handler" # File.function_name
  runtime          = "python3.9"
  timeout          = 60 # 1 minute timeout for testing
  memory_size      = 128

  filename         = data.archive_file.stop_ec2_lambda_zip.output_path
  source_code_hash = data.archive_file.stop_ec2_lambda_zip.output_base64sha256

  tags = {
    ManagedBy = "Terraform"
    Purpose   = "EC2 Scheduler Stop"
  }
}

# --- EventBridge Rule: Schedule to Start EC2 Instances (Production Schedule) ---
# This rule triggers the StartEC2Daily Lambda daily at 8:00 AM Pakistan Time (PKT).
# PKT is UTC+5, so 8:00 AM PKT is 3:00 AM UTC.
resource "aws_cloudwatch_event_rule" "start_ec2_schedule_rule" {
  name                = "start-ec2-daily-schedule"
  description         = "Schedule to start EC2 instances daily at 8:00 AM PKT"
  # Cron expression: Minutes Hours Day-of-month Month Day-of-week Year
  # 8:00 AM PKT (UTC+5) = 3:00 AM UTC
  schedule_expression = "cron(0 3 ? * MON-FRI *)" # <--- UPDATED to reflect office hours Mon-Fri
                                               # Using '?' for Day-of-month and 'MON-FRI' for Day-of-week
                                               # Year field is optional, omitted for 'every year'
  tags = {
    ManagedBy = "Terraform"
    Purpose   = "EC2 Scheduler Start"
  }
}

# --- EventBridge Target: Link Start Schedule to Lambda ---
# This links the 'start' schedule rule to the 'start' Lambda function.
resource "aws_cloudwatch_event_target" "start_ec2_lambda_target" {
  rule      = aws_cloudwatch_event_rule.start_ec2_schedule_rule.name
  target_id = "StartEC2Lambda" # Unique ID for the target
  arn       = aws_lambda_function.start_ec2_function.arn
}

# --- Lambda Permission for EventBridge to Invoke Start Function ---
# Grants EventBridge permission to invoke the StartEC2Daily Lambda.
resource "aws_lambda_permission" "allow_cloudwatch_to_invoke_start_lambda" {
  statement_id  = "AllowExecutionFromCloudWatchStart"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.start_ec2_function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.start_ec2_schedule_rule.arn
}

# --- EventBridge Rule: Schedule to Stop EC2 Instances (Production Schedule) ---
# This rule triggers the StopEC2Daily Lambda daily at 5:00 PM Pakistan Time (PKT).
# PKT is UTC+5, so 5:00 PM PKT (17:00) is 12:00 PM UTC.
resource "aws_cloudwatch_event_rule" "stop_ec2_schedule_rule" {
  name                = "stop-ec2-daily-schedule"
  description         = "Schedule to stop EC2 instances daily at 5:00 PM PKT"
  # Cron expression: Minutes Hours Day-of-month Month Day-of-week Year
  # 5:00 PM PKT (17:00) = 12:00 PM UTC
  schedule_expression = "cron(0 12 ? * MON-FRI *)" # <--- UPDATED to reflect office hours Mon-Fri
                                               # Using '?' for Day-of-month and 'MON-FRI' for Day-of-week
                                               # Year field is optional, omitted for 'every year'
  tags = {
    ManagedBy = "Terraform"
    Purpose   = "EC2 Scheduler Stop"
  }
}

# --- EventBridge Target: Link Stop Schedule to Lambda ---
# This links the 'stop' schedule rule to the 'stop' Lambda function.
resource "aws_cloudwatch_event_target" "stop_ec2_lambda_target" {
  rule      = aws_cloudwatch_event_rule.stop_ec2_schedule_rule.name
  target_id = "StopEC2Lambda" # Unique ID for the target
  arn       = aws_lambda_function.stop_ec2_function.arn
}

# --- Lambda Permission for EventBridge to Invoke Stop Function ---
# Grants EventBridge permission to invoke the StopEC2Daily Lambda.
resource "aws_lambda_permission" "allow_cloudwatch_to_invoke_stop_lambda" {
  statement_id  = "AllowExecutionFromCloudWatchStop"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.stop_ec2_function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.stop_ec2_schedule_rule.arn
}