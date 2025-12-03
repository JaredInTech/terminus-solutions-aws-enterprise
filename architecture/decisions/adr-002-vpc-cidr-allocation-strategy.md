
<!--
Terminus Solutions AWS Enterprise Architecture
Copyright (c) 2025 Jared (Terminus Solutions) - jaredintech.com
Licensed under CC BY-SA 4.0 - Attribution required
See LICENSE-DOCS for details
-->

# ADR-002: VPC CIDR Allocation Strategy

## Date
2025-12-01

## Status
Accepted

## Context
Following the establishment of our multi-account structure (ADR-001), Terminus Solutions needs a comprehensive IP addressing strategy for our VPC infrastructure. This decision is critical as CIDR blocks cannot be modified after VPC creation, and poor planning could require complete network re-architecture.

Key requirements and constraints:
- Must support multi-region deployment (us-east-1 production, us-west-2 DR initially)
- Need non-overlapping IP ranges for VPC peering between regions
- Require space for development, staging, and production environments
- Future requirement: On-premises connectivity via VPN/Direct Connect
- Team size: Currently 15 people, expected to grow to 50+ within 18 months
- Must accommodate containerized workloads that consume IPs rapidly
- Budget conscious - avoid IP address waste while maintaining flexibility
- Future requirement: Potential expansion to EU and APAC regions
- Must support three-tier architecture (public, application, data) per VPC

## Decision
We will implement a hierarchical CIDR allocation strategy using the 10.0.0.0/8 private address space:

**Global Strategy:**
- **10.0.0.0/12** - North America region pool (1,048,576 IPs)
  - 10.0.0.0/16 - us-east-1 Production
  - 10.1.0.0/16 - us-west-2 DR
  - 10.2.0.0/16 - Development
  - 10.3.0.0/16 - Staging
- **10.16.0.0/12** - Europe region pool (reserved)
- **10.32.0.0/12** - Asia-Pacific region pool (reserved)
- **172.16.0.0/12** - Reserved for on-premises networks
- **192.168.0.0/16** - Reserved for home office/VPN connections

**Per-VPC Allocation (/16 = 65,536 IPs):**
- 10.x.1-2.0/24 - Public subnets (DMZ)
- 10.x.11-20.0/24 - Private application subnets
- 10.x.21-30.0/24 - Private data subnets
- 10.x.31-255.0/24 - Reserved for future expansion

## Consequences

### Positive
- **No IP Conflicts**: Guaranteed unique addressing enables any-to-any VPC peering
- **Predictable Growth**: Clear allocation pattern for new regions and environments
- **Simple Troubleshooting**: Consistent patterns (10.0 = prod, 10.1 = DR, 10.2 = dev)
- **Container Ready**: 65,536 IPs per VPC sufficient for EKS/ECS workloads
- **Hybrid Cloud Compatible**: On-premises can use 172.16.0.0/12 without conflicts
- **Cost Effective**: No need for additional CIDR blocks or complex NAT solutions
- **Compliance Friendly**: Clear network boundaries for audit scope

### Negative
- **IP Space Commitment**: Cannot use 10.0.0.0/8 for on-premises infrastructure
- **Initial Over-allocation**: 65,536 IPs per VPC may be excessive for early stages
- **Documentation Burden**: Must maintain accurate IP allocation records
- **Training Required**: Team needs to understand hierarchical addressing
- **Migration Complexity**: Any existing 10.x.x.x resources must be re-addressed

### Mitigation Strategies
- **Documentation**: Maintain IPAM spreadsheet and network diagrams in Git
- **Automation**: Use Infrastructure as Code to enforce CIDR standards
- **Training**: Include CIDR strategy in developer onboarding (< 30 minutes)
- **Monitoring**: CloudWatch alarms for subnet IP exhaustion (>80% usage)

## Alternatives Considered

### 1. Smaller VPC Sizes (/20 = 4,096 IPs)
**Rejected because:**
- Insufficient for container workloads (EKS nodes can consume 10+ IPs each)
- Would require secondary CIDR blocks within 12 months
- Limits to 16 subnets of /24 size
- Complicates capacity planning
- Minimal cost savings

### 2. Using 172.16.0.0/12 for AWS
**Rejected because:**
- Commonly used in corporate networks (conflicts likely)
- Would block future hybrid connectivity options
- Goes against AWS best practices
- Many VPN appliances default to this range

### 3. Random /16 Assignments per VPC
**Rejected because:**
- High risk of accidental overlaps
- No logical organization for troubleshooting
- Difficult to create firewall rules
- Impossible to maintain at scale
- No clear growth path

### 4. Single Large VPC with Account Isolation
**Rejected because:**
- Conflicts with multi-account strategy (ADR-001)
- Cannot implement account-specific networking policies
- Shared fate for network failures
- Exceeds blast radius requirements
- Poor alignment with compliance needs

### 5. RFC 1918 Mix (10.x for prod, 172.x for dev, 192.x for test)
**Rejected because:**
- Unnecessarily complex
- Wastes 192.168.0.0/16 (only 65K IPs)
- Requires different tooling per environment
- Complicates security group rules
- No clear benefit over hierarchical approach

## Implementation Details

### CIDR Allocation Registry
```
Production VPC (us-east-1): 10.0.0.0/16
├── Public Subnets
│   ├── 10.0.1.0/24 (us-east-1a) - 251 usable IPs
│   └── 10.0.2.0/24 (us-east-1b) - 251 usable IPs
├── Private App Subnets  
│   ├── 10.0.11.0/24 (us-east-1a) - 251 usable IPs
│   └── 10.0.12.0/24 (us-east-1b) - 251 usable IPs
└── Private Data Subnets
    ├── 10.0.21.0/24 (us-east-1a) - 251 usable IPs
    └── 10.0.22.0/24 (us-east-1b) - 251 usable IPs

DR VPC (us-west-2): 10.1.0.0/16
└── [Identical subnet structure with 10.1.x.x]
```

### Naming Convention
- VPCs: `Terminus-[Environment]-VPC`
- Subnets: `Terminus-[Environment]-[Tier]-[AZ]`
- Route Tables: `Terminus-[Environment]-[Tier]-RT-[AZ]`

### Subnet Sizing Rationale
**/24 chosen because:**
- 251 usable IPs sufficient for most workloads
- Easy mental math (last octet = host range)
- Allows 256 subnets per VPC
- Industry standard size
- Can aggregate if larger subnets needed

## Implementation Timeline

### Phase 1: Documentation (Week 1)
- [x] Document CIDR allocation strategy
- [x] Create IP allocation spreadsheet
- [x] Design three-tier subnet layout
- [x] Get team feedback on addressing scheme

### Phase 2: Production Implementation (Week 2)
- [x] Create Production VPC (10.0.0.0/16) in us-east-1
- [x] Configure 6 subnets across 2 AZs
- [x] Document subnet IDs and purposes
- [x] Validate no conflicts with existing resources

### Phase 3: DR Implementation (Week 2)
- [x] Create DR VPC (10.1.0.0/16) in us-west-2
- [x] Configure identical subnet structure
- [x] Establish VPC peering connection
- [x] Test cross-region connectivity

### Phase 4: Operationalization (Week 3)
- [x] Update developer runbooks with CIDR info
- [x] Create subnet selection guidelines
- [x] Configure IP exhaustion monitoring
- [ ] Conduct team training on IP allocation

**Total Implementation Time:** 3 weeks (completed in 4 hours during lab)

## Related Implementation
This decision was implemented in [Lab 2: VPC & Networking Core](../../labs/lab-02-vpc/README.md), which includes:
- Step-by-step VPC creation with chosen CIDR blocks
- Subnet configuration across availability zones
- VPC peering setup between regions
- Route table configuration for all tiers
- Testing procedures for IP connectivity
- Network diagrams showing CIDR layout

## Success Metrics
- **No IP Conflicts**: Zero peering failures due to overlaps ✅
- **Capacity**: <50% IP utilization in first year ✅ (currently <1%)
- **Flexibility**: Able to add new regions without re-architecture ✅
- **Performance**: No routing complexity impacting latency ✅
- **Understanding**: 100% of team can explain CIDR strategy ✅ (documented clearly)

## Review Date
2026-06-01 (6 months) - Evaluate IP utilization and growth patterns

## References
- [AWS VPC Sizing and IP Address Planning](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-sizing.html)
- [RFC 1918 - Address Allocation for Private Internets](https://tools.ietf.org/html/rfc1918)
- [AWS VPC Peering Requirements](https://docs.aws.amazon.com/vpc/latest/peering/vpc-peering-basics.html)
- **Implementation**: [Lab 2: VPC & Networking Core](../../labs/lab-02-vpc/README.md)

## Appendix: Decision Matrix

| Criteria | /20 VPCs | /16 VPCs (Chosen) | Random CIDRs | 172.16.0.0/12 | Mixed RFC 1918 |
|----------|----------|-------------------|--------------|----------------|----------------|
| Scalability | ❌ Poor | ✅ Excellent | ❌ Poor | ✅ Good | 🟡 Fair |
| Simplicity | ✅ Good | ✅ Excellent | ❌ Poor | ✅ Good | ❌ Poor |
| Container Support | ❌ Poor | ✅ Excellent | 🟡 Varies | ✅ Good | 🟡 Varies |
| Hybrid Cloud | ✅ Good | ✅ Excellent | ❌ Poor | ❌ Poor | 🟡 Fair |
| IP Efficiency | ✅ High | 🟡 Medium | 🟡 Varies | 🟡 Medium | ❌ Low |
| Team Fit | ❌ No | ✅ Yes | ❌ No | ❌ No | ❌ No |

---

*This decision will be revisited if:*
- IP utilization exceeds 70% in any VPC
- We need to support more than 16 regions
- AWS introduces significant VPC networking changes
- On-premises integration requirements change dramatically