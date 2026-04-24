data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }
}

locals {
  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh.tftpl", {
    compose_project_name = var.compute.compose_project_name
    dockerhub_username   = var.compute.dockerhub_username
    image_tag            = var.compute.image_tag
    app_port             = var.security.app_port
    app_env              = var.compute.backend_env.app_env
    app_debug            = var.compute.backend_env.app_debug
    db_host              = var.compute.backend_env.db_host
    db_port              = var.compute.backend_env.db_port
    db_database          = var.compute.backend_env.db_database
    db_username          = var.compute.backend_env.db_username
    db_password          = var.compute.backend_env.db_password
  }))
}

resource "aws_security_group" "alb" {
  name        = "${var.network.name_prefix}-alb-sg"
  description = "Allow HTTP/HTTPS to the application load balancer"
  vpc_id      = var.network.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.security.alb_ingress_cidrs
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.security.alb_ingress_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.network.name_prefix}-alb-sg"
  })
}

resource "aws_security_group" "app" {
  name        = "${var.network.name_prefix}-app-sg"
  description = "Allow application traffic from the ALB"
  vpc_id      = var.network.vpc_id

  ingress {
    from_port       = var.security.app_port
    to_port         = var.security.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  dynamic "ingress" {
    for_each = length(var.security.ssh_ingress_cidrs) == 0 ? [] : [1]

    content {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = var.security.ssh_ingress_cidrs
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.network.name_prefix}-app-sg"
  })
}

resource "aws_lb" "this" {
  name               = "${var.network.name_prefix}-alb"
  internal           = var.load_balancer.internal
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.network.public_subnet_ids

  tags = merge(var.tags, {
    Name = "${var.network.name_prefix}-alb"
  })
}

resource "aws_lb_target_group" "app" {
  name        = "${var.network.name_prefix}-tg"
  port        = var.load_balancer.target_port
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = var.network.vpc_id

  health_check {
    enabled             = true
    path                = var.load_balancer.health_check_path
    protocol            = "HTTP"
    matcher             = "200-399"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
  }

  tags = merge(var.tags, {
    Name = "${var.network.name_prefix}-tg"
  })
}

resource "aws_lb_listener" "http_forward" {
  count = var.load_balancer.certificate_arn == null ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "aws_lb_listener" "http_redirect" {
  count = var.load_balancer.certificate_arn == null ? 0 : 1

  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
      host        = "#{host}"
      path        = "/#{path}"
      query       = "#{query}"
    }
  }
}

resource "aws_lb_listener" "https" {
  count = var.load_balancer.certificate_arn == null ? 0 : 1

  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.load_balancer.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "app" {
  name               = "${var.network.name_prefix}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.app.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "app" {
  name = "${var.network.name_prefix}-instance-profile"
  role = aws_iam_role.app.name
}

resource "aws_launch_template" "app" {
  name_prefix   = "${var.network.name_prefix}-lt-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.compute.instance_type
  key_name      = var.compute.key_name
  user_data     = local.user_data

  iam_instance_profile {
    name = aws_iam_instance_profile.app.name
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.compute.root_volume_size
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = true
    }
  }

  network_interfaces {
    associate_public_ip_address = var.compute.associate_public_ip_address
    security_groups             = [aws_security_group.app.id]
    delete_on_termination       = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge(var.tags, {
      Name = "${var.network.name_prefix}-app"
    })
  }

  tags = var.tags
}

resource "aws_autoscaling_group" "app" {
  name                = "${var.network.name_prefix}-asg"
  desired_capacity    = var.compute.desired_capacity
  min_size            = var.compute.min_size
  max_size            = var.compute.max_size
  vpc_zone_identifier = var.network.private_subnet_ids
  target_group_arns   = [aws_lb_target_group.app.arn]
  health_check_type   = "ELB"

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.network.name_prefix}-app"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.tags

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}
