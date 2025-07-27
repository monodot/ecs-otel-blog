resource "random_password" "db" {
  override_special = "-_"
  length           = 16
}

resource "aws_db_instance" "db" {
  allocated_storage      = 20
  engine                 = "postgres"
  engine_version         = "14.18"
  identifier             = "holiday-database-${var.environment_id}"
  instance_class         = "db.t3.micro"
  db_name                = "holidaydb"
  username               = "holiday"
  password               = random_password.db.result
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.database_sg.id]
  publicly_accessible    = false

  tags = {
    Name = "holiday-database-${var.environment_id}"
  }
}

resource "aws_security_group" "database_sg" {
  vpc_id = data.aws_vpc.default.id
  name   = "holiday-database-sg-${var.environment_id}"

  tags = {
    Name = "holiday-database-sg-${var.environment_id}"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_fargate_to_rds" {
  security_group_id            = aws_security_group.database_sg.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.fargate_task_sg.id # Allow access from Fargate tasks
  description                  = "Allow inbound traffic on port 5432 from Fargate tasks"
}

resource "aws_vpc_security_group_egress_rule" "allow_all_outbound" {
  security_group_id = aws_security_group.database_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Allow all outbound traffic"
  ip_protocol       = "-1"
}
