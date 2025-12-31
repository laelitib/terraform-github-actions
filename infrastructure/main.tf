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
  description = "Security group for web server"
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

# Instance EC2 - Configuration simplifiée pour AWS Sandbox
resource "aws_instance" "web_server" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type
  
  # Configuration réseau minimale
  subnet_id                   = tolist(data.aws_subnets.default.ids)[0]
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true

  # SUPPRIMÉ: root_block_device (non supporté en Sandbox)
  # SUPPRIMÉ: metadata_options (utilise les défauts)
  # SUPPRIMÉ: monitoring (utilise les défauts)

  user_data = <<-EOF
              #!/bin/bash
              set -e
              
              # Mise à jour du système
              dnf update -y
              
              # Installation Apache
              dnf install -y httpd
              
              # Démarrage Apache
              systemctl start httpd
              systemctl enable httpd
              
              # Récupérer les métadonnées de l'instance
              INSTANCE_ID=$(ec2-metadata --instance-id | cut -d " " -f 2)
              AZ=$(ec2-metadata --availability-zone | cut -d " " -f 2)
              PUBLIC_IP=$(ec2-metadata --public-ipv4 | cut -d " " -f 2)
              
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
                      .value {
                          color: #4a5568;
                          font-family: 'Courier New', monospace;
                      }
                      .badge {
                          display: inline-block;
                          background: #48bb78;
                          color: white;
                          padding: 8px 20px;
                          border-radius: 20px;
                          font-size: 0.9em;
                          margin: 10px 5px;
                          font-weight: bold;
                      }
                      .footer {
                          margin-top: 30px;
                          color: #718096;
                          font-size: 0.9em;
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
                              <span class="label">Instance ID:</span>
                              <span class="value">INSTANCE_ID_PLACEHOLDER</span>
                          </div>
                          <div class="info-item">
                              <span class="label">Availability Zone:</span>
                              <span class="value">AZ_PLACEHOLDER</span>
                          </div>
                          <div class="info-item">
                              <span class="label">Public IP:</span>
                              <span class="value">IP_PLACEHOLDER</span>
                          </div>
                          <div class="info-item">
                              <span class="label">Instance Type:</span>
                              <span class="value">${var.instance_type}</span>
                          </div>
                      </div>
                      <div>
                          <span class="badge">✅ Terraform</span>
                          <span class="badge">✅ GitHub Actions</span>
                          <span class="badge">✅ AWS EC2</span>
                      </div>
                      <div class="footer">
                          <p>Déployé automatiquement depuis GitHub</p>
                          <p>Projet: ${var.project_name}</p>
                      </div>
                  </div>
              </body>
              </html>
              HTML
              
              # Remplacer les placeholders par les vraies valeurs
              sed -i "s/INSTANCE_ID_PLACEHOLDER/$INSTANCE_ID/g" /var/www/html/index.html
              sed -i "s/AZ_PLACEHOLDER/$AZ/g" /var/www/html/index.html
              sed -i "s/IP_PLACEHOLDER/$PUBLIC_IP/g" /var/www/html/index.html
              
              # Permissions
              chmod 644 /var/www/html/index.html
              
              echo "✅ User data script completed successfully" >> /var/log/user-data.log
              EOF

  tags = {
    Name        = "${var.project_name}-web-server"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = var.project_name
    DeployedBy  = "GitHub-Actions"
  }
}

# Récupérer les informations du compte
data "aws_caller_identity" "current" {}