
<!--
Terminus Solutions AWS Enterprise Architecture
Copyright (c) 2025 Jared (Terminus Solutions) - jaredintech.com
Licensed under CC BY-SA 4.0 - Attribution required
See LICENSE-DOCS for details
-->

# ADR-009: Instance Profile Security

## Date
2025-06-13

## Status
Accepted

## Context
EC2 instances in our compute platform (ADR-007) require secure access to various AWS services including S3, CloudWatch, Systems Manager, and Secrets Manager. Traditional approaches using hard-coded credentials or storing access keys on instances pose significant security risks and management overhead.

Key requirements and constraints:
- Must eliminate storage of long-term credentials on instances
- Need fine-grained access control per service and resource
- Require automatic credential rotation without downtime
- Support environment isolation (dev/prod separation)
- Enable secure access to multiple AWS services
- Maintain audit trail for all service access
- Comply with security best practices and standards
- Minimize operational overhead for credential management
- Support future service integrations

Security challenges:
- Credential exposure risk in application code
- Manual key rotation complexity
- Cross-service permission management
- Environment isolation requirements
- Compliance audit requirements

## Decision
We will implement IAM instance profiles with role-based access control for all EC2 instances, following the principle of least privilege.

**Security Architecture:**
```
Instance Profile Structure:
├── No stored credentials on instances
├── Temporary credentials via STS
├── Automatic rotation (6 hours)
├── Environment-specific roles
├── Service-specific permissions
└── CloudTrail audit logging

Role Hierarchy:
├── TerminusEC2ServiceRole (Production)
│   ├── S3 access (terminus-prod-* buckets)
│   ├── CloudWatch metrics/logs
│   ├── Systems Manager operations
│   └── Secrets Manager (terminus/* secrets)
└── TerminusDevEC2ServiceRole (Development)
    ├── S3 access (terminus-dev-* buckets)
    ├── CloudWatch metrics/logs
    └── Limited Systems Manager
```

**Key Security Principles:**
1. **Zero stored credentials** on instances
2. **Least privilege** access per service
3. **Resource-based** restrictions
4. **Environment isolation** via separate roles
5. **Audit logging** for all API calls

## Consequences

### Positive
- **Enhanced Security**: No long-term credentials to compromise
- **Automatic Rotation**: STS handles credential lifecycle
- **Simplified Management**: No manual key distribution
- **Audit Compliance**: Complete CloudTrail logging
- **Environment Isolation**: Prevents cross-environment access
- **Scalability**: Works seamlessly with Auto Scaling
- **AWS Native**: Integrated with AWS services

### Negative
- **Initial Complexity**: Requires IAM policy expertise
- **Troubleshooting**: More complex than key-based access
- **Role Limits**: Soft limits on IAM roles per account
- **Policy Size**: 6KB policy document limit
- **Testing Overhead**: Requires thorough permission testing

### Mitigation Strategies
- **Policy Templates**: Reusable policy patterns
- **Documentation**: Clear permission mappings
- **Testing Framework**: Automated permission validation
- **Policy Optimization**: Consolidate similar permissions
- **Monitoring**: CloudTrail analysis for access patterns

## Alternatives Considered

### 1. Hard-coded Credentials
**Rejected because:**
- Major security risk
- Violates all security best practices
- Manual rotation nightmare
- Compliance violation
- No audit trail

### 2. Secrets Manager with Application Integration
**Rejected because:**
- Still requires initial authentication
- Application code changes needed
- Additional complexity
- Performance overhead
- Instance profiles superior for AWS services

### 3. HashiCorp Vault
**Rejected because:**
- Additional infrastructure required
- Operational complexity
- Learning curve for team
- Cost of running Vault cluster
- Native AWS solution preferred

### 4. Environment Variables
**Rejected because:**
- Visible in process listings
- Difficult to rotate
- Security risk if exposed
- Not scalable
- Poor practice for production

### 5. AWS Systems Manager Parameter Store Only
**Rejected because:**
- Still needs authentication method
- Not suitable for all credential types
- Additional API calls required
- Instance profiles still needed
- Better as complementary solution

## Implementation Details

### Permission Structure
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "S3Access",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::terminus-prod-*",
        "arn:aws:s3:::terminus-prod-*/*"
      ]
    },
    {
      "Sid": "CloudWatchAccess",
      "Effect": "Allow",
      "Action": [
        "cloudwatch:PutMetricData",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    }
  ]
}
```

### Resource Naming Standards
```yaml
S3 Buckets:
  Production: terminus-prod-*
  Development: terminus-dev-*
  Logs: terminus-logs-*

Secrets Manager:
  Pattern: terminus/[environment]/[service]/[secret]
  Example: terminus/prod/rds/password

CloudWatch Logs:
  Pattern: /terminus/[environment]/[tier]/[log-type]
  Example: /terminus/prod/web/access
```

### Security Best Practices
```yaml
Principle of Least Privilege:
  - Grant minimum required permissions
  - Use resource-level restrictions
  - Avoid wildcard permissions
  - Regular permission audits

Environment Isolation:
  - Separate roles per environment
  - Resource naming enforcement
  - No cross-environment access
  - Tag-based access control

Monitoring and Audit:
  - CloudTrail for all API calls
  - Access pattern analysis
  - Anomaly detection
  - Regular compliance reviews
```

## Implementation Timeline

### Phase 1: Policy Design (Day 1)
- [x] Define service requirements
- [x] Create permission matrices
- [x] Design resource restrictions
- [x] Document access patterns

### Phase 2: Role Creation (Day 1)
- [x] Create production role
- [x] Create development role
- [x] Attach managed policies
- [x] Test basic access

### Phase 3: Integration (Day 2)
- [x] Update launch templates
- [x] Test with Auto Scaling
- [x] Validate service access
- [x] Monitor CloudTrail

### Phase 4: Hardening (Week 2)
- [ ] Remove unnecessary permissions
- [ ] Implement SCPs for boundaries
- [ ] Set up access alerts
- [ ] Create compliance reports

**Total Implementation Time:** 2 weeks (completed core in 4 hours during lab)

## Related Implementation
This decision was implemented in [Lab 3: EC2 & Auto Scaling Platform](../../labs/lab-03-ec2/README.md), which includes:
- IAM role and policy creation
- Instance profile configuration
- Launch template integration
- Service access testing
- CloudTrail monitoring setup

## Success Metrics
- **Zero credentials**: No hard-coded keys in code or configs ✅
- **Access success rate**: >99.9% for authorized requests ✅
- **Rotation compliance**: 100% automatic rotation ✅
- **Audit coverage**: 100% API calls logged ✅
- **Incident reduction**: Zero credential-related incidents ✅ (target)

## Review Date
2025-09-13 (3 months) - Review permissions and access patterns

## References
- [IAM Roles for EC2](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/iam-roles-for-amazon-ec2.html)
- [Security Best Practices in IAM](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [AWS Well-Architected - Security Pillar](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/identity-and-access-management.html)
- **Implementation**: [Lab 3: EC2 & Auto Scaling Platform](../../labs/lab-03-ec2/README.md)

## Appendix: Permission Matrix

| Service | Action | Resource | Production | Development |
|---------|--------|----------|------------|-------------|
| S3 | Get/Put | terminus-prod-* | ✅ | ❌ |
| S3 | Get/Put | terminus-dev-* | ❌ | ✅ |
| CloudWatch | PutMetrics | * | ✅ | ✅ |
| Logs | Write | /terminus/* | ✅ | ✅ |
| SSM | Parameters | /terminus/prod/* | ✅ | ❌ |
| SSM | Parameters | /terminus/dev/* | ❌ | ✅ |
| Secrets | GetSecret | terminus/prod/* | ✅ | ❌ |
| Secrets | GetSecret | terminus/dev/* | ❌ | ✅ |

---

*This decision will be revisited if:*
- New services require access modifications
- Security incidents indicate permission issues
- AWS releases new security features
- Compliance requirements change