<!--
Terminus Solutions AWS Enterprise Architecture
Copyright (c) 2025 Jared (Terminus Solutions) - jaredintech.com
Licensed under CC BY-SA 4.0 - Attribution required
See LICENSE-DOCS for details
-->

# ADR-022: Global Content Delivery Strategy

## Date
2025-12-22

## Status
Accepted

## Context
With our storage infrastructure established (ADR-012 through ADR-016), Terminus Solutions needs to implement a global content delivery strategy to serve users worldwide with optimal performance. This decision determines our approach to edge caching, origin architecture, and content optimization to meet performance SLAs while controlling costs.

Key requirements and constraints:
- Must achieve <100ms Time to First Byte (TTFB) for cached content globally
- Require >90% cache hit rate for static content
- Support multiple origin types (S3, ALB, custom origins)
- Enable content optimization (compression, image formats)
- Integrate with existing S3 storage architecture (ADR-012)
- Minimize origin load through effective caching
- Support real-time content updates when needed
- Budget conscious—optimize edge location coverage vs. cost
- Scale automatically with traffic spikes (10x normal load)
- Meet compliance requirements for content restrictions

Current challenges:
- S3 direct access has high latency for global users (300-500ms from Asia)
- No edge caching increases origin bandwidth costs
- Static and dynamic content served through same path
- No content optimization at delivery layer
- Manual cache management for content updates

## Decision
We will implement Amazon CloudFront as our global content delivery network with a multi-origin architecture, intelligent cache behaviors, and Origin Shield for origin protection.

**CDN Architecture:**
```
                                    ┌─────────────────────────────────────────────────────────────┐
                                    │                     CloudFront Distribution                  │
                                    │                                                             │
    ┌──────────────┐               │  ┌─────────────────────────────────────────────────────┐    │
    │   Global     │               │  │                   Edge Locations                    │    │
    │   Users      │───────────────│──│  ┌─────────┐  ┌─────────┐  ┌─────────┐            │    │
    │              │               │  │  │ N.America│  │ Europe  │  │  Asia   │  ...       │    │
    └──────────────┘               │  │  │ (50+)   │  │ (30+)   │  │ (40+)   │            │    │
                                    │  │  └────┬────┘  └────┬────┘  └────┬────┘            │    │
                                    │  │       │            │            │                 │    │
                                    │  └───────┼────────────┼────────────┼─────────────────┘    │
                                    │          │            │            │                      │
                                    │          └────────────┼────────────┘                      │
                                    │                       │                                   │
                                    │                       ▼                                   │
                                    │          ┌────────────────────────┐                       │
                                    │          │     Origin Shield      │                       │
                                    │          │   (us-east-1 Region)   │                       │
                                    │          └───────────┬────────────┘                       │
                                    │                      │                                    │
                                    └──────────────────────┼────────────────────────────────────┘
                                                           │
                           ┌───────────────────────────────┼───────────────────────────────┐
                           │                               │                               │
                           ▼                               ▼                               ▼
                  ┌─────────────────┐            ┌─────────────────┐            ┌─────────────────┐
                  │   S3 Origin     │            │   ALB Origin    │            │  S3 Media       │
                  │ (Static Content)│            │(Dynamic Content)│            │    Origin       │
                  │                 │            │                 │            │                 │
                  │ - HTML/CSS/JS   │            │ - API responses │            │ - Images/Video  │
                  │ - Fonts/Icons   │            │ - User data     │            │ - Documents     │
                  │ - Public assets │            │ - Auth flows    │            │ - Large files   │
                  └─────────────────┘            └─────────────────┘            └─────────────────┘
```

**Cache Behavior Strategy:**

| Path Pattern | Origin | TTL | Cache Policy | Compression |
|--------------|--------|-----|--------------|-------------|
| `/api/*` | ALB | 0 | No cache | Yes |
| `/static/*` | S3-Static | 1 year | Optimized | Yes |
| `/media/*` | S3-Media | 7 days | Optimized | No |
| `/assets/*` | S3-Static | 30 days | Optimized | Yes |
| `/*` (default) | S3-Static | 1 day | Standard | Yes |

**Origin Shield Configuration:**
- Region: us-east-1 (closest to primary origins)
- Purpose: Consolidate origin requests, improve cache hit ratio
- Expected improvement: 20-30% reduction in origin requests

## Consequences

### Positive
- **Global Performance**: Sub-100ms TTFB from 400+ edge locations worldwide
- **Origin Protection**: Origin Shield reduces origin load by 60-80%
- **Cost Reduction**: 40-60% savings vs. direct S3 data transfer
- **Automatic Scaling**: Handles traffic spikes without infrastructure changes
- **Content Optimization**: Automatic compression reduces bandwidth 70%+
- **Cache Efficiency**: Behavior-specific TTLs maximize hit rates
- **Security Integration**: Native WAF and Shield integration at edge

### Negative
- **Cache Invalidation Costs**: $0.005 per path after first 1,000/month
- **Configuration Complexity**: Multiple behaviors require careful management
- **Propagation Delays**: Distribution changes take 15-20 minutes
- **Debugging Challenges**: Cached content harder to troubleshoot
- **Regional Pricing**: Some regions have higher per-GB costs

### Mitigation Strategies
- **Invalidation Costs**: Use versioned URLs (query strings) for cache busting instead of invalidations
- **Complexity**: Document all behaviors clearly; use infrastructure as code
- **Propagation**: Plan deployments around propagation time; use staging distribution
- **Debugging**: Enable detailed logging; use cache-control headers for testing
- **Regional Costs**: Use Price Class 100 (NA/EU only) for cost-sensitive workloads

## Alternatives Considered

### 1. S3 Static Website Hosting Only
**Rejected because:**
- Single region limits global performance (300-500ms latency from Asia)
- No edge caching capability
- Higher data transfer costs ($0.09/GB vs $0.085/GB from CloudFront)
- No DDoS protection included
- Limited caching control (browser cache only)

### 2. Cloudflare CDN
**Rejected because:**
- Requires DNS migration away from Route 53
- Less native AWS integration
- Free tier limitations for production use
- Separate billing and support relationships
- Additional vendor management overhead

### 3. Fastly CDN
**Rejected because:**
- Higher costs for our traffic volume
- Less AWS service integration
- Separate configuration and monitoring
- Learning curve for team
- VCL configuration complexity

### 4. AWS Global Accelerator
**Rejected because:**
- Designed for dynamic content (TCP/UDP optimization)
- No edge caching capability
- Higher cost for static content delivery
- Better suited for non-HTTP workloads
- Overkill for content delivery use case

### 5. Multi-Region S3 with Latency-Based Routing
**Rejected because:**
- Requires maintaining multiple S3 buckets with identical content
- Complex synchronization requirements
- Higher storage costs (3x for 3 regions)
- No edge caching benefits
- Still higher latency than edge delivery

## Implementation Details

### CloudFront Distribution Configuration
```yaml
Distribution:
  Enabled: true
  Comment: "Terminus Solutions Production CDN"
  PriceClass: PriceClass_100  # North America and Europe
  HttpVersion: http2and3
  IsIPV6Enabled: true
  DefaultRootObject: index.html
  
  Origins:
    - Id: S3-Static-Primary
      DomainName: terminus-static.s3.us-east-1.amazonaws.com
      S3OriginConfig:
        OriginAccessIdentity: ""
      OriginAccessControlId: !Ref OriginAccessControl
      OriginShield:
        Enabled: true
        OriginShieldRegion: us-east-1
        
    - Id: ALB-Dynamic
      DomainName: internal-terminus-alb.us-east-1.elb.amazonaws.com
      CustomOriginConfig:
        HTTPSPort: 443
        OriginProtocolPolicy: https-only
        OriginSSLProtocols: [TLSv1.2]
      OriginShield:
        Enabled: true
        OriginShieldRegion: us-east-1
        
    - Id: S3-Media
      DomainName: terminus-media.s3.us-east-1.amazonaws.com
      S3OriginConfig:
        OriginAccessIdentity: ""
      OriginAccessControlId: !Ref OriginAccessControl
```

### Cache Behavior Configuration
```yaml
CacheBehaviors:
  # API - No caching
  - PathPattern: "/api/*"
    TargetOriginId: ALB-Dynamic
    ViewerProtocolPolicy: https-only
    AllowedMethods: [GET, HEAD, OPTIONS, PUT, POST, PATCH, DELETE]
    CachePolicyId: !Ref CachingDisabledPolicy
    OriginRequestPolicyId: !Ref AllViewerPolicy
    Compress: true
    
  # Static assets - Long cache
  - PathPattern: "/static/*"
    TargetOriginId: S3-Static-Primary
    ViewerProtocolPolicy: https-only
    AllowedMethods: [GET, HEAD]
    CachePolicyId: !Ref CachingOptimizedPolicy
    Compress: true
    
  # Media files - Medium cache
  - PathPattern: "/media/*"
    TargetOriginId: S3-Media
    ViewerProtocolPolicy: https-only
    AllowedMethods: [GET, HEAD]
    CachePolicyId: !Ref MediaCachePolicy
    Compress: false  # Already compressed media
    
DefaultCacheBehavior:
  TargetOriginId: S3-Static-Primary
  ViewerProtocolPolicy: redirect-to-https
  AllowedMethods: [GET, HEAD]
  CachePolicyId: !Ref StandardCachePolicy
  Compress: true
```

### Cache Policy Definitions
```yaml
CachingOptimizedPolicy:
  DefaultTTL: 86400      # 1 day
  MaxTTL: 31536000       # 1 year
  MinTTL: 1
  ParametersInCacheKeyAndForwardedToOrigin:
    EnableAcceptEncodingGzip: true
    EnableAcceptEncodingBrotli: true
    HeadersConfig:
      HeaderBehavior: none
    CookiesConfig:
      CookieBehavior: none
    QueryStringsConfig:
      QueryStringBehavior: whitelist
      QueryStrings: [v, version]  # Version query strings

MediaCachePolicy:
  DefaultTTL: 604800     # 7 days
  MaxTTL: 2592000        # 30 days
  MinTTL: 86400          # 1 day minimum
  ParametersInCacheKeyAndForwardedToOrigin:
    EnableAcceptEncodingGzip: false
    EnableAcceptEncodingBrotli: false
    HeadersConfig:
      HeaderBehavior: none
    CookiesConfig:
      CookieBehavior: none
    QueryStringsConfig:
      QueryStringBehavior: none
```

### Content Optimization Settings
```yaml
Compression:
  Enabled: true
  SupportedFormats:
    - gzip
    - br (Brotli)
  ApplicableTypes:
    - text/html
    - text/css
    - text/javascript
    - application/javascript
    - application/json
    - image/svg+xml
    - application/xml
  ExpectedReduction: 70-90%

ErrorPages:
  - ErrorCode: 404
    ResponseCode: 404
    ResponsePagePath: /errors/404.html
    ErrorCachingMinTTL: 300
  - ErrorCode: 503
    ResponseCode: 503
    ResponsePagePath: /errors/maintenance.html
    ErrorCachingMinTTL: 60
```

## Implementation Timeline

### Phase 1: Foundation (Week 1)
- [x] Create CloudFront distribution with S3 origin
- [x] Configure Origin Access Control for S3
- [x] Enable Origin Shield in us-east-1
- [x] Set up default cache behavior

### Phase 2: Multi-Origin (Week 2)
- [x] Add ALB origin for dynamic content
- [x] Configure API cache behavior (no-cache)
- [x] Add media origin with optimized caching
- [x] Test origin failover configuration

### Phase 3: Optimization (Week 3)
- [x] Enable compression for text content
- [x] Configure custom error pages
- [x] Set up cache invalidation automation
- [x] Implement versioned URLs for static assets

**Total Implementation Time:** 3 weeks

## Related Implementation
This decision was implemented in [Lab 6: Route 53 & CloudFront Distribution](../../labs/lab-06-route53-cloudfront/README.md), which includes:
- Multi-origin CloudFront distribution configuration
- Cache behavior optimization for different content types
- Origin Shield implementation
- Integration with S3 buckets from Lab 4

## Success Metrics
- **Cache Hit Rate**: Target >90%, measuring monthly via CloudWatch
- **Global TTFB**: Target <100ms, measured from key geographic locations
- **Origin Request Reduction**: Target 80% reduction via Origin Shield
- **Compression Ratio**: Target 70%+ for text content
- **Error Rate**: Target <0.1% 4xx/5xx errors

## Review Date
2026-06-22 (6 months) - Evaluate cache efficiency, cost optimization opportunities, and potential for additional edge locations

## References
- [Amazon CloudFront Developer Guide](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/)
- [CloudFront Origin Shield](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/origin-shield.html)
- [Cache Policy Best Practices](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/controlling-the-cache-key.html)
- ADR-012: Object Storage Strategy
- ADR-013: Static Content Delivery

---

*This decision will be revisited if:*
- Cache hit rates fall below 85% consistently
- New geographic markets require expanded edge coverage
- Cost per GB exceeds $0.10 for extended periods
- Performance SLAs are not met in key regions
