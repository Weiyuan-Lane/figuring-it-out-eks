
resource "aws_security_group" "allow_vpc_sg_ssh" {
  name_prefix = "sec_group_sg"
  vpc_id      = module.vpc_sg.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks      = [module.vpc_sg.vpc_cidr_block]
  }

  provider = aws.sg
}


