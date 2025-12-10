## Table of Contents

- [Cost Summary](#-cost-summary)
- [Free Services Utilized](#-free-services-utilized)
- [Paid Services Breakdown](#-paid-services-breakdown)
- [Cost Scaling Analysis](#-cost-scaling-analysis)
- [Cost Optimization Strategies](#-cost-optimization-strategies)
- [Cost Comparison](#-cost-comparison)
- [Cost Monitoring](#-cost-monitoring)
- [Monthly Cost Review Checklist](#-monthly-cost-review-checklist)
- [Budget Recommendations](#-budget-recommendations)

# Lab 1: IAM & Organizations - Cost Analysis

This document provides a detailed breakdown of costs associated with the IAM and Organizations infrastructure implemented in Lab 1.

## 📊 Cost Summary

| Component | Monthly Cost | Annual Cost | Notes |
|-----------|--------------|-------------|-------|
| AWS Organizations | $0.00 | $0.00 | Always free |
| IAM Users/Roles/Policies | $0.00 | $0.00 | Always free |
| CloudTrail (Organization Trail) | $2.00 | $24.00 | First trail free, org trail counts as second |
| CloudWatch Logs | $4.20 | $50.40 | Log ingestion and storage |
| S3 Storage (CloudTrail) | $0.53 | $6.36 | Logs with lifecycle policies |
| KMS Encryption | $1.00 | $12.00 | CloudTrail encryption key |
| **Total Estimated** | **$7.73** | **$92.76** | Baseline governance costs |

## 🆓 Free Services Utilized

### AWS Organizations
```
Features Used (All Free):
├── Multi-account management
├── Organizational Units (OUs)
├── Service Control Policies (SCPs)
├── Consolidated billing
├── Cost allocation tags
└── API access for automation
```

### IAM Services
```
Components Created (All Free):
├── Cross-account roles: 3
├── Custom policies: 3
├── Instance profiles: 1
├── MFA enforcement: Configured
├── Password policies: Enabled
└── Access Advisor: Available
```

## 💰 Paid Services Breakdown

### CloudTrail Costs
```
Organization Trail Configuration:
├── Management Events: Read/Write
├── Data Events: None (would add cost)
├── Insights: Disabled (would add $0.35/100K events)
├── Regions: All regions included
└── Member Accounts: 4 accounts covered

Pricing:
├── First trail per region: Free
├── Organization trail: $2.00/month flat fee
├── Additional copies: $2.00/month each
└── Data events: $0.10/100K events (not enabled)
```

### CloudWatch Logs Storage
```
Log Group: /aws/cloudtrail/TerminusOrganization
├── Ingestion Rate: ~5GB/month
├── Retention: 90 days
├── Compression: gzip (automatic)
└── Query Usage: Minimal

Cost Breakdown:
├── First 5GB ingestion: Free
├── Additional ingestion: $0.50/GB
├── Storage (compressed): $0.03/GB
├── 90-day retention: ~15GB stored
└── Total: $4.20/month
```

### S3 Storage for CloudTrail
```
Bucket: terminus-cloudtrail-logs-xxxxx
├── Daily Log Volume: ~200MB
├── Monthly Volume: ~6GB
├── Lifecycle Rules: Applied
└── Encryption: SSE-KMS

Storage Tiers After Lifecycle:
├── Standard (30 days): 6GB × $0.023 = $0.14
├── Standard-IA (60 days): 6GB × $0.0125 = $0.08
├── Glacier (1 year): 72GB × $0.004 = $0.29
└── Total Monthly Average: $0.53
```

### KMS Encryption Costs
```
CloudTrail Encryption Key:
├── Key Type: Customer managed
├── Key Usage: CloudTrail only
├── Requests: ~10,000/month
└── Cost: $1.00/month (key) + minimal request charges

Note: Using AWS managed keys (free) would eliminate this cost
```

## 📈 Cost Scaling Analysis

### Current Setup (4 Accounts)
```
Baseline Costs:
├── Organizations: $0
├── CloudTrail: $2.00
├── Logs & Storage: $4.73
├── Total: $7.73/month
└── Per Account: $1.93/month
```

### Small Organization (10 Accounts)
```
Projected Costs:
├── Organizations: $0
├── CloudTrail: $2.00 (same)
├── Logs & Storage: ~$8.50
├── Total: $10.50/month
└── Per Account: $1.05/month
```

### Medium Organization (50 Accounts)
```
Projected Costs:
├── Organizations: $0
├── CloudTrail: $2.00 (same)
├── Logs & Storage: ~$35.00
├── Additional Trails: $6.00 (regional compliance)
├── Total: $43.00/month
└── Per Account: $0.86/month
```

### Enterprise Organization (200+ Accounts)
```
Projected Costs:
├── Organizations: $0
├── CloudTrail: $2.00 (primary)
├── Additional Org Trails: $10.00 (multi-region)
├── Logs & Storage: ~$150.00
├── CloudTrail Insights: $70.00
├── Total: $232.00/month
└── Per Account: $1.16/month
```

## 💡 Cost Optimization Strategies

### Immediate Optimizations

1. **CloudWatch Logs Retention**
   ```bash
   # Reduce retention for non-critical logs
   aws logs put-retention-policy \
     --log-group-name /aws/cloudtrail/TerminusOrganization \
     --retention-in-days 30  # From 90 to 30 days
   
   # Savings: ~$2.80/month (66% reduction in storage)
   ```

2. **S3 Lifecycle Optimization**
   ```json
   {
     "Rules": [{
       "Status": "Enabled",
       "Transitions": [
         {
           "Days": 1,
           "StorageClass": "GLACIER_IR"
         }
       ],
       "NoncurrentVersionExpiration": {
         "NoncurrentDays": 7
       }
     }]
   }
   # Savings: ~$0.40/month
   ```

3. **Use AWS Managed KMS Keys**
   ```bash
   # Switch to AWS managed keys for CloudTrail
   # Savings: $1.00/month
   # Trade-off: Less control over key rotation
   ```

### Long-Term Optimizations

1. **Selective CloudTrail Events**
   - Filter out read-only events for cost reduction
   - Focus on write events only
   - Potential savings: 40-60% on log volume

2. **Regional Consolidation**
   - Use single-region trails where compliance allows
   - Aggregate logs in primary region
   - Savings: $2.00/month per consolidated trail

3. **Log Analytics Alternatives**
   - Export to S3 and use Athena for queries
   - More cost-effective for sporadic analysis
   - Savings: Variable based on query patterns

## 📊 Cost Comparison

### DIY vs Enterprise Tools

| Solution | Monthly Cost | Features | Accounts Supported |
|----------|--------------|----------|-------------------|
| This Lab Setup | $7.73 | Basic governance | 4 |
| AWS Control Tower | ~$100 | Full automation | Unlimited |
| Third-party (CloudCheckr) | $500+ | Advanced analytics | Varies |
| Enterprise IAM (SailPoint) | $5,000+ | Full identity mgmt | Enterprise |

### ROI Analysis
```
Manual Process Costs (without automation):
├── Account creation: 2 hours × $100/hour = $200
├── Policy management: 4 hours/month × $100 = $400
├── Compliance reporting: 8 hours/month × $100 = $800
├── Total manual cost: $1,400/month

With This Architecture:
├── Platform cost: $7.73/month
├── Reduced manual effort: 2 hours/month × $100 = $200
├── Total cost: $207.73/month
└── Monthly savings: $1,192.27 (85% reduction)
```

## 🔍 Cost Monitoring

### CloudWatch Cost Alarms
```bash
# Create billing alarm
aws cloudwatch put-metric-alarm \
  --alarm-name "IAM-Services-Cost-Alarm" \
  --alarm-description "Alert when IAM services exceed $10/month" \
  --metric-name EstimatedCharges \
  --namespace AWS/Billing \
  --statistic Maximum \
  --period 86400 \
  --threshold 10 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=Currency,Value=USD
```

### Cost Explorer Queries
```bash
# Get governance service costs
aws ce get-cost-and-usage \
  --time-period Start=2025-07-01,End=2025-07-31 \
  --granularity MONTHLY \
  --metrics "BlendedCost" \
  --group-by Type=DIMENSION,Key=SERVICE \
  --filter '{
    "Or": [
      {"Dimensions": {"Key": "SERVICE", "Values": ["AWS CloudTrail"]}},
      {"Dimensions": {"Key": "SERVICE", "Values": ["Amazon CloudWatch"]}},
      {"Dimensions": {"Key": "SERVICE", "Values": ["AWS Key Management Service"]}}
    ]
  }'
```

## 📋 Monthly Cost Review Checklist

- [ ] Review CloudTrail event volume trends
- [ ] Check CloudWatch Logs storage growth
- [ ] Verify S3 lifecycle transitions are occurring
- [ ] Analyze KMS key usage patterns
- [ ] Identify any anomalous API activity
- [ ] Compare actual vs projected costs
- [ ] Review retention policies for optimization
- [ ] Validate no unnecessary trails exist

## 🎯 Budget Recommendations

### Development/Testing
- Budget: $5/month
- Reduce log retention to 7 days
- Use AWS managed keys
- Single region CloudTrail

### Production (Current)
- Budget: $10/month
- 90-day retention
- Organization-wide trail
- Customer managed KMS

### Enterprise Scale
- Budget: $250/month
- Multiple compliance trails
- Extended retention (1 year)
- CloudTrail Insights enabled
- Data events for critical buckets

---

*Note: All costs are estimates based on AWS pricing as of December 2025. Actual costs may vary based on usage patterns and AWS pricing changes.*