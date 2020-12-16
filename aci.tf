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

resource "aci_epg_to_domain" "epg_to_vmm" {

  application_epg_dn    = aci_application_epg.demoepg.id
  tdn                   = "uni/vmmp-Kubernetes/dom-KubeSpray"
}

resource "kubernetes_namespace" "ns" {
  metadata {
    name = var.epg
    annotations = {
      "opflex.cisco.com/endpoint-group" = "{\"tenant\":\"${var.tenant}\",\"app-profile\":\"${var.application}\",\"name\":\"${var.epg}\"}"
    }
  }
}

data "kubectl_file_documents" "manifests" {
    content = file("guestbook.yaml")
}

resource "kubectl_manifest" "my_app" {
    override_namespace = var.epg
    count     = length(data.kubectl_file_documents.manifests.documents)
    yaml_body = element(data.kubectl_file_documents.manifests.documents, count.index)
}