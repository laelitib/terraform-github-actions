terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  # Backend S3 configuré dynamiquement par le workflow
  backend "s3" {}
}

provider "aws" {
  region = var.aws_region
}

# Récupérer le VPC par défaut
data "aws_vpc" "default" {
  default = true
}

# Récupérer le subnet par défaut
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Security Group pour le serveur web
resource "aws_security_group" "web_sg" {
  name_prefix = "web-server-sg-"
  description = "Security group for web server - Managed by Terraform"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "web-server-sg"
    ManagedBy = "Terraform"
    Project   = var.project_name
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Récupérer la dernière AMI Amazon Linux 2023
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Instance EC2
resource "aws_instance" "web_server" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type
  
  subnet_id                   = tolist(data.aws_subnets.default.ids)[0]
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              # Mise à jour du système
              dnf update -y
              
              # Installation Apache
              dnf install -y httpd
              
              # Démarrage Apache
              systemctl start httpd
              systemctl enable httpd
              
              # Page d'accueil personnalisée
              cat > /var/www/html/index.html <<'HTML'
              <!DOCTYPE html>
              <html lang="fr">
              <head>
                  <meta charset="UTF-8">
                  <meta name="viewport" content="width=device-width, initial-scale=1.0">
                  <title>Terraform AWS Automation</title>
                  <style>
                      * { margin: 0; padding: 0; box-sizing: border-box; }
                      body {
                          font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                          min-height: 100vh;
                          display: flex;
                          justify-content: center;
                          align-items: center;
                          padding: 20px;
                      }
                      .container {
                          background: white;
                          border-radius: 20px;
                          box-shadow: 0 20px 60px rgba(0,0,0,0.3);
                          padding: 50px;
                          max-width: 600px;
                          text-align: center;
                      }
                      h1 {
                          color: #667eea;
                          font-size: 2.5em;
                          margin-bottom: 20px;
                      }
                      .emoji { font-size: 4em; margin: 20px 0; }
                      .info {
                          background: #f7fafc;
                          border-radius: 10px;
                          padding: 20px;
                          margin: 20px 0;
                          text-align: left;
                      }
                      .info-item {
                          margin: 10px 0;
                          padding: 10px;
                          background: white;
                          border-radius: 5px;
                          border-left: 4px solid #667eea;
                      }
                      .label {
                          font-weight: bold;
                          color: #667eea;
                      }
                      .badge {
                          display: inline-block;
                          background: #48bb78;
                          color: white;
                          padding: 5px 15px;
                          border-radius: 20px;
                          font-size: 0.9em;
                          margin: 10px 5px;
                      }
                  </style>
              </head>
              <body>
                  <div class="container">
                      <div class="emoji">🚀</div>
                      <h1>Infrastructure Déployée !</h1>
                      <p style="color: #718096; font-size: 1.2em; margin: 20px 0;">
                          Votre infrastructure AWS a été déployée avec succès via GitHub Actions et Terraform
                      </p>
                      <div class="info">
                          <div class="info-item">
                              <span class="label">Instance:</span> $(ec2-metadata --instance-id | cut -d " " -f 2)
                          </div>
                          <div class="info-item">
                              <span class="label">Zone:</span> $(ec2-metadata --availability-zone | cut -d " " -f 2)
                          </div>
                          <div class="info-item">
                              <span class="label">Type:</span> ${var.instance_type}
                          </div>
                      </div>
                      <div>
                          <span class="badge">✅ Terraform</span>
                          <span class="badge">✅ GitHub Actions</span>
                          <span class="badge">✅ AWS EC2</span>
                      </div>
                  </div>
              </body>
              </html>
              HTML
              
              # Permissions
              chmod 644 /var/www/html/index.html
              EOF

  tags = {
    Name        = "${var.project_name}-web-server"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = var.project_name
    DeployedBy  = "GitHub-Actions"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Récupérer les informations du compte
data "aws_caller_identity" "current" {}