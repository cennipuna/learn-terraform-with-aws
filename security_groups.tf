# ── App Server Security Group ─────────────────────────────────────────────────
# Nginx, PHP-FPM, Redis, Reverb (WebSocket), Queue Worker, Vue frontend
resource "aws_security_group" "app" {
  name        = "restaurant-app-sg"
  description = "App server: Nginx, PHP-FPM, Redis, Reverb, Queue"
  vpc_id      = aws_vpc.restaurant.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Laravel Reverb WebSocket"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "restaurant-app-sg" }
}

# ── Database Server Security Group ────────────────────────────────────────────
# MySQL only reachable from the app server; SSH open for direct access
resource "aws_security_group" "db" {
  name        = "restaurant-db-sg"
  description = "MySQL server: port 3306 only from app server SG"
  vpc_id      = aws_vpc.restaurant.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description     = "MySQL from app server only"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "restaurant-db-sg" }
}
