<!--
Terminus Solutions AWS Enterprise Architecture
Copyright (c) 2025 Jared (Terminus Solutions) - jaredintech.com
Licensed under CC BY-SA 4.0 - Attribution required
See LICENSE-DOCS for details
-->

# Terminus Solutions - Cost Analysis

## Table of Contents

- [Cost Analysis Overview](#cost-analysis-overview)
- [Current Implementation Costs (Labs 1-4)](#current-implementation-costs-labs-1-4)
- [Actual Infrastructure Costs](#actual-infrastructure-costs)
- [Cost Optimization Techniques Implemented](#cost-optimization-techniques-implemented)
  - [Storage Lifecycle Management](#1-storage-lifecycle-management-94-savings-on-backup-data)
  - [Compute Right-Sizing](#2-compute-right-sizing)
  - [Network Cost Reduction](#3-network-cost-reduction)
  - [Database Optimization](#4-database-optimization)
  - [CDN and Caching Strategy](#5-cdn--caching-strategy)
- [Production Scaling Cost Projections](#production-scaling-cost-projections)
- [Cloud vs Traditional Deployment Models](#cloud-vs-traditional-deployment-models)
- [Cost Monitoring and Governance](#cost-monitoring-and-governance)
- [Further Optimization Opportunities](#further-optimization-opportunities)
- [Cost Breakdown by Service Category](#cost-breakdown-by-service-category)
- [Monthly Cost Review Checklist](#monthly-cost-review-checklist)
- [Project Navigation](#project-navigation)


## Cost Analysis Overview

This project demonstrates enterprise-grade AWS architecture with intentional cost optimization strategies. Every architectural decision balances security, performance, and cost-effectiveness with detailed analysis and ROI justification.

### Key Cost Principles

- **Right-size from day one** - Start small, scale based on actual metrics
- **Automate cost optimization** - Lifecycle policies, scheduled scaling, cleanup scripts
- **Monitor proactively** - Budget alerts before overruns, anomaly detection
- **Document ROI** - Quantify savings vs. traditional approaches

---

## Current Implementation Costs (Labs 1-4)

### Completed Labs Cost Summary

| Lab | Component | Monthly Cost | Annual Cost | Key Cost Drivers |
|-----|-----------|--------------|-------------|------------------|
| **Lab 1** | IAM & Organizations | ~$8 | ~$93 | CloudTrail logs, CloudWatch, KMS |
| **Lab 2** | VPC & Networking | ~$245 | ~$2,946 | NAT Gateways (primary driver) |
| **Lab 3** | EC2 & Auto Scaling | ~$81 | ~$972 | 2x t3.small + ALB + EBS |
| **Lab 4** | S3 & Storage | ~$11 | ~$137 | Mixed storage classes + CloudFront |
| **Total** | **Labs 1-4** | **~$345** | **~$4,148** | Production-ready foundation |

### Lab 1: IAM & Organizations Cost Breakdown
```
Governance & Identity (4-Account Organization):
├── AWS Organizations: $0.00/month
│   └── Always free (unlimited accounts, OUs, SCPs)
├── IAM Users/Roles/Policies: $0.00/month
│   └── Always free (unlimited)
├── CloudTrail (Organization Trail): $2.00/month
│   ├── First trail per region: Free
│   └── Organization trail: $2.00 flat fee
├── CloudWatch Logs: $4.20/month
│   ├── Log ingestion: ~5GB/month
│   ├── Log storage (90-day retention): ~15GB
│   └── Compression: Automatic gzip
├── S3 Storage (CloudTrail Logs): $0.53/month
│   ├── Standard (30 days): 6GB
│   ├── Standard-IA (60 days): 6GB
│   └── Glacier (1 year): 72GB
├── KMS Encryption Key: $1.00/month
│   └── Customer managed key for CloudTrail
└── Total: ~$7.73/month

Cost Scaling by Organization Size:
├── Small (3-5 accounts): ~$5/month
├── Medium (10-20 accounts): ~$45-85/month
├── Enterprise (50+ accounts): ~$800-2,300/month
└── Per-Account Cost: $1.93 → $0.86 (economies of scale)
```

### Lab 2: VPC & Networking Cost Breakdown
```
Network Infrastructure (Multi-Region HA):
├── VPCs (2 regions): $0.00/month
│   └── Always free (includes subnets, route tables, IGW)
├── NAT Gateways (4 total): $131.40/month
│   ├── Production us-east-1: 2x $32.85
│   ├── DR us-west-2: 2x $32.85
│   └── Hourly rate: $0.045/hour each
├── NAT Gateway Data Processing: $45.00/month
│   ├── Estimated outbound: ~1TB/month
│   └── Rate: $0.045/GB processed
├── VPC Peering: $0.00/month
│   └── No hourly charges (data transfer only)
├── Cross-Region Data Transfer: $20.00/month
│   ├── Volume: ~1TB/month
│   └── Rate: $0.02/GB cross-region
├── VPC Endpoints (Interface): $43.80/month
│   ├── SSM endpoint: $14.60 (2 AZs)
│   ├── SSM Messages: $14.60 (2 AZs)
│   └── EC2 Messages: $14.60 (2 AZs)
├── VPC Flow Logs: $5.30/month
│   └── CloudWatch Logs storage
└── Total: ~$245.50/month

Cost Optimization Opportunities:
├── Single NAT Gateway (dev): Save $98/month
├── Gateway endpoints (S3/DynamoDB): Free vs $14.60/endpoint
├── Single region (no DR): Save ~$100/month
└── NAT Instance alternative: Save ~$25/month per gateway
```

### Lab 3: Compute Cost Breakdown
```
EC2 Compute (Multi-AZ HA):
├── Web Tier ASG (2x t3.small avg): $30.96/month
├── Application Load Balancer: $27.00/month
│   ├── Hourly: $16.74
│   └── LCU charges: $10.26
├── EBS Storage (gp3): $12.00/month
│   ├── Root volumes: 2x 20GB
│   └── Snapshots: ~50GB incremental
├── CloudWatch Monitoring: $6.00/month
├── Data Transfer: $5.00/month
└── Total: ~$80.96/month
```

### Lab 4: Storage Cost Breakdown
```
S3 Storage Architecture:
├── S3 Standard (100GB active): $2.30/month
├── S3 Standard-IA (50GB): $0.63/month
├── S3 Glacier Instant (50GB): $0.20/month
├── Cross-Region Replication: $1.00/month
├── CloudFront Distribution: $2.00/month
├── Transfer Acceleration: $0.80/month
├── Request Operations: $1.00/month
└── Total: ~$11.43/month

Lifecycle Optimization Savings:
├── Without lifecycle: ~$46/month (all Standard)
├── With lifecycle: ~$11/month
└── Monthly Savings: ~$35 (76% reduction)
```

---

## Actual Infrastructure Costs

### Full Production Deployment Estimates

| Component | Development | Production | Optimization Applied |
|-----------|-------------|------------|---------------------|
| **ALB** | ~$18/mo | ~$25-40/mo | Right-sized LCU allocation |
| **EC2 (Auto Scaling Group)** | ~$15/mo (t3.micro) | ~$60-150/mo | Spot-ready ASG configuration |
| **RDS MySQL** | ~$15/mo (Single-AZ) | ~$30-60/mo (Multi-AZ) | GP3 storage, auto-scaling |
| **S3 + CloudFront** | ~$5-10/mo | ~$15-50/mo | Lifecycle policies, caching |
| **Route 53** | ~$1-2/mo | ~$2-5/mo | Alias records (free queries) |
| **NAT Gateway** | ~$32/mo | ~$32-65/mo | VPC endpoints reduce traffic |
| **CloudWatch** | ~$3-5/mo | ~$10-20/mo | Custom metrics, log retention |
| **Secrets Manager** | ~$1/mo | ~$2-5/mo | Consolidated secrets |
| **Total Estimate** | **~$90-100/mo** | **~$200-400/mo** | |

*Costs vary based on traffic, data transfer, and region. Estimates based on us-east-1 pricing as of 2025.*

---

## Cost Optimization Techniques Implemented

### 1. Storage Lifecycle Management (94% Savings on Backup Data)
```
S3 Lifecycle Policy Progression:
├── Days 0-30:   S3 Standard ($0.023/GB)
├── Days 31-90:  Glacier Instant Retrieval ($0.004/GB)
├── Days 91-365: Glacier Flexible Retrieval ($0.0036/GB)
├── Year 2-7:    Glacier Deep Archive ($0.00099/GB)
└── Day 2555:    Automatic deletion (7-year retention)

Example: 500GB monthly backups
├── Without lifecycle: $966 over 7 years
├── With lifecycle:    $55.50 over 7 years
└── Savings: 94% (~$910 per 500GB)
```

### 2. Compute Right-Sizing
- **Development**: t3.micro instances (burstable, free-tier eligible)
- **Production-Ready**: ASG configured for easy scaling to t3.small/medium
- **Spot Instance Compatible**: Launch template supports spot pricing (up to 90% savings)
- **Reserved Instance Ready**: Architecture documented for 1-year commitment (40-60% savings)
- **gp3 over gp2**: 20% cost reduction with independent IOPS/throughput scaling
- **Target Tracking Scaling**: Automatic right-sizing based on CPU utilization

### 3. Network Cost Reduction
- **VPC Endpoints**: S3 Gateway endpoint eliminates NAT charges for S3 traffic
- **CloudFront Caching**: 80-90% cache hit ratio reduces origin requests
- **Regional Data Transfer**: Architecture optimized for minimal cross-AZ traffic
- **IPv6 Ready**: Dual-stack configuration avoids $0.005/hr public IPv4 charges

### 4. Database Optimization
- **GP3 Storage**: Better price/performance than GP2 (20% cost reduction)
- **Storage Auto-Scaling**: Prevents over-provisioning while avoiding outages
- **Performance Insights**: Free tier sufficient for optimization analysis
- **Read Replica Ready**: Architecture supports horizontal read scaling

### 5. CDN & Caching Strategy
- **CloudFront Price Class**: Configurable to limit edge locations by budget
- **Origin Shield**: Optional layer to reduce origin load (cost vs. performance trade-off)
- **Cache Behaviors**: Static assets cached 1 year, dynamic content appropriately short
- **Compression**: Gzip/Brotli reduces data transfer costs
- **Transfer Acceleration**: Only charges when faster than standard transfer

---

## Production Scaling Cost Projections

| Traffic Level | Monthly Users | Estimated Monthly Cost | Key Scaling Changes |
|---------------|---------------|------------------------|---------------------|
| **Development** | < 1,000 | ~$90-120 | Single instance, Single-AZ RDS |
| **Startup** | 1,000-10,000 | ~$200-400 | Multi-AZ RDS, 2+ EC2 instances |
| **Growth** | 10,000-100,000 | ~$500-1,500 | Reserved instances, larger RDS |
| **Scale** | 100,000+ | ~$2,000-5,000+ | Aurora Serverless, ElastiCache |

### Cost Progression by Organization Size

```
Small Organization (Single Region):
├── Compute: $63/month (2x t3.small, basic ALB)
├── Network: $45/month (1 NAT Gateway + endpoints)
├── Storage: $15/month (200GB mixed classes)
├── Monitoring: $5/month
└── Total: ~$128/month ($1,536/year)

Medium Organization (Multi-AZ HA):
├── Compute: $182/month (ASG 2-6 instances, HA ALB)
├── Network: $131/month (2 NAT Gateways + endpoints)
├── Storage: $35/month (1TB mixed classes)
├── Database: $60/month (RDS Multi-AZ)
├── Monitoring: $15/month
└── Total: ~$423/month ($5,076/year)

Enterprise Organization (Multi-Region):
├── Compute: $650/month (multi-region ASG, HA)
├── Network: $245/month (4 NAT Gateways, VPC peering)
├── Storage: $120/month (5TB with replication)
├── Database: $300/month (Aurora Multi-Region)
├── CDN: $100/month (global CloudFront)
├── Monitoring: $50/month
└── Total: ~$1,465/month ($17,580/year)
```

---

## Cloud vs Traditional Deployment Models

### IAM & Identity Management Comparison
```
Traditional Enterprise Identity Stack:
├── SailPoint IdentityIQ: $100,000-500,000/year
├── CyberArk Privileged Access: $50,000-200,000/year
├── Active Directory (CALs + Infrastructure): $25,000-100,000/year
├── Hardware Security Modules: $10,000-50,000/year
└── Total: $185,000-850,000/year

AWS Native Approach (This Project):
├── AWS Organizations: $0
├── AWS IAM: $0
├── AWS SSO/Identity Center: $0
├── CloudTrail (audit): ~$60/year
├── Config Rules: ~$50/year
└── Total: ~$110/year

Savings: 99.94% ($184,890-849,890/year)
```

### Compute Infrastructure Comparison
```
Traditional Data Center (3-Year TCO):
├── Hardware (servers, networking): $50,000
├── Software licenses: $15,000
├── Data center (power, cooling, space): $36,000
├── IT staff (portion): $150,000
└── Total: $251,000

AWS Cloud (3-Year TCO):
├── EC2 Auto Scaling Architecture: $32,187
├── Load Balancers: $8,100
├── EBS Storage: $4,320
└── Total: $44,607

Savings: 82% ($206,393 over 3 years)
```

### Storage Infrastructure Comparison
```
Traditional SAN/NAS (3-Year TCO for 50TB):
├── Hardware (SAN arrays, expansion): $150,000
├── Software licenses: $30,000
├── Data center costs: $18,000
├── IT staff (storage admin portion): $90,000
├── Backup infrastructure: $50,000
└── Total: $338,000

AWS S3 + Lifecycle (3-Year TCO for 50TB):
├── S3 Mixed Classes (optimized): $18,000
├── Cross-Region Replication: $3,600
├── CloudFront CDN: $2,400
├── Data Transfer: $6,000
└── Total: $30,000

Savings: 91% ($308,000 over 3 years)
```

---

## Cost Monitoring and Governance

### AWS Budgets Configuration
```yaml
Monthly Budget Alerts:
  - Threshold: 50% - Email notification
  - Threshold: 80% - Email + SNS notification
  - Threshold: 100% - Email + SNS + auto-remediation
  
Service-Specific Alerts:
  - EC2: $100/month threshold
  - NAT Gateway: $150/month threshold
  - Data Transfer: $50/month threshold
  - S3: $25/month threshold
```

### Cost Anomaly Detection
```bash
# Enable Cost Anomaly Detection
aws ce create-anomaly-monitor \
  --anomaly-monitor '{
    "MonitorName": "terminus-cost-monitor",
    "MonitorType": "DIMENSIONAL",
    "MonitorDimension": "SERVICE"
  }'

# Create subscription for alerts
aws ce create-anomaly-subscription \
  --anomaly-subscription '{
    "SubscriptionName": "cost-alerts",
    "Threshold": 10,
    "Frequency": "DAILY",
    "MonitorArnList": ["arn:aws:ce::123456789012:anomalymonitor/abc123"],
    "Subscribers": [{"Type": "EMAIL", "Address": "alerts@terminus.solutions"}]
  }'
```

### Cost Explorer Queries
```bash
# Get monthly costs by service
aws ce get-cost-and-usage \
  --time-period Start=2025-12-01,End=2025-12-31 \
  --granularity MONTHLY \
  --metrics "UnblendedCost" \
  --group-by Type=DIMENSION,Key=SERVICE

# Get EC2 costs by instance type
aws ce get-cost-and-usage \
  --time-period Start=2025-12-01,End=2025-12-31 \
  --granularity MONTHLY \
  --filter '{
    "Dimensions": {
      "Key": "SERVICE",
      "Values": ["Amazon Elastic Compute Cloud - Compute"]
    }
  }' \
  --group-by Type=DIMENSION,Key=INSTANCE_TYPE
```

---

## Further Optimization Opportunities

### Immediate Savings (Quick Wins)
| Opportunity | Potential Savings | Implementation Effort |
|-------------|-------------------|----------------------|
| Reserved Instances (1-year) | 40-60% on EC2 | Low |
| Savings Plans (Compute) | 30-40% on compute | Low |
| S3 Intelligent-Tiering | 20-40% on storage | Low |
| Spot Instances (dev/test) | Up to 90% | Medium |
| Right-sizing (after metrics) | 20-30% | Medium |

### Future Optimizations
| Opportunity | Potential Savings | When to Implement |
|-------------|-------------------|-------------------|
| Graviton Instances (ARM) | 20-40% | After baseline established |
| Aurora Serverless v2 | Variable (pay per use) | With database workload |
| Lambda@Edge | Reduce origin requests | With high CDN traffic |
| ElastiCache | Reduce database load | With read-heavy workload |
| NAT Gateway Consolidation | $65+/month | With Transit Gateway |

---

## Cost Breakdown by Service Category

### Detailed Cost Analysis Documents

| Document | Description | Labs Covered |
|----------|-------------|--------------|
| [Baseline Services](./baseline-costs.md) | IAM, Organizations, CloudTrail, Config | Lab 1 |
| [Networking Services](./network-costs.md) | VPC, NAT Gateways, VPC Endpoints, Peering | Lab 2 |
| [Compute Services](./compute-costs.md) | EC2, Auto Scaling, ALB, EBS, CloudWatch | Lab 3 |
| [Storage Services](./storage-costs.md) | S3, Glacier, CloudFront, Replication | Lab 4 |

### Upcoming Cost Analysis (Planned Labs)
- **Database Services** - RDS, Aurora, DynamoDB (Lab 5)
- **DNS & CDN** - Route53, CloudFront advanced (Lab 6)
- **Serverless** - Lambda, API Gateway (Lab 8)
- **Container Services** - ECS, EKS, Fargate (Lab 13)

---

## Monthly Cost Review Checklist

- [ ] Review AWS Cost Explorer for anomalies
- [ ] Check Auto Scaling group metrics for right-sizing opportunities
- [ ] Verify S3 lifecycle policies are transitioning data
- [ ] Review CloudFront cache hit ratio (target: >80%)
- [ ] Check for unattached EBS volumes and Elastic IPs
- [ ] Validate Reserved Instance/Savings Plan coverage
- [ ] Review NAT Gateway data processing charges
- [ ] Check CloudWatch log retention policies
- [ ] Compare actual vs budgeted spend
- [ ] Identify candidates for Spot Instance migration

---

## Project Navigation

| Lab | Component | Status | Documentation |
|-----|-----------|--------|---------------|
| 1 | IAM & Organizations | ✅ Complete | [View](./lab-01-iam/README.md) |
| 2 | VPC & Networking Core | ✅ Complete | [View](./lab-02-vpc/README.md) |
| 3 | EC2 & Auto Scaling Platform | ✅ Complete | [View](./lab-03-ec2/README.md) |
| 4 | S3 & Storage Strategy | ✅ Complete | [View](./lab-04-s3/README.md) |
| 5 | RDS & Database Services | 📅 Planned | - |
| 6 | Route53 & CloudFront Distribution | 📅 Planned | - |
| 7 | ELB & High Availability | 📅 Planned | - |
| 8 | Lambda & API Gateway Services | 📅 Planned | - |
| 9 | SQS, SNS & EventBridge Messaging | 📅 Planned | - |
| 10 | CloudWatch & Systems Manager Monitoring | 📅 Planned | - |
| 11 | CloudFormation Infrastructure as Code | 📅 Planned | - |
| 12 | Security Services Integration | 📅 Planned | - |
| 13 | Container Services (ECS/EKS) | 📅 Planned | - |

*Last Updated: December 10, 2025*