# Organization Standard: Secrets Management & Key Hygiene
**Document ID:** STD-SEC-KMS-03  
**Organization:** Apex Cloud Financial Systems (ApexPay)  
**Standard Mapping:** PCI-DSS v4.0 Requirement 3.6 / 8.6, SOC 2 CC6.1  

---

## Mandated Credential Hygiene Controls
1. **Zero Hardcoded Credentials:** Plaintext passwords, API keys, or private certificates in code repositories, Terraform files, or container environment variables are strictly forbidden.
2. **KMS CMK Encryption:** All secrets stored in AWS Secrets Manager or Systems Manager Parameter Store must be encrypted using Customer Managed Keys (CMKs) with annual key rotation.
3. **Mandatory Automated Rotation:** Production database passwords and API access tokens must undergo automated rotation every 30 to 90 days via AWS Lambda rotation handlers.
