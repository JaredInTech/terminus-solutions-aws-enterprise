<!--
Terminus Solutions AWS Enterprise Architecture
Copyright (c) 2025 Jared (Terminus Solutions) - jaredintech.com
Licensed under CC BY-SA 4.0 - Attribution required
See LICENSE-DOCS for details
-->

# ADR-017: Database Platform Strategy

## Date
2025-12-22

## Status
Accepted

## Context
With our compute and storage infrastructure established (ADR-007 through ADR-016), Terminus Solutions needs to design a comprehensive database strategy. This decision determines our approach to data persistence, including selection criteria for different database types and how they integrate with our multi-tier architecture.

Key requirements and constraints:
- Must support ACID-compliant transactional workloads
- Need sub-millisecond response times for session management
- Require horizontal read scaling for reporting workloads
- Support variable traffic patterns without over-provisioning
- Enable cross-region data availability for DR
- Minimize operational overhead (managed services preferred)
- Integrate with existing VPC and security architecture (ADR-003, ADR-005)
- Support future application growth without re-architecture
- Budget conscious while maintaining performance SLAs
- Compliance requirements for data encryption and audit trails

Current application needs:
- Primary transactional database for core business logic
- Session storage with global distribution
- Query caching for frequently accessed data
- Variable workload capacity for analytics
- Cross-region replication for disaster recovery

## Decision
We will implement a purpose-built database architecture using multiple AWS managed database services, each optimized for specific access patterns:

**Primary Database Architecture:**

1. **Amazon RDS MySQL** - Primary transactional workloads
   - Multi-AZ deployment for high availability
   - Read replicas for horizontal read scaling
   - Cross-region replica for disaster recovery
   - MySQL 8.0 for JSON support and performance

2. **Amazon Aurora Serverless v2** - Variable workloads
   - Auto-scaling capacity (0.5-1 ACU range)
   - MySQL 8.0 compatible
   - Pay-per-use for unpredictable workloads
   - Ideal for development and analytics

3. **Amazon DynamoDB** - Session and real-time data
   - On-demand billing mode
   - Global tables for multi-region
   - Sub-millisecond response times
   - TTL for automatic session expiration

4. **Amazon ElastiCache Redis** - Query caching
   - In-memory caching layer
   - Cluster mode for scalability
   - Encryption in transit and at rest
   - Automatic failover capability

**Selection Criteria Matrix:**
```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        Database Selection Criteria                          │
├───────────────────┬─────────────┬─────────────┬─────────────┬──────────────┤
│ Requirement       │ RDS MySQL   │ Aurora SL   │ DynamoDB    │ ElastiCache  │
├───────────────────┼─────────────┼─────────────┼─────────────┼──────────────┤
│ ACID Transactions │ ✅ Primary  │ ✅ Yes      │ ⚠️ Limited  │ ❌ No        │
│ Complex Queries   │ ✅ Full SQL │ ✅ Full SQL │ ❌ Key-Value│ ❌ No        │
│ Sub-ms Latency    │ ⚠️ ~5-10ms │ ⚠️ ~5-10ms │ ✅ <1ms     │ ✅ <1ms      │
│ Auto-Scaling      │ ⚠️ Manual  │ ✅ Automatic│ ✅ Automatic│ ⚠️ Manual    │
│ Global Replication│ ⚠️ Manual  │ ⚠️ Manual  │ ✅ Native   │ ⚠️ Manual    │
│ Cost at Scale     │ ✅ Good     │ ✅ Variable │ ⚠️ High R/W │ ✅ Good      │
│ Operational Burden│ ⚠️ Medium  │ ✅ Low      │ ✅ Low      │ ⚠️ Medium    │
└───────────────────┴─────────────┴─────────────┴─────────────┴──────────────┘
```

**Workload Routing:**
```
Incoming Request
      │
      ▼
┌─────────────────┐
│  Application    │
│     Tier        │
└────────┬────────┘
         │
    ┌────┴────┬──────────────┬─────────────┐
    ▼         ▼              ▼             ▼
┌───────┐ ┌───────┐    ┌──────────┐  ┌───────────┐
│ Redis │ │DynamoDB│   │RDS MySQL │  │  Aurora   │
│ Cache │ │Sessions│   │ Primary  │  │ Serverless│
└───────┘ └───────┘    └────┬─────┘  └───────────┘
                            │
                   ┌────────┼────────┐
                   ▼        ▼        ▼
              ┌────────┐ ┌────────┐ ┌────────┐
              │ Read   │ │ Read   │ │  DR    │
              │Replica1│ │Replica2│ │Replica │
              └────────┘ └────────┘ └────────┘
```

## Consequences

### Positive
- **Optimized Performance**: Each database handles its optimal workload pattern
- **Cost Efficiency**: Pay only for the capacity each workload requires
- **Operational Simplicity**: Managed services reduce DBA overhead
- **Horizontal Scaling**: Read replicas and DynamoDB scale independently
- **High Availability**: Multi-AZ and global tables provide resilience
- **Flexibility**: Can add or modify database types as needs evolve
- **Compliance Ready**: All services support encryption and audit logging

### Negative
- **Complexity**: Multiple database types require different expertise
- **Data Consistency**: Eventual consistency between caching layers
- **Connection Management**: Multiple connection pools to manage
- **Cost Monitoring**: Multiple services to track and optimize
- **Migration Complexity**: Data movement between services requires planning

### Mitigation Strategies
- **Standardization**: Use consistent naming and tagging across services
- **Documentation**: Clear data flow diagrams and access patterns
- **Monitoring**: Unified CloudWatch dashboards for all databases
- **Automation**: Infrastructure as Code for consistent deployments
- **Training**: Team education on each database technology

## Alternatives Considered

### 1. Single RDS Instance for Everything
**Rejected because:**
- Cannot provide sub-millisecond latency for sessions
- No automatic scaling for variable workloads
- Caching requires application-level implementation
- Single point of failure without complex setup
- Would require over-provisioning for peak loads

### 2. Aurora Global Database Only
**Rejected because:**
- Higher cost for simple session storage
- Overkill for key-value access patterns
- Still requires external caching solution
- Not optimized for real-time data
- Cost inefficient for current scale

### 3. DynamoDB for Everything
**Rejected because:**
- Complex queries require denormalization
- ACID transactions limited to single table
- Higher cost for relational workloads
- Steeper learning curve for SQL developers
- Not ideal for complex reporting queries

### 4. Self-Managed Databases on EC2
**Rejected because:**
- Significant operational overhead
- Manual backup and recovery
- No automatic failover
- Patching and security updates required
- Higher total cost of ownership
- Against cloud-native principles

### 5. Third-Party Database Services
**Rejected because:**
- Additional vendor dependency
- Network latency to external services
- Security and compliance concerns
- Less integration with AWS services
- Potentially higher costs

## Implementation Details

### Database Instance Specifications
```yaml
RDS MySQL Primary:
  Engine: MySQL 8.0.35
  Instance: db.t3.micro (development)
  Storage: 20GB gp3 (3000 IOPS)
  Multi-AZ: Enabled
  Encryption: AWS managed keys
  
Aurora Serverless v2:
  Engine: aurora-mysql (8.0 compatible)
  Min Capacity: 0.5 ACU
  Max Capacity: 1 ACU
  Auto-pause: 5 minutes idle
  
DynamoDB:
  Billing: On-demand
  Consistency: Eventually consistent (default)
  Global Tables: us-east-1, us-west-2
  
ElastiCache Redis:
  Engine: Redis 7.0
  Node Type: cache.t3.micro
  Replicas: 1
  Cluster Mode: Disabled
```

### Data Flow Patterns
```
User Session:
  Request → Application → DynamoDB (sub-ms lookup)
  
Cached Query:
  Request → Application → Redis (cache hit) → Response
  Request → Application → Redis (cache miss) → RDS → Redis → Response
  
Transactional Write:
  Request → Application → RDS Primary → Response
                            └→ Async replication to replicas
  
Analytics Query:
  Request → Application → Aurora Serverless → Response
                            (auto-scales with query complexity)
```

## Implementation Timeline

### Phase 1: Core Database Infrastructure (Week 1-2)
- [ ] Create DB subnet groups in private data subnets
- [ ] Configure security groups for database access
- [ ] Deploy RDS MySQL Multi-AZ instance
- [ ] Enable automated backups and encryption

### Phase 2: Read Scaling and Caching (Week 2-3)
- [ ] Create regional read replicas
- [ ] Deploy ElastiCache Redis cluster
- [ ] Configure application connection routing
- [ ] Implement cache invalidation patterns

### Phase 3: NoSQL and Serverless (Week 3-4)
- [ ] Deploy DynamoDB table with global tables
- [ ] Configure Aurora Serverless v2 cluster
- [ ] Implement session management integration
- [ ] Set up cross-region replication

### Phase 4: Monitoring and Optimization (Week 4)
- [ ] Configure Performance Insights
- [ ] Create CloudWatch dashboards
- [ ] Set up alerting thresholds
- [ ] Document access patterns and runbooks

**Total Implementation Time:** 4 weeks

## Related Implementation
This decision was implemented in [Lab 5: RDS & Database Services](../../labs/lab-05-rds/README.md), which includes:
- Multi-AZ RDS MySQL deployment
- Read replica configuration
- DynamoDB global table setup
- ElastiCache Redis cluster
- Aurora Serverless v2 deployment

## Success Metrics
- **Availability**: 99.95% database uptime
- **Performance**: <10ms p99 for transactional queries
- **Session Latency**: <5ms p99 for DynamoDB operations
- **Cache Hit Rate**: >80% for frequently accessed data
- **Cost Efficiency**: <$150/month for development infrastructure

## Review Date
2026-06-22 (6 months) - Evaluate scaling patterns and cost optimization opportunities

## References
- [AWS Database Selection Guide](https://aws.amazon.com/products/databases/)
- [RDS Multi-AZ Deployments](https://aws.amazon.com/rds/features/multi-az/)
- [DynamoDB Best Practices](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/best-practices.html)
- [ElastiCache for Redis](https://aws.amazon.com/elasticache/redis/)
- [Aurora Serverless v2](https://aws.amazon.com/rds/aurora/serverless/)

## Appendix: Database Selection Decision Matrix

| Criteria (Weight) | RDS MySQL | Aurora Serverless | DynamoDB | ElastiCache |
|-------------------|-----------|-------------------|----------|-------------|
| ACID Support (20%) | 5 | 5 | 2 | 1 |
| Query Flexibility (15%) | 5 | 5 | 2 | 1 |
| Latency (20%) | 3 | 3 | 5 | 5 |
| Auto-Scaling (15%) | 2 | 5 | 5 | 2 |
| Operational Overhead (15%) | 3 | 4 | 5 | 3 |
| Cost at Current Scale (15%) | 4 | 4 | 3 | 4 |
| **Weighted Score** | **3.6** | **4.2** | **3.7** | **2.9** |

*Scores: 1=Poor, 5=Excellent. Each database selected for its highest-scoring use case.*

---

*This decision will be revisited if:*
- Transaction volumes exceed 10,000 TPS consistently
- DynamoDB costs exceed RDS for similar workloads
- New database services offer better price/performance
- Application patterns shift significantly from current design
