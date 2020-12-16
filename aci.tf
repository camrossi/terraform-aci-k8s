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
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.9.4"
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

provider "kubernetes" {
  config_path = "./kube_config"
}

# Same parameters as kubernetes provider
provider "kubectl" {
  config_path = "./kube_config"
}

resource "aci_application_profile" "ap" {
  tenant_dn  = "uni/tn-Kubernetes"
  name       = var.application
}

resource "aci_application_epg" "demoepg" {
  application_profile_dn = aci_application_profile.ap.id
  name = var.epg
  flood_on_encap = "disabled"
  relation_fv_rs_bd = "uni/tn-Kubernetes/BD-aci-containers-Kubernetes-pod-bd"
  relation_fv_rs_prov = ["uni/tn-Kubernetes/brc-aci-containers-Kubernetes-health-check"]
  relation_fv_rs_cons = ["uni/tn-common/brc-Kubernetes-l3out-allow-all",
                        "uni/tn-Kubernetes/brc-aci-containers-Kubernetes-dns", 
                        "uni/tn-Kubernetes/brc-aci-containers-Kubernetes-icmp", 
                        "uni/tn-Kubernetes/brc-aci-containers-Kubernetes-istio"]
}

resource "aci_epg_to_domain" "epg_to_vmm" {

  application_epg_dn    = aci_application_epg.demoepg.id
  tdn                   = "uni/vmmp-Kubernetes/dom-Kubernetes"
}

resource "kubernetes_namespace" "ns" {
  metadata {
    name = var.application
    annotations = {
      "opflex.cisco.com/endpoint-group" = "{\"tenant\":\"Kubernetes\",\"app-profile\":\"${var.application}\",\"name\":\"${var.epg}\"}"
    }
  }
}

data "kubectl_file_documents" "manifests" {
    content = file("guestbook.yaml")
}

resource "kubectl_manifest" "my_app" {
    override_namespace = var.application
    count     = length(data.kubectl_file_documents.manifests.documents)
    yaml_body = element(data.kubectl_file_documents.manifests.documents, count.index)
}