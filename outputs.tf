output "frontend_service" {
  value = data.kubernetes_service.guestbook.frontend_service.load_balancer_ingress.ip
  description = "The public IP address of the Service"
}