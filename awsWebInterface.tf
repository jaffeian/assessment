# Container with a web interface
resource "aws_instance" "web_instance" {
    ami           = "ami-0557a15b87f6559cf"
    instance_type = "t2.micro"
    subnet_id     = aws_subnet.public_subnet_1a.id

    user_data = <<-EOF
                #!/bin/bash
                # Install Apache and host a simple website
                yum update -y
                yum install -y httpd
                service httpd start
                chkconfig httpd on
                echo "Hello, Terraform!" > /var/www/html/index.html
                EOF
}