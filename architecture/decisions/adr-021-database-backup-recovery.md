<!--
Terminus Solutions AWS Enterprise Architecture
Copyright (c) 2025 Jared (Terminus Solutions) - jaredintech.com
Licensed under CC BY-SA 4.0 - Attribution required
See LICENSE-DOCS for details
-->

# ADR-021: Database Backup and Recovery

## Date
2025-12-22

## Status
Accepted

## Context
With our database platform, high availability, security, and caching strategies established (ADR-017 through ADR-020), Terminus Solutions needs to implement a comprehensive backup and recovery strategy. This decision determines our approach to automated backups, point-in-time recovery, cross-region backup replication, and disaster recovery procedures.

Key requirements and constraints:
- Must support point-in-time recovery to any second within retention period
- Require cross-region backup storage for disaster recovery
- Need to meet RPO of <1 hour for primary database
- Target RTO of <4 hours for complete database restore
- Support both automated and manual backup workflows
- Minimize backup storage costs while meeting retention requirements
- Enable backup testing without impacting production
- Meet compliance requirements for data retention (7 years for some data)
- Support multiple database types (RDS, Aurora, DynamoDB)

Current challenges:
- No cross-region backup capability configured
- Backup testing not regularly performed
- No documented recovery procedures
- Unclear retention requirements per data type
- Manual snapshots not scheduled

## Decision
We will implement a comprehensive backup and recovery strategy using RDS automated backups with point-in-time recovery, cross-region backup replication, scheduled manual snapshots for long-term retention, and documented recovery procedures for each failure scenario.

**Backup Architecture:**
```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         Backup and Recovery Architecture                     │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                      us-east-1 (Primary)                            │    │
│  │                                                                     │    │
│  │  ┌──────────────┐    ┌─────────────────────────────────────────┐   │    │
│  │  │ RDS MySQL    │───▶│ Automated Backups                       │   │    │
│  │  │ Primary      │    │ ├── Daily snapshots (03:00 UTC)         │   │    │
│  │  └──────────────┘    │ ├── Transaction logs (5 min intervals)  │   │    │
│  │                      │ ├── 7-day retention                     │   │    │
│  │                      │ └── Point-in-time recovery enabled      │   │    │
│  │                      └──────────────────┬──────────────────────┘   │    │
│  │                                         │                          │    │
│  │  ┌──────────────┐    ┌─────────────────▼───────────────────────┐   │    │
│  │  │ Manual       │───▶│ Manual Snapshots                        │   │    │
│  │  │ Snapshots    │    │ ├── Weekly (Sunday 02:00 UTC)           │   │    │
│  │  │ (Scheduled)  │    │ ├── Pre-deployment                      │   │    │
│  │  └──────────────┘    │ ├── 90-day retention                    │   │    │
│  │                      │ └── Lifecycle policy for archival       │   │    │
│  │                      └──────────────────┬──────────────────────┘   │    │
│  └─────────────────────────────────────────┼───────────────────────────┘    │
│                                            │                                │
│                           Cross-Region Replication                          │
│                                            │                                │
│  ┌─────────────────────────────────────────▼───────────────────────────┐    │
│  │                        us-west-2 (DR)                               │    │
│  │                                                                     │    │
│  │  ┌─────────────────────────────────────────────────────────────┐   │    │
│  │  │ Replicated Backups                                          │   │    │
│  │  │ ├── Automated backup copies (daily)                         │   │    │
│  │  │ ├── Manual snapshot copies (weekly)                         │   │    │
│  │  │ ├── Same retention as source                                │   │    │
│  │  │ └── Independent restore capability                          │   │    │
│  │  └─────────────────────────────────────────────────────────────┘   │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Backup Strategy by Database Type:**

| Database | Backup Method | Frequency | Retention | Cross-Region | PITR |
|----------|---------------|-----------|-----------|--------------|------|
| RDS MySQL | Automated | Continuous | 7 days | Yes | Yes |
| RDS MySQL | Manual | Weekly | 90 days | Yes | N/A |
| Aurora | Continuous | Continuous | 7 days | Yes | Yes |
| DynamoDB | PITR | Continuous | 35 days | Via Global Tables | Yes |
| DynamoDB | On-demand | Weekly | 90 days | Yes | N/A |
| ElastiCache | Snapshot | Daily | 7 days | Manual | N/A |

**Recovery Time Objectives:**

| Scenario | RTO Target | RPO Target | Method |
|----------|------------|------------|--------|
| Table/Row Corruption | 30 min | 0 (PITR) | Point-in-time restore |
| Instance Failure | 2 min | 0 | Multi-AZ failover |
| AZ Outage | 2 min | 0 | Multi-AZ failover |
| Region Outage | 4 hours | <1 hour | Cross-region restore |
| Database Deletion | 1 hour | <5 min | Snapshot restore |
| Ransomware | 4 hours | <1 hour | Clean snapshot restore |

## Consequences

### Positive
- **Zero Data Loss**: Point-in-time recovery enables recovery to any second
- **Regional Resilience**: Cross-region backups survive regional disasters
- **Compliance Ready**: Retention policies meet regulatory requirements
- **Operational Flexibility**: Multiple recovery options for different scenarios
- **Cost Efficient**: Automated backups included in RDS pricing
- **Tested Recovery**: Regular backup testing validates procedures
- **Fast Recovery**: Multi-AZ failover provides 2-minute RTO

### Negative
- **Storage Costs**: Cross-region replication incurs transfer and storage costs
- **Complexity**: Multiple backup types require clear documentation
- **Restore Time**: Large database restores can take hours
- **Testing Overhead**: Regular backup testing requires resources
- **Snapshot Limits**: AWS limits on snapshots per region

### Mitigation Strategies
- **Cost Monitoring**: CloudWatch alerts for backup storage costs
- **Documentation**: Clear runbooks for each recovery scenario
- **Parallel Restore**: Use faster instance types for large restores
- **Automated Testing**: Lambda-based backup verification
- **Lifecycle Policies**: Automatic snapshot cleanup

## Alternatives Considered

### 1. Manual Backups Only
**Rejected because:**
- No point-in-time recovery capability
- Human error in backup scheduling
- No continuous protection
- Higher RPO (hours vs. minutes)
- Not compliant with best practices

### 2. Third-Party Backup Solutions
**Rejected because:**
- Additional cost and complexity
- External dependencies
- Less integrated with AWS
- Potential security concerns
- Native RDS backup is sufficient

### 3. Database Dump Scripts (mysqldump)
**Rejected because:**
- Performance impact during backup
- No point-in-time recovery
- Complex restoration process
- Not suitable for large databases
- Manual error-prone process

### 4. S3 Export Only
**Rejected because:**
- One-time export, not continuous
- Cannot restore to RDS directly
- No transaction log backup
- Higher RPO
- Complex restore process

### 5. Cross-Region Read Replica Only
**Rejected because:**
- Replica corrupted if primary corrupted
- No point-in-time recovery
- Higher cost than backup replication
- Not a true backup solution
- Complements but doesn't replace backups

## Implementation Details

### RDS Backup Configuration
```yaml
RDS MySQL Backup Settings:
  Instance: terminus-prod-mysql
  
  Automated Backups:
    Enabled: true
    Retention Period: 7 days
    Backup Window: 03:00-04:00 UTC
    Copy Tags to Snapshots: true
    
  Backup Replication:
    Enabled: true
    Target Region: us-west-2
    Retention: Same as source
    KMS Key: AWS managed key (destination)
    
  Point-in-Time Recovery:
    Enabled: true (automatic with backups)
    Granularity: 5 minutes (transaction logs)
    Recovery Window: Latest restorable time - 7 days
```

### Manual Snapshot Schedule
```yaml
Scheduled Snapshots:
  Weekly Snapshot:
    Schedule: cron(0 2 ? * SUN *)
    Identifier: terminus-mysql-weekly-{date}
    Retention: 90 days
    Cross-Region Copy: Yes
    
  Pre-Deployment Snapshot:
    Trigger: CodePipeline pre-deploy stage
    Identifier: terminus-mysql-predeploy-{timestamp}
    Retention: 30 days
    Cross-Region Copy: Yes
    
  Monthly Archive:
    Schedule: cron(0 4 1 * ? *)
    Identifier: terminus-mysql-monthly-{date}
    Retention: 365 days
    Cross-Region Copy: Yes
```

### DynamoDB Backup Configuration
```yaml
DynamoDB Backup Settings:
  Table: TerminusUserSessions
  
  Point-in-Time Recovery:
    Enabled: true
    Retention: 35 days
    
  On-Demand Backups:
    Schedule: Weekly (via Lambda)
    Retention: 90 days
    
  Global Tables:
    Regions: us-east-1, us-west-2
    Provides: Continuous cross-region replication
```

### Backup Verification
```python
# Lambda function for backup verification
import boto3
from datetime import datetime, timedelta

def verify_backups(event, context):
    """Verify backup health for all databases"""
    rds = boto3.client('rds')
    findings = []
    
    # Check RDS automated backups
    instances = rds.describe_db_instances()
    for instance in instances['DBInstances']:
        instance_id = instance['DBInstanceIdentifier']
        
        # Verify backup retention
        if instance['BackupRetentionPeriod'] < 7:
            findings.append(f"WARNING: {instance_id} has insufficient retention")
        
        # Verify latest backup exists
        latest = instance.get('LatestRestorableTime')
        if latest:
            age = datetime.utcnow().replace(tzinfo=latest.tzinfo) - latest
            if age > timedelta(hours=24):
                findings.append(f"CRITICAL: {instance_id} backup older than 24h")
        else:
            findings.append(f"CRITICAL: {instance_id} has no restorable backup")
    
    # Check for cross-region copies
    snapshots = rds.describe_db_snapshots(SnapshotType='automated')
    # Verify replication status...
    
    return {
        'status': 'HEALTHY' if not findings else 'DEGRADED',
        'findings': findings,
        'checked_at': datetime.utcnow().isoformat()
    }
```

### Recovery Procedures

```yaml
Scenario: Point-in-Time Recovery (Data Corruption)
Steps:
  1. Identify corruption timestamp
  2. Select target time (just before corruption)
  3. Initiate PITR restore to new instance
  4. Verify data integrity on new instance
  5. Promote new instance or migrate data
  6. Update application connection strings
RTO: 30-60 minutes
RPO: 0 (to the second)

Scenario: Cross-Region Disaster Recovery
Steps:
  1. Confirm primary region unavailable
  2. Locate latest snapshot in DR region
  3. Restore snapshot to new RDS instance
  4. Update Route 53 DNS records
  5. Verify application connectivity
  6. Communicate recovery complete
RTO: 2-4 hours
RPO: <1 hour (snapshot age)

Scenario: Accidental Deletion Recovery
Steps:
  1. Identify deleted resource
  2. Locate most recent snapshot
  3. Restore from snapshot
  4. Verify data completeness
  5. Update connection strings if needed
  6. Document incident
RTO: 1-2 hours
RPO: Last snapshot time
```

### Backup Cost Optimization
```yaml
Cost Optimization Strategies:
  
  Automated Backups:
    Cost: Included with RDS (storage only)
    Storage: Same as database size
    Optimization: N/A (required)
    
  Manual Snapshots:
    Cost: $0.095/GB/month
    Optimization:
      - Lifecycle policy for old snapshots
      - Delete pre-deployment snapshots after 30 days
      - Archive to cheaper storage class
      
  Cross-Region Copies:
    Transfer: $0.02/GB (one-time)
    Storage: $0.095/GB/month
    Optimization:
      - Copy only critical snapshots
      - Use lifecycle policy in DR region
      
  Estimated Monthly Cost:
    20GB database × 7 days automated: Included
    20GB × 4 weekly snapshots: $7.60
    Cross-region transfer: $0.40/week = $1.60
    DR storage: $7.60
    Total: ~$17/month
```

### Monitoring Configuration
```yaml
CloudWatch Alarms:
  Backup Age:
    Description: Alert if no backup in 24 hours
    Metric: Custom (via Lambda)
    Threshold: > 24 hours
    Action: SNS critical alert
    
  Backup Storage:
    Description: Monitor backup storage growth
    Metric: TotalBackupStorageBilled
    Threshold: > 100 GB
    Action: SNS warning
    
  Cross-Region Replication:
    Description: Verify replication active
    Metric: Custom (via Lambda)
    Threshold: Replication failed
    Action: SNS critical alert

EventBridge Rules:
  Backup Completion:
    Event: RDS-EVENT-0002 (Backup completed)
    Target: Lambda (verification function)
    
  Backup Failure:
    Event: RDS-EVENT-0004 (Backup failed)
    Target: SNS topic (critical alerts)
```

## Implementation Timeline

### Phase 1: Automated Backup Configuration (Week 1)
- [ ] Enable automated backups on all RDS instances
- [ ] Configure backup windows during low-traffic periods
- [ ] Enable point-in-time recovery
- [ ] Verify transaction log backup

### Phase 2: Cross-Region Replication (Week 1-2)
- [ ] Enable cross-region backup replication
- [ ] Configure destination KMS keys
- [ ] Verify backup copies in DR region
- [ ] Test cross-region restore

### Phase 3: Manual Snapshot Scheduling (Week 2-3)
- [ ] Create snapshot schedule (EventBridge + Lambda)
- [ ] Configure pre-deployment snapshots
- [ ] Implement lifecycle policies
- [ ] Document snapshot naming convention

### Phase 4: Recovery Testing and Documentation (Week 3-4)
- [ ] Test point-in-time recovery
- [ ] Test cross-region restore
- [ ] Create recovery runbooks
- [ ] Train team on recovery procedures

**Total Implementation Time:** 4 weeks

## Related Implementation
This decision was implemented in [Lab 5: RDS & Database Services](../../labs/lab-05-rds/README.md), which includes:
- Automated backup configuration
- Cross-region backup replication
- Point-in-time recovery testing
- Snapshot management
- Recovery procedure documentation

## Success Metrics
- **Backup Success Rate**: 100% of scheduled backups complete
- **Recovery Testing**: Monthly DR recovery tests pass
- **RPO Achievement**: <5 minutes data loss in recovery tests
- **RTO Achievement**: <2 hours for regional recovery
- **Backup Coverage**: 100% of databases have automated backups

## Review Date
2026-06-22 (6 months) - Review retention policies and recovery procedures

## References
- [RDS Backup and Restore](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_CommonTasks.BackupRestore.html)
- [Cross-Region Automated Backups](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_ReplicateBackups.html)
- [Point-in-Time Recovery](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_PIT.html)
- [DynamoDB Backup and Restore](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/BackupRestore.html)

## Appendix: Backup and Recovery Matrix

| Failure Type | Detection | Backup Used | Recovery Method | RTO | RPO |
|--------------|-----------|-------------|-----------------|-----|-----|
| Row Corruption | Application | Transaction Logs | PITR | 30min | 0 |
| Table Drop | Application | Latest Snapshot | Snapshot Restore | 1hr | Minutes |
| Instance Crash | Automatic | Multi-AZ Standby | Failover | 2min | 0 |
| AZ Failure | Automatic | Multi-AZ Standby | Failover | 2min | 0 |
| Region Failure | Manual | Cross-Region Backup | DR Restore | 4hr | <1hr |
| Ransomware | Manual | Clean Snapshot | Snapshot Restore | 4hr | Hours |
| Human Error | Manual | PITR or Snapshot | Varies | 1-4hr | Varies |

---

*This decision will be revisited if:*
- Compliance requires longer retention periods
- RPO/RTO requirements become more stringent
- Database size exceeds 1TB (restore times increase)
- New backup technologies become available
