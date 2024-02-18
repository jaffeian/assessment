terraform {
    required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "4.15.0"
    }
    }
}

provider "aws" {
    region                      = var.region
    shared_config_files      = ["~/.aws/config"]
    shared_credentials_files = ["~/.aws/credentials"]
    profile                  = "duplcloud_assessment"
}
