output "lambda_etl_function_name" {
  value = aws_lambda_function.etl.function_name
}

output "lambda_etl_function_arn" {
  value = aws_lambda_function.etl.arn
}

output "lambda_process_csv_function_name" {
  value = aws_lambda_function.process_csv.function_name
}

output "lambda_process_csv_function_arn" {
  value = aws_lambda_function.process_csv.arn
}
