# acme-infra

> **SYNTHETIC TEST INFRASTRUCTURE — DO NOT APPLY**
>
> This repository contains **deliberately misconfigured** Terraform code.
> It exists solely as a scan target for security-scanner validation.
> **Never run `terraform apply` on this code.** It will create insecure AWS
> resources and may incur costs or expose your account.

---

## Purpose

`acme-infra` is a synthetic AWS infrastructure repository crafted to benchmark
security guardrail auditors. It is inspired by
[TerraGoat](https://github.com/bridgecrewio/terragoat) and follows the same
spirit: realistic-looking IaC that deliberately mixes flaws and correct patterns.

The goal is to measure **both** dimensions of scanner quality:

| Dimension | Question |
|-----------|----------|
| **Recall** | Does the scanner catch every real flaw? |
| **Precision** | Does it stay quiet on things that are actually fine? |

---

## Resource categories

### A — True Red Flags (8 findings expected) `HIGH` / `CRITICAL`

Real misconfigurations a scanner **must** detect:

| File | Resource | Rule |
|------|----------|------|
| `s3.tf` | `aws_s3_bucket_acl.acme_public_bucket_acl` | S3 public-read ACL |
| `s3.tf` | `aws_s3_bucket.acme_unencrypted_bucket` | No SSE configured |
| `network.tf` | `aws_security_group.acme_open_ssh_sg` | SSH 0.0.0.0/0 |
| `network.tf` | `aws_security_group.acme_open_rdp_sg` | RDP 0.0.0.0/0 |
| `rds.tf` | `aws_db_instance.acme_public_rds` | `publicly_accessible = true` |
| `rds.tf` | `aws_db_instance.acme_unencrypted_rds` | `storage_encrypted = false` |
| `iam.tf` | `aws_iam_policy.acme_wildcard_policy` | `Action="*" Resource="*"` |
| `compute.tf` | `aws_instance.acme_insecure_ec2` | Hardcoded credentials in `user_data` |

### B — Clean Baseline (5 resources) — must NOT be flagged

Correctly configured resources a scanner must not report:

- Private encrypted S3 bucket with `aws_s3_bucket_public_access_block`
- Security group: ports 80/443 open to internet (legitimate public LB)
- Security group: SSH restricted to `10.0.0.0/8` only
- RDS: `storage_encrypted = true`, `publicly_accessible = false`
- IAM policy: scoped to two specific actions on one S3 bucket ARN

### C — False-Positive Traps (4 traps) — must NOT be flagged

Configurations that look suspicious to a naive scanner but are actually safe:

| File | Resource | Trap |
|------|----------|------|
| `s3.tf` | `aws_s3_bucket.acme_trap_separate_enc` | Encryption in sibling `aws_s3_bucket_server_side_encryption_configuration` resource, not inline |
| `network.tf` | `aws_security_group.acme_var_ssh_sg` | SSH CIDR is `var.bastion_cidr` — unresolvable statically; must emit `WARNING`, not `HIGH` |
| `s3.tf` | `aws_s3_bucket_policy.acme_vpce_policy` | `Principal="*"` scoped by `aws:SourceVpce` condition |
| `s3.tf` | `aws_s3_bucket.acme_unencrypted_bucket` | Comment `# acl = "public-read"` — inactive HCL |

---

## Ground-truth oracle

`tests/ground_truth.json` is the machine-readable oracle:

```json
{
  "expected_findings":  [...],   // scanner must report all 8
  "must_not_flag":      [...],   // scanner must not report any of these
  "expected_warnings":  [...]    // scanner should report as WARNING severity only
}
```

Use it in your test suite to assert precision and recall simultaneously.

---

## File layout

```
acme-infra/
├── provider.tf       # AWS provider + S3 backend (anonymized)
├── variables.tf      # All input variables incl. bastion_cidr (trap)
├── locals.tf         # VPC CIDR, AZ list, common tags
├── network.tf        # VPC module + security groups (clean + red flags + trap)
├── compute.tf        # EC2 instances (clean bastion + insecure worker)
├── s3.tf             # S3 buckets (clean + red flags + traps)
├── rds.tf            # RDS instances (clean + red flags)
├── iam.tf            # IAM roles and policies (clean + wildcard red flag)
├── ecr.tf            # ECR repository
├── apprunner.tf      # App Runner service (structural shape from source)
├── env/
│   └── staging.tfvars
└── tests/
    └── ground_truth.json
```

---

## Credits

Structure inspired by real AWS IaC patterns; misconfiguration patterns inspired by
[TerraGoat](https://github.com/bridgecrewio/terragoat) (Bridgecrew / Prisma Cloud).
All identifiers, account IDs, and ARNs are synthetic placeholders.
