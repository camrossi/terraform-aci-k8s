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

resource "aci_tenant" "tenant" {
  name        = var.tenant
  description = "This tenant is created by terraform"
}

resource "aci_application_profile" "ap" {
  tenant_dn  = aci_tenant.tenant.id
  name       = var.application
}

resource "aci_application_epg" "demoepg" {
  application_profile_dn = aci_application_profile.ap.id
  name = var.epg
  flood_on_encap = "disabled"
  relation_fv_rs_bd = "uni/tn-KubeSpray/BD-aci-containers-KubeSpray-pod-bd"
  relation_fv_rs_prov = ["uni/tn-KubeSpray/brc-aci-containers-KubeSpray-health-check"]
  relation_fv_rs_cons = ["uni/tn-common/brc-KubeSpray-l3out-allow-all",
                        "uni/tn-KubeSpray/brc-aci-containers-KubeSpray-dns", 
                        "uni/tn-KubeSpray/brc-aci-containers-KubeSpray-icmp", 
                        "uni/tn-KubeSpray/brc-aci-containers-KubeSpray-istio"]
}

# Same parameters as kubernetes provider
provider "kubernetes" {
  config_path = "./"
}

resource "kubernetes_namespace" "ns" {
  metadata {
    name = var.epg
    annotations = {
      "opflex.cisco.com/endpoint-group" = "{\"tenant\":\"${var.tenant}\",\"app-profile\":\"${var.application}\",\"name\":\"${var.epg}\"}"
    }
  }
}