<!--
Terminus Solutions AWS Enterprise Architecture
Copyright (c) 2025 Jared (Terminus Solutions) - jaredintech.com
Licensed under CC BY-SA 4.0 - Attribution required
See LICENSE-DOCS for details
-->

# ADR-026: CDN High Availability Design

## Date
2025-12-22

## Status
Accepted

## Context
With our content delivery, DNS, security, and certificate strategies defined (ADR-022 through ADR-025), Terminus Solutions needs to establish a high availability design for our CDN layer. This decision determines our approach to origin failover, health monitoring, and resilience patterns to meet our availability SLAs.

Key requirements and constraints:
- Must achieve 99.99% availability for content delivery
- Require automatic origin failover within 30 seconds
- Support multiple origin types (S3, ALB) with different health patterns
- Enable seamless failover without user impact
- Integrate with Route 53 health checks (ADR-023)
- Minimize failover false positives
- Support both regional and cross-regional failover
- Maintain cache integrity during origin failures
- Document recovery procedures for manual intervention

Current challenges:
- Single origin creates single point of failure
- No automatic failover between origins
- Origin health not actively monitored
- Cache serving during origin failures not optimized
- Manual intervention required for failover scenarios

## Decision
We will implement a multi-layer high availability design using CloudFront origin groups for automatic failover, Route 53 health checks for DNS-level routing, and optimized error caching to maximize availability during origin failures.

**High Availability Architecture:**
```
                                    ┌─────────────────────────────────────────────────────────────┐
                                    │                     High Availability Design                 │
                                    │                                                             │
                                    │                        Route 53                              │
                                    │                    (DNS-Level HA)                           │
                                    │                          │                                  │
                                    │              ┌───────────┴───────────┐                      │
                                    │              │                       │                      │
                                    │              ▼                       ▼                      │
                                    │      ┌─────────────┐         ┌─────────────┐               │
                                    │      │  Primary    │         │  Secondary  │               │
                                    │      │  (Healthy)  │         │  (Standby)  │               │
                                    │      └──────┬──────┘         └──────┬──────┘               │
                                    │             │                       │                      │
                                    └─────────────┼───────────────────────┼──────────────────────┘
                                                  │                       │
                                                  ▼                       ▼
                              ┌───────────────────────────────────────────────────────────────────┐
                              │                      CloudFront Distribution                       │
                              │                                                                   │
                              │    ┌─────────────────────────────────────────────────────────┐    │
                              │    │                    Origin Groups                         │    │
                              │    │                                                         │    │
                              │    │  ┌──────────────────┐    ┌──────────────────┐          │    │
                              │    │  │  Static Content  │    │  Dynamic Content │          │    │
                              │    │  │   Origin Group   │    │   Origin Group   │          │    │
                              │    │  │                  │    │                  │          │    │
                              │    │  │ Primary:         │    │ Primary:         │          │    │
                              │    │  │ S3-us-east-1     │    │ ALB-us-east-1    │          │    │
                              │    │  │                  │    │                  │          │    │
                              │    │  │ Failover:        │    │ Failover:        │          │    │
                              │    │  │ S3-us-west-2     │    │ ALB-us-west-2    │          │    │
                              │    │  └──────────────────┘    └──────────────────┘          │    │
                              │    │                                                         │    │
                              │    │  Failover Triggers: 500, 502, 503, 504, 403, 404       │    │
                              │    └─────────────────────────────────────────────────────────┘    │
                              │                                                                   │
                              │    ┌─────────────────────────────────────────────────────────┐    │
                              │    │                    Error Caching                         │    │
                              │    │                                                         │    │
                              │    │  - 5xx errors: Cache for 10 seconds (retry quickly)     │    │
                              │    │  - 4xx errors: Cache for 5 minutes (stable errors)      │    │
                              │    │  - Custom error pages: Served from S3                   │    │
                              │    └─────────────────────────────────────────────────────────┘    │
                              └───────────────────────────────────────────────────────────────────┘
```

**Failover Matrix:**

| Failure Scenario | Detection Method | Failover Mechanism | Recovery Time |
|------------------|------------------|-------------------|---------------|
| S3 bucket unavailable | Origin error (403/404) | Origin group failover | <10 seconds |
| ALB unhealthy | Origin error (502/503/504) | Origin group failover | <10 seconds |
| Primary region outage | Route 53 health check | DNS failover | <60 seconds |
| CloudFront edge issue | CloudFront automatic | Edge rerouting | <5 seconds |
| Complete origin failure | Multiple health checks | Custom error pages | Immediate |

**Health Check Strategy:**

| Check Type | Target | Interval | Threshold | Purpose |
|------------|--------|----------|-----------|---------|
| Route 53 Endpoint | /health on ALB | 30s | 3 failures | DNS failover trigger |
| CloudFront Origin | HTTP response codes | Per-request | Immediate | Origin group failover |
| CloudWatch Alarm | ALB 5xx rate | 1 min | >5% | Alerting/calculated checks |
| Synthetic Canary | Full user flow | 5 min | 2 failures | End-to-end monitoring |

## Consequences

### Positive
- **High Availability**: 99.99%+ availability through multi-layer failover
- **Fast Failover**: Origin group failover in <10 seconds
- **User Transparency**: Failover invisible to end users
- **Cache Resilience**: Stale content served during origin issues
- **Cost Efficiency**: No idle standby infrastructure (uses DR resources)
- **Comprehensive**: Handles partial and complete failure scenarios
- **Automated**: No manual intervention for common failures

### Negative
- **Complexity**: Multiple failover mechanisms to understand and test
- **Cross-Region Costs**: Data transfer between regions during failover
- **Cache Inconsistency**: Brief window of potential stale content
- **Testing Difficulty**: Hard to test all failure scenarios
- **Recovery Coordination**: Multiple systems to recover after failover

### Mitigation Strategies
- **Complexity**: Document all failover scenarios; create runbooks
- **Cross-Region Costs**: Accept as cost of availability; optimize with Origin Shield
- **Cache Inconsistency**: Use short error TTLs; implement cache invalidation
- **Testing**: Regular chaos engineering exercises; automated failover tests
- **Recovery**: Documented recovery procedures; automated health verification

## Alternatives Considered

### 1. Single Origin with No Failover
**Rejected because:**
- Single point of failure
- Origin issues cause complete outage
- Unacceptable for production workloads
- Does not meet 99.99% SLA
- No disaster recovery capability

### 2. Active-Active Multi-Region
**Rejected because:**
- Higher cost (2x infrastructure always running)
- Data synchronization complexity
- Overkill for current traffic levels
- Origin Shield reduces need for this
- Consider for future if traffic justifies

### 3. CloudFront Only (No Route 53 Failover)
**Rejected because:**
- Only handles origin-level failures
- Distribution-level issues not covered
- No protection against CloudFront regional issues
- Less comprehensive protection
- Route 53 adds minimal cost

### 4. Third-Party Failover Service
**Rejected because:**
- Additional cost and complexity
- Less AWS integration
- Another service to manage
- Route 53 + CloudFront covers needs
- No significant capability gap

### 5. Manual Failover Only
**Rejected because:**
- Slow response time (minutes to hours)
- Requires human availability
- Error-prone under pressure
- Does not meet recovery time objectives
- Unacceptable for production

## Implementation Details

### Origin Group Configuration
```yaml
OriginGroups:
  Quantity: 2
  Items:
    # Static Content Origin Group
    - Id: StaticContentOriginGroup
      FailoverCriteria:
        StatusCodes:
          Quantity: 6
          Items:
            - 500
            - 502
            - 503
            - 504
            - 403
            - 404
      Members:
        Quantity: 2
        Items:
          - OriginId: S3-Static-Primary      # us-east-1
          - OriginId: S3-Static-Secondary    # us-west-2
          
    # Dynamic Content Origin Group
    - Id: DynamicContentOriginGroup
      FailoverCriteria:
        StatusCodes:
          Quantity: 4
          Items:
            - 500
            - 502
            - 503
            - 504
      Members:
        Quantity: 2
        Items:
          - OriginId: ALB-Primary            # us-east-1
          - OriginId: ALB-Secondary          # us-west-2
```

### Cache Behavior with Origin Groups
```yaml
CacheBehaviors:
  # Static content uses static origin group
  - PathPattern: "/static/*"
    TargetOriginId: StaticContentOriginGroup
    ViewerProtocolPolicy: redirect-to-https
    CachePolicyId: !Ref OptimizedCachePolicy
    
  # API uses dynamic origin group
  - PathPattern: "/api/*"
    TargetOriginId: DynamicContentOriginGroup
    ViewerProtocolPolicy: https-only
    CachePolicyId: !Ref NoCachePolicy
    OriginRequestPolicyId: !Ref AllViewerPolicy

DefaultCacheBehavior:
  TargetOriginId: StaticContentOriginGroup
  ViewerProtocolPolicy: redirect-to-https
```

### Error Response Configuration
```yaml
CustomErrorResponses:
  # Server errors - short cache, allow retry
  - ErrorCode: 500
    ErrorCachingMinTTL: 10
    ResponseCode: 500
    ResponsePagePath: /errors/500.html
    
  - ErrorCode: 502
    ErrorCachingMinTTL: 10
    ResponseCode: 502
    ResponsePagePath: /errors/502.html
    
  - ErrorCode: 503
    ErrorCachingMinTTL: 10
    ResponseCode: 503
    ResponsePagePath: /errors/503.html
    
  - ErrorCode: 504
    ErrorCachingMinTTL: 10
    ResponseCode: 504
    ResponsePagePath: /errors/504.html
    
  # Client errors - longer cache
  - ErrorCode: 404
    ErrorCachingMinTTL: 300
    ResponseCode: 404
    ResponsePagePath: /errors/404.html
    
  - ErrorCode: 403
    ErrorCachingMinTTL: 300
    ResponseCode: 403
    ResponsePagePath: /errors/403.html
```

### Route 53 Failover Configuration
```yaml
# Primary record with health check
PrimaryRecord:
  Type: AWS::Route53::RecordSet
  Properties:
    HostedZoneId: !Ref HostedZone
    Name: app.terminus.solutions
    Type: A
    SetIdentifier: primary
    Failover: PRIMARY
    AliasTarget:
      DNSName: !GetAtt CloudFrontDistribution.DomainName
      HostedZoneId: Z2FDTNDATAQYW2
      EvaluateTargetHealth: true
    HealthCheckId: !Ref PrimaryHealthCheck

# Secondary record (DR)
SecondaryRecord:
  Type: AWS::Route53::RecordSet
  Properties:
    HostedZoneId: !Ref HostedZone
    Name: app.terminus.solutions
    Type: A
    SetIdentifier: secondary
    Failover: SECONDARY
    AliasTarget:
      DNSName: !GetAtt DRCloudFrontDistribution.DomainName
      HostedZoneId: Z2FDTNDATAQYW2
      EvaluateTargetHealth: true

# Health check for primary
PrimaryHealthCheck:
  Type: AWS::Route53::HealthCheck
  Properties:
    HealthCheckConfig:
      Type: HTTPS
      FullyQualifiedDomainName: health.terminus.solutions
      Port: 443
      ResourcePath: /health
      RequestInterval: 30
      FailureThreshold: 3
      MeasureLatency: true
      Regions:
        - us-east-1
        - us-west-2
        - eu-west-1
```

### Monitoring and Alerting
```yaml
# Origin Latency Alarm
OriginLatencyAlarm:
  Type: AWS::CloudWatch::Alarm
  Properties:
    AlarmName: CloudFront-High-Origin-Latency
    AlarmDescription: Origin latency exceeds threshold
    Namespace: AWS/CloudFront
    MetricName: OriginLatency
    Dimensions:
      - Name: DistributionId
        Value: !Ref CloudFrontDistribution
    Statistic: Average
    Period: 60
    EvaluationPeriods: 3
    Threshold: 2000  # 2 seconds
    ComparisonOperator: GreaterThanThreshold
    AlarmActions:
      - !Ref AlertingTopic

# Error Rate Alarm
ErrorRateAlarm:
  Type: AWS::CloudWatch::Alarm
  Properties:
    AlarmName: CloudFront-High-Error-Rate
    AlarmDescription: Error rate exceeds threshold
    Namespace: AWS/CloudFront
    MetricName: 5xxErrorRate
    Dimensions:
      - Name: DistributionId
        Value: !Ref CloudFrontDistribution
    Statistic: Average
    Period: 60
    EvaluationPeriods: 3
    Threshold: 1  # 1% error rate
    ComparisonOperator: GreaterThanThreshold
    AlarmActions:
      - !Ref AlertingTopic

# Failover Event Alert
FailoverEventRule:
  Type: AWS::Events::Rule
  Properties:
    Description: Alert on Route 53 health check status changes
    EventPattern:
      source:
        - aws.route53
      detail-type:
        - Route 53 Health Check Status Changed
    State: ENABLED
    Targets:
      - Arn: !Ref AlertingTopic
        Id: HealthCheckAlerts
```

### Synthetic Monitoring
```yaml
# CloudWatch Synthetics Canary
AvailabilityCanary:
  Type: AWS::Synthetics::Canary
  Properties:
    Name: terminus-availability-check
    RuntimeVersion: syn-nodejs-puppeteer-6.0
    ArtifactS3Location: s3://terminus-synthetics/canary-artifacts/
    Schedule:
      Expression: rate(5 minutes)
    StartCanaryAfterCreation: true
    Code:
      Handler: pageLoadBlueprint.handler
      Script: |
        const synthetics = require('Synthetics');
        const log = require('SyntheticsLogger');
        
        const pageLoadBlueprint = async function() {
            const urls = [
                'https://terminus.solutions',
                'https://api.terminus.solutions/health',
                'https://static.terminus.solutions/test.html'
            ];
            
            for (const url of urls) {
                await synthetics.executeStep('Verify ' + url, async function() {
                    const response = await synthetics.getPage().goto(url, {
                        waitUntil: 'domcontentloaded',
                        timeout: 30000
                    });
                    
                    if (response.status() !== 200) {
                        throw new Error('Expected 200, got ' + response.status());
                    }
                });
            }
        };
        
        exports.handler = async () => {
            return await pageLoadBlueprint();
        };
```

### Recovery Procedures
```yaml
RecoveryRunbook:
  Scenarios:
    OriginGroupFailover:
      Detection: CloudWatch alarm for origin errors
      AutomaticRecovery: true
      ManualSteps: None required
      Verification: Check cache hit rate returns to normal
      
    Route53Failover:
      Detection: Health check failure notification
      AutomaticRecovery: true
      ManualSteps:
        - Investigate primary region issue
        - Verify DR is handling traffic
        - Fix primary region
        - Verify primary health check passes
        - Traffic returns automatically
      Verification: Confirm traffic on both paths
      
    CompleteOriginFailure:
      Detection: All origins returning errors
      AutomaticRecovery: Custom error pages served
      ManualSteps:
        - Identify root cause
        - Restore at least one origin
        - Clear CloudFront cache if needed
        - Verify all origins healthy
      Verification: Full synthetic test pass
      
    CacheCorruption:
      Detection: User reports of incorrect content
      AutomaticRecovery: false
      ManualSteps:
        - Identify affected paths
        - Create cache invalidation
        - Wait for propagation (10-15 min)
        - Verify correct content serving
      Verification: Spot check affected URLs
```

## Implementation Timeline

### Phase 1: Origin Groups (Week 1)
- [x] Configure S3 bucket replication to DR region
- [x] Create origin groups for static content
- [x] Create origin groups for dynamic content
- [x] Test failover triggers

### Phase 2: Health Checks (Week 1-2)
- [x] Create Route 53 health checks
- [x] Configure calculated health checks
- [x] Set up DNS failover records
- [x] Verify failover timing

### Phase 3: Error Handling (Week 2)
- [x] Create custom error pages
- [x] Configure error caching TTLs
- [x] Test error page delivery
- [x] Document error scenarios

### Phase 4: Monitoring (Week 2-3)
- [x] Create CloudWatch dashboards
- [x] Set up CloudWatch alarms
- [x] Deploy synthetic canary
- [x] Document recovery procedures

**Total Implementation Time:** 3 weeks

## Related Implementation
This decision was implemented in [Lab 6: Route 53 & CloudFront Distribution](../../labs/lab-06-route53-cloudfront/README.md), which includes:
- Origin group configuration for automatic failover
- Route 53 health checks and failover routing
- Custom error pages and error caching
- Monitoring and alerting setup

## Success Metrics
- **Availability**: Target 99.99% uptime (4.32 minutes downtime/month max)
- **Failover Time**: Target <30 seconds for origin group failover
- **DNS Failover**: Target <60 seconds for Route 53 failover
- **Recovery Time**: Target <5 minutes for full recovery
- **False Positives**: Target 0 unnecessary failovers per month

## Review Date
2026-03-22 (3 months) - Review failover events, false positive rate, and consider active-active for high-traffic paths

## References
- [CloudFront Origin Groups](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/high_availability_origin_failover.html)
- [Route 53 Health Checks and Failover](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/dns-failover.html)
- [CloudWatch Synthetics](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Synthetics_Canaries.html)
- ADR-004: Multi-Region DR Network Design
- ADR-022: Global Content Delivery Strategy
- ADR-023: DNS Management and Routing

---

*This decision will be revisited if:*
- Availability falls below 99.9% in any month
- Failover time exceeds 60 seconds consistently
- Traffic growth justifies active-active architecture
- New AWS features provide better failover options
