<!--
Terminus Solutions AWS Enterprise Architecture
Copyright (c) 2025 Jared (Terminus Solutions) - jaredintech.com
Licensed under CC BY-SA 4.0 - Attribution required
See LICENSE-DOCS for details
-->

# ADR-018: High Availability Database Design

## Date
2025-12-22

## Status
Accepted

## Context
With our database platform strategy defined (ADR-017), Terminus Solutions needs to establish high availability patterns for our database infrastructure. This decision determines our approach to Multi-AZ deployments, read replica architecture, and failover strategies to meet our availability SLAs.

Key requirements and constraints:
- Must achieve 99.95% availability SLA for database layer
- Target RTO of 2 minutes for database failover
- Target RPO of 0 (zero data loss) for primary database
- Support read scaling without impacting write performance
- Enable cross-region disaster recovery capability
- Minimize failover impact on application connections
- Budget conscious—avoid over-provisioning standby resources
- Integrate with existing VPC architecture (ADR-003, ADR-004)
- Support future growth to 10+ read replicas if needed

Current challenges:
- Single AZ deployment creates availability risk
- Read traffic on primary impacts write performance
- No cross-region capability for regional disasters
- Application must handle connection failures gracefully
- Need to balance cost with availability requirements

## Decision
We will implement a comprehensive high availability architecture using Multi-AZ RDS deployments with synchronous replication, asynchronous read replicas for horizontal scaling, and cross-region replicas for disaster recovery.

**High Availability Architecture:**
```
                        ┌─────────────────────────────────────┐
                        │         us-east-1 (Primary)         │
                        │                                     │
                        │  ┌─────────────────────────────┐    │
                        │  │       RDS MySQL Primary     │    │
                        │  │      (us-east-1a)           │    │
                        │  │                             │    │
                        │  │  ┌─────────────────────┐    │    │
                        │  │  │ Synchronous Standby │    │    │
                        │  │  │   (us-east-1b)      │    │    │
                        │  │  │   [Multi-AZ]        │    │    │
                        │  │  └─────────────────────┘    │    │
                        │  └──────────┬──────────────────┘    │
                        │             │                       │
                        │      ┌──────┴──────┐                │
                        │      │ Async Repl  │                │
                        │      ▼             ▼                │
                        │  ┌───────┐     ┌───────┐            │
                        │  │Read-1 │     │Read-2 │            │
                        │  │1a     │     │1b     │            │
                        │  └───────┘     └───────┘            │
                        └─────────────────┬───────────────────┘
                                          │
                              Cross-Region│Async Replication
                                          │
                        ┌─────────────────▼───────────────────┐
                        │         us-west-2 (DR)              │
                        │                                     │
                        │  ┌─────────────────────────────┐    │
                        │  │    Cross-Region Replica     │    │
                        │  │    (Promotable to Primary)  │    │
                        │  └─────────────────────────────┘    │
                        └─────────────────────────────────────┘
```

**Replication Strategy:**

| Replication Type | Source | Target | Latency | Data Loss | Purpose |
|------------------|--------|--------|---------|-----------|---------|
| Synchronous | Primary | Multi-AZ Standby | ~0ms | Zero | Automatic failover |
| Asynchronous | Primary | Regional Replicas | 1-3s | Minimal | Read scaling |
| Asynchronous | Primary | Cross-Region | 3-10s | Seconds | Disaster recovery |

**Failover Hierarchy:**
1. **AZ Failure**: Multi-AZ automatic failover (60-120 seconds)
2. **Regional Degradation**: Promote regional read replica (manual, ~5 minutes)
3. **Regional Disaster**: Promote cross-region replica (manual, ~10 minutes)

## Consequences

### Positive
- **Zero Data Loss**: Synchronous Multi-AZ replication ensures no data loss
- **Automatic Recovery**: Multi-AZ failover requires no manual intervention
- **Read Scaling**: Read replicas handle reporting without impacting primary
- **Geographic Resilience**: Cross-region replica enables DR capability
- **Flexible Scaling**: Can add read replicas independently of primary
- **Cost Efficient**: Standby only charges for compute, not additional I/O
- **Connection Continuity**: DNS-based failover minimizes application changes

### Negative
- **Increased Cost**: Multi-AZ roughly doubles compute costs
- **Write Latency**: Synchronous replication adds ~2-5ms to writes
- **Replica Lag**: Asynchronous replicas may have stale data
- **Complexity**: Multiple endpoints to manage and monitor
- **Cross-Region Cost**: Data transfer charges for cross-region replication

### Mitigation Strategies
- **Cost Optimization**: Use smaller instance sizes for read replicas
- **Latency Monitoring**: CloudWatch alarms for write latency
- **Lag Monitoring**: Alerts when replica lag exceeds 5 seconds
- **Connection Pooling**: Use RDS Proxy to manage connections
- **Data Transfer**: Batch cross-region replication during off-peak

## Alternatives Considered

### 1. Single-AZ with Frequent Snapshots
**Rejected because:**
- Recovery requires restore from snapshot (30+ minutes)
- Data loss between snapshots (RPO = snapshot interval)
- No automatic failover capability
- Manual intervention required for recovery
- Violates availability SLA requirements

### 2. Multi-AZ Only (No Read Replicas)
**Rejected because:**
- Read traffic impacts write performance
- Cannot scale reads independently
- No geographic distribution of reads
- Limited disaster recovery options
- Single endpoint for all traffic

### 3. Aurora Global Database
**Rejected because:**
- Higher cost for current scale
- More complex than requirements demand
- Overkill for 2-region architecture
- Can migrate to Aurora later if needed
- RDS meets current HA requirements

### 4. Active-Active Multi-Region
**Rejected because:**
- Significant application complexity
- Conflict resolution challenges
- Much higher cost
- Overkill for current traffic levels
- Can implement later if needed

### 5. Database Clustering (Galera/Group Replication)
**Rejected because:**
- Operational complexity
- Not fully managed by AWS
- Performance overhead for sync
- Harder to scale across regions
- RDS handles clustering internally

## Implementation Details

### Multi-AZ Configuration
```yaml
RDS MySQL Multi-AZ:
  Primary Instance:
    Identifier: terminus-prod-mysql
    Class: db.t3.micro
    AZ: us-east-1a
    Storage: 20GB gp3
    
  Standby Instance:
    Location: us-east-1b (automatic)
    Synchronous Replication: Enabled
    Automatic Failover: Enabled
    
  Failover Settings:
    DNS TTL: 5 seconds
    Failover Time: 60-120 seconds
    Data Loss: Zero
```

### Read Replica Configuration
```yaml
Regional Read Replicas:
  Replica 1:
    Identifier: terminus-mysql-read-1
    Class: db.t3.micro
    AZ: us-east-1a
    Source: terminus-prod-mysql
    
  Replica 2:
    Identifier: terminus-mysql-read-2
    Class: db.t3.micro
    AZ: us-east-1b
    Source: terminus-prod-mysql
    
Cross-Region Replica:
  Identifier: terminus-mysql-dr-replica
  Class: db.t3.micro
  Region: us-west-2
  Source: terminus-prod-mysql
  Promotion: Manual (DR scenario only)
```

### Endpoint Architecture
```
Application Connection Strategy:
├── Primary Endpoint (Writes)
│   └── terminus-prod-mysql.xxx.us-east-1.rds.amazonaws.com
│       ├── Resolves to: Primary instance
│       └── Failover: Automatically updated DNS
│
├── Reader Endpoint (Reads - Regional)
│   └── terminus-prod-mysql-ro.xxx.us-east-1.rds.amazonaws.com
│       ├── Load balances across: Read replicas
│       └── Excludes: Primary instance
│
└── DR Endpoint (Emergency Only)
    └── terminus-mysql-dr-replica.xxx.us-west-2.rds.amazonaws.com
        ├── Read-only until promoted
        └── Promotion: Breaks replication, becomes primary
```

### Monitoring Configuration
```yaml
CloudWatch Alarms:
  Multi-AZ Failover:
    Metric: RDSEventSubscription
    Events: failover-started, failover-completed
    Action: SNS notification
    
  Replica Lag:
    Metric: ReplicaLag
    Threshold: > 5 seconds
    Period: 60 seconds
    Action: SNS notification
    
  Replication Status:
    Metric: ReplicationState
    Expected: connected
    Action: SNS notification on disconnect
```

### Failover Procedures
```
Automatic Failover (AZ Failure):
1. RDS detects primary unavailable
2. DNS record updated to standby
3. Standby promoted to primary
4. Applications reconnect via DNS
5. New standby created (async)
Time: 60-120 seconds

Manual Failover (Testing):
$ aws rds reboot-db-instance \
    --db-instance-identifier terminus-prod-mysql \
    --force-failover

Regional Promotion (DR):
$ aws rds promote-read-replica \
    --db-instance-identifier terminus-mysql-dr-replica
# Note: Breaks replication permanently
```

## Implementation Timeline

### Phase 1: Multi-AZ Deployment (Week 1)
- [ ] Enable Multi-AZ on primary RDS instance
- [ ] Verify synchronous replication active
- [ ] Configure DNS TTL for failover
- [ ] Test automatic failover

### Phase 2: Regional Read Replicas (Week 1-2)
- [ ] Create first read replica in us-east-1a
- [ ] Create second read replica in us-east-1b
- [ ] Configure reader endpoint
- [ ] Update application connection strings

### Phase 3: Cross-Region DR (Week 2-3)
- [ ] Create cross-region replica in us-west-2
- [ ] Configure VPC peering for replication
- [ ] Document promotion procedures
- [ ] Test promotion process

### Phase 4: Monitoring and Validation (Week 3-4)
- [ ] Configure CloudWatch alarms
- [ ] Set up replica lag monitoring
- [ ] Create failover runbooks
- [ ] Conduct failover drill

**Total Implementation Time:** 4 weeks

## Related Implementation
This decision was implemented in [Lab 5: RDS & Database Services](../../labs/lab-05-rds/README.md), which includes:
- Multi-AZ RDS MySQL deployment
- Regional read replica configuration
- Cross-region replica setup
- Failover testing procedures
- CloudWatch monitoring configuration

## Success Metrics
- **Availability**: 99.95% uptime (allows ~22 minutes downtime/month)
- **Failover Time**: <2 minutes for automatic failover
- **Replica Lag**: <5 seconds for 99% of measurements
- **RPO**: 0 seconds for Multi-AZ, <10 seconds for cross-region
- **RTO**: <2 minutes for AZ failure, <15 minutes for regional DR

## Review Date
2026-06-22 (6 months) - Review failover metrics and replica performance

## References
- [RDS Multi-AZ Deployments](https://aws.amazon.com/rds/features/multi-az/)
- [Working with Read Replicas](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_ReadRepl.html)
- [Cross-Region Read Replicas](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_ReadRepl.XRgn.html)
- [RDS Failover Process](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.MultiAZSingleStandby.html)

## Appendix: Failover Scenario Matrix

| Scenario | Detection | Action | RTO | RPO | Automation |
|----------|-----------|--------|-----|-----|------------|
| Primary Instance Failure | Automatic | Multi-AZ Failover | 60-120s | 0 | Full |
| AZ Network Partition | Automatic | Multi-AZ Failover | 60-120s | 0 | Full |
| Storage Failure | Automatic | Multi-AZ Failover | 60-120s | 0 | Full |
| Planned Maintenance | Scheduled | Multi-AZ Failover | 60-120s | 0 | Full |
| Regional Service Degradation | Manual | Promote Read Replica | 5-10min | Seconds | Partial |
| Regional Disaster | Manual | Promote DR Replica | 10-15min | Seconds | Partial |
| Database Corruption | Manual | Point-in-Time Recovery | 30-60min | Minutes | Partial |

---

*This decision will be revisited if:*
- Availability SLA increases to 99.99%
- Cross-region RPO requirement becomes 0
- Read traffic exceeds 5 replica capacity
- Aurora Global Database becomes cost-competitive
