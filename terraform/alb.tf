resource "aws_lb_target_group" "tg-vaction" {
name = "tg-vaction"
port = 80
protocol = "HTTP"
vpc_id = aws_vpc.vpc-vaction.id

health_check {
path = "/"
protocol = "HTTP"
matcher = "200"
interval = 30
timeout = 5
healthy_threshold = 3
unhealthy_threshold = 3
}

tags = {
Name = "tg-vaction"
}
}

resource "aws_lb" "alb-vaction" {
name = "alb-vaction"
internal = false
load_balancer_type = "application"
security_groups = [aws_security_group.sg-alb-vaction.id]

subnets = [
aws_subnet.public.id,
aws_subnet.public_b.id
]

enable_deletion_protection = false

tags = {
Name = "alb-vaction"
}
}

resource "aws_lb_listener" "alb-listener-http" {
load_balancer_arn = aws_lb.alb-vaction.arn
port = 80
protocol = "HTTP"

default_action {
type = "forward"
target_group_arn = aws_lb_target_group.tg-vaction.arn
}
}

resource "aws_lb_target_group_attachment" "tg-attach-app-public" {
target_group_arn = aws_lb_target_group.tg-vaction.arn
target_id = aws_instance.ec2-public-vaction.id
port = 80
}