# Project 7: Secrets Management & Credential Hygiene Governance

**GRC Domain:** Credential Hygiene, Cryptographic Key Governance, Access Controls  
**Role Simulated:** Security Engineer / GRC Technical Specialist  
**Framework/Regulation:** PCI-DSS v4.0 Requirement 3.6 / 8.6, SOC 2 CC6.1  
**Project Type:** Fictional Portfolio Case Study  

> **Scenario Context:** Apex Cloud Financial Systems (ApexPay) – Automated Secret Rotation Governance  

## Project Deliverables Index
- 🏗️ **Secrets Manager Terraform Code:** [`terraform/secrets_manager.tf`](./terraform/secrets_manager.tf)
- 📋 **Secrets Governance & Key Standard:** [`docs/secrets_governance_policy.md`](./docs/secrets_governance_policy.md)
- 🔎 **Simulated Rotation Event Log:** [`evidence/SIMULATED_SECRET_ROTATION_EVENT.json`](./evidence/SIMULATED_SECRET_ROTATION_EVENT.json)

---

## Overview

Instead of hardcoding credentials or using environment variables everywhere, this project designs a setup where secrets are centrally managed, rotated, and accessed with least privilege. What makes this stand out is explicitly showing what NOT to do and then fixing it—mirroring how real remediation work happens in production.


## The Problem: How Secrets Go Wrong

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                    COMMON SECRET ANTI-PATTERNS                                  │
└─────────────────────────────────────────────────────────────────────────────────┘

    ✗ ANTI-PATTERN 1: Hardcoded in Source Code
    ════════════════════════════════════════════

    # config.py - NEVER DO THIS
    ┌─────────────────────────────────────────────────────────────────┐
    │  DATABASE_PASSWORD = "SuperSecret123!"                         │
    │  API_KEY = "sk-live-abc123def456"                              │
    │  AWS_SECRET_KEY = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"   │
    └─────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
    RISKS:
    • Committed to git history (forever)
    • Visible to anyone with repo access
    • No rotation capability
    • No audit trail


    ✗ ANTI-PATTERN 2: Environment Variables Everywhere
    ═══════════════════════════════════════════════════

    # .env file checked into repo or shared via Slack
    ┌─────────────────────────────────────────────────────────────────┐
    │  export DB_PASSWORD="AnotherSecret456"                         │
    │  export STRIPE_KEY="sk_live_..."                               │
    └─────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
    RISKS:
    • Often shared insecurely
    • Visible in process listings
    • No centralized control
    • Inconsistent across environments


    ✗ ANTI-PATTERN 3: Shared Credentials
    ═════════════════════════════════════

    ┌───────────┐     ┌───────────┐     ┌───────────┐
    │  Dev 1    │     │  Dev 2    │     │  Dev 3    │
    └─────┬─────┘     └─────┬─────┘     └─────┬─────┘
          │                 │                 │
          └────────────────┬┴─────────────────┘
                           │
                           ▼
                   ┌───────────────┐
                   │ Same password │
                   │ for everyone  │
                   └───────────────┘
                           │
                           ▼
    RISKS:
    • No accountability (who did what?)
    • Can't revoke one person's access
    • Rotation requires coordinating everyone
```

## The Solution: Proper Secrets Management

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                    SECRETS MANAGEMENT ARCHITECTURE                              │
└─────────────────────────────────────────────────────────────────────────────────┘

                         ┌─────────────────────────────────┐
                         │       SECRETS MANAGER           │
                         │   (AWS Secrets Manager / Vault) │
                         │                                 │
                         │  ┌───────────────────────────┐  │
                         │  │  Secret: db/production    │  │
                         │  │  ├── username: app_user   │  │
                         │  │  ├── password: ********   │  │
                         │  │  └── rotation: 30 days    │  │
                         │  └───────────────────────────┘  │
                         │                                 │
                         │  ┌───────────────────────────┐  │
                         │  │  Secret: api/stripe       │  │
                         │  │  ├── key: sk_live_****    │  │
                         │  │  └── rotation: 90 days    │  │
                         │  └───────────────────────────┘  │
                         └──────────────┬──────────────────┘
                                        │
                    ┌───────────────────┼───────────────────┐
                    │                   │                   │
                    ▼                   ▼                   ▼
            ┌───────────────┐   ┌───────────────┐   ┌───────────────┐
            │  Application  │   │     Lambda    │   │    CI/CD      │
            │   (EC2/ECS)   │   │   Function    │   │   Pipeline    │
            │               │   │               │   │               │
            │  IAM Role:    │   │  IAM Role:    │   │  IAM Role:    │
            │  app-prod     │   │  lambda-exec  │   │  deploy-role  │
            │               │   │               │   │               │
            │  Permissions: │   │  Permissions: │   │  Permissions: │
            │  db/prod ONLY │   │  api/* ONLY   │   │  READ ONLY    │
            └───────────────┘   └───────────────┘   └───────────────┘
```

## Access Flow

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                    HOW APPLICATIONS GET SECRETS                                 │
└─────────────────────────────────────────────────────────────────────────────────┘

    ┌─────────────────┐
    │   Application   │
    │   starts up     │
    └────────┬────────┘
             │
             ▼
    ┌─────────────────────────────────────────────────────────────────────────┐
    │  1. Application assumes IAM role (via instance profile, ECS task role)  │
    └────────┬────────────────────────────────────────────────────────────────┘
             │
             ▼
    ┌─────────────────────────────────────────────────────────────────────────┐
    │  2. Application calls: GetSecretValue("db/production")                  │
    └────────┬────────────────────────────────────────────────────────────────┘
             │
             ▼
    ┌─────────────────────────────────────────────────────────────────────────┐
    │  3. Secrets Manager checks IAM policy:                                  │
    │     • Is caller authorized for this secret? ✓                           │
    │     • Is caller from allowed network? ✓                                 │
    │     • Log access to CloudTrail                                          │
    └────────┬────────────────────────────────────────────────────────────────┘
             │
             ▼
    ┌─────────────────────────────────────────────────────────────────────────┐
    │  4. Secret value returned (decrypted with KMS)                          │
    │     Application caches for configured TTL                               │
    └────────┬────────────────────────────────────────────────────────────────┘
             │
             ▼
    ┌─────────────────────────────────────────────────────────────────────────┐
    │  5. Application connects to database using retrieved credentials        │
    └─────────────────────────────────────────────────────────────────────────┘


    ═══════════════════════════════════════════════════════════════════════════
    KEY BENEFITS:
    • No secrets in code or environment
    • Least privilege access (only secrets you need)
    • Full audit trail (who accessed what, when)
    • Automatic rotation possible
    ═══════════════════════════════════════════════════════════════════════════
```

## Automatic Rotation

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                    AUTOMATIC SECRET ROTATION                                    │
└─────────────────────────────────────────────────────────────────────────────────┘

                    ROTATION PROCESS (RDS Example)
                    ══════════════════════════════

    Day 0 (Before Rotation)              Day 30 (Rotation Triggered)
    ═══════════════════════              ══════════════════════════

    ┌─────────────────┐                  ┌─────────────────┐
    │ Secrets Manager │                  │ Secrets Manager │
    │                 │                  │                 │
    │ Current:        │       ──────▶    │ Current:        │
    │ Password: abc   │                  │ Password: xyz   │
    │ Version: v1     │                  │ Version: v2     │
    │                 │                  │                 │
    │ Previous:       │                  │ Previous:       │
    │ (none)          │                  │ Password: abc   │
    └────────┬────────┘                  │ Version: v1     │
             │                           └────────┬────────┘
             │                                    │
             ▼                                    ▼
    ┌─────────────────┐                  ┌─────────────────┐
    │      RDS        │                  │      RDS        │
    │                 │                  │                 │
    │ Password: abc   │                  │ Password: xyz   │
    │                 │                  │ (Old still      │
    └─────────────────┘                  │  works briefly) │
                                         └─────────────────┘

    ROTATION LAMBDA STEPS:
    ═══════════════════════
    1. createSecret    - Generate new password, store as PENDING
    2. setSecret       - Update RDS with new password
    3. testSecret      - Verify new password works
    4. finishSecret    - Mark new password as CURRENT
```

## Blast Radius Reduction

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                    WHAT HAPPENS WHEN A SECRET LEAKS?                            │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  WITHOUT PROPER MANAGEMENT:            WITH PROPER MANAGEMENT:                  │
│  ══════════════════════════            ═══════════════════════                  │
│                                                                                 │
│  Secret leaked → Attacker has:         Secret leaked → Attacker has:            │
│                                                                                 │
│  ┌────────────────────────────┐        ┌────────────────────────────┐          │
│  │ • Production database      │        │ • One specific secret      │          │
│  │ • All API keys             │        │ • That may already be      │          │
│  │ • AWS credentials          │        │   rotated                  │          │
│  │ • Everything forever       │        │ • With audit trail         │          │
│  │   (no rotation)            │        │   showing access           │          │
│  └────────────────────────────┘        └────────────────────────────┘          │
│                                                                                 │
│  Response time:                        Response time:                           │
│  Hours to days                         Minutes                                  │
│  (find and replace everywhere)         (rotate affected secret)                 │
│                                                                                 │
│  Impact:                               Impact:                                  │
│  CATASTROPHIC                          CONTAINED                                │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## Before and After Comparison

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                    REMEDIATION: BEFORE AND AFTER                                │
└─────────────────────────────────────────────────────────────────────────────────┘

BEFORE (Insecure):
══════════════════

    # app.py
    ┌─────────────────────────────────────────────────────────────────────────┐
    │  import os                                                              │
    │  import psycopg2                                                        │
    │                                                                         │
    │  # BAD: Hardcoded credentials                                           │
    │  DB_HOST = "prod-db.example.com"                                        │
    │  DB_USER = "admin"                                                      │
    │  DB_PASS = "SuperSecretPassword123!"                                    │
    │                                                                         │
    │  conn = psycopg2.connect(                                               │
    │      host=DB_HOST,                                                      │
    │      user=DB_USER,                                                      │
    │      password=DB_PASS                                                   │
    │  )                                                                      │
    └─────────────────────────────────────────────────────────────────────────┘


AFTER (Secure):
═══════════════

    # app.py
    ┌─────────────────────────────────────────────────────────────────────────┐
    │  import boto3                                                           │
    │  import json                                                            │
    │  import psycopg2                                                        │
    │                                                                         │
    │  def get_db_credentials():                                              │
    │      """Retrieve database credentials from Secrets Manager."""          │
    │      client = boto3.client('secretsmanager')                            │
    │      response = client.get_secret_value(                                │
    │          SecretId='prod/database/credentials'                           │
    │      )                                                                  │
    │      return json.loads(response['SecretString'])                        │
    │                                                                         │
    │  creds = get_db_credentials()                                           │
    │  conn = psycopg2.connect(                                               │
    │      host=creds['host'],                                                │
    │      user=creds['username'],                                            │
    │      password=creds['password']                                         │
    │  )                                                                      │
    └─────────────────────────────────────────────────────────────────────────┘

    # IAM Policy for application role
    ┌─────────────────────────────────────────────────────────────────────────┐
    │  {                                                                      │
    │    "Effect": "Allow",                                                   │
    │    "Action": "secretsmanager:GetSecretValue",                           │
    │    "Resource": "arn:aws:secretsmanager:*:*:secret:prod/database/*"     │
    │  }                                                                      │
    └─────────────────────────────────────────────────────────────────────────┘
```

## Project Structure

```
07-secrets-management/
├── README.md
├── examples/
│   ├── insecure/                      # What NOT to do
│   │   ├── hardcoded-creds.py
│   │   ├── env-file-shared.py
│   │   └── README.md                  # Why these are bad
│   └── secure/                        # Proper implementation
│       ├── secrets-manager-client.py
│       ├── rotation-lambda.py
│       └── README.md                  # Why these are good
├── terraform/
│   ├── main.tf
│   ├── secrets.tf                     # Secret definitions
│   ├── rotation.tf                    # Rotation Lambda
│   ├── iam.tf                         # Access policies
│   └── kms.tf                         # Encryption key
└── docs/
    ├── migration-guide.md             # How to migrate from insecure
    ├── rotation-setup.md              # Setting up auto-rotation
    └── incident-response.md           # What to do if secret leaks
```

## Least Privilege for Secrets

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                    LEAST PRIVILEGE ACCESS PATTERNS                              │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  APPLICATION                    SECRETS ACCESS                                  │
│  ═══════════                    ═══════════════                                 │
│                                                                                 │
│  ┌────────────────────┐         ┌────────────────────────────────────────┐     │
│  │ Web App (prod)     │────────▶│ prod/database/app-user        (read)  │     │
│  └────────────────────┘         │ prod/api/stripe               (read)  │     │
│                                 └────────────────────────────────────────┘     │
│                                                                                 │
│  ┌────────────────────┐         ┌────────────────────────────────────────┐     │
│  │ Admin Lambda       │────────▶│ prod/database/admin-user      (read)  │     │
│  └────────────────────┘         └────────────────────────────────────────┘     │
│                                                                                 │
│  ┌────────────────────┐         ┌────────────────────────────────────────┐     │
│  │ CI/CD Pipeline     │────────▶│ prod/*                        (read)  │     │
│  │ (deploy phase)     │         │ (deployment secrets only)             │     │
│  └────────────────────┘         └────────────────────────────────────────┘     │
│                                                                                 │
│  ┌────────────────────┐         ┌────────────────────────────────────────┐     │
│  │ Dev Environment    │────────▶│ dev/*                         (read)  │     │
│  │                    │         │ prod/* DENIED                         │     │
│  └────────────────────┘         └────────────────────────────────────────┘     │
│                                                                                 │
│  ═══════════════════════════════════════════════════════════════════════════   │
│  │  PRINCIPLE: Each workload only accesses the secrets it needs.           │   │
│  │  No shared secrets. No broad access. No production secrets in dev.      │   │
│  ═══════════════════════════════════════════════════════════════════════════   │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## Deliverables Checklist

- [ ] Examples of insecure patterns (documented)
- [ ] Secure implementation using Secrets Manager
- [ ] IAM policies with least privilege
- [ ] KMS key for secret encryption
- [ ] Automatic rotation Lambda
- [ ] Migration guide from hardcoded to managed
- [ ] Incident response playbook for leaked secrets
- [ ] CI/CD integration for secret access

## Questions to Answer in Your Documentation

1. **What insecure patterns are you fixing?**
2. **How are secrets accessed at runtime?**
3. **What happens when a secret leaks?**
4. **How does rotation reduce blast radius?**
5. **How is access audited?**
6. **How would you handle secrets in CI/CD?**

## Further Reading

- [AWS Secrets Manager Best Practices](https://docs.aws.amazon.com/secretsmanager/latest/userguide/best-practices.html)
- [HashiCorp Vault](https://www.vaultproject.io/)
- [OWASP Secrets Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)

---

**Remember:** Security teams spend a huge amount of time cleaning up poor secrets practices. Demonstrating what not to do and then improving it mirrors how real remediation work happens in production. Showing you understand this pain point is powerful.
