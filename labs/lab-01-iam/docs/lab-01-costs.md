
# Lab Services Cost Analysis

Services that run continuously across all labs.

## AWS Organizations
- **Cost**: $0 (Always free)
- **Features Used**: All features enabled, SCPs, CloudTrail aggregation

## IAM
- **Cost**: $0 (Always free)
- **Scale**: 4 accounts, 15+ roles, 20+ policies

## CloudTrail
| Component | Monthly Cost | Annual Cost | Notes |
|-----------|--------------|-------------|-------|
| Organization Trail | $2.00 | $24 | First trail free, org trail counts as second |
| Data Events | $0.10/100K | ~$5 | S3 and Lambda data events |
| Insights | $0.35/100K | ~$20 | Anomaly detection |
| **Subtotal** | **$2.45** | **~$50** | |

## CloudWatch Logs (CloudTrail)
| Component | Monthly Cost | Annual Cost | Optimization |
|-----------|--------------|-------------|--------------|
| Ingestion | $0.50/GB | ~$30 | First 5GB free |
| Storage | $0.03/GB | ~$20 | 90-day retention |
| **Subtotal** | **$4.20** | **~$50** | Use log groups |

## S3 (CloudTrail Storage)
| Component | Monthly Cost | Annual Cost | Lifecycle Policy |
|-----------|--------------|-------------|------------------|
| Standard (30 days) | $0.15 | ~$2 | Recent logs |
| Standard-IA (60 days) | $0.08 | ~$1 | Occasional access |
| Glacier (1 year) | $0.20 | ~$2.50 | Compliance |
| Glacier Deep (7 years) | $0.10 | ~$1.20 | Long-term |
| **Subtotal** | **$0.53** | **~$7** | Automated transitions |

## Total Baseline Costs
- **Monthly**: $7.18
- **Annual**: ~$86
- **Per Account**: ~$1.80/month

## In-Depth Architectural Cost Aanalysis

**For in-depth architectural cost analysis, refer to [Baseline Costs](../../../architecture/cost-analysis/baseline-costs.md).**