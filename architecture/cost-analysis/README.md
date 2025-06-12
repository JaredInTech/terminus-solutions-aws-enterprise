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
- [Compute Services](./compute-costs.md) - EC2, Lambda, ECS, EKS
- [Storage Services](./storage-costs.md) - S3, EBS, Backup
- [Database Services](./database-costs.md) - RDS, DynamoDB
- [Network Services](./network-costs.md) - VPC, CloudFront, Route53
- [Security Services](./security-costs.md) - GuardDuty, KMS, WAF
- [Monitoring Services](./monitoring-costs.md) - CloudWatch, Systems Manager

## Cost Optimization Strategies Applied
1. **Multi-AZ over Multi-Region** where possible (50% savings)
2. **Spot Instances** for development (70% savings)
3. **S3 Lifecycle Policies** for logs (80% savings)
4. **Reserved Instances** for production (40% savings)