
<!--
Terminus Solutions AWS Enterprise Architecture
Copyright (c) 2025 Jared (Terminus Solutions) - jaredintech.com
Licensed under CC BY-SA 4.0 - Attribution required
See LICENSE-DOCS for details
-->

# ADR-003: Network Segmentation Architecture

## Date
2025-12-01

## Status
Accepted

## Context
With our CIDR allocation strategy defined (ADR-002), Terminus Solutions needs to determine how to segment our VPC networks internally. This decision affects security posture, application performance, operational complexity, and cost. Poor segmentation design could lead to security breaches, compliance failures, or unnecessary complexity.

Key requirements and constraints:
- Must support three-tier web application architecture
- Need to isolate database tier from direct internet access
- Require clear security boundaries for compliance (future SOC2, HIPAA)
- Support both containerized and traditional EC2 workloads
- Enable high availability across multiple availability zones
- Minimize data transfer costs while maintaining security
- Must accommodate future growth without re-architecture
- Support disaster recovery with identical structure in DR region
- Allow for future addition of specialized subnets (Lambda, containers)

Current application architecture needs:
- Public-facing load balancers
- Private application servers (web/app tier)
- Isolated database instances (RDS, ElastiCache)
- Outbound internet access for updates/API calls
- No direct internet access for databases

## Decision
We will implement a three-tier network segmentation model with dedicated subnets per tier, per availability zone:

**Tier 1 - Public Subnets (DMZ)**
- Purpose: Internet-facing components only
- Components: Application Load Balancers, NAT Gateways, future Bastion hosts
- Internet: Bidirectional via Internet Gateway
- Size: /24 per AZ (251 usable IPs)

**Tier 2 - Private Application Subnets**
- Purpose: Application compute layer
- Components: EC2 instances, ECS tasks, Lambda (VPC-attached)
- Internet: Outbound only via NAT Gateway
- Size: /24 per AZ (251 usable IPs)

**Tier 3 - Private Data Subnets**
- Purpose: Data persistence layer
- Components: RDS instances, ElastiCache clusters, EFS
- Internet: No routes to internet (complete isolation)
- Size: /24 per AZ (251 usable IPs)

**Subnet Allocation Pattern (per VPC):**
```
Public Tier:    10.x.1-10.0/24   (reserved for up to 10 public subnets)
Application:    10.x.11-20.0/24  (reserved for up to 10 app subnets)
Data Tier:      10.x.21-30.0/24  (reserved for up to 10 data subnets)
Future Use:     10.x.31-255.0/24 (224 subnets for expansion)
```

## Consequences

### Positive
- **Security Isolation**: Database tier completely isolated from internet
- **Compliance Ready**: Clear network boundaries for audit and compliance
- **Cost Optimization**: Same-tier traffic within AZ is free
- **Scalability**: Room for 10 subnets per tier (supports up to 5 AZs)
- **Operational Clarity**: Tier purpose immediately clear from IP address
- **DR Simplicity**: Identical structure simplifies failover procedures
- **Defense in Depth**: Multiple network layers between internet and data

### Negative
- **Complexity**: Three tiers require more route tables and NACLs
- **IP Usage**: May waste IPs in smaller tiers (data tier often needs fewer)
- **Management Overhead**: More subnets to manage and monitor
- **Cross-Tier Latency**: Potential microseconds added for tier traversal
- **NAT Gateway Costs**: Required for private subnet internet access

### Mitigation Strategies
- **Automation**: Use Infrastructure as Code to manage complexity
- **Monitoring**: Set up VPC Flow Logs to understand traffic patterns
- **Documentation**: Maintain clear network diagrams and runbooks
- **Right-sizing**: Start with /24, can subnet further if needed

## Alternatives Considered

### 1. Two-Tier Architecture (Public/Private)
**Rejected because:**
- Insufficient isolation between application and database
- Single private subnet hosts both compute and data
- Harder to implement least-privilege security
- Common security group for diverse resources
- Industry best practice is three-tier

### 2. Four-Tier Architecture (Adding separate Web/App tiers)
**Rejected because:**
- Unnecessary complexity for current scale
- Marginal security benefit over three-tier
- More NAT Gateway traversals (higher cost)
- Harder to understand and troubleshoot
- Can evolve to this if needed later

### 3. Microsubnet Design (One subnet per service)
**Rejected because:**
- Excessive operational overhead
- Complex routing table management
- Difficult to maintain at current team size
- Wastes IP addresses (AWS reserves 5 per subnet)
- Better suited for very large organizations

### 4. Single Private Subnet with Security Groups Only
**Rejected because:**
- Relies solely on security groups for isolation
- No defense in depth
- Cannot enforce subnet-level routing policies
- Difficult to implement network flow restrictions
- Does not meet compliance requirements

### 5. AZ-Independent Design (Tier spans all AZs)
**Rejected because:**
- Reduces fault isolation
- Complicates IP management
- Harder to track cross-AZ data transfer costs
- Less granular control over routing
- Against AWS best practices

## Implementation Details

### Subnet Naming Convention
```
Terminus-[Environment]-[Tier]-[AZ]
Examples:
- Terminus-Production-Public-1A
- Terminus-Production-Private-App-1B
- Terminus-DR-Private-Data-2A
```

### Route Table Strategy
- **Public Subnets**: Direct route to Internet Gateway
- **Application Subnets**: Default route to NAT Gateway in same AZ
- **Data Subnets**: Local routes only (no internet route)

### Network ACL Strategy
- **Public NACL**: Allow HTTP/S inbound, ephemeral outbound
- **Application NACL**: Allow from public subnets, restrict outbound
- **Data NACL**: Allow only from application subnets on DB ports

### High Availability Design
- Minimum 2 AZs per region (supports AZ failure)
- Identical subnet structure in each AZ
- Resources distributed across AZs
- NAT Gateway per AZ for redundancy

## Implementation Timeline

### Phase 1: Design Documentation (Day 1)
- [x] Document three-tier architecture
- [x] Create subnet allocation spreadsheet
- [x] Design security boundaries
- [x] Review with security team

### Phase 2: Production VPC Implementation (Day 2)
- [x] Create public subnets in 2 AZs
- [x] Create private application subnets
- [x] Create private data subnets
- [x] Configure route tables per tier

### Phase 3: Security Implementation (Day 3)
- [x] Create tier-specific NACLs
- [x] Configure security group templates
- [x] Set up VPC Flow Logs
- [x] Test network isolation

### Phase 4: DR Region Replication (Day 4)
- [x] Replicate subnet structure in us-west-2
- [x] Ensure consistent naming
- [x] Validate IP addressing
- [x] Test cross-region connectivity

**Total Implementation Time:** 4 days (completed in 4 hours during lab)

## Related Implementation
This decision was implemented in [Lab 2: VPC & Networking Core](../../labs/lab-02-vpc/README.md), which includes:
- Detailed subnet creation steps
- Route table configuration per tier
- Security group and NACL implementation
- Network isolation testing procedures
- Traffic flow diagrams
- Troubleshooting guide

## Success Metrics
- **Isolation**: Zero database tier internet exposure ✅
- **Availability**: 99.99% subnet availability ✅ (no issues in testing)
- **Performance**: <1ms added latency between tiers ✅
- **Cost**: <$50/month NAT Gateway costs per region ✅
- **Clarity**: 100% team understanding of tier purposes ✅

## Review Date
2026-06-01 (6 months) - Evaluate if three tiers still meet needs

## References
- [AWS Three-Tier Architecture](https://docs.aws.amazon.com/whitepapers/latest/serverless-multi-tier-architectures/three-tier-architecture-overview.html)
- [AWS Network Security Best Practices](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-best-practices.html)
- [NIST Special Publication 800-125B](https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-125B.pdf)
- **Implementation**: [Lab 2: VPC & Networking Core](../../labs/lab-02-vpc/README.md)

## Appendix: Decision Matrix

| Criteria | 2-Tier | 3-Tier (Chosen) | 4-Tier | Microsubnets | Single Subnet |
|----------|---------|-----------------|---------|--------------|---------------|
| Security | 🟡 Fair | ✅ Good | ✅ Excellent | ✅ Excellent | ❌ Poor |
| Complexity | ✅ Low | ✅ Medium | 🟡 High | ❌ Very High | ✅ Very Low |
| Scalability | 🟡 Fair | ✅ Good | ✅ Good | ✅ Excellent | ❌ Poor |
| Cost | ✅ Low | ✅ Medium | 🟡 Higher | ❌ High | ✅ Lowest |
| Compliance | ❌ Poor | ✅ Good | ✅ Excellent | ✅ Excellent | ❌ Poor |
| Team Fit | 🟡 Maybe | ✅ Yes | ❌ No | ❌ No | ❌ No |

### Tier Comparison Details

| Aspect | Public Tier | Application Tier | Data Tier |
|--------|-------------|------------------|-----------|
| Internet Access | Bidirectional | Outbound only | None |
| Primary Components | ALB, NAT GW | EC2, ECS, Lambda | RDS, ElastiCache |
| Security Focus | DDoS protection | App isolation | Data protection |
| Route Complexity | Simple (IGW) | Medium (NAT) | Simple (Local) |
| Typical Utilization | Low (10-20%) | High (60-80%) | Medium (40-50%) |

---

*This decision will be revisited if:*
- Application architecture shifts to microservices
- Compliance requirements demand additional isolation
- Container orchestration needs dedicated networking
- Team grows beyond 100 people requiring per-team isolation