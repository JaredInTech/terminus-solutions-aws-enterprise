
<!--
Terminus Solutions AWS Enterprise Architecture
Copyright (c) 2025 Jared (Terminus Solutions) - jaredintech.com
Licensed under CC BY-SA 4.0 - Attribution required
See LICENSE-DOCS for details
-->

# ADR-004: Multi-Region DR Network Design

## Date
2025-12-01

## Status
Accepted

## Context
With our network segmentation architecture defined (ADR-003), Terminus Solutions needs to establish network connectivity between our primary region (us-east-1) and disaster recovery region (us-west-2). This decision is critical for enabling database replication, application failover, and maintaining business continuity with our target RTO of 4 hours and RPO of 1 hour.

Key requirements and constraints:
- Must support cross-region RDS read replica replication
- Need secure, private connectivity (no internet traversal)
- Require <100ms latency for database replication
- Support future application-level data synchronization
- Budget conscious - avoid unnecessary ongoing costs
- Current scale: 2 regions (may expand to 4-5 regions within 2 years)
- Must maintain network isolation between environments
- Support bidirectional communication for failover scenarios
- Enable Route 53 health checks across regions

Business context:
- 99.9% uptime SLA requires multi-region capability
- Compliance requires data residency in multiple geographic locations
- Cost sensitivity: DR can use smaller resources but network must be ready
- Team size: 15 people (limited operational overhead tolerance)

## Decision
We will implement VPC Peering for cross-region connectivity between Production (us-east-1) and DR (us-west-2) regions.

**Architecture:**
- Point-to-point VPC peering connection
- Full mesh not required (only 2 regions currently)
- DNS resolution enabled for cross-region name resolution
- Routing tables updated in both VPCs
- Security groups use CIDR blocks (not SG references across regions)

**Connection Details:**
```
Production VPC (10.0.0.0/16) <--Peering--> DR VPC (10.1.0.0/16)
Connection: Encrypted over AWS backbone
Bandwidth: No artificial limits
Cost: $0.02/GB data transfer
```

## Consequences

### Positive
- **Simplicity**: Direct connection, easy to understand and troubleshoot
- **Cost Effective**: No hourly charges, only data transfer costs
- **Performance**: Uses AWS backbone, typically <70ms coast-to-coast
- **Security**: Traffic never traverses internet, encrypted by default
- **Reliability**: No single point of failure, AWS-managed service
- **Quick Setup**: Can be established in minutes
- **No Bandwidth Limits**: Scales with application needs

### Negative
- **No Transitive Routing**: Cannot route through one VPC to reach another
- **Limited to 2 Regions**: Would need mesh topology for more regions
- **CIDR Management**: Must use IP addresses in security groups
- **Manual Routes**: Route tables must be updated manually
- **Future Refactoring**: May need to migrate to Transit Gateway later

### Mitigation Strategies
- **Documentation**: Maintain clear network diagrams showing peering
- **Automation**: Use IaC to manage route table updates
- **Planning**: Reserve Transit Gateway CIDR space for future
- **Monitoring**: Set up CloudWatch metrics for peering connection

## Alternatives Considered

### 1. AWS Transit Gateway
**Rejected because:**
- Overkill for 2 regions ($0.05/hour + $0.02/GB vs $0.02/GB only)
- Additional ~$73/month in hourly charges
- Added complexity not justified at current scale
- 10-20ms additional latency
- Can migrate to this when we have 4+ regions

### 2. VPN Over Internet
**Rejected because:**
- Security concerns with internet traversal
- Variable latency and bandwidth
- Complex key management
- IPSec overhead reduces throughput
- Not suitable for production database replication

### 3. AWS Direct Connect
**Rejected because:**
- Extremely expensive for DR use case
- Long provisioning time (weeks to months)
- Requires physical infrastructure commitment
- Overkill for current bandwidth needs
- Better suited for hybrid cloud

### 4. Application-Level Replication Only
**Rejected because:**
- Misses infrastructure-level connectivity needs
- Cannot use native RDS read replicas
- Requires custom application logic
- Higher RPO than required
- More complex failover procedures

### 5. No DR Connectivity (Cold DR)
**Rejected because:**
- Cannot meet 4-hour RTO requirement
- No continuous data replication
- Requires full backup/restore for failover
- Unacceptable RPO for business needs
- Does not demonstrate enterprise practices

## Implementation Details

### VPC Peering Configuration
```yaml
Peering Connection:
  Name: Terminus-Production-DR-Peering
  Requester VPC: vpc-xxxxx (DR VPC in us-west-2)
  Accepter VPC: vpc-yyyyy (Production VPC in us-east-1)
  DNS Resolution: Enabled bidirectionally
  Status: Active
```

### Route Table Updates
**Production VPC Routes:**
- Add: 10.1.0.0/16 → pcx-xxxxx (all route tables)

**DR VPC Routes:**
- Add: 10.0.0.0/16 → pcx-xxxxx (all route tables)

### Security Group Modifications
```yaml
Production Database SG:
  - Add inbound MySQL (3306) from 10.1.11.0/24 (DR app subnet)
  - Add inbound MySQL (3306) from 10.1.12.0/24 (DR app subnet)

DR Database SG:
  - Add inbound MySQL (3306) from 10.0.11.0/24 (Prod app subnet)
  - Add inbound MySQL (3306) from 10.0.12.0/24 (Prod app subnet)
```

### Cost Analysis
```
Monthly Costs (Estimated):
- VPC Peering: $0 (no hourly charges)
- Data Transfer: ~$20/month (assuming 1TB replication)
- Total: $20/month

Compared to Transit Gateway:
- TGW Hourly: $73/month (2 attachments)
- Data Transfer: $20/month
- Total: $93/month
- Savings: $73/month (78% lower)
```

## Implementation Timeline

### Phase 1: Planning (Day 1)
- [x] Document connectivity requirements
- [x] Validate non-overlapping CIDRs
- [x] Plan security group changes
- [x] Review with security team

### Phase 2: Peering Setup (Day 2)
- [x] Create peering connection from DR region
- [x] Accept peering in production region
- [x] Enable DNS resolution settings
- [x] Verify connection status

### Phase 3: Routing Configuration (Day 2)
- [x] Update production route tables
- [x] Update DR route tables
- [x] Test basic connectivity (ping)
- [x] Document routing changes

### Phase 4: Security and Testing (Day 3)
- [x] Update security groups for cross-region
- [x] Test database connectivity
- [x] Validate encryption in transit
- [x] Run failover drill

**Total Implementation Time:** 3 days (completed in 30 minutes during lab)

## Related Implementation
This decision was implemented in [Lab 2: VPC & Networking Core](../../labs/lab-02-vpc/README.md), which includes:
- Step-by-step VPC peering creation
- Route table configuration for both regions
- Security group updates for cross-region access
- Connectivity testing procedures
- Troubleshooting guide
- Cost optimization strategies

## Success Metrics
- **Connectivity**: 100% packet success rate ✅
- **Latency**: <70ms cross-region (actual: 67ms) ✅
- **Availability**: 100% uptime since implementation ✅
- **Cost**: <$25/month (actual: ~$5/month) ✅
- **Setup Time**: <1 hour (actual: 30 minutes) ✅

## Review Date
2026-06-01 (6 months) - Evaluate if Transit Gateway needed

## References
- [AWS VPC Peering Guide](https://docs.aws.amazon.com/vpc/latest/peering/what-is-vpc-peering.html)
- [AWS Transit Gateway Comparison](https://docs.aws.amazon.com/whitepapers/latest/aws-vpc-connectivity-options/aws-transit-gateway.html)
- [Cross-Region Replication Best Practices](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_ReadRepl.html)
- **Implementation**: [Lab 2: VPC & Networking Core](../../labs/lab-02-vpc/README.md)

## Appendix: Connectivity Options Comparison

| Feature | VPC Peering (Chosen) | Transit Gateway | VPN | Direct Connect | No Connection |
|---------|---------------------|-----------------|-----|----------------|---------------|
| Setup Complexity | ✅ Low | 🟡 Medium | 🟡 Medium | ❌ High | ✅ None |
| Ongoing Cost | ✅ None | ❌ $73/month | 🟡 $36/month | ❌ $500+/month | ✅ None |
| Latency | ✅ Native | 🟡 +10-20ms | 🟡 Variable | ✅ Best | ❌ N/A |
| Bandwidth | ✅ Unlimited | ✅ Unlimited | 🟡 1.25Gbps | ✅ 10Gbps+ | ❌ None |
| Reliability | ✅ High | ✅ High | 🟡 Medium | ✅ Highest | ❌ None |
| Scalability | 🟡 125 VPCs | ✅ 5000 VPCs | 🟡 Limited | 🟡 Limited | ❌ None |

### Future Migration Path
```
Current State (2 regions):
  Production VPC <--Peering--> DR VPC
  Monthly Cost: $20

Future State (4+ regions):
  All VPCs <---> Transit Gateway <---> All VPCs
  Monthly Cost: ~$180
  Migration Trigger: When peering mesh becomes complex
```

### DR Activation Procedures
1. **Health Check Failure**: Route 53 detects production failure
2. **DNS Update**: Route 53 updates records to DR endpoints
3. **Database Promotion**: RDS read replica promoted to master
4. **Application Scaling**: Auto Scaling groups in DR region activate
5. **Verification**: Synthetic monitors confirm DR functionality

---

*This decision will be revisited if:*
- We expand beyond 3 regions (mesh complexity)
- Monthly data transfer exceeds $100 (TGW may be cost-effective)
- We need transitive routing for shared services
- AWS significantly reduces Transit Gateway pricing