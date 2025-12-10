<!--
Terminus Solutions AWS Enterprise Architecture
Copyright (c) 2025 Jared (Terminus Solutions) - jaredintech.com
Licensed under CC BY-SA 4.0 - Attribution required
See LICENSE-DOCS for details
-->

# ADR-012: Object Storage Strategy

## Date
2025-07-01

## Status
Accepted

## Context
With our compute platform established (ADR-007 through ADR-011), Terminus Solutions needs a comprehensive object storage strategy. S3 will serve multiple purposes including static content hosting, application data storage, backup archival, and log aggregation. The strategy must balance security, performance, cost, and compliance requirements while supporting various access patterns.

Key requirements and constraints:
- Must support public static content delivery and private application data
- Need automated lifecycle management for cost optimization
- Require encryption for all data at rest and in transit
- Support cross-region replication for disaster recovery
- Enable event-driven processing for uploaded content
- Minimize storage costs while meeting performance SLAs
- Implement proper access controls and audit logging
- Support future data lake and analytics workloads
- Budget conscious with projected 50TB growth annually

Current challenges:
- Multiple data types with different access patterns
- Balancing security with accessibility
- Cost optimization across storage classes
- Cross-region data synchronization
- Compliance and audit requirements

## Decision
We will implement a multi-bucket architecture with purpose-specific configurations, leveraging S3's storage classes and features for optimization.

**Bucket Architecture:**
```
Storage Strategy:
├── Static Content Bucket
│   ├── Public read via CloudFront
│   ├── Website hosting enabled
│   └── SSE-S3 encryption
├── Application Data Bucket
│   ├── Private access only
│   ├── Versioning enabled
│   └── SSE-KMS encryption
├── Backup/Archive Bucket
│   ├── Glacier immediate transition
│   ├── 7-year retention
│   └── Cross-region replication
├── Log Aggregation Bucket
│   ├── Write-only from services
│   ├── Lifecycle to Glacier
│   └── MFA delete protection
└── DR Replication Bucket
    ├── Read replica in us-west-2
    ├── Different storage class
    └── Automated failover ready
```

**Key Design Principles:**
1. **Segregation by purpose** - Separate buckets for different data types
2. **Least privilege access** - Bucket policies enforce minimal permissions
3. **Automated lifecycle** - Cost optimization through storage classes
4. **Defense in depth** - Multiple security layers
5. **Event-driven architecture** - S3 events trigger processing

## Consequences

### Positive
- **Security Isolation**: Different security policies per data type
- **Cost Optimization**: Automated tiering saves 60-80% on storage
- **Performance**: CloudFront integration for static content
- **Compliance**: Separate buckets simplify audit scope
- **Scalability**: No limits on storage growth
- **Flexibility**: Easy to add new buckets for new purposes
- **DR Ready**: Cross-region replication automated

### Negative
- **Complexity**: Multiple buckets to manage
- **Cost Overhead**: Minimum charges per bucket
- **Replication Lag**: Cross-region sync not instantaneous
- **Policy Management**: Multiple bucket policies to maintain
- **Monitoring Overhead**: More resources to track

### Mitigation Strategies
- **Automation**: Use IaC for bucket management
- **Naming Convention**: Consistent naming for easy identification
- **Centralized Monitoring**: S3 Storage Lens for visibility
- **Policy Templates**: Reusable security policies
- **Cost Alerts**: Budget monitoring per bucket

## Alternatives Considered

### 1. Single Bucket with Prefixes
**Rejected because:**
- Difficult to enforce different security policies
- Cannot have different encryption per prefix
- Lifecycle policies become complex
- Harder to track costs per data type
- Single point of failure

### 2. Account-Level Separation
**Rejected because:**
- Excessive operational overhead
- Complex cross-account permissions
- Higher costs for data transfer
- Difficult application integration
- Over-engineering for current scale

### 3. EFS for Application Data
**Rejected because:**
- 3x more expensive than S3
- Limited to single region
- Not suitable for object storage patterns
- Lacks S3's rich feature set
- Better for file system needs

### 4. Third-Party Object Storage
**Rejected because:**
- Adds external dependencies
- Higher costs for comparable features
- Less integration with AWS services
- Additional security considerations
- Vendor lock-in concerns

### 5. Hybrid with On-Premises
**Rejected because:**
- Defeats cloud-first strategy
- Complex synchronization
- Higher operational overhead
- Requires Storage Gateway
- Increases latency

## Implementation Details

### Bucket Naming Convention
```yaml
Pattern: terminus-[purpose]-[environment]-[random]
Examples:
  - terminus-static-prod-a1b2c3
  - terminus-appdata-prod-d4e5f6
  - terminus-backups-prod-g7h8i9
  - terminus-logs-prod-j1k2l3
  
Benefits:
  - Globally unique
  - Purpose immediately clear
  - Environment segregation
  - Avoids naming conflicts
```

### Encryption Strategy
```yaml
Static Content:
  Type: SSE-S3
  Reason: Cost-effective, no audit requirements
  
Application Data:
  Type: SSE-KMS (Customer Managed)
  Reason: Audit trail, key rotation control
  
Backups:
  Type: SSE-KMS (Customer Managed)
  Reason: Compliance requirements
  
Logs:
  Type: SSE-S3
  Reason: High volume, cost optimization
```

### Lifecycle Policies
```json
{
  "AppDataLifecycle": {
    "Rules": [{
      "Status": "Enabled",
      "Transitions": [
        {"Days": 30, "StorageClass": "STANDARD_IA"},
        {"Days": 90, "StorageClass": "INTELLIGENT_TIERING"},
        {"Days": 180, "StorageClass": "GLACIER_IR"}
      ],
      "NoncurrentVersionExpiration": {"Days": 90}
    }]
  }
}
```

### Access Control Strategy
```yaml
Bucket Policies:
  - Deny all public access by default
  - Explicit allow for specific principals
  - Require HTTPS for all operations
  - Enable CloudTrail logging
  
IAM Policies:
  - Service-specific access
  - Resource-level restrictions
  - Condition keys for additional security
  
VPC Endpoints:
  - Private access from VPC
  - No internet traversal
  - Reduced data transfer costs
```

## Implementation Timeline

### Phase 1: Foundation (Day 1)
- [x] Create bucket structure
- [x] Configure encryption settings
- [x] Implement basic bucket policies
- [x] Enable versioning where required

### Phase 2: Lifecycle Management (Day 2)
- [x] Configure lifecycle policies
- [x] Set up Intelligent-Tiering
- [x] Implement expiration rules
- [x] Test transition behaviors

### Phase 3: Replication Setup (Day 3)
- [x] Configure cross-region replication
- [x] Set up replication IAM roles
- [x] Verify replication metrics
- [x] Test failover procedures

### Phase 4: Advanced Features (Week 2)
- [x] Enable Transfer Acceleration
- [x] Configure S3 events
- [x] Implement CloudFront distribution
- [ ] Set up S3 Inventory reports

**Total Implementation Time:** 2 weeks (completed core in 4 hours during lab)

## Related Implementation
This decision was implemented in [Lab 4: S3 & Storage Strategy](../../labs/lab-04-s3/README.md), which includes:
- Multi-bucket architecture setup
- Lifecycle policy configuration
- Cross-region replication
- Static website hosting
- Event notification setup
- Cost optimization analysis

## Success Metrics
- **Storage Cost Reduction**: >60% via lifecycle policies ✅
- **Availability**: 99.99% for critical data ✅ (S3 SLA)
- **Replication Lag**: <15 minutes for DR ✅
- **Security**: 100% encrypted at rest ✅
- **Performance**: <100ms static content delivery ✅

## Review Date
2025-10-01 (3 months) - Review storage growth and costs

## References
- [AWS S3 Best Practices](https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-best-practices.html)
- [S3 Storage Classes](https://aws.amazon.com/s3/storage-classes/)
- [S3 Lifecycle Policies](https://docs.aws.amazon.com/AmazonS3/latest/userguide/lifecycle-transition-general-considerations.html)
- **Implementation**: [Lab 4: S3 & Storage Strategy](../../labs/lab-04-s3/README.md)

## Appendix: Storage Class Selection Matrix

| Data Type | Access Pattern | Recommended Class | Transition Timeline |
|-----------|----------------|-------------------|---------------------|
| Static Assets | Frequent | STANDARD | Never |
| User Uploads | Variable | INTELLIGENT_TIERING | Immediate |
| Application Logs | Rare after 30d | STANDARD → GLACIER | 30 → 90 days |
| Backups | Very Rare | GLACIER_IR | Immediate |
| Archives | Never | DEEP_ARCHIVE | After 180 days |

### Cost Comparison (per TB/month)
```
STANDARD: $23.00
STANDARD_IA: $12.50 (45% savings)
INTELLIGENT_TIERING: $12.80 (44% savings)
GLACIER_IR: $4.00 (83% savings)
GLACIER_FLEXIBLE: $3.60 (84% savings)
DEEP_ARCHIVE: $1.00 (96% savings)
```

---

*This decision will be revisited if:*
- Storage growth exceeds 100TB
- New compliance requirements emerge
- AWS releases new storage classes
- Access patterns change significantly