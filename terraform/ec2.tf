resource "aws_instance" "ec2-public-vaction" {
  ami                    = "ami-0e86e20dae9224db8"  # Ubuntu 22.04 LTS
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public.id
  associate_public_ip_address = true
  security_groups        = [aws_security_group.sg-public-vaction.id]
  key_name = "key-ec2-public-vaction"


  provisioner "file" {
    source      = "C:\\Users\\Gabriel\\Desktop\\faculdade\\5-sem-pi\\key-ec2-private-vaction.pem"
    destination = "/home/ubuntu/.ssh/key-ec2-private-vaction.pem"
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("C:\\Users\\Gabriel\\Desktop\\faculdade\\5-sem-pi\\key-ec2-public-vaction.pem")
    host        = self.public_ip

    bastion_host        = aws_instance.ec2-public-vaction.public_ip
    bastion_user        = "ubuntu"
    bastion_private_key = file("C:\\Users\\Gabriel\\Desktop\\faculdade\\5-sem-pi\\key-ec2-public-vaction.pem")
  }

  tags = {
    Name = "ec2-public-vaction"
  }
}

resource "aws_instance" "ec2-private-vaction" {
  ami                    = "ami-0e86e20dae9224db8"  # Ubuntu 22.04 LTS
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private.id
  associate_public_ip_address = false
  security_groups        = [aws_security_group.sg-private-vaction.id]
  key_name = "key-ec2-private-vaction"

  depends_on = [aws_instance.ec2-public-vaction, aws_route_table_association.rt-private-association-vaction]


  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("C:\\Users\\Gabriel\\Desktop\\faculdade\\5-sem-pi\\key-ec2-private-vaction.pem")
    host        = self.private_ip

    bastion_host        = aws_instance.ec2-public-vaction.public_ip
    bastion_user        = "ubuntu"
    bastion_private_key = file("C:\\Users\\Gabriel\\Desktop\\faculdade\\5-sem-pi\\key-ec2-public-vaction.pem")
  }

  tags = {
    Name = "ec2-private-vaction"
  }
}

# ======================== Armazenando o IP do MySql no AWS SSM ========================

resource "aws_ssm_parameter" "private_ip" {
  name  = "/config/backend_private_ip"
  type  = "String"
  value = aws_instance.ec2-private-vaction.private_ip
}

# ======================== Executando o Script de Configuração ========================

# ======================== Outputs (para visualizar os IPs) ========================
output "nginx_public_ip" {
  description = "IP Público do Servidor Nginx"
  value       = aws_instance.ec2-public-vaction.public_ip
}

output "backend_private_ip" {
  description = "IP Privado do Servidor MySQL"
  value       = aws_instance.ec2-private-vaction.private_ip
}