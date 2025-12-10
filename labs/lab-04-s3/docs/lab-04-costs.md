## Table of Contents

- [Cost Summary](#-cost-summary)
- [Storage Class Breakdown](#-storage-class-breakdown)
- [Data Transfer Costs](#-data-transfer-costs)
- [Request Pricing](#-request-pricing)
- [Cost Optimization Strategies](#-cost-optimization-strategies)
- [Monthly Cost Progression](#-monthly-cost-progression)
- [Cost Control Measures](#-cost-control-measures)
- [Scaling Projections](#-scaling-projections)
- [Cost Monitoring Commands](#-cost-monitoring-commands)
- [Cost Optimization Recommendations](#-cost-optimization-recommendations)
- [Cost Checklist](#-cost-checklist)

# Lab 4: S3 & Storage Strategy - Cost Analysis

This document provides a detailed breakdown of costs associated with the S3 storage infrastructure implemented in Lab 4.

## 📊 Cost Summary

| Component | Monthly Cost | Annual Cost | Notes |
|-----------|--------------|-------------|-------|
| S3 Storage (Standard) | $2.30 | $27.60 | ~100GB across all buckets |
| S3 Storage (Standard-IA) | $0.63 | $7.56 | ~50GB after lifecycle transitions |
| S3 Storage (Glacier Instant) | $0.20 | $2.40 | ~50GB archived data |
| Data Transfer | $4.50 | $54.00 | Cross-region replication + CloudFront |
| Requests & Operations | $1.00 | $12.00 | PUT/GET/LIST operations |
| CloudFront Distribution | $2.00 | $24.00 | ~20GB monthly transfer |
| Transfer Acceleration | $0.80 | $9.60 | ~20GB accelerated uploads |
| **Total Estimated** | **$11.43** | **$137.16** | Based on typical usage |

## 💾 Storage Class Breakdown

### S3 Standard Storage
| Data Type | Size (GB) | Monthly Cost | Use Case |
|-----------|-----------|--------------|----------|
| Static Website | 5 | $0.12 | HTML/CSS/JS/Images |
| Application Data | 50 | $1.15 | Active user uploads |
| Recent Logs | 30 | $0.69 | Last 30 days |
| New Backups | 15 | $0.34 | Current month |
| **Subtotal** | **100** | **$2.30** | First 30 days |

### S3 Standard-IA Storage
| Data Type | Size (GB) | Monthly Cost | Lifecycle Stage |
|-----------|-----------|--------------|-----------------|
| Older App Data | 30 | $0.38 | 30-90 days old |
| Archived Logs | 20 | $0.25 | 90-180 days old |
| **Subtotal** | **50** | **$0.63** | Infrequent access |

### S3 Glacier Storage Classes
| Storage Class | Size (GB) | Monthly Cost | Retention |
|---------------|-----------|--------------|-----------|
| Glacier Instant | 30 | $0.12 | 90-180 days |
| Glacier Flexible | 15 | $0.06 | 180-365 days |
| Glacier Deep Archive | 5 | $0.02 | 1+ years |
| **Subtotal** | **50** | **$0.20** | Long-term archive |

## 🔄 Data Transfer Costs

### Cross-Region Replication
```
Source Region: us-east-1
Destination Region: us-west-2
Monthly Replication Volume: 50GB

Cost Calculation:
50GB × $0.02/GB = $1.00/month
Annual: $12.00
```

### CloudFront Distribution
```
Monthly Transfer Breakdown:
├── First 10TB: $0.085/GB
├── Static Content: 20GB/month
├── Cache Hit Ratio: 80%
└── Origin Fetches: 4GB/month

Cost Calculation:
20GB × $0.085 = $1.70
Origin Transfer: 4GB × $0.02 = $0.08
Total: $1.78/month (~$2.00)
```

### Transfer Acceleration
```
Global Upload Volume: 20GB/month
Acceleration Benefit: 40% faster
Eligible Transfers: 100% (all benefit)

Cost Calculation:
20GB × $0.04/GB = $0.80/month
Note: Only charged when faster
```

## 📈 Request Pricing

### Monthly Request Estimates
| Request Type | Count (thousands) | Price per 1k | Monthly Cost |
|--------------|-------------------|--------------|--------------|
| PUT/COPY/POST | 100 | $0.005 | $0.50 |
| GET/SELECT | 500 | $0.0004 | $0.20 |
| LIST | 50 | $0.005 | $0.25 |
| DELETE | 10 | Free | $0.00 |
| **Total** | **660k** | - | **$0.95** |

### Lifecycle Transition Costs
```
Monthly Transitions:
├── Standard → Standard-IA: 1,000 objects
├── Standard-IA → Glacier: 500 objects
├── Cost per 1,000 transitions: $0.01
└── Total: $0.015/month (negligible)
```

## 💰 Cost Optimization Strategies

### 1. Lifecycle Policy Savings
```
Without Lifecycle Policies:
- 200GB in Standard: $4.60/month
- Annual Cost: $55.20

With Lifecycle Policies:
- 100GB Standard: $2.30
- 50GB Standard-IA: $0.63
- 50GB Glacier: $0.20
- Total: $3.13/month
- Annual Cost: $37.56

Annual Savings: $17.64 (32% reduction)
```

### 2. Intelligent-Tiering Analysis
```
For Unknown Access Patterns:
- Monitoring Fee: $0.0025 per 1,000 objects
- Automatic Optimization: Saves 20-70%
- Break-even: >128KB objects accessed <1x/month
- Recommendation: Use for user uploads
```

### 3. CloudFront Caching Benefits
```
Without CloudFront:
- S3 Transfer: 100GB × $0.09 = $9.00/month

With CloudFront:
- CF Transfer: 100GB × $0.085 = $8.50
- Origin Fetch: 20GB × $0.02 = $0.40
- Total: $8.90/month
- Plus: Better global performance
```

### 4. Storage Class Recommendations

| Data Type | Recommended Class | Transition Timeline | Annual Savings |
|-----------|------------------|---------------------|----------------|
| Static Assets | Standard + CF Cache | Never transition | N/A |
| User Uploads | Intelligent-Tiering | Immediate | ~40% |
| Application Logs | Standard → IA → Glacier | 30 → 90 → 180 days | ~60% |
| Database Backups | Glacier Instant | Immediate | ~80% |
| Compliance Archives | Deep Archive | After 180 days | ~95% |

## 📊 Monthly Cost Progression

### Month 1 (Initial Setup)
```
Storage: 50GB Standard = $1.15
Operations: Heavy initial uploads = $2.00
CloudFront: Setup and testing = $1.00
Total: ~$4.15
```

### Month 3 (Steady State)
```
Storage: Mixed classes = $3.13
Operations: Normal usage = $0.95
CloudFront: Regular traffic = $2.00
Replication: Full sync = $1.00
Total: ~$7.08
```

### Month 6 (Optimized)
```
Storage: Lifecycle optimized = $2.80
Operations: Predictable = $0.95
CloudFront: Cached content = $1.80
Replication: Incremental = $0.80
Total: ~$6.35
```

### Month 12 (Mature State)
```
Storage: Fully tiered = $2.50
Operations: Efficient = $0.90
CloudFront: High cache ratio = $1.50
All features: Optimized = $5.90
Total: ~$5.90/month
```

## 🎯 Cost Control Measures

### Implemented Cost Controls
1. **S3 Lifecycle Policies**
   - Automatic transition to cheaper storage classes
   - Expiration for old data
   - Estimated savings: 40-60%

2. **CloudFront Caching**
   - Reduces S3 transfer costs
   - Improves performance
   - Cache hit ratio target: >80%

3. **Transfer Acceleration**
   - Only charges when faster
   - No cost if not beneficial
   - Automatic optimization

4. **Bucket Policies**
   - Prevent accidental public access
   - Reduce unauthorized requests
   - Security and cost benefit

### Budget Alerts Configuration
```yaml
S3 Budget Alert:
  Threshold: $15/month
  Actions: Email notification
  
Data Transfer Alert:
  Threshold: $10/month
  Actions: Email + SNS notification
  
Total Storage Alert:
  Threshold: 500GB
  Actions: Review lifecycle policies
```

## 📈 Scaling Projections

### Small Scale (Current)
- Storage: 200GB total
- Transfer: 50GB/month
- Cost: ~$11/month

### Medium Scale (6 months)
- Storage: 1TB total
- Transfer: 200GB/month
- Projected Cost: ~$35/month

### Large Scale (1 year)
- Storage: 5TB total
- Transfer: 500GB/month
- Projected Cost: ~$120/month

## 🔍 Cost Monitoring Commands

```bash
# Check current month S3 costs
aws ce get-cost-and-usage \
  --time-period Start=2025-07-01,End=2025-07-31 \
  --granularity MONTHLY \
  --metrics "UnblendedCost" \
  --filter '{
    "Dimensions": {
      "Key": "SERVICE",
      "Values": ["Amazon Simple Storage Service"]
    }
  }'

# Get storage metrics by bucket
aws cloudwatch get-metric-statistics \
  --namespace AWS/S3 \
  --metric-name BucketSizeBytes \
  --dimensions Name=BucketName,Value=terminus-app-data-xxxx \
  --statistics Average \
  --start-time 2025-07-01T00:00:00Z \
  --end-time 2025-07-31T23:59:59Z \
  --period 86400

# List objects by storage class
aws s3api list-objects-v2 \
  --bucket terminus-app-data-xxxx \
  --query 'Contents[?StorageClass!=`STANDARD`].[Key,StorageClass,Size]' \
  --output table
```

## 💡 Cost Optimization Recommendations

### Immediate Actions
1. **Enable S3 Inventory**
   - Weekly reports on storage usage
   - Identify optimization opportunities
   - Cost: $0.0025 per million objects

2. **Review CloudFront Settings**
   - Increase cache TTLs where possible
   - Enable compression
   - Optimize cache behaviors

3. **Implement Request Metrics**
   - Monitor abnormal request patterns
   - Identify potential abuse
   - Set up CloudWatch alarms

### Future Optimizations
1. **Consider S3 Batch Operations**
   - Bulk transitions for existing objects
   - One-time cost for long-term savings

2. **Evaluate Reserved Capacity**
   - Not available for S3 directly
   - Consider CloudFront Security Savings Bundle

3. **Cross-Region Replication Filtering**
   - Replicate only critical data
   - Use prefix/tag filters
   - Reduce transfer costs

## 📋 Cost Checklist

- [x] Lifecycle policies configured for all buckets
- [x] CloudFront distribution optimized
- [x] Transfer Acceleration enabled selectively
- [x] Monitoring alerts configured
- [x] Regular cost reviews scheduled
- [ ] Quarterly optimization review
- [ ] Annual storage class evaluation

---

*Note: All costs are estimates based on AWS pricing as of July 2025. Actual costs may vary based on usage patterns and AWS pricing changes.*