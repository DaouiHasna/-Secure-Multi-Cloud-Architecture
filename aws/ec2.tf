resource "aws_instance" "bastion" {
  ami                    = "ami-08f9a9c699d2ab3f9" # Amazon Linux 2 us-east-1
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  key_name               = "terraform-key"

  associate_public_ip_address = true


  tags = {
    Name = "Bastion-Host"
  }
}


#Private App Server
resource "aws_instance" "private_app" {
  ami                    = "ami-08f9a9c699d2ab3f9"
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.private_sg.id]
  key_name               = "terraform-key"

  associate_public_ip_address = false

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  root_block_device {
    encrypted = true
  }

  tags = {
    Name = "Private-App"
  }
}
