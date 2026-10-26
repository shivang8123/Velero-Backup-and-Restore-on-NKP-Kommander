# Velero Backup and Restore on NKP/Kommander

A sanitized operational runbook for configuring Velero with an S3-compatible object-storage backend and creating Kubernetes management-cluster backups.

> This repository intentionally contains examples and placeholders only. Never commit real credentials, kubeconfig files, customer IP addresses, presigned URLs, or support bundles.

## Repository structure

```text
.
├── README.md
├── .gitignore
└── examples/
    ├── velero-secret.example.yaml
    └── velero-config-overrides.example.yaml
```

## Workflow

1. Select the correct management-cluster kubeconfig.
2. Confirm that Velero is deployed.
3. Create the object-storage credentials Secret.
4. Create the Velero override ConfigMap.
5. Patch the Velero AppDeployment to reference the ConfigMap.
6. Wait for Helm/Flux reconciliation.
7. Confirm the BackupStorageLocation is `Available`.
8. Install a compatible Velero CLI on the administration host.
9. Create and validate a test backup.
10. Create and validate the management-cluster backup.

## Why the override ConfigMap is used

The override ConfigMap stores the Helm values consumed by the Kommander Velero AppDeployment. It provides a declarative and repeatable configuration for the BackupStorageLocation, S3 endpoint, credentials reference, CSI integration, and node agent.

Do not permanently edit a Helm-managed BackupStorageLocation directly. Update the override ConfigMap and allow the application controller to reconcile the change.

## Why the Velero CLI is used

The Velero server runs inside Kubernetes. The CLI is installed on an administration host and communicates with the Velero API through kubeconfig. It is used to create backups, inspect status, read logs, and create restores.

The CLI version should be compatible with the Velero server version and should be consistent between source and DR clusters.

## Example configuration

Copy the example files and replace the placeholders locally:

```bash
cp examples/velero-secret.example.yaml velero-secret.yaml
cp examples/velero-config-overrides.example.yaml velero-config-overrides.yaml
```

Apply the Secret:

```bash
kubectl apply -f velero-secret.yaml
```

Apply the ConfigMap:

```bash
kubectl apply -f velero-config-overrides.yaml
```

Patch the Velero AppDeployment:

```bash
kubectl -n <WORKSPACE_NAMESPACE> patch appdeployment velero \
  --type=merge --patch-file=/dev/stdin <<EOF
spec:
  configOverrides:
    name: velero-config-overrides
EOF
```

## Validate the BackupStorageLocation

```bash
kubectl get backupstoragelocations -A
kubectl describe backupstoragelocation <BSL_NAME> -n <WORKSPACE_NAMESPACE>
```

The BSL should report `Available` before a backup is created.

## Install the Velero CLI

Download a CLI version compatible with the server:

```bash
VELERO_VERSION=<VELERO_VERSION>
wget https://github.com/velero-io/velero/releases/download/${VELERO_VERSION}/velero-${VELERO_VERSION}-linux-amd64.tar.gz
tar -xzf velero-${VELERO_VERSION}-linux-amd64.tar.gz
sudo cp velero-${VELERO_VERSION}-linux-amd64/velero /usr/local/bin/velero
velero version
```

## Create a test backup

```bash
export BACKUP_NAME=velero-test-$(date +%Y%m%d%H%M%S)

velero backup create "${BACKUP_NAME}" \
  --namespace <WORKSPACE_NAMESPACE> \
  --storage-location <BSL_NAME> \
  --snapshot-volumes=false \
  --wait

velero backup describe "${BACKUP_NAME}" \
  --namespace <WORKSPACE_NAMESPACE> \
  --details
```

If certificate verification is intentionally disabled, add the CLI option supported by the installed version:

```bash
--insecure-skip-tls-verify
```

This mode is intended for controlled lab or approved environments. Production deployments should use a certificate-validating FQDN and CA configuration.

## Create a management-cluster backup

```bash
export BACKUP_NAME=management-$(date +%Y%m%d%H%M%S)

velero backup create "${BACKUP_NAME}" \
  --namespace <WORKSPACE_NAMESPACE> \
  --storage-location <BSL_NAME> \
  --snapshot-volumes=false \
  --wait

velero backup get --namespace <WORKSPACE_NAMESPACE>
velero backup describe "${BACKUP_NAME}" \
  --namespace <WORKSPACE_NAMESPACE> \
  --details
velero backup logs "${BACKUP_NAME}" \
  --namespace <WORKSPACE_NAMESPACE>
```



