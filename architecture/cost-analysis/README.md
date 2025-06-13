<!--
Terminus Solutions AWS Enterprise Architecture
Copyright (c) 2025 Jared (Terminus Solutions) - jaredintech.com
Licensed under CC BY-SA 4.0 - Attribution required
See LICENSE-DOCS for details
-->

# <img src="../../assets/logo.png" alt="Terminus Solutions" height="60"/> Terminus Solutions - Cost Analysis

## Total Project Cost Summary

| Phase | Labs | Monthly Cost | Annual Cost | vs Enterprise Tools |
|-------|------|--------------|-------------|-------------------|
| Foundation | 1-3 | $45 | $540 | -99% vs SailPoint |
| Compute & Data | 4-7 | $280 | $3,360 | -85% vs On-Prem |
| Application | 8-10 | $125 | $1,500 | -90% vs Traditional |
| Operations | 11-13 | $150 | $1,800 | -95% vs Enterprise |
| **TOTAL** | All | **$600** | **$7,200** | **-92%** |

## Cost Breakdown by Service Category
- [Baseline Services](./baseline-costs.md) - IAM, Organizations, CloudTrail
- [Networking Services](./network-costs.md) - VPC & Networking
- [Compute Services](./compute-costs.md) - EC2, Lambda, ECS, EKS
- [Storage Services](./storage-costs.md) - S3, EBS, Backup
- [Database Services](./database-costs.md) - RDS, DynamoDB
- [DNS Services](./dns-costs.md) - CloudFront, Route53
- [Security Services](./security-costs.md) - GuardDuty, KMS, WAF
- [Monitoring Services](./monitoring-costs.md) - CloudWatch, Systems Manager

## Cost Optimization Strategies Applied
1. **Multi-AZ over Multi-Region** where possible (50% savings)
2. **Spot Instances** for development (70% savings)
3. **S3 Lifecycle Policies** for logs (80% savings)
4. **Reserved Instances** for production (40% savings)

---

### 📊 Project Navigation

| Lab | Component | Status | Documentation |
|-----|-----------|--------|---------------|
| 1 | IAM & Organizations | ✅ Complete | [View](/labs/lab-01-iam/README.md) |
| 2 | VPC & Networking Core | ✅ Complete | [View](/labs/lab-02-vpc/README.md) |
| 3 | EC2 & Auto Scaling Platform | 📅 Planned | - |
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

---

*Last Updated: June 12th, 2025*