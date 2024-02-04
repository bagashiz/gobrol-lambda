resource "aws_dynamodb_table" "gobrol" {
  name         = "gobrol"
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "connectionId"

  attribute {
    name = "connectionId"
    type = "S"
  }
}
