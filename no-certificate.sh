export BSL_NAME=test
export VELERO_BUCKET=test-bucket
export OBJECT_FQDN=10.161.64.53
export AWS_PROFILE_VELERO=test-bucket

export WORKSPACE_NAMESPACE=kommander
kubectl -n "${WORKSPACE_NAMESPACE}" apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: velero-config-overrides
  namespace: ${WORKSPACE_NAMESPACE}
data:
  values.yaml: |
    credentials:
      extraSecretRef: ""
    configuration:
      features: EnableCSI
      backupStorageLocation:
        - name: ${BSL_NAME}
          bucket: ${VELERO_BUCKET}
          provider: "aws"
          default: true
          config:
            region: us-east-1
            s3ForcePathStyle: "true"
            insecureSkipTLSVerify: "true"
            s3Url: "https://${OBJECT_FQDN}"
            profile: ${AWS_PROFILE_VELERO}
          credential:
            key: aws
            name: dkp-velero
      deployNodeAgent: true
      nodeAgent:
        podVolumePath: /var/lib/kubelet/pods
        tolerations:
          - operator: Exists
EOF
