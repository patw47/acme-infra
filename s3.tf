# ── CLEAN BASELINE ──────────────────────────────────────────────────────────

# CLEAN: private, encrypted bucket — inline encryption + public-access block
resource "aws_s3_bucket" "acme_private_bucket" {
  bucket = "acme-private-data-${var.environment}"
  tags   = local.tags
}

resource "aws_s3_bucket_server_side_encryption_configuration" "acme_private_bucket_enc" {
  bucket = aws_s3_bucket.acme_private_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "acme_private_bucket_pab" {
  bucket                  = aws_s3_bucket.acme_private_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ── TRUE RED FLAGS ───────────────────────────────────────────────────────────

# RED FLAG: public-read ACL
resource "aws_s3_bucket" "acme_public_bucket" {
  bucket = "acme-public-assets-${var.environment}"
  # acl is set via aws_s3_bucket_acl below
  tags = local.tags
}

resource "aws_s3_bucket_acl" "acme_public_bucket_acl" {
  bucket = aws_s3_bucket.acme_public_bucket.id
  acl    = "public-read"
}

# RED FLAG: no server-side encryption configured anywhere for this bucket
resource "aws_s3_bucket" "acme_unencrypted_bucket" {
  bucket = "acme-unencrypted-logs-${var.environment}"
  tags   = local.tags
  # acl    = "public-read"   ← commented out; not active (false-positive trap for regex)
}

# ── FALSE-POSITIVE TRAPS ─────────────────────────────────────────────────────

# TRAP 1: Encryption and public-access-block live in SEPARATE sibling resources.
# A scanner reading only the bucket block sees no inline encryption and may flag it.
# Correct scanners must follow the aws_s3_bucket_* resource references.
resource "aws_s3_bucket" "acme_trap_separate_enc" {
  bucket = "acme-trap-separate-enc-${var.environment}"
  tags   = local.tags
}

resource "aws_s3_bucket_server_side_encryption_configuration" "acme_trap_enc" {
  bucket = aws_s3_bucket.acme_trap_separate_enc.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
      kms_master_key_id = "arn:aws:kms:us-east-1:111122223333:key/mrk-EXAMPLE00000000000000000000000"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "acme_trap_pab" {
  bucket                  = aws_s3_bucket.acme_trap_separate_enc.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# TRAP 2: Principal="*" with aws:SourceVpce condition — safe, not a wildcard grant.
# Naive scanners panic at Principal=*; correct scanners read the Condition block.
resource "aws_s3_bucket_policy" "acme_vpce_policy" {
  bucket = aws_s3_bucket.acme_private_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowVpcEndpointOnly"
        Effect    = "Allow"
        Principal = "*"
        Action    = ["s3:GetObject", "s3:PutObject"]
        Resource  = "${aws_s3_bucket.acme_private_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "aws:SourceVpce" = "vpce-0a1b2c3d4e5f00000"
          }
        }
      }
    ]
  })
}
