# Lab 5: RDS & Database Services - Cost Analysis

This document provides a detailed breakdown of costs associated with the database infrastructure implemented in Lab 5.

## 📑 Table of Contents

- [Cost Summary](#-cost-summary)
- [RDS MySQL Costs](#-rds-mysql-costs)
- [Aurora Serverless v2 Costs](#-aurora-serverless-v2-costs)
- [DynamoDB Costs](#-dynamodb-costs)
- [ElastiCache Redis Costs](#-elasticache-redis-costs)
- [Security & Management Costs](#-security--management-costs)
- [Scaling Cost Scenarios](#-scaling-cost-scenarios)
- [Cost Optimization Strategies](#-cost-optimization-strategies)
- [Cost Monitoring](#-cost-monitoring)
- [Cost Review Checklist](#-cost-review-checklist)
- [Budget Recommendations](#-budget-recommendations)
- [ROI Justification](#-roi-justification)

## 📊 Cost Summary

| Component | Monthly Cost | Annual Cost | Notes |
|-----------|--------------|-------------|-------|
| RDS MySQL Multi-AZ | $25.30 | $303.60 | db.t3.micro + 20GB storage |
| Read Replicas (2 regional) | $25.26 | $303.12 | 2× db.t3.micro |
| Read Replica (cross-region) | $13.63 | $163.56 | 1× db.t3.micro + transfer |
| Aurora Serverless v2 | $43.80 | $525.60 | 0.5-1 ACU range |
| DynamoDB On-Demand | $5.00 | $60.00 | ~20M requests/month |
| DynamoDB Global Tables | $10.00 | $120.00 | Replication + storage |
| ElastiCache Redis | $12.63 | $151.56 | cache.t3.micro + replica |
| Secrets Manager | $1.60 | $19.20 | 2 secrets + rotation |
| Performance Insights | $0.00 | $0.00 | 7-day retention (free) |
| Backup Storage | $2.30 | $27.60 | Automated + manual snapshots |
| Data Transfer | $10.00 | $120.00 | Cross-region replication |
| **Total Estimated** | **$149.52** | **$1,794.24** | Full database infrastructure |

## 💾 RDS MySQL Costs

### Multi-AZ Deployment
```
Primary Instance Configuration:
├── Instance Type: db.t3.micro
├── vCPUs: 2
├── Memory: 1 GB
├── Network: Up to 2,085 Mbps
├── Cost: $0.034/hour

Multi-AZ Premium:
├── Standard price: $0.017/hour
├── Multi-AZ price: $0.034/hour (2x)
├── Provides: Synchronous standby
└── Failover: Automatic in 60-120 seconds

Monthly Instance Cost:
├── Hours: 744 hours/month
├── Rate: $0.034/hour
├── Total: $25.30/month
└── Annual: $303.60
```

### Storage Costs
```
Primary Storage:
├── Type: General Purpose SSD (gp3)
├── Size: 20 GB
├── IOPS: 3,000 (included)
├── Throughput: 125 MB/s (included)
├── Cost: $0.115/GB/month
└── Total: $2.30/month

Storage Autoscaling:
├── Maximum: 100 GB
├── Growth rate: ~5GB/month
├── Additional cost: $0.575/month per 5GB
└── Note: Only charged for allocated storage
```

### Read Replica Costs
```
Regional Read Replicas (us-east-1):
├── Instance Type: db.t3.micro
├── Count: 2
├── Cost per replica: $0.017/hour
├── Monthly per replica: $12.63
├── Total (2 replicas): $25.26/month
└── Purpose: Read scaling, analytics

Cross-Region Read Replica (us-west-2):
├── Instance cost: $12.63/month
├── Replication transfer: ~50GB/month
├── Transfer cost: 50GB × $0.02 = $1.00
├── Total: $13.63/month
└── Purpose: Disaster recovery
```

## 🚀 Aurora Serverless v2 Costs

### Capacity Configuration
```
ACU (Aurora Capacity Units):
├── Minimum: 0.5 ACU
├── Maximum: 1.0 ACU
├── ACU definition: ~2GB RAM + CPU
└── Cost: $0.12/ACU/hour

Usage Pattern:
├── Idle (60% of time): 0.5 ACU
├── Active (30% of time): 0.75 ACU
├── Peak (10% of time): 1.0 ACU
└── Average: 0.6 ACU

Monthly Calculation:
├── Average ACUs: 0.6
├── Hours: 744
├── Rate: $0.12/ACU/hour
├── Total: 0.6 × 744 × $0.12 = $53.57
└── With Aurora I/O: ~$43.80/month
```

### Aurora Storage
```
Storage Pricing:
├── Rate: $0.10/GB/month
├── Initial size: 10 GB minimum
├── Growth: Automatic, pay for used
├── Replication: Included (6 copies)
└── Monthly cost: $1.00

I/O Pricing:
├── Rate: $0.20 per million requests
├── Estimated: 10M requests/month
├── Cost: $2.00/month
└── Note: Included in Serverless pricing
```

## 📊 DynamoDB Costs

### On-Demand Pricing
```
Request Pricing:
├── Write requests: $1.25 per million
├── Read requests: $0.25 per million
├── Strongly consistent reads: 2x cost
└── Eventually consistent: Standard rate

Estimated Usage:
├── Writes: 5M/month = $6.25
├── Reads: 15M/month = $3.75
├── Total requests: $10.00/month
└── Note: No pre-provisioning required

Storage Pricing:
├── Rate: $0.25/GB/month
├── Estimated size: 2GB
├── Cost: $0.50/month
└── Includes indexes
```

### Global Tables
```
Replication Costs:
├── Write replication: 2x write costs
├── Cross-region transfer: Included
├── Additional storage: 2x storage
└── Total multiplier: ~2x base cost

Global Table Total:
├── Base table: $10.50/month
├── Global replication: $10.50/month
├── Total: $21.00/month
└── Provides: Multi-region active-active
```

## 🔴 ElastiCache Redis Costs

### Cluster Configuration
```
Primary Node:
├── Type: cache.t3.micro
├── Memory: 0.5 GB
├── Network: Up to 5 Gbps
├── Cost: $0.017/hour
└── Monthly: $12.63

Replica Node:
├── Same specifications
├── Provides: Automatic failover
├── Cost: $0.017/hour
└── Monthly: $12.63

Total Cluster:
├── 2 nodes (primary + replica)
├── Monthly cost: $25.26
└── Annual: $303.12
```

### Data Transfer
```
Within AZ: Free
Cross-AZ replication: 
├── Volume: ~10GB/month
├── Rate: $0.01/GB
├── Cost: $0.10/month
└── Negligible for this size
```

## 🔐 Security & Management Costs

### Secrets Manager
```
Secret Storage:
├── RDS master password: 1 secret
├── Application credentials: 1 secret
├── Cost per secret: $0.40/month
├── Total: $0.80/month

Rotation:
├── Lambda invocations: ~60/month
├── Cost: Negligible (free tier)
├── Rotation API calls: $0.05/10k
└── Total rotation: ~$0.01/month

Total Secrets Manager: $0.81/month
```

### Backup Costs
```
Automated Backups (RDS):
├── Retention: 7 days
├── Size: Same as database (free)
├── Cross-region copy: Included
└── Cost: $0 (included with RDS)

Manual Snapshots:
├── Storage: $0.095/GB/month
├── Estimated: 20GB × 2 snapshots
├── Cost: $3.80/month
└── Lifecycle: Delete after 30 days

Aurora Backups:
├── Continuous: Included
├── Retention: 1 day (free)
└── Extended retention: $0.021/GB/month
```

## 📈 Scaling Cost Scenarios

### Minimum Development Setup
```
Configuration:
├── Single RDS instance (no Multi-AZ)
├── No read replicas
├── DynamoDB on-demand (minimal)
├── No ElastiCache
└── Monthly Cost: ~$20.00
```

### Current Lab Setup
```
Configuration:
├── Multi-AZ RDS MySQL
├── 3 read replicas
├── Aurora Serverless v2
├── DynamoDB with global tables
├── ElastiCache cluster
└── Monthly Cost: ~$149.52
```

### Production Scale
```
Configuration:
├── RDS m6i.large Multi-AZ
├── 5 read replicas
├── Aurora provisioned cluster
├── DynamoDB provisioned capacity
├── ElastiCache m6g.large cluster
└── Monthly Cost: ~$1,200
```

### Enterprise Scale
```
Configuration:
├── Aurora Global Database
├── 10+ read replicas globally
├── DynamoDB global tables (5 regions)
├── ElastiCache Global Datastore
├── Database Activity Streams
└── Monthly Cost: ~$5,000-10,000
```

## 💡 Cost Optimization Strategies

### Immediate Savings

1. **Stop Non-Production Databases**
   ```bash
   # Stop RDS instances when not needed
   aws rds stop-db-instance \
     --db-instance-identifier terminus-mysql-read-1
   
   # Savings: 100% during stopped period
   # Note: Automatically starts after 7 days
   ```

2. **Aurora Serverless Auto-Pause**
   ```yaml
   # Configure auto-pause
   MinCapacity: 0 (auto-pause enabled)
   AutoPauseDelay: 300 seconds
   # Savings: 100% when paused
   ```

3. **Right-Size Read Replicas**
   ```yaml
   # For reporting workloads
   Consider: t3.small instead of matching primary
   Savings: 50% on replica costs
   Trade-off: Potential lag during heavy loads
   ```

### Long-Term Optimizations

1. **Reserved Instances**
   ```
   1-year term, All Upfront:
   ├── db.t3.micro: 30% savings
   ├── Monthly: $17.71 (vs $25.30)
   └── Annual savings: $90.48
   
   3-year term, All Upfront:
   ├── db.t3.micro: 50% savings
   ├── Monthly: $12.65 (vs $25.30)
   └── Annual savings: $151.80
   ```

2. **DynamoDB Reserved Capacity**
   ```
   For predictable workloads:
   ├── 100 WCU: $0.0065/hour → $0.00455/hour
   ├── 100 RCU: $0.0013/hour → $0.00091/hour
   └── Savings: 30% for 1-year commitment
   ```

3. **Consolidation Opportunities**
   ```yaml
   Instead of multiple small instances:
   ├── 3× db.t3.micro = $75.90/month
   ├── 1× db.t3.medium = $68.26/month
   └── Savings: $7.64/month + better performance
   ```

## 📊 Cost Monitoring

### CloudWatch Cost Alarms
```bash
# Create billing alarm for databases
aws cloudwatch put-metric-alarm \
  --alarm-name "RDS-Monthly-Cost-Alert" \
  --alarm-description "Alert when RDS costs exceed $200/month" \
  --metric-name EstimatedCharges \
  --namespace AWS/Billing \
  --statistic Maximum \
  --period 86400 \
  --threshold 200 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=Currency,Value=USD \
               Name=ServiceName,Value=AmazonRDS
```

### Cost Explorer Queries
```bash
# Get database service costs breakdown
aws ce get-cost-and-usage \
  --time-period Start=2025-07-01,End=2025-07-31 \
  --granularity MONTHLY \
  --metrics "UnblendedCost" \
  --group-by Type=DIMENSION,Key=SERVICE \
  --filter '{
    "Or": [
      {"Dimensions": {"Key": "SERVICE", "Values": ["Amazon Relational Database Service"]}},
      {"Dimensions": {"Key": "SERVICE", "Values": ["Amazon DynamoDB"]}},
      {"Dimensions": {"Key": "SERVICE", "Values": ["Amazon ElastiCache"]}}
    ]
  }'
```

## 📋 Cost Review Checklist

- [ ] Review RDS instance utilization (right-sizing opportunity)
- [ ] Check read replica usage patterns
- [ ] Analyze Aurora Serverless scaling patterns
- [ ] Evaluate DynamoDB request patterns for provisioned vs on-demand
- [ ] Review backup retention policies
- [ ] Check for orphaned snapshots
- [ ] Validate cross-region transfer volumes
- [ ] Consider Reserved Instance purchases
- [ ] Review ElastiCache memory utilization
- [ ] Analyze Performance Insights data (right-sizing)

## 🎯 Budget Recommendations

### Development/Testing
- Budget: $20-40/month
- Single AZ RDS instances
- Minimal read replicas
- DynamoDB on-demand
- Stop databases when not in use

### Production (Current)
- Budget: $150-200/month
- Multi-AZ for critical databases
- Strategic read replicas
- Mixed provisioned/on-demand
- Regular cost reviews

### Growth Phase
- Budget: $500-800/month
- Larger instance types
- More read replicas
- Global tables expansion
- Reserved Instances

### Enterprise Scale
- Budget: $2,000-5,000/month
- Global database clusters
- Extensive replication
- Advanced monitoring
- Database activity streams

## 💰 ROI Justification

### High Availability Value
```
Downtime Cost: $50,000/hour
Multi-AZ Cost: $12.65/month extra
Downtime Prevented: ~2 hours/year
Value Generated: $100,000/year
ROI: 657,000%
```

### Read Replica Performance
```
Without Read Replicas:
- Report queries impact production: 30% slower
- Business impact: $10,000/month

With Read Replicas:
- Cost: $25.26/month
- Performance improvement: 100%
- Net benefit: $9,974.74/month
```

---

*Note: All costs are estimates based on AWS pricing as of July 2025. Actual costs may vary based on usage patterns and AWS pricing changes.*