terraform {
  backend "s3" {
    bucket = "imtech-2025"
    key    = "Ofir/terraform.tfstate"
    region = "il-central-1"
    encrypt = true
  }
}
