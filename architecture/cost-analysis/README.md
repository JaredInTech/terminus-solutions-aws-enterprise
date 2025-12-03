<!--
Terminus Solutions AWS Enterprise Architecture
Copyright (c) 2025 Jared (Terminus Solutions) - jaredintech.com
Licensed under CC BY-SA 4.0 - Attribution required
See LICENSE-DOCS for details
-->

# <img src="../../assets/logo.png" alt="Terminus Solutions" height="60"/> Terminus Solutions - Cost Analysis

## Table of Contents
- [Cost Analysis & Optimization](#-cost-analysis--optimization)
  - [Actual Infrastructure Costs](#actual-infrastructure-costs)
- [Cost Optimization Techniques Implemented](#cost-optimization-techniques-implemented)
  - [Storage Lifecycle Management](#1-storage-lifecycle-management-94-savings-on-backup-data)
  - [Compute Right-Sizing](#2-compute-right-sizing)
  - [Network Cost Reduction](#3-network-cost-reduction)
  - [Database Optimization](#4-database-optimization)
  - [CDN & Caching Strategy](#5-cdn--caching-strategy)
- [Production Scaling Cost Projections](#production-scaling-cost-projections)
- [Cloud vs. Traditional Deployment Models](#cloud-vs-traditional-deployment-models)
- [Cost Monitoring & Governance](#cost-monitoring--governance)
- [Further Optimization Opportunities](#further-optimization-opportunities)
- [Cost Breakdown by Service Category](#cost-breakdown-by-service-category)
- [Project Navigation](#-project-navigation)


## 💰 Cost Analysis & Optimization

This project demonstrates enterprise-grade AWS architecture with intentional cost optimization strategies.

### Actual Infrastructure Costs

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

*Costs vary based on traffic, data transfer, and region. Estimates based on us-east-1 pricing as of 2024.*

---

### Cost Optimization Techniques Implemented

#### 1. Storage Lifecycle Management (94% Savings on Backup Data)
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

#### 2. Compute Right-Sizing
- **Development**: t3.micro instances (burstable, free-tier eligible)
- **Production-Ready**: ASG configured for easy scaling to t3.small/medium
- **Spot Instance Compatible**: Launch template supports spot pricing (up to 90% savings)
- **Reserved Instance Ready**: Architecture documented for 1-year commitment (40-60% savings)

#### 3. Network Cost Reduction
- **VPC Endpoints**: S3 Gateway endpoint eliminates NAT charges for S3 traffic
- **CloudFront Caching**: 80-90% cache hit ratio reduces origin requests
- **Regional Data Transfer**: Architecture optimized for minimal cross-AZ traffic
- **IPv6 Ready**: Dual-stack configuration avoids $0.005/hr public IPv4 charges

#### 4. Database Optimization
- **GP3 Storage**: Better price/performance than GP2 (20% cost reduction)
- **Storage Auto-Scaling**: Prevents over-provisioning while avoiding outages
- **Performance Insights**: Free tier sufficient for optimization analysis
- **Read Replica Ready**: Architecture supports horizontal read scaling

#### 5. CDN & Caching Strategy
- **CloudFront Price Class**: Configurable to limit edge locations by budget
- **Origin Shield**: Optional layer to reduce origin load (cost vs. performance trade-off)
- **Cache Behaviors**: Static assets cached 1 year, dynamic content appropriately short
- **Compression**: Gzip/Brotli reduces data transfer costs

---

### Production Scaling Cost Projections

| Traffic Level | Monthly Users | Estimated Monthly Cost | Key Scaling Changes |
|---------------|---------------|------------------------|---------------------|
| **Development** | < 1,000 | ~$90-120 | Single instance, Single-AZ RDS |
| **Startup** | 1,000-10,000 | ~$200-400 | Multi-AZ RDS, 2+ EC2 instances |
| **Growth** | 10,000-100,000 | ~$500-1,500 | Reserved instances, larger RDS |
| **Scale** | 100,000+ | ~$2,000-5,000+ | Aurora Serverless, ElastiCache |

---

### Cloud vs. Traditional Deployment Models

Rather than comparing raw infrastructure costs (which vary dramatically by use case), this architecture demonstrates key cloud advantages:

| Metric | Traditional On-Premises | This AWS Architecture |
|--------|------------------------|----------------------|
| **Time to Deploy** | 6-12 weeks (hardware procurement) | < 1 day (IaC ready) |
| **Upfront CapEx** | $50,000+ (servers, networking, facility) | $0 |
| **Scaling Speed** | Days to weeks | Minutes (Auto Scaling) |
| **Geographic Reach** | Single data center | Global (13 CloudFront edge locations) |
| **Disaster Recovery** | Separate DR site required | Multi-AZ built-in |
| **Maintenance Windows** | Scheduled downtime | Rolling updates, zero downtime |
| **Capacity Planning** | Must predict 3-5 years ahead | Adjust monthly |

---

### Cost Monitoring & Governance

This architecture includes cost visibility best practices:

- **Resource Tagging**: All resources tagged with `Project`, `Environment`, `ManagedBy`
- **AWS Budgets Ready**: Threshold alerts configurable at account level
- **Cost Allocation**: Tags enable per-service and per-environment cost tracking
- **Trusted Advisor**: Architecture follows recommendations for cost optimization

---

### Further Optimization Opportunities

| Optimization | Potential Savings | Implementation Effort |
|--------------|-------------------|----------------------|
| Reserved Instances (1-year) | 40-60% on EC2/RDS | Low (commitment required) |
| Spot Instances for ASG | Up to 90% on EC2 | Medium (interruption handling) |
| Aurora Serverless v2 | Variable workload savings | Medium (migration required) |
| Graviton Instances | 20-40% better price/performance | Low (ARM compatibility check) |
| S3 Intelligent-Tiering | Automatic storage optimization | Low (enable on bucket) |
| Compute Savings Plans | 66% on Lambda/Fargate | Low (commitment required) |

---

*For detailed cost breakdowns by service, see the [AWS Pricing Calculator](https://calculator.aws/) or individual lab documentation.*

---

## Cost Breakdown by Service Category
- [Baseline Services](./baseline-costs.md) - IAM, Organizations, CloudTrail
- [Networking Services](./network-costs.md) - VPC & Networking

---

### 📊 Project Navigation

| Lab | Component | Status | Documentation |
|-----|-----------|--------|---------------|
| 1 | IAM & Organizations | ✅ Complete | [View](/labs/lab-01-iam/README.md) |
| 2 | VPC & Networking Core | ✅ Complete | [View](/labs/lab-02-vpc/README.md) |
| 3 | EC2 & Auto Scaling Platform | 🚧 In Progress | - |
| 4 | S3 & Storage Strategy | 📅 Planned | - |
| 5 | RDS & Database Services | 📅 Planned | - |
| 6 | Route53 & CloudFront Distribution | 📅 Planned | - |
| 7 | ELB & High Availability | 📅 Planned | - |
| 8 | Lambda & API Gateway Services | 📅 Planned | - |
| 9 | SQS, SNS & EventBridge Messaging | 📅 Planned | - |
| 10 | CloudWatch & Systems Manager Monitoring | 📅 Planned | - |
| 11 | CloudFormation Infrastructure as Code | 📅 Planned | - |
| 12 | Security Services Integration | 📅 Planned | - |
| 13 | Container Services (ECS/EKS) | 📅 Planned | - |

*Last Updated: December 3rd, 2025*
