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
  
  # הגדרות סינכרון:
  # המתנה להשלמת הפריסה (כולל ה-Service וכו') לפני סיום הפקודה
  wait    = true
  # זמן קצוב מקסימלי (בדקות) לאתחול (Vault לוקח זמן לעלות)
  timeout = 900 
}