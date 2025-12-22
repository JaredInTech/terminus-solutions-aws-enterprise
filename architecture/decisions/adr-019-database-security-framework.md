<!--
Terminus Solutions AWS Enterprise Architecture
Copyright (c) 2025 Jared (Terminus Solutions) - jaredintech.com
Licensed under CC BY-SA 4.0 - Attribution required
See LICENSE-DOCS for details
-->

# ADR-019: Database Security Framework

## Date
2025-12-22

## Status
Accepted

## Context
With our database platform and high availability architecture defined (ADR-017, ADR-018), Terminus Solutions needs to establish a comprehensive security framework for database access. This decision determines our approach to authentication, authorization, encryption, and audit logging to meet security and compliance requirements.

Key requirements and constraints:
- Must support multiple authentication methods (password and IAM)
- Require encryption at rest and in transit for all databases
- Need automated credential rotation without downtime
- Enable comprehensive audit logging for compliance
- Integrate with existing IAM architecture (ADR-001, ADR-009)
- Support principle of least privilege for database access
- Minimize credential exposure in application code
- Meet future SOC2 and HIPAA compliance requirements
- Budget conscious—avoid expensive add-on security services

Current security challenges:
- Password-based authentication creates credential management burden
- Static credentials in application configs are security risk
- Manual credential rotation causes downtime risk
- Insufficient audit trails for compliance
- Need defense-in-depth for database layer

## Decision
We will implement a defense-in-depth database security framework with multiple authentication methods, comprehensive encryption, automated credential management through AWS Secrets Manager, and integrated audit logging.

**Security Architecture:**
```
                    ┌─────────────────────────────────────────────────┐
                    │              Defense-in-Depth Layers            │
                    │                                                 │
│ Layer 1: Network │  ┌─────────────────────────────────────────┐    │
│                  │  │  Private Subnets (No Internet Access)   │    │
│                  │  │  Security Groups (App Tier → DB only)   │    │
│                  │  │  NACLs (Additional filtering)           │    │
│                  │  └─────────────────────────────────────────┘    │
                    │                     │                           │
│ Layer 2: Auth    │  ┌─────────────────────────────────────────┐    │
│                  │  │  IAM Database Authentication            │    │
│                  │  │  Password Auth (via Secrets Manager)    │    │
│                  │  │  SSL/TLS Required for Connections       │    │
│                  │  └─────────────────────────────────────────┘    │
                    │                     │                           │
│ Layer 3: Encrypt │  ┌─────────────────────────────────────────┐    │
│                  │  │  Encryption at Rest (KMS)               │    │
│                  │  │  Encryption in Transit (TLS 1.2+)       │    │
│                  │  │  Encrypted Backups and Snapshots        │    │
│                  │  └─────────────────────────────────────────┘    │
                    │                     │                           │
│ Layer 4: Audit   │  ┌─────────────────────────────────────────┐    │
│                  │  │  Database Activity Logging              │    │
│                  │  │  CloudWatch Logs Integration            │    │
│                  │  │  CloudTrail API Logging                 │    │
│                  │  └─────────────────────────────────────────┘    │
                    └─────────────────────────────────────────────────┘
```

**Authentication Strategy:**

| Method | Use Case | Credentials | Rotation | Complexity |
|--------|----------|-------------|----------|------------|
| IAM Authentication | Application servers | IAM role tokens | Automatic (15 min) | Medium |
| Secrets Manager | Administrative access | Stored secrets | Auto (30 days) | Low |
| Password Auth | Legacy/emergency | Secrets Manager | Auto (30 days) | Low |

**Encryption Standards:**
```yaml
Encryption at Rest:
  RDS MySQL: AWS managed KMS key
  Aurora: AWS managed KMS key
  DynamoDB: AWS owned key (default)
  ElastiCache: Customer managed key
  Backups: Inherit from source (encrypted)
  
Encryption in Transit:
  Protocol: TLS 1.2 minimum
  Cipher Suites: AWS recommended
  Certificate: AWS managed RDS CA
  Verification: Required (rds-ca-2019)
```

## Consequences

### Positive
- **Defense in Depth**: Multiple security layers protect data
- **Credential Elimination**: IAM auth removes stored credentials
- **Automatic Rotation**: Secrets Manager rotates without downtime
- **Audit Compliance**: Comprehensive logging meets SOC2/HIPAA
- **Encryption Everywhere**: Data protected at rest and in transit
- **Least Privilege**: Fine-grained IAM policies for database access
- **Operational Simplicity**: Managed services reduce security overhead

### Negative
- **Initial Complexity**: IAM authentication requires setup
- **Token Expiration**: IAM tokens expire every 15 minutes
- **Monitoring Overhead**: Multiple log streams to aggregate
- **Cost**: Secrets Manager charges per secret per month
- **Learning Curve**: Team needs IAM authentication expertise

### Mitigation Strategies
- **Connection Pooling**: Use RDS Proxy to manage IAM token refresh
- **Log Aggregation**: Centralize logs in CloudWatch Logs Insights
- **Documentation**: Clear runbooks for authentication methods
- **Cost Management**: Consolidate secrets where appropriate
- **Training**: Team education on IAM database authentication

## Alternatives Considered

### 1. Password Authentication Only
**Rejected because:**
- Credentials stored in application configs
- Manual rotation causes downtime risk
- No automatic expiration mechanism
- Harder to audit access patterns
- Single authentication method is less secure

### 2. Client Certificates (mTLS)
**Rejected because:**
- Certificate management complexity
- Not natively supported by RDS
- Difficult to rotate certificates
- Requires application changes
- IAM auth provides similar benefits

### 3. AWS Secrets Manager Only (No IAM Auth)
**Rejected because:**
- Still requires credential retrieval
- Secrets cached in application memory
- IAM auth is more secure for EC2
- Missing automatic token rotation
- Extra network call for each connection

### 4. Third-Party Secret Management (HashiCorp Vault)
**Rejected because:**
- Additional infrastructure to manage
- Higher operational complexity
- Cost of running Vault cluster
- Learning curve for team
- AWS native solution preferred

### 5. Database-Level Encryption Only
**Rejected because:**
- Doesn't protect credentials in transit
- No automated key rotation
- Missing audit logging integration
- Incomplete security posture
- Compliance gaps

## Implementation Details

### IAM Database Authentication
```yaml
IAM Authentication Setup:
  RDS Configuration:
    Parameter: rds.force_ssl = 1
    IAM Auth: Enabled
    
  IAM Policy (TerminusRDSIAMAuthPolicy):
    Effect: Allow
    Action: rds-db:connect
    Resource: arn:aws:rds-db:region:account:dbuser:resource-id/db_user
    
  Database User:
    CREATE USER 'app_user' IDENTIFIED WITH AWSAuthenticationPlugin AS 'RDS';
    GRANT SELECT, INSERT, UPDATE, DELETE ON terminus_app.* TO 'app_user';
```

### Token Generation
```bash
# Generate IAM authentication token
aws rds generate-db-auth-token \
    --hostname terminus-prod-mysql.xxx.us-east-1.rds.amazonaws.com \
    --port 3306 \
    --username app_user \
    --region us-east-1

# Token valid for 15 minutes
# Use as password in MySQL connection
```

### Secrets Manager Configuration
```yaml
Secret: terminus/rds/mysql/master
  Content:
    username: admin
    password: <auto-generated>
    host: terminus-prod-mysql.xxx.us-east-1.rds.amazonaws.com
    port: 3306
    dbname: terminus_app
    
  Rotation:
    Enabled: true
    Schedule: rate(30 days)
    Lambda: SecretsManagerRDSMySQLRotation
    
  Permissions:
    - Principal: EC2 Instance Role
      Actions: secretsmanager:GetSecretValue
```

### Security Group Configuration
```yaml
Database Security Group (terminus-rds-mysql-sg):
  Inbound Rules:
    - Protocol: TCP
      Port: 3306
      Source: Application Tier SG
      Description: MySQL from app tier
      
    - Protocol: TCP
      Port: 3306
      Source: Bastion SG (if applicable)
      Description: MySQL from bastion
      
  Outbound Rules:
    - Protocol: All
      Destination: None
      Description: No outbound (database only receives)
```

### Encryption Configuration
```yaml
RDS Encryption at Rest:
  KMS Key: aws/rds (AWS managed)
  Algorithm: AES-256
  Scope: Storage, snapshots, replicas, logs
  
SSL/TLS in Transit:
  Certificate: rds-ca-rsa2048-g1
  Minimum Version: TLS 1.2
  Cipher: TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
  
Connection String (SSL Required):
  mysql --ssl-mode=REQUIRED \
        --ssl-ca=/path/to/rds-ca-2019-root.pem \
        -h endpoint -u user -p
```

### Audit Logging Configuration
```yaml
RDS Audit Logging:
  Error Log: Enabled → CloudWatch Logs
  Slow Query Log: Enabled → CloudWatch Logs
  General Log: Disabled (performance)
  Audit Log: MariaDB Audit Plugin (optional)
  
CloudWatch Log Groups:
  - /aws/rds/instance/terminus-prod-mysql/error
  - /aws/rds/instance/terminus-prod-mysql/slowquery
  
Retention: 30 days (configurable)

DynamoDB Audit:
  CloudTrail: Data events enabled
  Log Group: /aws/cloudtrail/dynamodb-data-events
```

### Access Control Matrix
```
┌─────────────────────────────────────────────────────────────────────────┐
│                    Database Access Control Matrix                       │
├──────────────────┬────────────────┬───────────────┬────────────────────┤
│ Role             │ Authentication │ Permissions   │ Secrets Access     │
├──────────────────┼────────────────┼───────────────┼────────────────────┤
│ Application      │ IAM Auth       │ CRUD on app   │ No secrets needed  │
│ Server           │                │ tables        │                    │
├──────────────────┼────────────────┼───────────────┼────────────────────┤
│ Lambda Function  │ IAM Auth       │ Read on       │ No secrets needed  │
│                  │                │ specific      │                    │
├──────────────────┼────────────────┼───────────────┼────────────────────┤
│ DBA (Human)      │ Secrets Mgr    │ Full admin    │ GetSecretValue     │
│                  │                │               │ (MFA required)     │
├──────────────────┼────────────────┼───────────────┼────────────────────┤
│ Reporting        │ IAM Auth       │ Read-only     │ No secrets needed  │
│ Service          │ (Read Replica) │ replica       │                    │
├──────────────────┼────────────────┼───────────────┼────────────────────┤
│ Emergency        │ Secrets Mgr    │ Full admin    │ Break-glass        │
│ Access           │ (Master)       │               │ procedure          │
└──────────────────┴────────────────┴───────────────┴────────────────────┘
```

## Implementation Timeline

### Phase 1: Encryption Foundation (Week 1)
- [ ] Enable encryption at rest on RDS instance
- [ ] Configure SSL/TLS requirement
- [ ] Download and distribute RDS certificates
- [ ] Test encrypted connections

### Phase 2: Secrets Manager (Week 1-2)
- [ ] Create master credential secret
- [ ] Configure automatic rotation
- [ ] Deploy rotation Lambda function
- [ ] Test rotation process

### Phase 3: IAM Authentication (Week 2-3)
- [ ] Enable IAM authentication on RDS
- [ ] Create IAM database users
- [ ] Create IAM policies for database access
- [ ] Update application connection logic

### Phase 4: Audit and Monitoring (Week 3-4)
- [ ] Enable RDS logging to CloudWatch
- [ ] Configure log retention policies
- [ ] Create security dashboards
- [ ] Set up access anomaly alerts

**Total Implementation Time:** 4 weeks

## Related Implementation
This decision was implemented in [Lab 5: RDS & Database Services](../../labs/lab-05-rds/README.md), which includes:
- Encryption at rest configuration
- Secrets Manager setup and rotation
- IAM database authentication
- Security group configuration
- CloudWatch logging integration

## Success Metrics
- **Credential Exposure**: Zero hardcoded credentials in code
- **Encryption Coverage**: 100% of data encrypted at rest and transit
- **Rotation Compliance**: 100% of secrets rotated within 30 days
- **Audit Coverage**: 100% of database access logged
- **Access Control**: Zero unauthorized access attempts

## Review Date
2026-06-22 (6 months) - Review authentication patterns and compliance readiness

## References
- [IAM Database Authentication for MySQL](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.IAMDBAuth.html)
- [Secrets Manager RDS Integration](https://docs.aws.amazon.com/secretsmanager/latest/userguide/rotating-secrets-rds.html)
- [RDS Encryption](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Overview.Encryption.html)
- [RDS Logging](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_LogAccess.html)

## Appendix: Security Control Mapping

| Control | Implementation | Compliance Mapping |
|---------|----------------|-------------------|
| Access Control | IAM Auth + Security Groups | SOC2 CC6.1, HIPAA 164.312(d) |
| Encryption at Rest | KMS managed keys | SOC2 CC6.7, HIPAA 164.312(a)(2)(iv) |
| Encryption in Transit | TLS 1.2+ required | SOC2 CC6.7, HIPAA 164.312(e)(1) |
| Credential Management | Secrets Manager rotation | SOC2 CC6.1, HIPAA 164.312(d) |
| Audit Logging | CloudWatch + CloudTrail | SOC2 CC7.2, HIPAA 164.312(b) |
| Network Isolation | Private subnets + SG | SOC2 CC6.6, HIPAA 164.312(e)(1) |

---

*This decision will be revisited if:*
- Compliance requirements change significantly
- AWS introduces new authentication methods
- Performance impact of IAM auth becomes significant
- Secret rotation frequency needs adjustment
