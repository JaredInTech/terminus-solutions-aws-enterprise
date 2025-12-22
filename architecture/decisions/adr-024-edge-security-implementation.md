<!--
Terminus Solutions AWS Enterprise Architecture
Copyright (c) 2025 Jared (Terminus Solutions) - jaredintech.com
Licensed under CC BY-SA 4.0 - Attribution required
See LICENSE-DOCS for details
-->

# ADR-024: Edge Security Implementation

## Date
2025-12-22

## Status
Accepted

## Context
With our global content delivery and DNS infrastructure defined (ADR-022, ADR-023), Terminus Solutions needs to implement comprehensive security controls at the edge layer. This decision determines our approach to web application firewall (WAF), DDoS protection, security header enforcement, and origin access control to protect both our infrastructure and users.

Key requirements and constraints:
- Must protect against OWASP Top 10 vulnerabilities
- Require DDoS protection at network and application layers
- Need rate limiting to prevent abuse
- Enforce security headers on all responses
- Restrict origin access to CloudFront only
- Support geographic restrictions for compliance
- Enable detailed logging for security analysis
- Minimize latency impact from security processing
- Budget conscious—balance protection vs. cost
- Meet future SOC2 and PCI compliance requirements

Current security challenges:
- Direct origin access bypasses CDN security controls
- No application-layer attack protection
- Missing security headers on responses
- No rate limiting for API abuse prevention
- Limited visibility into attack patterns

## Decision
We will implement a defense-in-depth edge security architecture using AWS WAF with managed and custom rules, AWS Shield Standard for DDoS protection, Lambda@Edge for security header injection, and Origin Access Control for S3 protection.

**Edge Security Architecture:**
```
                                    Internet Traffic
                                           │
                                           ▼
                              ┌────────────────────────┐
                              │     AWS Shield         │
                              │   (DDoS Protection)    │
                              │                        │
                              │  - Network layer (L3)  │
                              │  - Transport layer (L4)│
                              │  - Always-on           │
                              └───────────┬────────────┘
                                          │
                                          ▼
                              ┌────────────────────────┐
                              │       AWS WAF          │
                              │  (Web ACL Protection)  │
                              │                        │
                              │  ┌──────────────────┐  │
                              │  │  Managed Rules   │  │
                              │  │  - Core Rule Set │  │
                              │  │  - SQL Injection │  │
                              │  │  - Known Bad IPs │  │
                              │  └──────────────────┘  │
                              │                        │
                              │  ┌──────────────────┐  │
                              │  │  Custom Rules    │  │
                              │  │  - Rate Limiting │  │
                              │  │  - Geo Blocking  │  │
                              │  │  - IP Allowlist  │  │
                              │  └──────────────────┘  │
                              └───────────┬────────────┘
                                          │
                                          ▼
                              ┌────────────────────────┐
                              │      CloudFront        │
                              │   (Edge Processing)    │
                              │                        │
                              │  ┌──────────────────┐  │
                              │  │  Lambda@Edge     │  │
                              │  │  - Security Hdrs │  │
                              │  │  - Request Valid │  │
                              │  └──────────────────┘  │
                              │                        │
                              │  ┌──────────────────┐  │
                              │  │  OAC (S3 Origin) │  │
                              │  │  - Signed Reqs   │  │
                              │  │  - No Public S3  │  │
                              │  └──────────────────┘  │
                              └───────────┬────────────┘
                                          │
                                          ▼
                              ┌────────────────────────┐
                              │    Protected Origins   │
                              │                        │
                              │  S3 (Private) │ ALB    │
                              └────────────────────────┘
```

**WAF Rule Strategy:**

| Rule Group | Priority | Action | Purpose |
|------------|----------|--------|---------|
| IP Reputation | 1 | Block | Block known malicious IPs |
| Rate Limiting | 2 | Block | Prevent abuse (1000 req/5min) |
| Core Rule Set | 3 | Block | OWASP Top 10 protection |
| SQL Injection | 4 | Block | Database attack prevention |
| XSS Protection | 5 | Block | Cross-site scripting prevention |
| Geo Restriction | 6 | Block | Block embargoed countries |
| Custom Allow | 7 | Allow | Whitelist trusted IPs |

## Consequences

### Positive
- **Comprehensive Protection**: Multi-layer security from network to application
- **OWASP Coverage**: Managed rules protect against common vulnerabilities
- **DDoS Resilience**: Shield Standard included at no extra cost
- **Origin Security**: OAC ensures only CloudFront can access origins
- **Header Enforcement**: Consistent security headers on all responses
- **Visibility**: Detailed WAF logs for security analysis
- **Scalability**: Edge processing handles attacks before reaching origin

### Negative
- **WAF Costs**: $5/month base + $1/rule + $0.60/million requests
- **False Positives**: Managed rules may block legitimate traffic
- **Lambda@Edge Latency**: Small latency addition (1-5ms)
- **Complexity**: Multiple security layers require coordination
- **Rule Tuning**: Ongoing effort to optimize rule effectiveness

### Mitigation Strategies
- **WAF Costs**: Start with essential rules; add based on threat analysis
- **False Positives**: Use Count mode initially; tune before Block mode
- **Latency**: Use viewer-response trigger for headers (minimal impact)
- **Complexity**: Document all rules; use infrastructure as code
- **Tuning**: Regular review of WAF logs; automated alerting

## Alternatives Considered

### 1. CloudFront Native Security Only
**Rejected because:**
- No application-layer attack protection
- Limited rate limiting capability
- No OWASP rule coverage
- Cannot inspect request bodies
- Insufficient for compliance requirements

### 2. Third-Party WAF (Cloudflare, Imperva)
**Rejected because:**
- Requires traffic to leave AWS network
- Additional latency from external routing
- Separate management interface
- Less CloudFront integration
- Higher costs for comparable protection

### 3. WAF on ALB Only (No Edge WAF)
**Rejected because:**
- Attacks consume CloudFront bandwidth before blocking
- Higher data transfer costs from attacks
- No protection for static content
- Delayed attack response
- Origin receives attack traffic

### 4. AWS Shield Advanced
**Considered but deferred:**
- $3,000/month base cost
- Best for high-value targets
- Includes WAF at no additional cost
- 24/7 DDoS Response Team access
- Will reconsider if attack frequency increases

### 5. Custom Security Layer on EC2
**Rejected because:**
- High operational overhead
- No global edge presence
- Manual scaling required
- Single point of failure
- Higher total cost of ownership

## Implementation Details

### WAF Web ACL Configuration
```yaml
WebACL:
  Name: Terminus-Production-ACL
  Scope: CLOUDFRONT  # Must be in us-east-1
  DefaultAction:
    Allow: {}
  VisibilityConfig:
    SampledRequestsEnabled: true
    CloudWatchMetricsEnabled: true
    MetricName: TerminusProductionACL
    
  Rules:
    # IP Reputation - Block known bad actors
    - Name: AWSManagedRulesAmazonIpReputationList
      Priority: 1
      Statement:
        ManagedRuleGroupStatement:
          VendorName: AWS
          Name: AWSManagedRulesAmazonIpReputationList
      OverrideAction:
        None: {}
      VisibilityConfig:
        MetricName: IPReputation
        
    # Rate Limiting - Prevent abuse
    - Name: RateLimitRule
      Priority: 2
      Statement:
        RateBasedStatement:
          Limit: 1000  # 1000 requests per 5 minutes
          AggregateKeyType: IP
      Action:
        Block: {}
      VisibilityConfig:
        MetricName: RateLimit
        
    # Core Rule Set - OWASP Top 10
    - Name: AWSManagedRulesCommonRuleSet
      Priority: 3
      Statement:
        ManagedRuleGroupStatement:
          VendorName: AWS
          Name: AWSManagedRulesCommonRuleSet
          ExcludedRules:
            - Name: SizeRestrictions_BODY  # Allow larger uploads
      OverrideAction:
        None: {}
      VisibilityConfig:
        MetricName: CommonRuleSet
        
    # SQL Injection Protection
    - Name: AWSManagedRulesSQLiRuleSet
      Priority: 4
      Statement:
        ManagedRuleGroupStatement:
          VendorName: AWS
          Name: AWSManagedRulesSQLiRuleSet
      OverrideAction:
        None: {}
      VisibilityConfig:
        MetricName: SQLiProtection
        
    # Geographic Restriction
    - Name: GeoBlockRule
      Priority: 6
      Statement:
        GeoMatchStatement:
          CountryCodes:
            - KP  # North Korea
            - IR  # Iran
            - SY  # Syria
            - CU  # Cuba
      Action:
        Block: {}
      VisibilityConfig:
        MetricName: GeoBlock
```

### Lambda@Edge Security Headers
```javascript
// Lambda@Edge Function: Security Headers
// Trigger: viewer-response

exports.handler = async (event) => {
    const response = event.Records[0].cf.response;
    const headers = response.headers;
    
    // Strict Transport Security
    headers['strict-transport-security'] = [{
        key: 'Strict-Transport-Security',
        value: 'max-age=63072000; includeSubDomains; preload'
    }];
    
    // Content Security Policy
    headers['content-security-policy'] = [{
        key: 'Content-Security-Policy',
        value: "default-src 'self'; script-src 'self' 'unsafe-inline' https://cdn.terminus.solutions; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' https://fonts.gstatic.com; connect-src 'self' https://api.terminus.solutions; frame-ancestors 'none'; base-uri 'self'; form-action 'self';"
    }];
    
    // X-Content-Type-Options
    headers['x-content-type-options'] = [{
        key: 'X-Content-Type-Options',
        value: 'nosniff'
    }];
    
    // X-Frame-Options
    headers['x-frame-options'] = [{
        key: 'X-Frame-Options',
        value: 'DENY'
    }];
    
    // X-XSS-Protection
    headers['x-xss-protection'] = [{
        key: 'X-XSS-Protection',
        value: '1; mode=block'
    }];
    
    // Referrer Policy
    headers['referrer-policy'] = [{
        key: 'Referrer-Policy',
        value: 'strict-origin-when-cross-origin'
    }];
    
    // Permissions Policy
    headers['permissions-policy'] = [{
        key: 'Permissions-Policy',
        value: 'accelerometer=(), camera=(), geolocation=(), gyroscope=(), magnetometer=(), microphone=(), payment=(), usb=()'
    }];
    
    return response;
};
```

### Origin Access Control Configuration
```yaml
OriginAccessControl:
  Name: Terminus-S3-OAC
  Description: "OAC for Terminus S3 origins"
  SigningProtocol: sigv4
  SigningBehavior: always
  OriginAccessControlOriginType: s3

# S3 Bucket Policy (applied to origin bucket)
S3BucketPolicy:
  Version: "2012-10-17"
  Statement:
    - Sid: AllowCloudFrontServicePrincipal
      Effect: Allow
      Principal:
        Service: cloudfront.amazonaws.com
      Action: s3:GetObject
      Resource: arn:aws:s3:::terminus-static/*
      Condition:
        StringEquals:
          AWS:SourceArn: arn:aws:cloudfront::ACCOUNT_ID:distribution/DISTRIBUTION_ID
```

### Rate Limiting Configuration
```yaml
RateLimiting:
  GlobalLimit:
    Requests: 1000
    Period: 300  # 5 minutes
    Action: Block
    
  APILimit:
    PathPattern: /api/*
    Requests: 100
    Period: 60  # 1 minute
    Action: Block
    
  LoginLimit:
    PathPattern: /auth/login
    Requests: 10
    Period: 60  # 1 minute
    Action: Block
    
  Response:
    StatusCode: 429
    CustomResponse:
      ResponseCode: 429
      CustomResponseBodyKey: RateLimitExceeded
      ResponseHeaders:
        - Name: Retry-After
          Value: "60"
```

### WAF Logging Configuration
```yaml
WAFLogging:
  LogDestination: 
    - arn:aws:s3:::terminus-waf-logs
  LoggingFilter:
    DefaultBehavior: DROP  # Only log interesting events
    Filters:
      - Behavior: KEEP
        Conditions:
          - ActionCondition:
              Action: BLOCK
          - ActionCondition:
              Action: COUNT
  RedactedFields:
    - SingleHeader:
        Name: authorization
    - SingleHeader:
        Name: cookie
```

## Implementation Timeline

### Phase 1: Foundation (Week 1)
- [x] Create WAF Web ACL in us-east-1
- [x] Add IP reputation managed rules
- [x] Configure rate limiting rule
- [x] Associate WAF with CloudFront distribution

### Phase 2: Application Protection (Week 2)
- [x] Add Core Rule Set (Count mode initially)
- [x] Add SQL injection rule set
- [x] Configure geographic restrictions
- [x] Tune rules based on traffic analysis

### Phase 3: Edge Functions (Week 2-3)
- [x] Deploy Lambda@Edge for security headers
- [x] Configure Origin Access Control
- [x] Update S3 bucket policies
- [x] Verify origin access restriction

### Phase 4: Monitoring (Week 3)
- [x] Enable WAF logging to S3
- [x] Create CloudWatch dashboards
- [x] Set up alerting for blocked requests
- [x] Document incident response procedures

**Total Implementation Time:** 3 weeks

## Related Implementation
This decision was implemented in [Lab 6: Route 53 & CloudFront Distribution](../../labs/lab-06-route53-cloudfront/README.md), which includes:
- WAF Web ACL configuration with managed rules
- Lambda@Edge security header function
- Origin Access Control setup
- WAF logging and monitoring

## Success Metrics
- **Block Rate**: Monitor percentage of blocked requests (target <1% of legitimate traffic)
- **False Positive Rate**: Target 0 confirmed false positives per month
- **Security Headers**: 100% coverage on all responses (verify with securityheaders.com)
- **Attack Detection**: Time to detect new attack patterns (<5 minutes)
- **Origin Protection**: 0 direct origin access attempts successful

## Review Date
2026-03-22 (3 months) - Review WAF rule effectiveness, false positive rate, and consider Shield Advanced

## References
- [AWS WAF Developer Guide](https://docs.aws.amazon.com/waf/latest/developerguide/)
- [AWS Managed Rules](https://docs.aws.amazon.com/waf/latest/developerguide/aws-managed-rule-groups.html)
- [Lambda@Edge Developer Guide](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/lambda-at-the-edge.html)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- ADR-022: Global Content Delivery Strategy
- ADR-005: Network Security Controls Strategy

---

*This decision will be revisited if:*
- DDoS attacks exceed Shield Standard protection capabilities
- False positive rate exceeds 0.1% of legitimate traffic
- New compliance requirements mandate additional controls
- Attack patterns require custom rule development
