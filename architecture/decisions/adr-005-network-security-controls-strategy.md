
<!--
Terminus Solutions AWS Enterprise Architecture
Copyright (c) 2025 Jared (Terminus Solutions) - jaredintech.com
Licensed under CC BY-SA 4.0 - Attribution required
See LICENSE-DOCS for details
-->

# ADR-005: Network Security Controls Strategy

## Date
2025-12-01

## Status
Accepted

## Context
With our three-tier network architecture established (ADR-003) and cross-region connectivity defined (ADR-004), Terminus Solutions needs to implement comprehensive network security controls. This decision determines how we'll protect our infrastructure from threats while maintaining operational flexibility and meeting compliance requirements.

Key requirements and constraints:
- Must implement defense-in-depth security strategy
- Need to protect against common attacks (DDoS, port scanning, unauthorized access)
- Require detailed audit trails for security incidents
- Support developer productivity without compromising security
- Future compliance requirements (SOC2, HIPAA) demand network monitoring
- Limited security team - controls must be manageable
- Must distinguish between subnet-level and instance-level controls
- Balance security with performance and cost
- Need visibility into all network traffic for troubleshooting

Current security challenges:
- Stateful vs stateless rule management complexity
- Cross-region security group limitations
- Ephemeral port handling for return traffic
- East-west traffic control between tiers
- Audit and compliance logging requirements

## Decision
We will implement a layered network security strategy using both Network ACLs (subnet-level) and Security Groups (instance-level), complemented by VPC Flow Logs for monitoring.

**Security Layers:**
1. **Network ACLs** - Stateless subnet perimeter defense
2. **Security Groups** - Stateful instance-level protection  
3. **VPC Flow Logs** - Comprehensive traffic monitoring
4. **Route Tables** - Traffic flow control (implicit security)

**Implementation Strategy:**
```
Internet → [NACL] → [Security Group] → Instance
   ↓          ↓            ↓              ↓
Coarse    Subnet      Instance      Application
Filter    Defense      Defense        Level
```

**Key Design Principles:**
- Default deny with explicit allow rules
- Least privilege access between tiers
- Security group chaining using references (not IPs)
- Stateless rules for subnet boundaries
- Comprehensive logging of all traffic

## Consequences

### Positive
- **Defense in Depth**: Multiple security layers protect against breaches
- **Granular Control**: Can apply different policies at subnet and instance levels
- **Compliance Ready**: Flow logs provide complete audit trail
- **Flexibility**: Security groups can reference each other dynamically
- **Performance**: NACLs process at line rate with no performance impact
- **Troubleshooting**: Flow logs enable rapid issue diagnosis
- **Scalability**: Security group references auto-update with scaling

### Negative
- **Complexity**: Two different security models to understand
- **Ephemeral Ports**: NACL stateless nature requires explicit return rules
- **Rule Limits**: 60 inbound + 60 outbound rules per security group
- **Cross-Region Limitations**: Cannot reference SGs across regions
- **Flow Log Costs**: CloudWatch storage and analysis charges
- **Learning Curve**: Team must understand stateful vs stateless

### Mitigation Strategies
- **Documentation**: Create clear traffic flow diagrams
- **Automation**: Use IaC to manage rule consistency
- **Training**: Include security controls in onboarding
- **Monitoring**: Alert on rule changes and anomalies
- **Templates**: Pre-built security group patterns

## Alternatives Considered

### 1. Security Groups Only (No NACLs)
**Rejected because:**
- Single layer of defense insufficient
- No subnet-level isolation
- Cannot block traffic before it reaches instances
- Less granular audit controls
- Doesn't meet defense-in-depth requirements

### 2. NACLs Only (No Security Groups)
**Rejected because:**
- Stateless rules too complex for applications
- No dynamic instance grouping
- Cannot use security group references
- Extremely difficult ephemeral port management
- Poor developer experience

### 3. Third-Party Firewall Appliances
**Rejected because:**
- Additional cost ($1000+/month)
- Single point of failure
- Performance bottleneck
- Complexity for current team size
- Native AWS controls sufficient

### 4. AWS Network Firewall
**Rejected because:**
- Overkill for current requirements
- Expensive (~$395/month + processing)
- Additional complexity
- Can add later if needed
- Current controls meet compliance needs

### 5. Single Security Layer (Simplified)
**Rejected because:**
- Insufficient for production workloads
- No defense against subnet-level attacks
- Cannot demonstrate enterprise practices
- Fails compliance requirements
- No proper network segmentation

## Implementation Details

### Network ACL Configuration

**Public Subnet NACL:**
```yaml
Inbound Rules:
  100: HTTP (80) from 0.0.0.0/0 - ALLOW
  110: HTTPS (443) from 0.0.0.0/0 - ALLOW
  120: SSH (22) from Admin-IP/32 - ALLOW
  130: Ephemeral (1024-65535) from 0.0.0.0/0 - ALLOW
  *: All Traffic - DENY

Outbound Rules:
  100: HTTP (80) to 0.0.0.0/0 - ALLOW
  110: HTTPS (443) to 0.0.0.0/0 - ALLOW
  120: All Traffic to 10.0.0.0/16 - ALLOW
  130: Ephemeral (1024-65535) to 0.0.0.0/0 - ALLOW
  *: All Traffic - DENY
```

**Application Subnet NACL:**
```yaml
Inbound Rules:
  100: HTTP (80) from 10.0.1.0/24 - ALLOW
  110: HTTP (80) from 10.0.2.0/24 - ALLOW
  120: HTTPS (443) from 10.0.1.0/24 - ALLOW
  130: HTTPS (443) from 10.0.2.0/24 - ALLOW
  140: Ephemeral (1024-65535) from 0.0.0.0/0 - ALLOW
  *: All Traffic - DENY

Outbound Rules:
  100: MySQL (3306) to 10.0.21.0/24 - ALLOW
  110: MySQL (3306) to 10.0.22.0/24 - ALLOW
  120: HTTP (80) to 0.0.0.0/0 - ALLOW
  130: HTTPS (443) to 0.0.0.0/0 - ALLOW
  140: Ephemeral (1024-65535) to 0.0.0.0/0 - ALLOW
  *: All Traffic - DENY
```

**Data Subnet NACL:**
```yaml
Inbound Rules:
  100: MySQL (3306) from 10.0.11.0/24 - ALLOW
  110: MySQL (3306) from 10.0.12.0/24 - ALLOW
  120: Ephemeral (1024-65535) from 10.0.11.0/24 - ALLOW
  130: Ephemeral (1024-65535) from 10.0.12.0/24 - ALLOW
  *: All Traffic - DENY

Outbound Rules:
  100: Ephemeral (1024-65535) to 10.0.11.0/24 - ALLOW
  110: Ephemeral (1024-65535) to 10.0.12.0/24 - ALLOW
  *: All Traffic - DENY
```

### Security Group Configuration

**ALB Security Group:**
```yaml
Name: Terminus-ALB-SG
Inbound:
  - HTTP (80) from 0.0.0.0/0
  - HTTPS (443) from 0.0.0.0/0
Outbound:
  - HTTP (80) to Terminus-WebTier-SG
```

**Web Tier Security Group:**
```yaml
Name: Terminus-WebTier-SG
Inbound:
  - HTTP (80) from Terminus-ALB-SG
  - HTTPS (443) from Terminus-ALB-SG
  - SSH (22) from Terminus-Bastion-SG
Outbound:
  - HTTPS (443) to 0.0.0.0/0 (for updates)
  - MySQL (3306) to Terminus-Database-SG
```

**Database Security Group:**
```yaml
Name: Terminus-Database-SG
Inbound:
  - MySQL (3306) from Terminus-WebTier-SG
  - MySQL (3306) from 10.1.11.0/24 (DR replication)
Outbound:
  - None (databases don't initiate connections)
```

### VPC Flow Logs Configuration
```yaml
Configuration:
  Filter: ALL (Accept, Reject, and All)
  Destination: CloudWatch Logs
  Log Group: /aws/vpc/flowlogs/terminus-production
  Retention: 90 days
  Format: Default AWS format
  
Monitoring Queries:
  - Top rejected connections
  - Unusual port scanning
  - High volume transfers
  - Cross-AZ traffic analysis
```

### Rule Numbering Strategy
```
NACL Rules:
  100-199: Critical application traffic
  200-299: Management traffic
  300-399: Monitoring and logging
  400-499: Future use
  500-599: Ephemeral ports
  
Leave gaps of 10 for future insertions
```

## Implementation Timeline

### Phase 1: NACL Implementation (Day 1)
- [x] Create custom NACLs per tier
- [x] Configure inbound rules
- [x] Configure outbound rules with ephemeral ports
- [x] Associate with appropriate subnets

### Phase 2: Security Group Setup (Day 2)
- [x] Create security groups per tier
- [x] Implement security group chaining
- [x] Configure least-privilege rules
- [x] Test connectivity between tiers

### Phase 3: Flow Logs Activation (Day 3)
- [x] Create CloudWatch log groups
- [x] Configure VPC Flow Logs
- [x] Set retention policies
- [x] Create initial monitoring queries

### Phase 4: Testing and Validation (Day 4)
- [x] Test positive scenarios (allowed traffic)
- [x] Test negative scenarios (blocked traffic)
- [x] Validate flow log capture
- [x] Document traffic patterns

**Total Implementation Time:** 4 days (completed in 2 hours during lab)

## Related Implementation
This decision was implemented in [Lab 2: VPC & Networking Core](../../labs/lab-02-vpc/README.md), which includes:
- Detailed NACL rule configuration
- Security group creation and chaining
- Flow log setup and queries
- Traffic flow testing procedures
- Troubleshooting guide
- Common security patterns

## Success Metrics
- **Security Incidents**: Zero breaches ✅
- **False Positives**: <5% blocked legitimate traffic ✅
- **Audit Coverage**: 100% traffic logged ✅
- **Rule Complexity**: <50 rules per NACL ✅ (actual: ~15)
- **Performance Impact**: <1ms latency added ✅

## Review Date
2026-03-01 (3 months) - Review rule effectiveness and optimize

## References
- [AWS Security Best Practices](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-best-practices.html)
- [Security Group vs NACL Comparison](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Security.html)
- [VPC Flow Logs Guide](https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs.html)
- **Implementation**: [Lab 2: VPC & Networking Core](../../labs/lab-02-vpc/README.md)

## Appendix: Security Control Comparison

| Feature | Security Groups | Network ACLs | VPC Flow Logs |
|---------|----------------|--------------|---------------|
| Scope | Instance level | Subnet level | VPC level |
| State | Stateful | Stateless | N/A |
| Rules | Allow only | Allow + Deny | N/A |
| Evaluation | All rules | First match | All traffic |
| Default | Deny all inbound | Allow all | No logging |
| Performance | No impact | Line rate | Storage costs |

### Common Attack Mitigation

| Attack Type | NACL Defense | Security Group Defense | Flow Log Detection |
|-------------|--------------|------------------------|-------------------|
| Port Scanning | Deny unused ports | Default deny all | Rejected connections |
| DDoS | Rate limiting (limited) | Connection limits | Traffic spikes |
| Lateral Movement | Subnet isolation | SG references | Unusual patterns |
| Data Exfiltration | Restrict outbound | Limit destinations | Large transfers |

### Troubleshooting Decision Tree
```
Connection Failed?
├── Check Security Group rules
│   ├── Source allowed?
│   ├── Port allowed?
│   └── Protocol correct?
├── Check NACL rules
│   ├── Inbound allowed?
│   ├── Outbound allowed?
│   └── Ephemeral ports configured?
├── Check Route Tables
│   └── Route exists to destination?
└── Check Flow Logs
    └── Traffic rejected? Where?
```

---

*This decision will be revisited if:*
- Security incidents indicate gaps in controls
- Compliance requirements change (PCI-DSS, HIPAA)
- AWS releases new security features
- Performance impacts become noticeable