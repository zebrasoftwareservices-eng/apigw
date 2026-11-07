# Oracle Cloud provisioning

The Terraform configuration creates an Ubuntu 24.04 ARM VM, VCN, public subnet,
internet gateway, route table, and firewall rules for SSH, HTTP, and HTTPS. It
does not open Kong's ports 8000 or 8001.

## 1. Configure Oracle API access

In the Oracle Cloud Console, open your user profile, then **API keys**, and add
an API key. Download or copy the generated configuration into `~/.oci/config`
and store the private key at the path referenced by that configuration.

The local machine needs Terraform. The OCI CLI is helpful but not required by
Terraform.

## 2. Select the home region

Always Free compute must be created in the tenancy's home region. Oracle may
report `Out of host capacity` for A1 shapes. Retrying later or selecting another
availability domain is sometimes necessary; Terraform currently selects the
first availability domain.

## 3. Create the VM

```bash
cd infra/terraform
cp terraform.tfvars.example terraform.tfvars
# Edit the OCIDs, region, SSH public key path, and SSH allowlist CIDR.
terraform init
terraform plan -out apigw.tfplan
terraform apply apigw.tfplan
terraform output -raw public_ip
```

Check the Oracle cost estimator before applying. The defaults target the
Always Free A1 allowance, but eligibility and limits belong to the Oracle
account and may change.

## 4. Bootstrap Ubuntu

```bash
ssh ubuntu@ORACLE_PUBLIC_IP
```

From the local repository:

```bash
scp scripts/bootstrap-ubuntu.sh ubuntu@ORACLE_PUBLIC_IP:/tmp/
ssh -t ubuntu@ORACLE_PUBLIC_IP 'sudo /tmp/bootstrap-ubuntu.sh'
```

Log out and back in after bootstrap so the `ubuntu` user receives its Docker
group membership.

## 5. Configure DNS and deploy

Create two DNS A records pointing to the Terraform `public_ip` output:

- `gateway.example.com` for proxied API traffic
- `admin.gateway.example.com` for the token-protected Admin API

Generate `.env` locally, then copy and deploy the project:

```bash
./scripts/generate-env.sh \
  gateway.example.com \
  admin.gateway.example.com \
  admin@example.com
./scripts/deploy-remote.sh ubuntu@ORACLE_PUBLIC_IP
```

Caddy obtains TLS certificates automatically after DNS has propagated.

## Destroying the infrastructure

Back up Kong first. Then run `terraform destroy` from `infra/terraform`.
This permanently deletes the VM and its boot volume.
