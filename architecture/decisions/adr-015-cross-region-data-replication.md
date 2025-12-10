<!--
Terminus Solutions AWS Enterprise Architecture
Copyright (c) 2025 Jared (Terminus Solutions) - jaredintech.com
Licensed under CC BY-SA 4.0 - Attribution required
See LICENSE-DOCS for details
-->

# ADR-015: Cross-Region Data Replication

## Date
2025-07-01

## Status
Accepted

## Context
Following our multi-region DR network design (ADR-004) and object storage strategy (ADR-012), Terminus Solutions requires a robust cross-region replication strategy for critical data. Our disaster recovery requirements mandate an RPO (Recovery Point Objective) of 1 hour and RTO (Recovery Time Objective) of 4 hours. The strategy must balance data consistency, replication costs, and recovery speed.

Key requirements and constraints:
- Must achieve RPO of 1 hour for critical data
- Need to support RTO of 4 hours for full recovery
- Require selective replication (not all data needs DR)
- Support compliance with data residency requirements
- Minimize cross-region data transfer costs
- Enable automated failover capabilities
- Maintain data integrity during replication
- Support both real-time and batch replication patterns
- Scale to handle 10TB+ of critical data
- Budget constraint: <$500/month for replication

Current challenges:
- Identifying which data requires replication
- Balancing replication frequency with costs
- Managing replication lag and consistency
- Coordinating multi-service replication
- Testing failover without disruption

## Decision
We will implement S3 Cross-Region Replication (CRR) for object storage with service-specific replication strategies for other data types.

**Replication Architecture:**
```
Replication Strategy:
├── S3 Cross-Region Replication
│   ├── Critical application data
│   ├── User uploads
│   ├── Configuration files
│   └── Backup files
├── RDS Read Replicas (Future)
│   ├── Async replication
│   ├── Automated backups
│   └── Point-in-time recovery
├── DynamoDB Global Tables (Future)
│   ├── Multi-region active
│   ├── Eventual consistency
│   └── Automatic failover
└── Application State
    ├── ElastiCache snapshots
    ├── EBS snapshots
    └── Lambda functions
```

**Replication Tiers:**
1. **Tier 1 - Critical** (Real-time): Business-critical data, immediate replication
2. **Tier 2 - Important** (Hourly): Important but not critical, scheduled replication
3. **Tier 3 - Standard** (Daily): Standard data, daily replication
4. **Tier 4 - Archive** (Weekly): Historical data, weekly replication

## Consequences

### Positive
- **DR Readiness**: Meets RPO/RTO requirements
- **Data Durability**: Multi-region redundancy
- **Compliance**: Supports data residency requirements
- **Automation**: Minimal operational overhead
- **Flexibility**: Granular control over what replicates
- **Cost Control**: Replicate only necessary data
- **Consistency**: Maintains object metadata and tags

### Negative
- **Transfer Costs**: $0.02/GB cross-region transfer
- **Storage Duplication**: Doubles storage costs for replicated data
- **Replication Lag**: Not instantaneous (usually < 15 minutes)
- **Complexity**: Multiple replication strategies to manage
- **Version Conflicts**: Potential for version mismatches

### Mitigation Strategies
- **Selective Replication**: Use prefixes and tags to control
- **Storage Classes**: Replicate to cheaper storage class
- **Monitoring**: Track replication metrics and lag
- **Testing**: Regular failover drills
- **Documentation**: Clear runbooks for failover

## Alternatives Considered

### 1. AWS Backup Cross-Region
**Rejected because:**
- Higher costs for continuous replication
- Less granular control
- Longer RPO (minimum 1 hour)
- Not real-time
- Better for scheduled backups

### 2. Manual Replication Scripts
**Rejected because:**
- High operational overhead
- Error prone
- Difficult to scale
- No built-in monitoring
- Reinventing native features

### 3. Third-Party Replication Tools
**Rejected because:**
- Additional licensing costs
- External dependencies
- Security considerations
- Less AWS integration
- Complexity for team

### 4. Single Region with Backups
**Rejected because:**
- Doesn't meet RTO requirements
- No real-time replication
- Higher recovery complexity
- Regional failure vulnerability
- Against DR best practices

### 5. Multi-Region Active-Active
**Rejected because:**
- Significantly higher costs
- Application changes required
- Complexity beyond current needs
- Synchronization challenges
- Over-engineering for requirements

## Implementation Details

### S3 Replication Configuration
```json
{
  "Role": "arn:aws:iam::123456789012:role/replication-role",
  "Rules": [{
    "ID": "CriticalDataReplication",
    "Priority": 1,
    "Status": "Enabled",
    "Filter": {
      "And": {
        "Prefix": "critical/",
        "Tags": [{
          "Key": "ReplicationTier",
          "Value": "1"
        }]
      }
    },
    "Destination": {
      "Bucket": "arn:aws:s3:::terminus-dr-bucket",
      "ReplicationTime": {
        "Status": "Enabled",
        "Time": {
          "Minutes": 15
        }
      },
      "Metrics": {
        "Status": "Enabled",
        "EventThreshold": {
          "Minutes": 15
        }
      },
      "StorageClass": "STANDARD_IA"
    },
    "DeleteMarkerReplication": {
      "Status": "Enabled"
    }
  }]
}
```

### Replication Monitoring
```yaml
CloudWatch Metrics:
  ReplicationLatency:
    Alarm: > 3600 seconds
    Action: SNS notification
    
  PendingReplicationCount:
    Alarm: > 1000 objects
    Action: Investigate bottleneck
    
  FailedReplicationCount:
    Alarm: > 10 objects
    Action: Check permissions

S3 Replication Metrics:
  - Bytes pending replication
  - Operations pending replication  
  - Replication latency (max)
  - Failed operations count
```

### Cost Optimization
```yaml
Data Classification:
  Critical (Tier 1):
    Volume: ~500GB
    Replication: Real-time
    Storage Class: STANDARD → STANDARD_IA
    Monthly Cost: $10 (transfer) + $6.25 (storage)
    
  Important (Tier 2):
    Volume: ~2TB
    Replication: Hourly batch
    Storage Class: STANDARD_IA → GLACIER_IR
    Monthly Cost: $40 (transfer) + $8 (storage)
    
  Standard (Tier 3):
    Volume: ~5TB
    Replication: Daily
    Storage Class: INTELLIGENT_TIERING
    Monthly Cost: $100 (transfer) + $64 (storage)
    
Total Estimated: $228.25/month
```

### Failover Procedures
```yaml
Detection:
  - Route 53 health checks
  - CloudWatch synthetics
  - Manual declaration
  
Failover Steps:
  1. Verify primary region failure
  2. Update Route 53 records
  3. Promote RDS read replicas
  4. Update application configs
  5. Verify data consistency
  6. Monitor performance
  
Failback Steps:
  1. Restore primary region
  2. Reverse replicate changes
  3. Verify data sync
  4. Switch Route 53 back
  5. Resume normal replication
```

## Implementation Timeline

### Phase 1: S3 Replication Setup (Day 1)
- [x] Configure replication roles
- [x] Set up destination buckets
- [x] Create replication rules
- [x] Enable replication metrics

### Phase 2: Monitoring and Alerting (Day 2)
- [x] Configure CloudWatch alarms
- [x] Set up SNS notifications
- [x] Create dashboards
- [x] Document procedures

### Phase 3: Testing and Validation (Week 1)
- [x] Test replication lag
- [x] Verify data integrity
- [x] Perform failover drill
- [x] Measure recovery time

### Phase 4: Optimization (Month 1)
- [ ] Analyze replication costs
- [ ] Optimize storage classes
- [ ] Refine replication rules
- [ ] Update documentation

**Total Implementation Time:** 1 month (completed core in 3 hours during lab)

## Related Implementation
This decision was implemented in [Lab 4: S3 & Storage Strategy](../../labs/lab-04-s3/README.md), which includes:
- Cross-region replication setup
- Replication rule configuration
- Monitoring dashboard creation
- Failover testing procedures
- Cost analysis and optimization

## Success Metrics
- **RPO Achievement**: < 1 hour for Tier 1 data ✅
- **Replication Lag**: < 15 minutes average ✅
- **Data Integrity**: 100% consistency ✅
- **Cost Target**: < $500/month ✅ (actual: ~$230)
- **Failover Success**: 100% in testing ✅

## Review Date
2025-10-01 (3 months) - Review replication performance and costs

## References
- [S3 Cross-Region Replication](https://docs.aws.amazon.com/AmazonS3/latest/userguide/replication.html)
- [Disaster Recovery Strategies](https://docs.aws.amazon.com/whitepapers/latest/disaster-recovery-workloads-on-aws/disaster-recovery-options-in-the-cloud.html)
- [Replication Best Practices](https://aws.amazon.com/blogs/storage/s3-cross-region-replication-best-practices/)
- **Implementation**: [Lab 4: S3 & Storage Strategy](../../labs/lab-04-s3/README.md)

## Appendix: DR Strategy Comparison

| Strategy | RTO | RPO | Cost/Month | Complexity |
|----------|-----|-----|------------|------------|
| Backup & Restore | 24h | 24h | $50 | Low |
| Pilot Light | 4h | 1h | $200 | Medium |
| Warm Standby | 1h | 5m | $1000 | High |
| Multi-Site Active | 0 | 0 | $5000+ | Very High |
| **Our Choice** | **4h** | **1h** | **$230** | **Medium** |

### Replication Decision Tree
```
Is data business critical?
├── Yes → Tier 1 (Real-time replication)
├── No → Is it important for operations?
│   ├── Yes → Tier 2 (Hourly replication)
│   └── No → Is it needed for compliance?
│       ├── Yes → Tier 3 (Daily replication)
│       └── No → Tier 4 (Weekly) or no replication
```

---

*This decision will be revisited if:*
- DR requirements change (RTO/RPO)
- Replication costs exceed budget
- New AWS services provide better options
- Data volume grows beyond projections