resource "aws_lb" "k8s_api" {
  name               = "gitops-lab-k8s-api"
  internal           = true
  load_balancer_type = "network"
  enable_cross_zone_load_balancing = true
  subnets            = [for s in aws_subnet.public : s.id]
}

resource "aws_lb_target_group" "k8s_api" {
  name     = "k8s-api-tg"
  port     = 6443
  protocol = "TCP"
  vpc_id   = aws_vpc.main.id
  health_check {
    protocol = "TCP"
    port     = 6443
  }
}

resource "aws_lb_target_group_attachment" "k8s_api" {
  for_each         = aws_instance.master
  target_group_arn = aws_lb_target_group.k8s_api.arn
  target_id        = each.value.id
  port             = 6443
}

resource "aws_lb_listener" "k8s_api" {
  load_balancer_arn = aws_lb.k8s_api.arn
  port              = 6443
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.k8s_api.arn
  }
}

output "k8s_api_lb_dns" {
  value = aws_lb.k8s_api.dns_name
}
