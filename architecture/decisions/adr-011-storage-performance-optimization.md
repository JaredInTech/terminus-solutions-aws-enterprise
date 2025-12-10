
<!--
Terminus Solutions AWS Enterprise Architecture
Copyright (c) 2025 Jared (Terminus Solutions) - jaredintech.com
Licensed under CC BY-SA 4.0 - Attribution required
See LICENSE-DOCS for details
-->

# ADR-011: Storage Performance Optimization

## Date
2025-06-13

## Status
Accepted

## Context
Our compute platform (ADR-007) requires optimized storage solutions for various workloads including web content, application data, and system logs. Storage performance directly impacts application responsiveness, and storage costs can significantly affect our infrastructure budget. We need a strategy that balances performance, reliability, and cost.

Key requirements and constraints:
- Must provide consistent IOPS for database operations
- Need cost-effective storage for web content and logs
- Require automated backup and disaster recovery
- Support rapid instance scaling without storage bottlenecks
- Enable encryption for compliance requirements
- Minimize storage costs while meeting performance SLAs
- Implement point-in-time recovery capabilities
- Support cross-region replication for DR
- Limited budget for storage infrastructure

Current challenges:
- Unknown IOPS requirements for application
- Balancing performance vs. cost
- Backup strategy complexity
- Cross-region data transfer costs
- Encryption key management

## Decision
We will implement a tiered storage strategy using EBS gp3 volumes with optimized configurations, automated snapshot lifecycle policies, and customer-managed encryption.

**Storage Architecture:**
```
Storage Tiers:
├── System/Root Volumes
│   ├── Type: gp3
│   ├── Size: 20-30 GB
│   ├── IOPS: 3,000 (baseline)
│   └── Throughput: 125 MB/s
├── Application Data Volumes
│   ├── Type: gp3
│   ├── Size: 100 GB
│   ├── IOPS: 5,000
│   └── Throughput: 250 MB/s
└── Backup Strategy
    ├── Daily snapshots (7-day retention)
    ├── Weekly snapshots (12-week retention)
    └── Cross-region replication to DR
```

**Optimization Strategy:**
1. **gp3 over gp2** for cost/performance efficiency
2. **EBS-optimized instances** for dedicated bandwidth
3. **Independent IOPS/throughput** scaling
4. **Automated lifecycle management** for snapshots
5. **Customer-managed KMS** for encryption control

## Consequences

### Positive
- **Performance Control**: Independent IOPS and throughput tuning
- **Cost Efficiency**: 20% cheaper than gp2 at better performance
- **Predictable Performance**: No credit-based bursting system
- **Automated Backups**: Policy-driven snapshot management
- **DR Readiness**: Cross-region snapshots for recovery
- **Compliance**: Encryption with key control
- **Scalability**: Performance scales with application needs

### Negative
- **Snapshot Storage Costs**: Multiple versions increase storage
- **Cross-Region Transfer**: Replication incurs data charges
- **Management Complexity**: Multiple policies to maintain
- **KMS Key Costs**: Customer keys have hourly charges
- **Performance Limits**: Still bound by instance type limits

### Mitigation Strategies
- **Retention Policies**: Limit snapshot count and age
- **Incremental Snapshots**: Only changed blocks transferred
- **Consolidated Policies**: Minimize policy sprawl
- **Key Reuse**: Single key for multiple volumes
- **Right-sizing**: Regular volume performance analysis

## Alternatives Considered

### 1. gp2 Volumes (Previous Generation)
**Rejected because:**
- Credit-based system unpredictable
- Cannot independently scale IOPS/throughput
- More expensive for same performance
- Bursting not suitable for consistent workloads
- Being phased out for gp3

### 2. io2 Volumes (Provisioned IOPS)
**Rejected because:**
- Significantly more expensive
- Overkill for our workloads
- 64,000 IOPS unnecessary
- Better for databases (future consideration)
- Cost prohibitive at scale

### 3. Instance Store Only
**Rejected because:**
- Data loss on instance stop/terminate
- No snapshot capability
- Not suitable for persistent data
- Complicates Auto Scaling
- Only for temporary data

### 4. EFS (Elastic File System)
**Rejected because:**
- Higher latency than EBS
- More expensive for our use case
- Unnecessary shared access features
- Regional service limitations
- Better for shared content scenarios

### 5. Manual Snapshot Management
**Rejected because:**
- Operational overhead
- Human error risk
- Inconsistent backup schedules
- No automated replication
- Poor compliance posture

## Implementation Details

### gp3 Configuration
```yaml
Root Volumes:
  Size: 20 GB (web), 30 GB (app)
  Volume Type: gp3
  IOPS: 3,000
  Throughput: 125 MB/s
  Encryption: Customer KMS key
  Delete on Termination: true

Application Volumes:
  Size: 100 GB
  Volume Type: gp3  
  IOPS: 5,000
  Throughput: 250 MB/s
  Encryption: Customer KMS key
  Delete on Termination: true
  Mount Point: /opt/terminus/data
```

### Snapshot Lifecycle Policies
```yaml
Daily Backup Policy:
  Schedule: Daily at 03:00 UTC
  Retention: 7 snapshots
  Target Tags:
    - Environment: Production
    - SnapshotPolicy: Daily
  Cross-Region Copy:
    Target: us-west-2
    Retention: 14 snapshots
    Encryption: Default KMS key

Weekly Backup Policy:
  Schedule: Sunday at 01:00 UTC
  Retention: 12 snapshots
  Target Tags:
    - Environment: Production
    - SnapshotPolicy: Weekly
  Cross-Region Copy:
    Target: us-west-2
    Retention: 24 snapshots
```

### Performance Optimization
```yaml
EBS Optimization:
  Instance Types: All selected types support
  Benefit: Dedicated network bandwidth
  Impact: Consistent storage performance

IOPS Calculation:
  Baseline: 3,000 IOPS (free with gp3)
  Application: 5,000 IOPS (+$160/month)
  Throughput: Independently scalable
  
Cost Comparison (100GB):
  gp2: $10/month (300 IOPS baseline)
  gp3: $8/month (3,000 IOPS baseline)
  gp3+5k IOPS: $10.40/month (66% more IOPS)
```

### Encryption Strategy
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "Enable EBS Encryption",
    "Effect": "Allow",
    "Principal": {
      "AWS": "arn:aws:iam::ACCOUNT:role/TerminusEC2ServiceRole"
    },
    "Action": [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ],
    "Resource": "*",
    "Condition": {
      "StringEquals": {
        "kms:ViaService": "ec2.us-east-1.amazonaws.com"
      }
    }
  }]
}
```

## Implementation Timeline

### Phase 1: Volume Configuration (Day 1)
- [x] Configure gp3 volumes in launch templates
- [x] Set IOPS and throughput values
- [x] Enable EBS optimization
- [x] Test performance baselines

### Phase 2: Encryption Setup (Day 1)
- [x] Create customer KMS key
- [x] Configure key policies
- [x] Update launch templates
- [x] Verify encryption status

### Phase 3: Snapshot Automation (Day 2)
- [x] Create lifecycle policies
- [x] Configure retention rules
- [x] Enable cross-region copy
- [x] Test snapshot creation

### Phase 4: Optimization (Week 2)
- [ ] Performance monitoring
- [ ] Cost analysis
- [ ] Right-sizing review
- [ ] Policy refinement

**Total Implementation Time:** 2 weeks (completed core in 4 hours during lab)

## Related Implementation
This decision was implemented in [Lab 3: EC2 & Auto Scaling Platform](../../labs/lab-03-ec2/README.md), which includes:
- EBS volume configuration
- Performance testing procedures
- Snapshot lifecycle setup
- KMS key management
- Cost optimization analysis

## Success Metrics
- **IOPS consistency**: >99% delivery of provisioned IOPS ✅ (tested)
- **Snapshot success**: 100% automated backup success ✅
- **Recovery time**: <30 minutes from snapshot ✅ (tested)
- **Cost optimization**: 20% savings vs. gp2 ✅
- **Encryption coverage**: 100% volumes encrypted ✅

## Review Date
2025-09-13 (3 months) - Review performance metrics and costs

## References
- [Amazon EBS Volume Types](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-volume-types.html)
- [EBS Snapshots](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EBSSnapshots.html)
- [EBS Encryption](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EBSEncryption.html)
- **Implementation**: [Lab 3: EC2 & Auto Scaling Platform](../../labs/lab-03-ec2/README.md)

## Appendix: Storage Cost Analysis

| Volume Type | Size | IOPS | Throughput | Monthly Cost |
|-------------|------|------|------------|--------------|
| gp2 | 100GB | 300 | 250 MB/s | $10.00 |
| gp3 | 100GB | 3000 | 125 MB/s | $8.00 |
| gp3 | 100GB | 5000 | 250 MB/s | $10.40 |
| io2 | 100GB | 5000 | 250 MB/s | $62.50 |

### Snapshot Storage Costs
```
Daily Snapshots (Incremental):
- First snapshot: ~5GB
- Daily incremental: ~500MB
- 7-day retention: ~8.5GB total
- Monthly cost: ~$0.43

Weekly Snapshots:
- Weekly incremental: ~2GB
- 12-week retention: ~24GB total
- Monthly cost: ~$1.20

Cross-region replication: 2x storage cost
Total snapshot cost: ~$3.26/month per volume
```

---

*This decision will be revisited if:*
- Application IOPS requirements change significantly
- New EBS volume types are released
- Storage costs become primary concern
- Disaster recovery requirements change