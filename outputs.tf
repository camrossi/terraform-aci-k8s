output "frontend_service" {
  value = data.kubernetes_service.guestbook.id
  description = "The public IP address of the Service"
}