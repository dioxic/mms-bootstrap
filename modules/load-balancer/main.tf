#locals {
#  target_routes_with_id = [
#    for route in var.target_routes : merge(route, {
#      id = "${route.protocol}-${route.public_port}"
#    })
#  ]
#  target_route_map   = {for route in local.target_routes_with_id : route["id"] => route}
#  route_instance_map = {
#    for pair in setproduct(local.target_routes_with_id, var.instance_ids) : "${pair[0]["id"]}-${pair[1]}"
#    => merge(pair[0], {
#      instance_id = pair[1]
#    })
#  }
#}

resource "aws_lb_target_group" "main" {
  name     = "${var.name}-mms-${var.public_port}"
  port     = var.internal_port
  protocol = "TCP"
  vpc_id   = var.vpc_id

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 10
    protocol            = "TCP"
  }
}

resource "aws_lb_target_group_attachment" "main" {
  count            = length(var.instance_ids)
  target_group_arn = aws_lb_target_group.main.arn
  target_id        = var.instance_ids[count.index]
  port             = var.internal_port
}

resource "aws_lb_listener" "main" {
  load_balancer_arn = var.load_balancer_arn
  port              = var.public_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}