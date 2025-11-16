resource "helm_release" "vault" {
  name      = "vault"
  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault"
  namespace  = "vault"
  create_namespace = true
  
  set {
    name  = "injector.enabled"
    value = "true"
  }
  
  set {
    name  = "global.tlsDisable"
    value = "true"
  }
  
  set {
    name  = "server.dataStorage.enabled"
    value = "true"
  }
  
  # StorageClass configuration
  set {
    name  = "server.dataStorage.storageClass"
    value = "gp2"
  }
  
  set {
    name  = "server.auditStorage.enabled"
    value = "true"
  }
  
  set {
    name  = "server.auditStorage.storageClass"
    value = "gp2"
  }
  
  # Vault server configuration
  set {
    name  = "server.standalone.enabled"
    value = "true"
  }
  
  set {
    name  = "server.standalone.config"
    value = <<-EOT
      ui = true
      
      listener "tcp" {
        address = "[::]:8200"
        cluster_address = "[::]:8201"
        tls_disable = 1
      }
      
      storage "raft" {
        path = "/vault/data"
      }
      
      api_addr = "http://vault.vault.svc.cluster.local:8200"
      cluster_addr = "http://vault.vault.svc.cluster.local:8201"
      
      disable_mlock = true
    EOT
  }
  
  # הגדרות סינכרון:
  # המתנה להשלמת הפריסה (כולל ה-Service וכו') לפני סיום הפקודה
  wait    = true
  # זמן קצוב מקסימלי (בדקות) לאתחול (Vault לוקח זמן לעלות)
  timeout = 900 
}