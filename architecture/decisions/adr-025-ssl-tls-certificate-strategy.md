<!--
Terminus Solutions AWS Enterprise Architecture
Copyright (c) 2025 Jared (Terminus Solutions) - jaredintech.com
Licensed under CC BY-SA 4.0 - Attribution required
See LICENSE-DOCS for details
-->

# ADR-025: SSL/TLS Certificate Strategy

## Date
2025-12-22

## Status
Accepted

## Context
With our edge security implementation defined (ADR-024), Terminus Solutions needs to establish a comprehensive SSL/TLS certificate management strategy. This decision determines how we provision, deploy, and maintain certificates across CloudFront distributions, load balancers, and other endpoints to ensure secure communications and compliance.

Key requirements and constraints:
- Must enforce HTTPS for all public endpoints
- Require TLS 1.2 minimum for all connections
- Support wildcard certificates for subdomain flexibility
- Enable automatic certificate renewal
- Minimize operational overhead for certificate management
- Meet compliance requirements (PCI-DSS, SOC2)
- Support both edge (CloudFront) and regional (ALB) certificates
- Maintain zero downtime during certificate operations
- Budget conscious—avoid expensive third-party certificates

Current challenges:
- Manual certificate management is error-prone
- Certificate expiration causes outages
- Different certificate requirements for edge vs. regional services
- No centralized certificate visibility
- Renewal coordination across multiple services

## Decision
We will use AWS Certificate Manager (ACM) for all SSL/TLS certificate provisioning with DNS validation through Route 53, implementing separate certificate strategies for CloudFront (us-east-1) and regional services.

**Certificate Architecture:**
```
                          ┌─────────────────────────────────────────────────────────────┐
                          │                    Certificate Strategy                      │
                          │                                                             │
                          │  ┌─────────────────────────────────────────────────────┐    │
                          │  │               AWS Certificate Manager                │    │
                          │  │                                                     │    │
                          │  │  ┌─────────────────┐    ┌─────────────────┐        │    │
                          │  │  │   us-east-1     │    │   us-west-2     │        │    │
                          │  │  │  (CloudFront)   │    │     (DR)        │        │    │
                          │  │  │                 │    │                 │        │    │
                          │  │  │ *.terminus.     │    │ *.terminus.     │        │    │
                          │  │  │   solutions     │    │   solutions     │        │    │
                          │  │  │                 │    │                 │        │    │
                          │  │  │ Validation:     │    │ Validation:     │        │    │
                          │  │  │ DNS (Route 53)  │    │ DNS (Route 53)  │        │    │
                          │  │  └────────┬────────┘    └────────┬────────┘        │    │
                          │  │           │                      │                 │    │
                          │  └───────────┼──────────────────────┼─────────────────┘    │
                          │              │                      │                      │
                          └──────────────┼──────────────────────┼──────────────────────┘
                                         │                      │
              ┌──────────────────────────┼──────────────────────┼──────────────────────────┐
              │                          │                      │                          │
              ▼                          ▼                      ▼                          ▼
    ┌─────────────────┐        ┌─────────────────┐    ┌─────────────────┐        ┌─────────────────┐
    │   CloudFront    │        │  ALB (us-east-1)│    │  ALB (us-west-2)│        │   API Gateway   │
    │   Distribution  │        │                 │    │                 │        │    (Future)     │
    │                 │        │                 │    │                 │        │                 │
    │ TLS 1.2+ only   │        │ TLS 1.2+ only   │    │ TLS 1.2+ only   │        │ TLS 1.2+ only   │
    │ SNI required    │        │ SNI required    │    │ SNI required    │        │ SNI required    │
    └─────────────────┘        └─────────────────┘    └─────────────────┘        └─────────────────┘
```

**Certificate Inventory:**

| Certificate | Domain | Region | Service | Validation |
|-------------|--------|--------|---------|------------|
| Primary Wildcard | *.terminus.solutions | us-east-1 | CloudFront | DNS |
| Apex Domain | terminus.solutions | us-east-1 | CloudFront | DNS |
| Regional Primary | *.terminus.solutions | us-east-1 | ALB, API GW | DNS |
| Regional DR | *.terminus.solutions | us-west-2 | ALB (DR) | DNS |

**TLS Configuration:**

| Service | Minimum TLS | Security Policy | Cipher Preference |
|---------|-------------|-----------------|-------------------|
| CloudFront | TLS 1.2 | TLSv1.2_2021 | Server order |
| ALB | TLS 1.2 | ELBSecurityPolicy-TLS13-1-2-2021-06 | Forward secrecy |
| API Gateway | TLS 1.2 | TLS_1_2 | Managed |

## Consequences

### Positive
- **Zero Cost**: ACM public certificates are free
- **Auto-Renewal**: Certificates renew automatically 60 days before expiry
- **Native Integration**: Seamless deployment to CloudFront, ALB, API Gateway
- **DNS Validation**: No manual email validation; works with Route 53
- **Wildcard Support**: Single certificate covers all subdomains
- **Compliance**: Meets PCI-DSS and SOC2 requirements
- **Visibility**: Centralized certificate management in ACM console

### Negative
- **Regional Deployment**: Must deploy certificates in each region used
- **CloudFront Requirement**: CloudFront requires us-east-1 certificates
- **No Export**: Cannot export ACM certificates for external use
- **Validation Delay**: DNS validation can take 30+ minutes initially
- **Route 53 Dependency**: DNS validation requires Route 53 access

### Mitigation Strategies
- **Regional Deployment**: Automate with CloudFormation/Terraform
- **CloudFront Requirement**: Document clearly; include in deployment runbooks
- **No Export**: Use ACM Private CA if export needed (not current requirement)
- **Validation Delay**: Use DNS validation with auto-created records
- **Route 53 Dependency**: Already using Route 53 per ADR-023

## Alternatives Considered

### 1. Third-Party Certificates (DigiCert, Comodo)
**Rejected because:**
- Significant annual cost ($200-500/year per certificate)
- Manual renewal and installation process
- Separate management interface
- No native AWS integration
- Key management responsibility

### 2. Let's Encrypt with Certbot
**Rejected because:**
- Requires compute resources for renewal
- 90-day certificate lifetime (more renewals)
- Manual integration with AWS services
- Operational overhead for automation
- No wildcard support without DNS plugins

### 3. ACM Private CA
**Rejected because:**
- $400/month base cost
- Designed for internal/private certificates
- Overkill for public-facing services
- Would still need ACM for public certs
- Better for mTLS scenarios

### 4. Self-Signed Certificates
**Rejected because:**
- Browser warnings destroy user trust
- Not acceptable for production
- Compliance violations
- No certificate transparency
- Security anti-pattern

### 5. Single Certificate for All Regions
**Rejected because:**
- Cannot use same ACM cert across regions
- CloudFront requires us-east-1 specifically
- Regional ALBs need regional certificates
- AWS architectural constraint

## Implementation Details

### Certificate Request Configuration
```yaml
# CloudFront Certificate (must be us-east-1)
CloudFrontCertificate:
  Type: AWS::CertificateManager::Certificate
  Properties:
    DomainName: terminus.solutions
    SubjectAlternativeNames:
      - "*.terminus.solutions"
      - terminus.solutions
    ValidationMethod: DNS
    DomainValidationOptions:
      - DomainName: terminus.solutions
        HostedZoneId: !Ref HostedZone
      - DomainName: "*.terminus.solutions"
        HostedZoneId: !Ref HostedZone
    Tags:
      - Key: Name
        Value: terminus-cloudfront-cert
      - Key: Environment
        Value: Production

# Regional Certificate (us-east-1 for ALB)
RegionalCertificateEast:
  Type: AWS::CertificateManager::Certificate
  Properties:
    DomainName: "*.terminus.solutions"
    SubjectAlternativeNames:
      - terminus.solutions
    ValidationMethod: DNS
    DomainValidationOptions:
      - DomainName: "*.terminus.solutions"
        HostedZoneId: !Ref HostedZone
    Tags:
      - Key: Name
        Value: terminus-regional-east-cert
      - Key: Environment
        Value: Production
        
# DR Region Certificate (us-west-2)
RegionalCertificateWest:
  Type: AWS::CertificateManager::Certificate
  Condition: CreateDRResources
  Properties:
    DomainName: "*.terminus.solutions"
    SubjectAlternativeNames:
      - terminus.solutions
    ValidationMethod: DNS
    DomainValidationOptions:
      - DomainName: "*.terminus.solutions"
        HostedZoneId: !Ref HostedZone
    Tags:
      - Key: Name
        Value: terminus-regional-west-cert
      - Key: Environment
        Value: Production
```

### CloudFront TLS Configuration
```yaml
CloudFrontDistribution:
  Type: AWS::CloudFront::Distribution
  Properties:
    DistributionConfig:
      Aliases:
        - terminus.solutions
        - www.terminus.solutions
        - static.terminus.solutions
        - api.terminus.solutions
      ViewerCertificate:
        AcmCertificateArn: !Ref CloudFrontCertificate
        SslSupportMethod: sni-only
        MinimumProtocolVersion: TLSv1.2_2021
        # Security policy includes:
        # - TLS 1.2 and 1.3 only
        # - Strong cipher suites
        # - Forward secrecy required
```

### ALB TLS Configuration
```yaml
ALBListener:
  Type: AWS::ElasticLoadBalancingV2::Listener
  Properties:
    LoadBalancerArn: !Ref ApplicationLoadBalancer
    Port: 443
    Protocol: HTTPS
    SslPolicy: ELBSecurityPolicy-TLS13-1-2-2021-06
    Certificates:
      - CertificateArn: !Ref RegionalCertificateEast
    DefaultActions:
      - Type: forward
        TargetGroupArn: !Ref TargetGroup

# Additional certificates for multiple domains
ALBListenerCertificate:
  Type: AWS::ElasticLoadBalancingV2::ListenerCertificate
  Properties:
    ListenerArn: !Ref ALBListener
    Certificates:
      - CertificateArn: !Ref AdditionalCertificate
```

### DNS Validation Records
```yaml
# ACM creates these automatically when using Route 53
# Shown for documentation purposes

ValidationRecord:
  Type: CNAME
  Name: _abc123.terminus.solutions
  Value: _xyz789.acm-validations.aws.
  TTL: 300
  
# Route 53 integration auto-creates validation records:
CertificateValidation:
  DependsOn: Certificate
  # ACM + Route 53 integration handles this automatically
  # Records created within 60 seconds
  # Validation completes within 30 minutes
```

### Certificate Monitoring
```yaml
# CloudWatch Alarm for Certificate Expiry
CertificateExpiryAlarm:
  Type: AWS::CloudWatch::Alarm
  Properties:
    AlarmName: ACM-Certificate-Expiry-Warning
    AlarmDescription: Certificate expires in less than 30 days
    Namespace: AWS/CertificateManager
    MetricName: DaysToExpiry
    Dimensions:
      - Name: CertificateArn
        Value: !Ref CloudFrontCertificate
    Statistic: Minimum
    Period: 86400  # Daily check
    EvaluationPeriods: 1
    Threshold: 30
    ComparisonOperator: LessThanThreshold
    AlarmActions:
      - !Ref AlertingTopic

# EventBridge Rule for Certificate Events
CertificateEventRule:
  Type: AWS::Events::Rule
  Properties:
    Description: Monitor ACM certificate events
    EventPattern:
      source:
        - aws.acm
      detail-type:
        - ACM Certificate Approaching Expiration
        - ACM Certificate Renewal Complete
        - ACM Certificate Validation Failed
    State: ENABLED
    Targets:
      - Arn: !Ref AlertingTopic
        Id: CertificateAlerts
```

### TLS Security Policy Details
```yaml
# CloudFront TLSv1.2_2021 Policy
CloudFrontSecurityPolicy:
  Protocols:
    - TLSv1.2
    - TLSv1.3
  Ciphers:
    - ECDHE-RSA-AES128-GCM-SHA256
    - ECDHE-RSA-AES256-GCM-SHA384
    - ECDHE-RSA-AES128-SHA256
    - ECDHE-RSA-AES256-SHA384
  Features:
    - Forward Secrecy: Required
    - OCSP Stapling: Enabled
    - Session Tickets: Disabled

# ALB ELBSecurityPolicy-TLS13-1-2-2021-06
ALBSecurityPolicy:
  Protocols:
    - TLSv1.2
    - TLSv1.3
  Ciphers:
    - TLS_AES_128_GCM_SHA256
    - TLS_AES_256_GCM_SHA384
    - TLS_CHACHA20_POLY1305_SHA256
    - ECDHE-ECDSA-AES128-GCM-SHA256
    - ECDHE-RSA-AES128-GCM-SHA256
  Features:
    - Forward Secrecy: Required
    - Server Order Preference: Enabled
```

## Implementation Timeline

### Phase 1: Certificate Provisioning (Week 1)
- [x] Request wildcard certificate in us-east-1 for CloudFront
- [x] Request regional certificates for ALB in us-east-1
- [x] Configure DNS validation records via Route 53
- [x] Verify certificate issuance and validation

### Phase 2: Service Integration (Week 1-2)
- [x] Associate certificate with CloudFront distribution
- [x] Configure ALB HTTPS listener with certificate
- [x] Update security policies to TLS 1.2 minimum
- [x] Test HTTPS connectivity for all endpoints

### Phase 3: Monitoring (Week 2)
- [x] Set up CloudWatch alarms for certificate expiry
- [x] Configure EventBridge rules for certificate events
- [x] Document certificate inventory
- [x] Create renewal verification procedures

### Phase 4: DR Region (Week 2-3)
- [x] Provision certificates in us-west-2
- [x] Associate with DR ALB
- [x] Verify DR HTTPS functionality
- [x] Document multi-region certificate strategy

**Total Implementation Time:** 3 weeks

## Related Implementation
This decision was implemented in [Lab 6: Route 53 & CloudFront Distribution](../../labs/lab-06-route53-cloudfront/README.md), which includes:
- ACM certificate provisioning with DNS validation
- CloudFront distribution SSL/TLS configuration
- ALB HTTPS listener setup
- Certificate monitoring and alerting

## Success Metrics
- **Certificate Coverage**: 100% of public endpoints use ACM certificates
- **TLS Version**: 100% of connections use TLS 1.2 or higher
- **Renewal Success**: 100% automatic renewal success rate
- **Expiry Alerts**: Zero certificates expire without 30-day warning
- **Validation Time**: <30 minutes for new certificate validation

## Review Date
2026-06-22 (6 months) - Review certificate inventory, consider TLS 1.3-only policy

## References
- [AWS Certificate Manager User Guide](https://docs.aws.amazon.com/acm/latest/userguide/)
- [CloudFront SSL/TLS Requirements](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/cnames-and-https-requirements.html)
- [ALB Security Policies](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html)
- [TLS Best Practices](https://wiki.mozilla.org/Security/Server_Side_TLS)
- ADR-022: Global Content Delivery Strategy
- ADR-024: Edge Security Implementation

---

*This decision will be revisited if:*
- TLS 1.3-only policies become industry standard
- Certificate transparency requirements change
- Private certificate requirements emerge (mTLS)
- Multi-cloud strategy requires portable certificates
