<!--
Terminus Solutions AWS Enterprise Architecture
Copyright (c) 2025 Jared (Terminus Solutions) - jaredintech.com
Licensed under CC BY-SA 4.0 - Attribution required
See LICENSE-DOCS for details
-->

# Terminus Solutions - Cost Analysis

## Table of Contents

- [Cost Analysis Overview](#cost-analysis-overview)
- [Current Implementation Costs (Labs 1-6)](#current-implementation-costs-labs-1-6)
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

## Current Implementation Costs (Labs 1-6)

### Completed Labs Cost Summary

| Lab | Component | Monthly Cost | Annual Cost | Key Cost Drivers |
|-----|-----------|--------------|-------------|------------------|
| **Lab 1** | IAM & Organizations | ~$8 | ~$93 | CloudTrail logs, CloudWatch, KMS |
| **Lab 2** | VPC & Networking | ~$245 | ~$2,946 | NAT Gateways (primary driver) |
| **Lab 3** | EC2 & Auto Scaling | ~$81 | ~$972 | 2x t3.small + ALB + EBS |
| **Lab 4** | S3 & Storage | ~$11 | ~$137 | Mixed storage classes + CloudFront |
| **Lab 5** | RDS & Database Services | ~$65 | ~$780 | Multi-AZ RDS + backups + secrets |
| **Lab 6** | Route53 & CloudFront | ~$15 | ~$180 | DNS queries + CDN + WAF (basic) |
| **Total** | **Labs 1-6** | **~$425** | **~$5,108** | Production-ready foundation |

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

### Lab 5: RDS & Database Services Cost Breakdown
```
Database Infrastructure (Production-Ready):
├── RDS MySQL (db.t3.medium Multi-AZ): $48.96/month
│   ├── Primary instance: $24.48
│   ├── Standby instance: $24.48
│   └── Failover: Automatic
├── RDS Storage (50GB gp3): $5.75/month
│   ├── Storage: $0.115/GB-month
│   └── IOPS: Included with gp3
├── Automated Backups: $2.50/month
│   ├── Retention: 7 days
│   └── Storage: ~50GB backup data
├── Secrets Manager: $0.80/month
│   ├── 2 secrets: $0.80
│   └── API calls: Negligible
├── Enhanced Monitoring: $0.00/month
│   └── Included (basic granularity)
├── Performance Insights: $0.00/month
│   └── Free tier (7-day retention)
├── Parameter Groups: $0.00/month
│   └── Always free
├── Subnet Groups: $0.00/month
│   └── Always free
├── KMS Encryption: $1.00/month
│   └── Customer-managed key
├── CloudWatch Logs: $2.00/month
│   └── Error and slow query logs
├── Data Transfer: $4.00/month
│   └── Cross-AZ replication
└── Total: ~$65.01/month

Cost Scaling Options:
├── Dev/Test (Single-AZ db.t3.micro): ~$12/month
├── Production (Multi-AZ db.t3.medium): ~$65/month
├── High-Performance (db.r6g.large): ~$250/month
└── Enterprise (Aurora Serverless v2): ~$100-500/month (variable)

Read Replica Costs (Optional):
├── Same-region replica: +$24.48/month
├── Cross-region replica: +$30/month (includes transfer)
└── Use case: Read scaling, DR warm standby
```

### Lab 6: Route53 & CloudFront Distribution Cost Breakdown
```
DNS & CDN Infrastructure:
├── Route 53 Hosted Zone: $0.50/month
│   └── Per hosted zone
├── Route 53 DNS Queries: $0.80/month
│   ├── Standard queries: ~2M/month
│   └── Rate: $0.40 per million
├── Route 53 Health Checks: $1.50/month
│   ├── 3 HTTPS health checks
│   └── Rate: $0.50 each
├── CloudFront Distribution: $8.50/month
│   ├── Data transfer (100GB): $8.50
│   └── Rate: $0.085/GB (first 10TB)
├── ACM Certificates: $0.00/month
│   └── Public certificates are FREE
├── WAF Web ACL (Basic): $6.00/month
│   ├── Web ACL: $5.00
│   ├── Rules (1 custom): $1.00
│   └── Managed rules: FREE (Core Rule Set)
├── WAF Requests: $0.60/month
│   ├── ~1M requests/month
│   └── Rate: $0.60 per million
├── Lambda@Edge (Optional): $0.00/month
│   └── Covered by free tier initially
└── Total: ~$17.90/month

Cost Scaling by Traffic:
├── Low traffic (<100GB): ~$15/month
├── Medium traffic (1TB): ~$100/month
├── High traffic (10TB): ~$900/month
└── Enterprise (100TB+): Custom pricing available

Price Class Optimization:
├── All Edge Locations: Full price
├── Price Class 200: ~15% savings
├── Price Class 100: ~30% savings (US/Europe only)
└── Choose based on audience geography
```

---

## Actual Infrastructure Costs

### Full Production Deployment Estimates

| Component | Development | Production | Optimization Applied |
|-----------|-------------|------------|---------------------|
| **ALB** | ~$18/mo | ~$25-40/mo | Right-sized LCU allocation |
| **EC2 (Auto Scaling Group)** | ~$15/mo (t3.micro) | ~$60-150/mo | Spot-ready ASG configuration |
| **RDS MySQL** | ~$15/mo (Single-AZ) | ~$65-120/mo (Multi-AZ) | GP3 storage, auto-scaling |
| **S3 + CloudFront** | ~$5-10/mo | ~$15-50/mo | Lifecycle policies, caching |
| **Route 53 + CDN** | ~$5-10/mo | ~$15-100/mo | Alias records, cache optimization |
| **WAF** | ~$6/mo | ~$50-400/mo | Managed rules, bot control |
| **NAT Gateway** | ~$32/mo | ~$32-65/mo | VPC endpoints reduce traffic |
| **CloudWatch** | ~$3-5/mo | ~$10-20/mo | Custom metrics, log retention |
| **Secrets Manager** | ~$1/mo | ~$2-5/mo | Consolidated secrets |
| **Total Estimate** | **~$100-120/mo** | **~$275-950/mo** | |

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
- **VPC Endpoints**: Gateway endpoints for S3/DynamoDB (free vs. NAT Gateway charges)
- **NAT Gateway Consolidation**: Single NAT per AZ minimum, not per subnet
- **Cross-AZ Awareness**: Data processing stays within AZ when possible
- **VPC Flow Logs Sampling**: Capture 10% for analysis, reduce log costs

### 4. Database Optimization
- **GP3 Storage**: Better price/performance than GP2 (20% cost reduction)
- **Storage Auto-Scaling**: Prevents over-provisioning while avoiding outages
- **Performance Insights**: Free tier sufficient for optimization analysis
- **Read Replica Ready**: Architecture supports horizontal read scaling
- **Multi-AZ Only When Needed**: Single-AZ for dev, Multi-AZ for production
- **Secrets Manager Consolidation**: Group related credentials to reduce per-secret costs

### 5. CDN & Caching Strategy
- **CloudFront Price Class**: Configurable to limit edge locations by budget
- **Origin Shield**: Optional layer to reduce origin load (cost vs. performance trade-off)
- **Cache Behaviors**: Static assets cached 1 year, dynamic content appropriately short
- **Compression**: Gzip/Brotli reduces data transfer costs
- **Alias Records**: Free DNS queries for AWS resources vs. standard query costs
- **Cache Hit Optimization**: Target 80%+ cache hit ratio to reduce origin costs

---

## Production Scaling Cost Projections

| Traffic Level | Monthly Users | Estimated Monthly Cost | Key Scaling Changes |
|---------------|---------------|------------------------|---------------------|
| **Development** | < 1,000 | ~$100-150 | Single instance, Single-AZ RDS |
| **Startup** | 1,000-10,000 | ~$250-500 | Multi-AZ RDS, 2+ EC2 instances |
| **Growth** | 10,000-100,000 | ~$600-1,500 | Reserved instances, read replicas, CDN |
| **Scale** | 100,000+ | ~$2,000-5,000+ | Aurora Serverless, ElastiCache, full WAF |

### Cost Progression by Organization Size

```
Small Organization (Single Region):
├── Compute: $63/month (2x t3.small, basic ALB)
├── Network: $45/month (1 NAT Gateway + endpoints)
├── Storage: $15/month (200GB mixed classes)
├── Database: $25/month (Single-AZ db.t3.micro)
├── DNS/CDN: $12/month (basic CloudFront)
├── Monitoring: $5/month
└── Total: ~$165/month ($1,980/year)

Medium Organization (Multi-AZ HA):
├── Compute: $182/month (ASG 2-6 instances, HA ALB)
├── Network: $131/month (2 NAT Gateways + endpoints)
├── Storage: $35/month (1TB mixed classes)
├── Database: $95/month (Multi-AZ + read replica)
├── DNS/CDN: $85/month (CloudFront + WAF)
├── Monitoring: $15/month
└── Total: ~$543/month ($6,516/year)

Enterprise Organization (Multi-Region):
├── Compute: $650/month (multi-region ASG, HA)
├── Network: $245/month (4 NAT Gateways, VPC peering)
├── Storage: $120/month (5TB with replication)
├── Database: $450/month (Aurora Multi-Region)
├── DNS/CDN: $350/month (global CloudFront, full WAF)
├── Monitoring: $50/month
└── Total: ~$1,865/month ($22,380/year)
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

### Database Infrastructure Comparison
```
Traditional Database (3-Year TCO):
├── Oracle/SQL Server licenses: $150,000
├── Hardware (HA cluster): $80,000
├── SAN storage: $50,000
├── Backup infrastructure: $30,000
├── DBA staff (portion): $180,000
└── Total: $490,000

AWS RDS Multi-AZ (3-Year TCO):
├── RDS instances (Multi-AZ): $21,060
├── Storage (gp3): $2,070
├── Backups: $900
├── Secrets Manager: $29
└── Total: $24,059

Savings: 95% ($465,941 over 3 years)
```

### CDN & DNS Comparison
```
Traditional CDN (3-Year TCO - 10TB/month):
├── Akamai/enterprise CDN: $180,000
├── DDoS protection: $60,000
├── WAF appliances: $90,000
├── DNS services: $12,000
├── SSL certificates: $3,000
└── Total: $345,000

AWS CloudFront + Route53 + WAF (3-Year TCO):
├── CloudFront: $30,600
├── Route 53: $540
├── WAF: $2,160
├── ACM certificates: $0
└── Total: $33,300

Savings: 90% ($311,700 over 3 years)
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
  - RDS: $100/month threshold
  - NAT Gateway: $150/month threshold
  - CloudFront: $50/month threshold
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
    "SubscriptionName": "terminus-cost-alerts",
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

---

## Further Optimization Opportunities

### Reserved Instances / Savings Plans (40-72% Savings)
```
Current On-Demand Costs:
├── EC2 (2x t3.small): $30.96/month
├── RDS (db.t3.medium Multi-AZ): $48.96/month
└── Total: $79.92/month

With 1-Year Reserved/Savings Plan:
├── EC2 Savings Plan: $18.57/month (40% off)
├── RDS Reserved: $29.38/month (40% off)
└── Total: $47.95/month

Annual Savings: $383.64
```

### Spot Instances for Non-Critical Workloads
```
Web Tier with Spot (Mixed Instance Policy):
├── 2 On-Demand (baseline): $30.96/month
├── 2 Spot (burst capacity): $6.19/month (80% discount)
└── Potential Monthly Savings: $24.77
```

### S3 Intelligent-Tiering
```
For Unpredictable Access Patterns:
├── Standard: $0.023/GB
├── Intelligent-Tiering (Frequent): $0.023/GB
├── Intelligent-Tiering (Infrequent): $0.0125/GB
├── Monitoring Fee: $0.0025 per 1,000 objects
└── Benefit: Automatic optimization without lifecycle management
```

---

## Cost Breakdown by Service Category

### Detailed Cost Analysis Documents

| Document | Services Covered | Lab |
|----------|------------------|-----|
| [Baseline Costs](./baseline-costs.md) | Organizations, IAM, CloudTrail, CloudWatch | Lab 1 |
| [Network Costs](./network-costs.md) | VPC, NAT Gateway, Endpoints, Peering | Lab 2 |
| [Compute Costs](./compute-costs.md) | EC2, Auto Scaling, ALB, EBS, CloudWatch | Lab 3 |
| [Storage Costs](./storage-costs.md) | S3, Glacier, CloudFront, Replication | Lab 4 |
| [Database Costs](./database-costs.md) | RDS, Aurora, Secrets Manager, Backups | Lab 5 |
| [CDN Costs](./cdn-costs.md) | Route53, CloudFront, WAF, ACM, Lambda@Edge | Lab 6 |

### Upcoming Cost Analysis (Planned Labs)
- **Load Balancing** - ALB/NLB advanced configurations (Lab 7)
- **Serverless** - Lambda, API Gateway, Step Functions (Lab 8)
- **Messaging** - SQS, SNS, EventBridge (Lab 9)
- **Monitoring** - CloudWatch advanced, X-Ray, Systems Manager (Lab 10)
- **Infrastructure as Code** - CloudFormation, Terraform (Lab 11)
- **Security Services** - GuardDuty, Security Hub, Config (Lab 12)
- **Container Services** - ECS, EKS, Fargate, ECR (Lab 13)

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
- [ ] Verify RDS storage auto-scaling thresholds
- [ ] Review Route 53 health check necessity
- [ ] Analyze WAF rule effectiveness vs. cost
- [ ] Compare actual vs. budgeted spend
- [ ] Identify candidates for Spot Instance migration

---

## Project Navigation

| Lab | Component | Status | Documentation |
|-----|-----------|--------|---------------|
| 1 | IAM & Organizations | ✅ Complete | [View](/labs/lab-01-iam/README.md) |
| 2 | VPC & Networking Core | ✅ Complete | [View](/labs/lab-02-vpc/README.md) |
| 3 | EC2 & Auto Scaling Platform | ✅ Complete | [View](/labs/lab-03-ec2/README.md) |
| 4 | S3 & Storage Strategy | ✅ Complete | [View](/labs/lab-04-s3/README.md) |
| 5 | RDS & Database Services | ✅ Complete | [View](/labs/lab-05-rds/README.md) |
| 6 | Route53 & CloudFront Distribution | ✅ Complete | [View](/labs/lab-06-route53-cloudfront/README.md) |
| 7 | ELB & High Availability | 📅 Planned | - |
| 8 | Lambda & API Gateway Services | 📅 Planned | - |
| 9 | SQS, SNS & EventBridge Messaging | 📅 Planned | - |
| 10 | CloudWatch & Systems Manager Monitoring | 📅 Planned | - |
| 11 | CloudFormation Infrastructure as Code | 📅 Planned | - |
| 12 | Security Services Integration | 📅 Planned | - |
| 13 | Container Services (ECS/EKS) | 📅 Planned | - |

*Last Updated: December 22, 2025*