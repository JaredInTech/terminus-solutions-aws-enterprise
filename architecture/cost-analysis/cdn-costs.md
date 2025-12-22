<!--
Terminus Solutions AWS Enterprise Architecture
Copyright (c) 2025 Jared (Terminus Solutions) - jaredintech.com
Licensed under CC BY-SA 4.0 - Attribution required
See LICENSE-DOCS for details
-->

# <img src="../../assets/logo.png" alt="Terminus Solutions" height="60"/> Lab-06 CDN & DNS Cost Considerations - Detailed Analysis

## Table of Contents

- [Free Tier Services Used](#-free-tier-services-used)
- [Cost Projections - CDN & DNS Infrastructure](#-cost-projections---cdn--dns-infrastructure)
  - [Small Organization](#-small-organization-single-domain-basic-cdn)
  - [Medium Organization](#-medium-organization-multi-domain-global-cdn)
  - [Enterprise Organization](#%EF%B8%8F-enterprise-organization-global-multi-region-waf)
- [Service-by-Service Cost Breakdown](#-service-by-service-cost-breakdown)
  - [Route 53 DNS Costs](#route-53-dns-costs)
  - [CloudFront CDN Costs](#cloudfront-cdn-costs)
  - [ACM Certificate Costs](#acm-certificate-costs)
  - [WAF Costs](#waf-costs)
  - [Lambda@Edge Costs](#lambdaedge-costs)
- [Cost Optimization Strategies](#%EF%B8%8F-cost-optimization-strategies)
  - [Immediate Optimizations](#-immediate-optimizations-quick-wins)
  - [CloudFront Price Class Strategy](#-cloudfront-price-class-strategy)
  - [Cache Optimization ROI](#-cache-optimization-roi)
- [CDN Architecture Cost Comparison](#-cdn-architecture-cost-comparison)
  - [CDN Provider Comparison](#-cdn-provider-comparison)
  - [Total CDN TCO](#-total-cdn-tco-3-year-projection)
- [Real-World Budget Planning](#-real-world-budget-planning)
  - [CDN Budget Allocation Guidelines](#-cdn-budget-allocation-guidelines)
  - [Cost Justification Framework](#-cost-justification-framework)
- [Cost Monitoring and Alerting](#-cost-monitoring-and-alerting)
  - [CDN Cost Anomaly Detection](#-cdn-cost-anomaly-detection)
  - [Automated Cost Optimization](#-automated-cost-optimization)
- [Cost Dashboard Metrics](#-cost-dashboard-metrics)
- [Monthly Cost Review Checklist](#-monthly-cost-review-checklist)
- [Project Navigation](#-project-navigation)

---

## 🆓 Free Tier Services Used

```
Route 53 Free Tier:
├── Health Checks: First 50 AWS endpoint health checks free
├── Alias Queries: Queries to Alias records pointing to AWS resources are free
├── Domain Registration: N/A (no free tier, but one-time annual cost)
└── Note: Hosted zone charges apply from day one

CloudFront Free Tier (First Year):
├── Data Transfer Out: 1TB/month free
├── HTTP/HTTPS Requests: 10,000,000/month free
├── CloudFront Functions: 2,000,000 invocations free
├── Invalidation Paths: 1,000 paths/month free
└── Note: After first year, all usage charged

ACM (AWS Certificate Manager):
├── Public SSL/TLS Certificates: Always FREE
├── Private CA Certificates: $400/month per CA
├── Certificate Renewal: Automatic and FREE
└── Note: Only private CA has costs

WAF Free Tier:
├── Web ACL: No free tier
├── Rules: No free tier
├── Requests: No free tier
└── Note: Pay-per-use from first request

Lambda@Edge Free Tier:
├── Requests: 1,000,000 free/month (shared with Lambda)
├── Compute: 400,000 GB-seconds free/month
└── Note: Standard Lambda free tier applies
```

---

## 📈 Cost Projections - CDN & DNS Infrastructure

### 🏢 Small Organization (Single Domain, Basic CDN)

```
Monthly CDN & DNS Costs:
├── Route 53: $2.90/month
│   ├── Hosted Zone (1): $0.50
│   ├── DNS Queries (~2M): $0.80
│   ├── Health Checks (3 endpoints): $1.50
│   └── Alias Queries: $0.00 (free to AWS resources)
├── CloudFront: $8.50/month
│   ├── Data Transfer (100GB): $8.50
│   │   └── Rate: $0.085/GB (first 10TB)
│   ├── HTTP Requests (5M): Included in transfer
│   └── HTTPS Requests (5M): Included in transfer
├── ACM Certificates: $0.00/month
│   └── Public certificates are free
├── WAF (Optional): $0.00/month
│   └── Not deployed in basic configuration
└── Total Estimated: $11.40/month ($137/year)

Traffic Profile:
├── Monthly Visitors: ~50,000
├── Data Transfer: ~100GB
├── Cache Hit Ratio: 70%
└── Geographic: Single region focus

Annual Cost: ~$137 USD
```

### 🏭 Medium Organization (Multi-Domain, Global CDN)

```
Monthly CDN & DNS Costs:
├── Route 53: $12.50/month
│   ├── Hosted Zones (5 domains): $2.50
│   ├── DNS Queries (~20M): $8.00
│   │   └── Rate: $0.40/M (first billion)
│   ├── Health Checks (10 endpoints): $5.00
│   │   └── HTTPS checks: $0.50 each
│   ├── Latency-Based Routing: Included
│   ├── Failover Routing: Included
│   └── Alias Queries: $0.00 (free)
├── CloudFront: $127.50/month
│   ├── Data Transfer (1TB): $85.00
│   │   └── Rate: $0.085/GB (first 10TB)
│   ├── Data Transfer (500GB to origin): $10.00
│   │   └── Origin fetches on cache miss
│   ├── HTTPS Requests (50M): $5.00
│   │   └── Rate: $0.0100/10,000
│   ├── Invalidations (2,000 paths): $5.00
│   │   └── First 1,000 free, $0.005 each after
│   ├── Origin Shield: $12.50
│   │   └── Additional caching layer
│   └── Real-Time Logs: $10.00
│       └── Kinesis Data Streams integration
├── ACM Certificates: $0.00/month
│   └── Wildcard + specific certs (all free)
├── WAF: $46.00/month
│   ├── Web ACL: $5.00
│   ├── Rules (10 rules): $10.00
│   │   └── Rate: $1.00 per rule
│   ├── Managed Rule Groups (3): $21.00
│   │   ├── Core Rule Set: $0.00 (free)
│   │   ├── Known Bad Inputs: $0.00 (free)
│   │   └── Bot Control: $10.00
│   └── Requests (50M): $10.00
│       └── Rate: $0.60/M for managed rules
├── Lambda@Edge: $8.00/month
│   ├── Requests (20M): $4.00
│   ├── Duration (128MB, 50ms avg): $4.00
│   └── Security headers, A/B testing
└── Total Estimated: $194.00/month ($2,328/year)

Traffic Profile:
├── Monthly Visitors: ~500,000
├── Data Transfer: ~1.5TB
├── Cache Hit Ratio: 85%
└── Geographic: Multi-region (Americas, Europe)

Annual Cost: ~$2,328 USD
```

### 🏛️ Enterprise Organization (Global, Multi-Region, Full WAF)

```
Monthly CDN & DNS Costs:
├── Route 53: $85.00/month
│   ├── Hosted Zones (20 domains): $10.00
│   ├── DNS Queries (~200M): $80.00
│   │   └── High volume pricing tiers
│   ├── Health Checks (50 endpoints): $25.00
│   │   ├── Standard HTTPS: 30x $0.50 = $15.00
│   │   └── With string matching: 20x $0.50 = $10.00
│   ├── Traffic Flow Policies (5): $50.00
│   │   └── Complex routing policies
│   ├── DNSSEC Signing: Included
│   └── Resolver Query Logging: $10.00
├── CloudFront: $1,275.00/month
│   ├── Data Transfer (10TB): $850.00
│   │   ├── First 10TB: $0.085/GB = $850
│   │   └── Next 40TB: $0.080/GB (if needed)
│   ├── HTTPS Requests (500M): $50.00
│   │   └── Rate: $0.0100/10,000
│   ├── Origin Shield (3 regions): $75.00
│   │   └── us-east-1, eu-west-1, ap-northeast-1
│   ├── Real-Time Logs: $50.00
│   │   └── High-volume streaming
│   ├── Field-Level Encryption: $20.00
│   ├── Invalidations (10,000 paths): $45.00
│   └── Origin Failover Groups: Included
├── ACM Certificates: $0.00/month
│   └── All public certificates free
├── WAF: $385.00/month
│   ├── Web ACLs (3 - by environment): $15.00
│   ├── Rules (30 custom rules): $30.00
│   ├── Managed Rule Groups: $60.00
│   │   ├── Core Rule Set: $0.00
│   │   ├── Known Bad Inputs: $0.00
│   │   ├── SQL Database: $0.00
│   │   ├── Bot Control: $10.00
│   │   ├── Account Takeover Prevention: $10.00
│   │   └── Fraud Control: $10.00
│   ├── Requests (500M): $180.00
│   │   └── Rate: $0.60/M for managed rules
│   ├── Intelligent Threat Mitigation: $50.00
│   └── Logging to S3: $50.00
├── Lambda@Edge: $120.00/month
│   ├── Requests (100M): $20.00
│   ├── Duration (256MB, 100ms avg): $80.00
│   ├── Security transformations: Included
│   └── Geographic personalization: Included
├── AWS Shield Advanced (Optional): $3,000.00/month
│   ├── Subscription: $3,000.00
│   ├── DDoS Cost Protection: Included
│   └── 24/7 DDoS Response Team: Included
└── Total (without Shield): $1,865.00/month ($22,380/year)
└── Total (with Shield): $4,865.00/month ($58,380/year)

Traffic Profile:
├── Monthly Visitors: ~5,000,000
├── Data Transfer: ~10TB+
├── Cache Hit Ratio: 92%
└── Geographic: Global (all edge locations)

Annual Cost: ~$22,380 USD (without Shield Advanced)
Annual Cost: ~$58,380 USD (with Shield Advanced)
```

---

## 💵 Service-by-Service Cost Breakdown

### Route 53 DNS Costs

```
Route 53 Pricing Components:
├── Hosted Zones
│   ├── First 25 hosted zones: $0.50/month each
│   └── Additional zones: $0.10/month each
│
├── DNS Queries (Standard)
│   ├── First 1 billion/month: $0.40 per million
│   └── Over 1 billion/month: $0.20 per million
│
├── Latency-Based Routing Queries
│   ├── First 1 billion/month: $0.60 per million
│   └── Over 1 billion/month: $0.30 per million
│
├── Geo DNS and Geoproximity Queries
│   ├── First 1 billion/month: $0.70 per million
│   └── Over 1 billion/month: $0.35 per million
│
├── Health Checks
│   ├── Basic (HTTP/TCP, AWS endpoints): FREE (first 50)
│   ├── Basic (HTTP/TCP, non-AWS): $0.50/month
│   ├── HTTPS health checks: $0.50/month
│   ├── With string matching: +$0.50/month
│   ├── Fast interval (10 sec): +$1.00/month
│   └── Calculated health checks: $0.50/month
│
├── Domain Registration (Annual)
│   ├── .com: $13/year
│   ├── .net: $12/year
│   ├── .org: $13/year
│   ├── .io: $39/year
│   └── .solutions: $24/year
│
└── Traffic Flow
    ├── Policy record: $50/month per policy
    └── Geoproximity routing: Included with Traffic Flow
```

### CloudFront CDN Costs

```
CloudFront Pricing (Regional Pricing - US/Europe):
├── Data Transfer Out to Internet
│   ├── First 10 TB/month: $0.085/GB
│   ├── Next 40 TB/month: $0.080/GB
│   ├── Next 100 TB/month: $0.060/GB
│   ├── Next 350 TB/month: $0.040/GB
│   └── Over 500 TB/month: Custom pricing
│
├── Data Transfer to Origin
│   ├── All regions: $0.020/GB
│   └── Note: Only on cache misses
│
├── HTTP/HTTPS Requests
│   ├── HTTP: $0.0075 per 10,000 requests
│   └── HTTPS: $0.0100 per 10,000 requests
│
├── Origin Shield (Per Region)
│   └── Additional requests: $0.0090 per 10,000
│
├── Real-Time Logs
│   ├── Per log line: $0.01 per million
│   └── Plus Kinesis Data Streams costs
│
├── Field-Level Encryption
│   └── Per request: $0.02 per 10,000
│
├── Invalidation Requests
│   ├── First 1,000 paths/month: FREE
│   └── Additional paths: $0.005 per path
│
└── Price Classes (Data Transfer Savings)
    ├── All Edge Locations: Full price
    ├── Price Class 200: ~10-20% cheaper (excludes expensive regions)
    └── Price Class 100: ~20-30% cheaper (US, Europe only)
```

### ACM Certificate Costs

```
ACM Certificate Pricing:
├── Public SSL/TLS Certificates
│   ├── Certificate issuance: FREE
│   ├── Certificate renewal: FREE (automatic)
│   ├── Wildcard certificates: FREE
│   └── Multi-domain (SAN): FREE
│
├── Private Certificate Authority
│   ├── Monthly fee: $400/month per CA
│   ├── Certificates issued: $0.75 per certificate (first 1000)
│   └── Bulk pricing: $0.35 per certificate (10,000+)
│
└── Important Notes:
    ├── CloudFront requires certificates in us-east-1
    ├── Regional services use regional certificates
    └── No charge for ACM certificates used with AWS services
```

### WAF Costs

```
AWS WAF Pricing:
├── Web ACL
│   └── Monthly fee: $5.00 per Web ACL
│
├── Rules
│   └── Monthly fee: $1.00 per rule per Web ACL
│
├── Requests Inspected
│   └── Base rate: $0.60 per million requests
│
├── Managed Rule Groups
│   ├── AWS Managed Rules (Basic)
│   │   ├── Core Rule Set: FREE
│   │   ├── Admin Protection: FREE
│   │   ├── Known Bad Inputs: FREE
│   │   ├── SQL Database: FREE
│   │   ├── Linux/Unix OS: FREE
│   │   ├── Windows OS: FREE
│   │   ├── PHP Application: FREE
│   │   └── WordPress: FREE
│   │
│   ├── AWS Managed Rules (Premium)
│   │   ├── Bot Control: $10.00/month + $1.00/M requests
│   │   ├── Account Takeover Prevention: $10.00/month
│   │   └── Fraud Control: $10.00/month
│   │
│   └── Marketplace Rule Groups: Varies by vendor
│
├── Intelligent Threat Mitigation
│   ├── CAPTCHA: $0.40 per 1,000 challenge attempts
│   └── Challenge: $0.40 per 1,000 challenge attempts
│
└── Logging
    ├── CloudWatch Logs: Standard CloudWatch pricing
    ├── S3: Standard S3 pricing
    └── Kinesis Data Firehose: Standard Firehose pricing
```

### Lambda@Edge Costs

```
Lambda@Edge Pricing:
├── Requests
│   ├── Price: $0.60 per million requests
│   └── Free tier: 1M requests/month (shared with Lambda)
│
├── Duration
│   ├── Price: $0.00000625 per 128MB-second
│   ├── Minimum: 1ms billing granularity
│   └── Free tier: 400,000 GB-seconds/month
│
├── Regional Execution (Viewer Request/Response)
│   ├── Max memory: 128MB
│   ├── Max timeout: 5 seconds
│   └── Package size: 1MB
│
├── Origin Execution (Origin Request/Response)
│   ├── Max memory: 10GB
│   ├── Max timeout: 30 seconds
│   └── Package size: 50MB
│
└── CloudFront Functions (Alternative for Simple Logic)
    ├── Requests: $0.10 per million
    ├── Execution: Free (included in request cost)
    ├── Max memory: 2MB
    ├── Max timeout: 1ms
    └── 10x cheaper than Lambda@Edge for simple tasks
```

---

## ⚙️ Cost Optimization Strategies

### 💡 Immediate Optimizations (Quick Wins)

```bash
# 1. Use Alias Records Instead of CNAME (Free Queries)
# Alias to CloudFront: $0.00 per query
# CNAME to CloudFront: $0.40 per million queries
# Savings: 100% on DNS query costs for AWS resources

# 2. Consolidate Hosted Zones
# Before: 10 separate zones = $5.00/month
# After: Subdomains in single zone = $0.50/month
# Savings: $4.50/month ($54/year)

# 3. Remove Unused Health Checks
aws route53 list-health-checks --query 'HealthChecks[*].[Id,HealthCheckConfig.FullyQualifiedDomainName]' --output table
# Review and delete orphaned health checks

# 4. Use CloudFront Functions Instead of Lambda@Edge
# Lambda@Edge: $0.60 per million requests
# CloudFront Functions: $0.10 per million requests
# Savings: 83% for simple transformations (headers, redirects)
```

### 📊 CloudFront Price Class Strategy

```
Price Class Comparison (1TB Monthly Transfer):
├── All Edge Locations
│   ├── Coverage: Global (400+ locations)
│   ├── Cost: ~$85.00/month
│   └── Use when: Global audience is critical
│
├── Price Class 200
│   ├── Coverage: US, Canada, Europe, Asia, Middle East, Africa
│   ├── Cost: ~$72.00/month
│   ├── Savings: ~15% vs All
│   └── Use when: South America/Australia traffic is minimal
│
├── Price Class 100
│   ├── Coverage: US, Canada, Europe
│   ├── Cost: ~$60.00/month
│   ├── Savings: ~30% vs All
│   └── Use when: Primarily North American/European audience
│
└── Recommendation by Traffic Pattern:
    ├── Startup (US-focused): Price Class 100
    ├── Growth (Multi-region): Price Class 200
    └── Enterprise (Global): All Edge Locations
```

### 📈 Cache Optimization ROI

```
Cache Hit Ratio Impact on Costs:

Scenario: 10TB monthly traffic, 100M requests

Cache Hit Ratio: 50%
├── Origin Transfer: 5TB × $0.02 = $100.00
├── CloudFront Transfer: 10TB × $0.085 = $850.00
└── Total: $950.00/month

Cache Hit Ratio: 80%
├── Origin Transfer: 2TB × $0.02 = $40.00
├── CloudFront Transfer: 10TB × $0.085 = $850.00
└── Total: $890.00/month

Cache Hit Ratio: 95%
├── Origin Transfer: 500GB × $0.02 = $10.00
├── CloudFront Transfer: 10TB × $0.085 = $850.00
└── Total: $860.00/month

Improvement Strategies:
├── Increase TTL for static assets: 1 year for versioned files
├── Normalize query strings: Sort and filter parameters
├── Enable Origin Shield: Consolidate cache misses
├── Use cache policies: Minimize cache key variations
└── Implement versioned URLs: Avoid invalidations

Origin Shield ROI:
├── Cost: ~$0.0090 per 10,000 requests
├── Benefit: 50-80% reduction in origin requests
├── Break-even: When origin costs exceed Shield fees
└── Best for: Dynamic content, multiple edge pops
```

---

## 🆚 CDN Architecture Cost Comparison

### 🌐 CDN Provider Comparison

```
Monthly Cost Comparison (1TB transfer, 50M requests):

AWS CloudFront:
├── Data Transfer: $85.00
├── Requests: $5.00
├── Total: $90.00
├── Pros: Deep AWS integration, Origin Shield, Lambda@Edge
└── Cons: Higher base price

Cloudflare Pro:
├── Plan Cost: $20.00/month (flat)
├── Data Transfer: Unlimited
├── Total: $20.00
├── Pros: Flat pricing, DDoS protection included
└── Cons: Less AWS integration, limited customization

Fastly:
├── Data Transfer: $80.00 ($0.08/GB)
├── Requests: $7.50
├── Total: $87.50
├── Pros: Real-time purging, edge compute
└── Cons: Complex pricing, higher request costs

Akamai:
├── Typical Cost: $150-300 (enterprise contracts)
├── Data Transfer: Volume-based discounts
├── Total: ~$200.00 (estimated)
├── Pros: Enterprise features, global coverage
└── Cons: High minimum commitment, complex pricing

CloudFront Value Proposition:
├── Native AWS integration (ALB, S3, EC2)
├── IAM-based access control
├── Same billing account consolidation
├── Origin Shield for origin protection
├── Lambda@Edge for edge compute
└── Unified monitoring with CloudWatch
```

### 💰 Total CDN TCO (3-Year Projection)

```
Small Organization - 3 Year TCO:

CloudFront + Route 53 (This Implementation):
├── Year 1: $137 (CDN + DNS)
├── Year 2: $160 (growth adjustment)
├── Year 3: $185 (continued growth)
├── Total: $482

Alternative (Self-Managed):
├── VPS for CDN/DNS: $1,080 ($30/month)
├── SSL Certificates: $300 (commercial certs)
├── Management time: $2,400 (10 hrs/year @ $80/hr)
├── Downtime costs: $500 (estimated)
├── Total: $4,280

Savings with AWS: $3,798 (89% reduction)

---

Medium Organization - 3 Year TCO:

CloudFront + Route 53 + WAF:
├── Year 1: $2,328
├── Year 2: $2,800 (traffic growth)
├── Year 3: $3,400 (expanded WAF rules)
├── Total: $8,528

Alternative (Enterprise CDN + Separate WAF):
├── Enterprise CDN: $7,200/year
├── Separate WAF Appliance: $12,000/year
├── DDoS Protection: $5,000/year
├── Management: $10,000/year
├── Total: $102,600

Savings with AWS: $94,072 (92% reduction)

---

Enterprise Organization - 3 Year TCO:

CloudFront + Route 53 + WAF + Shield Advanced:
├── Year 1: $58,380
├── Year 2: $65,000 (traffic growth)
├── Year 3: $72,000 (expanded coverage)
├── Total: $195,380

Alternative (Enterprise Stack):
├── Akamai CDN: $300,000/year
├── F5/Imperva WAF: $150,000/year
├── DDoS Protection: $100,000/year
├── 24/7 NOC Support: $250,000/year
├── Total: $2,400,000

Savings with AWS: $2,204,620 (92% reduction)
```

---

## 📋 Real-World Budget Planning

### 💼 CDN Budget Allocation Guidelines

```
CDN Infrastructure Budget Distribution:

Startup/Small Business (< $500/month total AWS):
├── Route 53 DNS: 3% (~$3-5)
├── CloudFront CDN: 7% (~$8-15)
├── WAF: 0% (not deployed)
├── Certificates: 0% (free ACM)
└── Total CDN: ~10% of AWS budget

Growth Stage ($500-5,000/month total AWS):
├── Route 53 DNS: 1% (~$15-25)
├── CloudFront CDN: 4% (~$100-200)
├── WAF: 1% (~$50-100)
├── Lambda@Edge: 0.5% (~$10-25)
└── Total CDN: ~6.5% of AWS budget

Enterprise ($5,000+/month total AWS):
├── Route 53 DNS: 0.5% (~$50-100)
├── CloudFront CDN: 3% (~$500-2,000)
├── WAF: 1% (~$200-500)
├── Lambda@Edge: 0.5% (~$50-200)
├── Shield Advanced: 5-10% (~$3,000)
└── Total CDN: ~5-15% of AWS budget
```

### 📊 Cost Justification Framework

```
CDN Investment ROI Calculation:

Direct Cost Savings:
├── Origin bandwidth reduction: 80% (cache hits)
├── Origin compute reduction: 60% (fewer requests)
├── DDoS mitigation (avoided downtime): $10,000+/incident
└── Estimated annual savings: $5,000-50,000

Performance Benefits (Indirect):
├── Page load improvement: 50-70% faster
├── Conversion rate increase: 7% per second saved
├── SEO ranking improvement: Measurable
└── Estimated revenue impact: 2-5% increase

Security Benefits:
├── DDoS protection: Included with CloudFront
├── WAF protection: OWASP Top 10 coverage
├── Bot mitigation: Reduced fraud/scraping
└── Compliance: PCI DSS, SOC 2 compatible

Total Value Delivered:
├── Small org: 5-10x return on CDN investment
├── Medium org: 10-20x return on CDN investment
└── Enterprise: 20-50x return on CDN investment
```

---

## 🔔 Cost Monitoring and Alerting

### 📊 CDN Cost Anomaly Detection

```bash
# Create Cost Anomaly Monitor for CDN Services
aws ce create-anomaly-monitor \
  --anomaly-monitor '{
    "MonitorName": "terminus-cdn-cost-monitor",
    "MonitorType": "DIMENSIONAL",
    "MonitorDimension": "SERVICE"
  }'

# Create Alert Subscription
aws ce create-anomaly-subscription \
  --anomaly-subscription '{
    "SubscriptionName": "cdn-cost-alerts",
    "MonitorArnList": ["MONITOR_ARN"],
    "Subscribers": [
      {
        "Type": "EMAIL",
        "Address": "cloud-costs@terminus.solutions"
      }
    ],
    "Threshold": 20
  }'
```

### 🤖 Automated Cost Optimization

```yaml
CloudWatch Alarms for CDN Cost Control:

Route 53 Query Volume:
  MetricName: DNSQueries
  Threshold: 10,000,000 queries/day
  Action: SNS notification for traffic spike

CloudFront Data Transfer:
  MetricName: BytesDownloaded
  Threshold: 500 GB/day
  Action: Review cache settings, check for abuse

CloudFront Cache Hit Ratio:
  MetricName: CacheHitRate
  Threshold: < 70%
  Action: Review cache policy, adjust TTLs

WAF Blocked Requests:
  MetricName: BlockedRequests
  Threshold: > 10% of total requests
  Action: Review rules for false positives

Lambda@Edge Errors:
  MetricName: Errors
  Threshold: > 1% error rate
  Action: Review function code, check timeouts
```

```bash
# Monthly Cost Report Script
#!/bin/bash

START_DATE=$(date -d "first day of last month" +%Y-%m-%d)
END_DATE=$(date -d "last day of last month" +%Y-%m-%d)

echo "=== CDN Cost Report: $START_DATE to $END_DATE ==="

# Route 53 Costs
aws ce get-cost-and-usage \
  --time-period Start=$START_DATE,End=$END_DATE \
  --granularity MONTHLY \
  --metrics "UnblendedCost" \
  --filter '{
    "Dimensions": {
      "Key": "SERVICE",
      "Values": ["Amazon Route 53"]
    }
  }' \
  --query 'ResultsByTime[0].Total.UnblendedCost.Amount'

# CloudFront Costs
aws ce get-cost-and-usage \
  --time-period Start=$START_DATE,End=$END_DATE \
  --granularity MONTHLY \
  --metrics "UnblendedCost" \
  --filter '{
    "Dimensions": {
      "Key": "SERVICE",
      "Values": ["Amazon CloudFront"]
    }
  }' \
  --query 'ResultsByTime[0].Total.UnblendedCost.Amount'

# WAF Costs
aws ce get-cost-and-usage \
  --time-period Start=$START_DATE,End=$END_DATE \
  --granularity MONTHLY \
  --metrics "UnblendedCost" \
  --filter '{
    "Dimensions": {
      "Key": "SERVICE",
      "Values": ["AWS WAF"]
    }
  }' \
  --query 'ResultsByTime[0].Total.UnblendedCost.Amount'
```

---

## 📈 Cost Dashboard Metrics

```
Key Metrics to Track:

Route 53:
├── DNS queries by hosted zone
├── Health check count and status
├── Query latency by routing policy
└── Cost per million queries

CloudFront:
├── Data transfer by distribution
├── Request count (HTTP vs HTTPS)
├── Cache hit ratio by behavior
├── Origin latency and errors
├── Geographic distribution of traffic
└── Cost per GB transferred

WAF:
├── Requests inspected
├── Blocked vs allowed requests
├── Rule match distribution
├── Bot detection statistics
└── Cost per million requests

Lambda@Edge:
├── Invocation count by function
├── Duration percentiles (P50, P95, P99)
├── Error rates by region
└── Cost per million invocations
```

---

## ✅ Monthly Cost Review Checklist

```
Weekly Quick Check:
□ Review CloudFront cache hit ratio (target: >80%)
□ Check for unusual traffic spikes
□ Verify health checks are passing
□ Monitor WAF blocked request rate

Monthly Deep Review:
□ Analyze DNS query patterns for optimization
□ Review CloudFront price class appropriateness
□ Audit WAF rules for effectiveness vs cost
□ Check Lambda@Edge error rates and duration
□ Compare actual vs budgeted CDN costs
□ Identify unused health checks or distributions
□ Review Origin Shield utilization
□ Validate SSL certificate expiration dates

Quarterly Optimization:
□ Re-evaluate price class based on traffic patterns
□ Review and consolidate hosted zones
□ Audit WAF managed rule group necessity
□ Consider Reserved Capacity for predictable workloads
□ Benchmark against CDN alternatives
□ Update cache policies based on content changes
□ Review Lambda@Edge for CloudFront Functions migration
□ Negotiate volume discounts if applicable
```

---

*Last Updated: December 2025*

*Note: All costs are estimates based on AWS pricing as of December 2025. Actual costs may vary based on usage patterns, region, and AWS pricing changes. Data transfer costs assume US/Europe regions; other regions may have different pricing.*