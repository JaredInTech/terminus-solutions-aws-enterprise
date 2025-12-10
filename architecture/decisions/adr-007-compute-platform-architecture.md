
<!--
Terminus Solutions AWS Enterprise Architecture
Copyright (c) 2025 Jared (Terminus Solutions) - jaredintech.com
Licensed under CC BY-SA 4.0 - Attribution required
See LICENSE-DOCS for details
-->

# ADR-007: Compute Platform Architecture

## Date
2025-06-13

## Status
Accepted

## Context
With our network infrastructure established (ADR-002 through ADR-006), Terminus Solutions needs to design a scalable, reliable, and cost-effective compute platform. This decision determines our approach to EC2 instance deployment, scaling strategies, and operational management for both web and application tiers.

Key requirements and constraints:
- Must support variable traffic patterns with automatic scaling
- Need high availability across multiple availability zones
- Require rapid deployment and scaling (< 5 minutes)
- Support both stateless web servers and stateful application servers
- Enable zero-downtime deployments and updates
- Minimize costs while maintaining performance SLAs
- Integrate with existing VPC and security architecture
- Support future containerization migration path
- Limited operations team (automation is critical)

Current challenges:
- Unknown traffic patterns for new application
- Need to balance cost with performance
- Requirement for both burst capacity and sustained performance
- Complex application dependencies between tiers
- Compliance requirements for patching and updates

## Decision
We will implement a multi-tier compute architecture using EC2 Auto Scaling Groups with custom AMIs, advanced launch templates, and multi-dimensional scaling policies.

**Architecture Components:**
1. **Custom AMIs** for rapid, consistent deployments
2. **Launch Templates** with advanced EC2 features
3. **Auto Scaling Groups** per application tier
4. **Multi-policy scaling** approach
5. **Placement Groups** for performance optimization
6. **Instance Profiles** for secure AWS service access

**Tier-Specific Design:**
```
Web Tier:
├── Instance Type: t3.medium (burstable)
├── Scaling: Target tracking on CPU
├── Placement: Partition (fault isolation)
├── Min/Max: 1-6 instances
└── Distribution: Multi-AZ

Application Tier:
├── Instance Type: c5.large (compute-optimized)
├── Scaling: Multi-metric approach
├── Placement: Cluster (performance)
├── Min/Max: 1-4 instances
└── Distribution: Multi-AZ with affinity
```

## Consequences

### Positive
- **Rapid Scaling**: Pre-built AMIs enable 30-60 second deployments
- **Cost Optimization**: Auto Scaling ensures pay-per-use efficiency
- **High Availability**: Multi-AZ deployment survives AZ failures
- **Performance**: Placement groups optimize network performance
- **Operational Efficiency**: Automation reduces manual management
- **Security**: Instance profiles eliminate credential management
- **Flexibility**: Launch templates support easy updates

### Negative
- **AMI Management**: Requires regular AMI updates and versioning
- **Initial Complexity**: More complex than simple EC2 deployment
- **State Management**: Stateful apps require careful scaling design
- **Cost Variability**: Auto Scaling creates variable monthly costs
- **Monitoring Overhead**: Requires comprehensive monitoring setup

### Mitigation Strategies
- **AMI Pipeline**: Automated AMI building and testing process
- **Documentation**: Clear runbooks for scaling behavior
- **Graceful Shutdown**: Lifecycle hooks for stateful applications
- **Cost Alerts**: Budget alerts for unexpected scaling
- **Monitoring**: CloudWatch dashboards and alarms

## Alternatives Considered

### 1. Manual EC2 Instance Management
**Rejected because:**
- No automatic failure recovery
- Manual scaling is slow and error-prone
- Higher operational overhead
- Increased risk during peak loads
- Poor cost efficiency (over-provisioning)

### 2. Elastic Beanstalk
**Rejected because:**
- Less control over infrastructure
- Limited customization options
- Vendor lock-in concerns
- Learning curve for team
- Not suitable for complex architectures

### 3. ECS Fargate (Containers)
**Rejected because:**
- Application not yet containerized
- Team lacks container expertise
- Higher complexity for current needs
- Can migrate to containers later
- Current timeline doesn't allow refactoring

### 4. Fixed Instance Fleet
**Rejected because:**
- No elasticity for traffic variations
- Higher costs during low traffic
- Manual intervention for failures
- Cannot handle traffic spikes
- Against cloud-native principles

### 5. Spot Instances Only
**Rejected because:**
- Interruption risk for production
- Not suitable for stateful applications
- Complexity of spot fleet management
- Customer-facing SLA requirements
- Better as supplementary capacity

## Implementation Details

### Instance Type Selection
```yaml
Web Tier (t3.medium):
  vCPUs: 2
  Memory: 4 GB
  Network: Up to 5 Gbps
  Rationale: 
    - Burstable for variable web traffic
    - Cost-effective baseline performance
    - T3 Unlimited prevents throttling

Application Tier (c5.large):
  vCPUs: 2
  Memory: 4 GB
  Network: Up to 10 Gbps
  Rationale:
    - Compute-optimized for processing
    - Consistent performance (no bursting)
    - Enhanced networking support
```

### Scaling Strategy
```yaml
Target Tracking Scaling:
  Metric: CPU Utilization
  Target: 70%
  Scale-out cooldown: 60 seconds
  Scale-in cooldown: 300 seconds

Step Scaling (Web Tier):
  85-95% CPU: +2 instances
  >95% CPU: +4 instances
  <30% CPU: -1 instance

Scheduled Scaling:
  Business hours: Min 2 instances
  After hours: Min 1 instance
  Weekends: Reduced capacity
```

### Health Check Configuration
```yaml
Health Check Type: ELB (when available) / EC2
Grace Period: 300 seconds
Replacement: Automatic on failure
```

## Implementation Timeline

### Phase 1: Foundation (Week 1)
- [x] Create IAM instance profiles and policies
- [x] Design AMI building strategy
- [x] Document instance requirements
- [x] Plan scaling policies

### Phase 2: AMI Development (Week 1-2)
- [x] Build web server AMI with Apache/PHP
- [x] Build application server AMI with Java/Python
- [x] Test AMI deployment speed
- [x] Implement AMI versioning

### Phase 3: Auto Scaling Setup (Week 2)
- [x] Create launch templates
- [x] Configure Auto Scaling groups
- [x] Implement scaling policies
- [x] Set up CloudWatch monitoring

### Phase 4: Testing and Optimization (Week 3)
- [x] Load testing and scaling validation
- [x] Performance optimization
- [x] Cost analysis and optimization
- [ ] Production deployment

**Total Implementation Time:** 3 weeks (completed core in 5 hours during lab)

## Related Implementation
This decision was implemented in [Lab 3: EC2 & Auto Scaling Platform](../../labs/lab-03-ec2/README.md), which includes:
- Custom AMI creation process
- Launch template configuration
- Auto Scaling group setup
- Scaling policy implementation
- Monitoring and alerting setup
- Testing and validation procedures

## Success Metrics
- **Deployment Speed**: < 60 seconds from scale decision to ready instance ✅
- **Scaling Response**: < 5 minutes to handle traffic spikes ✅
- **Availability**: 99.9% uptime across AZ failures ✅ (designed for)
- **Cost Efficiency**: 40% reduction vs. fixed capacity ✅ (projected)
- **Operational Overhead**: < 2 hours/week maintenance ✅

## Review Date
2025-12-13 (6 months) - Evaluate scaling patterns and costs

## References
- [AWS Auto Scaling Best Practices](https://docs.aws.amazon.com/autoscaling/ec2/userguide/auto-scaling-best-practices.html)
- [EC2 Instance Types](https://aws.amazon.com/ec2/instance-types/)
- [AWS Well-Architected - Reliability Pillar](https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/welcome.html)
- **Implementation**: [Lab 3: EC2 & Auto Scaling Platform](../../labs/lab-03-ec2/README.md)

## Appendix: Instance Type Comparison

| Criteria | t3.medium | t3.large | c5.large | m5.large |
|----------|-----------|----------|----------|----------|
| vCPUs | 2 | 2 | 2 | 2 |
| Memory | 4 GB | 8 GB | 4 GB | 8 GB |
| Network | Up to 5 Gbps | Up to 5 Gbps | Up to 10 Gbps | Up to 10 Gbps |
| Use Case | Web servers | Memory-heavy web | Compute-intensive | Balanced workloads |
| Cost/hour | $0.0416 | $0.0832 | $0.085 | $0.096 |
| Chosen For | Web tier ✓ | - | App tier ✓ | - |

---

*This decision will be revisited if:*
- Traffic patterns stabilize allowing for Reserved Instances
- Application is containerized enabling ECS/Fargate migration
- Spot instance integration becomes viable for portions of workload
- Performance requirements change significantly