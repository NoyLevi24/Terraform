variable "cluster_name" {
  type = string
}

variable "node_iam_role_name" {
  type = string
}

variable "environment" {
  type = string
}

# EC2NodeClass - מגדיר איך ליצור instances
resource "kubectl_manifest" "karpenter_node_class" {
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1beta1
    kind: EC2NodeClass
    metadata:
      name: default
    spec:
      amiFamily: AL2023
      role: ${var.node_iam_role_name}
      subnetSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${var.cluster_name}
      securityGroupSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${var.cluster_name}
      tags:
        Name: karpenter-node
        Environment: ${var.environment}
        ManagedBy: Karpenter
  YAML

  depends_on = [var.karpenter_dependency]
}

# NodePool - מגדיר מתי וכמה instances
resource "kubectl_manifest" "karpenter_node_pool" {
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1beta1
    kind: NodePool
    metadata:
      name: default
    spec:
      template:
        spec:
          nodeClassRef:
            name: default
          requirements:
            - key: karpenter.sh/capacity-type
              operator: In
              values: ["spot", "on-demand"]
            - key: node.kubernetes.io/instance-type
              operator: In
              values: ["t3.medium", "t3.large", "t3a.medium", "t3a.large"]
            - key: kubernetes.io/arch
              operator: In
              values: ["amd64"]
      limits:
        cpu: "1000"
        memory: 1000Gi
      disruption:
        consolidationPolicy: WhenUnderutilized
        expireAfter: 720h # 30 days
  YAML

  depends_on = [kubectl_manifest.karpenter_node_class]
}

variable "karpenter_dependency" {
  description = "Dependency on Karpenter module"
  type        = any
  default     = null
}