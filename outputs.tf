output "frontend_service" {
  value = data.kubernetes_service.guestbook
  description = "The public IP address of the Service"
}