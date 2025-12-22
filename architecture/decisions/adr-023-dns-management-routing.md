<!--
Terminus Solutions AWS Enterprise Architecture
Copyright (c) 2025 Jared (Terminus Solutions) - jaredintech.com
Licensed under CC BY-SA 4.0 - Attribution required
See LICENSE-DOCS for details
-->

# ADR-023: DNS Management and Routing

## Date
2025-12-22

## Status
Accepted

## Context
With our global content delivery strategy defined (ADR-022), Terminus Solutions needs to establish a comprehensive DNS management approach for intelligent traffic routing, high availability, and global performance optimization. This decision determines how we manage domain resolution, implement routing policies, and ensure DNS-level resilience.

Key requirements and constraints:
- Must achieve 100% DNS availability (matching Route 53 SLA)
- Support intelligent routing based on latency, geography, and health
- Enable automatic failover for disaster recovery scenarios
- Integrate with existing multi-region architecture (ADR-004)
- Minimize DNS resolution latency globally
- Support both apex domain and subdomains
- Meet compliance requirements for geographic data routing
- Enable health check-based traffic management
- Budget conscious—optimize for essential features

Current challenges:
- Single-region DNS creates potential single point of failure
- No automated failover between regions
- Manual DNS changes for traffic management
- Limited visibility into DNS performance
- No integration between DNS and application health

## Decision
We will implement Amazon Route 53 as our authoritative DNS service with multiple routing policies, integrated health checks, and alias records for AWS resource integration.

**DNS Architecture:**
```
                                         ┌─────────────────────────────────────────┐
                                         │            Route 53 Global              │
                                         │         (Anycast DNS Network)           │
                                         │                                         │
                                         │  ┌─────────────────────────────────┐    │
                                         │  │      terminus.solutions         │    │
                                         │  │        (Hosted Zone)            │    │
                                         │  └─────────────────────────────────┘    │
                                         │                   │                     │
                                         └───────────────────┼─────────────────────┘
                                                             │
                    ┌────────────────────────────────────────┼────────────────────────────────────────┐
                    │                                        │                                        │
                    ▼                                        ▼                                        ▼
        ┌───────────────────────┐              ┌───────────────────────┐              ┌───────────────────────┐
        │    Simple Routing     │              │   Latency Routing     │              │   Failover Routing    │
        │                       │              │                       │              │                       │
        │  terminus.solutions   │              │  api.terminus.solutions│             │  app.terminus.solutions│
        │         │             │              │         │             │              │         │             │
        │         ▼             │              │    ┌────┴────┐        │              │    ┌────┴────┐        │
        │   CloudFront Alias    │              │    ▼         ▼        │              │    ▼         ▼        │
        │                       │              │ us-east-1  eu-west-1  │              │ Primary   Secondary   │
        └───────────────────────┘              │   ALB        ALB      │              │  (Prod)     (DR)      │
                                               └───────────────────────┘              └───────────────────────┘
                                                        │                                      │
                                                        ▼                                      ▼
                                               ┌─────────────────┐                    ┌─────────────────┐
                                               │  Health Checks  │                    │  Health Checks  │
                                               │  (Per Endpoint) │                    │  (Calculated)   │
                                               └─────────────────┘                    └─────────────────┘
```

**Routing Policy Strategy:**

| Record | Type | Routing Policy | Use Case |
|--------|------|----------------|----------|
| terminus.solutions | A (Alias) | Simple | Apex domain to CloudFront |
| www.terminus.solutions | CNAME | Simple | WWW redirect to apex |
| api.terminus.solutions | A (Alias) | Latency | Route to nearest regional ALB |
| app.terminus.solutions | A (Alias) | Failover | Primary/DR with health checks |
| static.terminus.solutions | A (Alias) | Simple | Direct to CloudFront |
| *.dev.terminus.solutions | CNAME | Simple | Development environments |

**Health Check Configuration:**
```
Health Check Types:
├── Endpoint Health Checks
│   ├── Protocol: HTTPS
│   ├── Port: 443
│   ├── Path: /health
│   ├── Interval: 30 seconds
│   ├── Failure Threshold: 3
│   └── Regions: 3 (for redundancy)
│
├── Calculated Health Checks
│   ├── Child Checks: 2+ endpoint checks
│   ├── Logic: AND/OR combinations
│   └── Use: Complex availability decisions
│
└── CloudWatch Alarm Health Checks
    ├── Source: CloudWatch metrics
    ├── Use: AWS resource monitoring
    └── Cost: Lower than endpoint checks
```

## Consequences

### Positive
- **100% SLA**: Route 53 provides industry-leading DNS availability guarantee
- **Global Performance**: Anycast network routes queries to nearest DNS server
- **Native Integration**: Alias records eliminate extra DNS lookup for AWS resources
- **Intelligent Routing**: Latency, geolocation, and failover policies optimize traffic
- **Health Integration**: Automatic failover based on endpoint health
- **Cost Effective**: $0.50/zone + $0.40/million queries is economical
- **Security**: DNSSEC support for cryptographic validation

### Negative
- **Health Check Costs**: HTTPS health checks cost $0.75/month each
- **Propagation Time**: TTL-based propagation can delay changes
- **Complexity**: Multiple routing policies require careful management
- **Vendor Lock-in**: Deep AWS integration makes migration complex
- **Learning Curve**: Advanced routing policies require expertise

### Mitigation Strategies
- **Health Check Costs**: Use CloudWatch alarm-based checks ($0.50/month) for AWS resources
- **Propagation**: Use low TTL (60-300s) for critical records; plan changes accordingly
- **Complexity**: Document all records and policies; use infrastructure as code
- **Lock-in**: Accept for strategic benefits; document migration path if needed
- **Learning Curve**: Invest in team training; document patterns for reuse

## Alternatives Considered

### 1. External DNS Provider (Cloudflare, DNSimple)
**Rejected because:**
- Requires separate management console and API
- Less native integration with AWS services
- No alias record equivalent (extra DNS lookup)
- Separate billing relationship
- Health check integration more complex

### 2. Self-Managed DNS (BIND on EC2)
**Rejected because:**
- High operational overhead
- No global anycast network
- Single point of failure risk
- Security patching responsibility
- No SLA guarantee

### 3. AWS Global Accelerator for DNS
**Rejected because:**
- Not a DNS service (IP-based routing)
- Higher cost for our use case
- Overkill for DNS-level routing
- Better for TCP/UDP optimization
- Complementary, not replacement

### 4. Multi-Provider DNS (Route 53 + External)
**Rejected because:**
- Increased complexity
- Synchronization challenges
- Higher costs
- Debugging difficulties
- Limited benefit for our scale

## Implementation Details

### Hosted Zone Configuration
```yaml
HostedZone:
  Name: terminus.solutions
  Type: Public
  Comment: "Primary hosted zone for Terminus Solutions"
  Tags:
    - Key: Environment
      Value: Production
    - Key: Project
      Value: TerminusSolutions
    - Key: CostCenter
      Value: Infrastructure
```

### Record Set Definitions
```yaml
RecordSets:
  # Apex domain - CloudFront alias
  - Name: terminus.solutions
    Type: A
    AliasTarget:
      DNSName: d1234abcdef.cloudfront.net
      HostedZoneId: Z2FDTNDATAQYW2  # CloudFront zone ID
      EvaluateTargetHealth: true
      
  # WWW subdomain
  - Name: www.terminus.solutions
    Type: CNAME
    TTL: 300
    ResourceRecords:
      - terminus.solutions
      
  # API with latency routing (us-east-1)
  - Name: api.terminus.solutions
    Type: A
    SetIdentifier: api-us-east-1
    Region: us-east-1
    AliasTarget:
      DNSName: internal-terminus-alb-east.elb.amazonaws.com
      HostedZoneId: Z35SXDOTRQ7X7K
      EvaluateTargetHealth: true
    HealthCheckId: !Ref APIHealthCheckEast
      
  # API with latency routing (eu-west-1)
  - Name: api.terminus.solutions
    Type: A
    SetIdentifier: api-eu-west-1
    Region: eu-west-1
    AliasTarget:
      DNSName: internal-terminus-alb-west.elb.amazonaws.com
      HostedZoneId: Z32O12XQLNTSW2
      EvaluateTargetHealth: true
    HealthCheckId: !Ref APIHealthCheckWest
    
  # Application with failover routing
  - Name: app.terminus.solutions
    Type: A
    SetIdentifier: app-primary
    Failover: PRIMARY
    AliasTarget:
      DNSName: internal-terminus-alb-prod.elb.amazonaws.com
      HostedZoneId: Z35SXDOTRQ7X7K
      EvaluateTargetHealth: true
    HealthCheckId: !Ref AppPrimaryHealthCheck
    
  - Name: app.terminus.solutions
    Type: A
    SetIdentifier: app-secondary
    Failover: SECONDARY
    AliasTarget:
      DNSName: internal-terminus-alb-dr.elb.amazonaws.com
      HostedZoneId: Z1H1FL5HABSF5
      EvaluateTargetHealth: true
```

### Health Check Configuration
```yaml
HealthChecks:
  # Primary ALB health check
  AppPrimaryHealthCheck:
    Type: HTTPS
    FullyQualifiedDomainName: app-health.terminus.solutions
    Port: 443
    ResourcePath: /health
    RequestInterval: 30
    FailureThreshold: 3
    MeasureLatency: true
    Regions:
      - us-east-1
      - us-west-2
      - eu-west-1
    Tags:
      - Key: Name
        Value: app-primary-health
        
  # API endpoint health check
  APIHealthCheckEast:
    Type: HTTPS
    FullyQualifiedDomainName: api-east.terminus.solutions
    Port: 443
    ResourcePath: /health
    RequestInterval: 30
    FailureThreshold: 3
    EnableSNI: true
    
  # Calculated health check for overall status
  OverallHealthCheck:
    Type: CALCULATED
    ChildHealthChecks:
      - !Ref AppPrimaryHealthCheck
      - !Ref APIHealthCheckEast
    HealthThreshold: 1  # At least 1 must be healthy
```

### Geolocation Routing (Compliance)
```yaml
# EU users routed to EU infrastructure
EUGeolocationRecord:
  - Name: app.terminus.solutions
    Type: A
    SetIdentifier: app-eu-geo
    GeoLocation:
      ContinentCode: EU
    AliasTarget:
      DNSName: internal-terminus-alb-eu.elb.amazonaws.com
      HostedZoneId: Z32O12XQLNTSW2
      EvaluateTargetHealth: true
      
# Default for all other locations
DefaultGeolocationRecord:
  - Name: app.terminus.solutions
    Type: A
    SetIdentifier: app-default-geo
    GeoLocation:
      CountryCode: "*"  # Default
    AliasTarget:
      DNSName: internal-terminus-alb-prod.elb.amazonaws.com
      HostedZoneId: Z35SXDOTRQ7X7K
      EvaluateTargetHealth: true
```

### TTL Strategy
```yaml
TTL Configuration:
  Static Records:
    - Type: NS, SOA
      TTL: 172800 (48 hours)
    - Type: MX
      TTL: 3600 (1 hour)
      
  Dynamic Records:
    - Type: A (CloudFront alias)
      TTL: 60 (1 minute) - inherited from alias
    - Type: A (ALB alias)  
      TTL: 60 (1 minute) - inherited from alias
      
  Failover Records:
    - Type: A (Failover)
      TTL: 60 (1 minute) - fast failover
      
  Development:
    - Type: CNAME
      TTL: 300 (5 minutes)
```

## Implementation Timeline

### Phase 1: Foundation (Week 1)
- [x] Create hosted zone for terminus.solutions
- [x] Configure NS records at domain registrar
- [x] Create apex domain alias to CloudFront
- [x] Set up www CNAME redirect

### Phase 2: Health Checks (Week 1-2)
- [x] Create HTTPS health checks for primary endpoints
- [x] Configure health check alerting
- [x] Set up calculated health check for overall status
- [x] Verify health check functionality

### Phase 3: Advanced Routing (Week 2-3)
- [x] Implement latency-based routing for API
- [x] Configure failover routing for application
- [x] Set up geolocation routing for compliance
- [x] Test all routing policies

**Total Implementation Time:** 3 weeks

## Related Implementation
This decision was implemented in [Lab 6: Route 53 & CloudFront Distribution](../../labs/lab-06-route53-cloudfront/README.md), which includes:
- Hosted zone creation and NS configuration
- Multiple routing policy implementations
- Health check configuration and monitoring
- Integration with CloudFront and ALB

## Success Metrics
- **DNS Availability**: Target 100% (Route 53 SLA)
- **Resolution Latency**: Target <50ms globally
- **Failover Time**: Target <60 seconds for health check-based failover
- **Health Check Accuracy**: Target 0 false positives per month
- **Query Volume**: Monitor for anomalies and cost optimization

## Review Date
2026-06-22 (6 months) - Evaluate routing policy effectiveness, health check accuracy, and potential for DNSSEC implementation

## References
- [Amazon Route 53 Developer Guide](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/)
- [Route 53 Routing Policies](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/routing-policy.html)
- [Route 53 Health Checks](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/dns-failover.html)
- ADR-004: Multi-Region DR Network Design
- ADR-022: Global Content Delivery Strategy

---

*This decision will be revisited if:*
- DNS query costs exceed $50/month consistently
- Health check false positives occur more than once per quarter
- New compliance requirements mandate DNS-level controls
- Multi-cloud strategy requires external DNS consideration
