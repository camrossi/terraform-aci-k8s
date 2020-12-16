terraform {
 required_providers {
   aci = {
     source = "CiscoDevNet/aci"
     version = "0.5.2"
   }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "1.13.3"
    }
 }
}

provider "aci" {
  # cisco-aci user name
  username = "admin"
  # cisco-aci password
  password = "123Cisco123"
  # cisco-aci url
  url      = "http://fab2-apic1.cam.ciscolabs.com/"
  insecure = true
}

resource "aci_tenant" "test-tenant" {
  name        = "test-tenant"
  description = "This tenant is created by terraform"
}

# Same parameters as kubernetes provider
provider "kubernetes" {
  config_path = "./"
}

resource "kubernetes_namespace" "example" {
  metadata {
    name = "my-first-namespace"
  }
}