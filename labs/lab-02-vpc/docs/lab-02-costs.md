# Lab 2 Services Cost Analysis

Services deployed in the VPC & Networking Core lab with ongoing costs.

## VPCs
- **Cost**: $0 (VPCs themselves are free)
- **Scale**: 2 VPCs (Production in us-east-1, DR in us-west-2)
- **Features Used**: DNS resolution, DNS hostnames enabled

## Internet Gateways
- **Cost**: $0 (No hourly charges)
- **Scale**: 2 IGWs (one per VPC)
- **Data Transfer**: Charged separately under EC2 data transfer

## NAT Gateways
| Component | Monthly Cost | Annual Cost | Notes |
|-----------|--------------|-------------|-------|
| Production (2 × $0.045/hr) | $65.70 | $788 | Multi-AZ HA in us-east-1 |
| DR (2 × $0.045/hr) | $65.70 | $788 | Multi-AZ HA in us-west-2 |
| Data Processing ($0.045/GB) | ~$45 | ~$540 | ~1TB/month estimated |
| **Subtotal** | **$176.40** | **$2,116** | Primary cost driver |

## VPC Peering
| Component | Monthly Cost | Annual Cost | Notes |
|-----------|--------------|-------------|-------|
| Connection | $0 | $0 | No hourly charges |
| Data Transfer | ~$20 | ~$240 | Cross-region @ $0.02/GB |
| **Subtotal** | **$20** | **$240** | ~1TB/month replication |

## VPC Endpoints
| Component | Monthly Cost | Annual Cost | Optimization |
|-----------|--------------|-------------|--------------|
| S3 Gateway Endpoint | $0 | $0 | No charges |
| DynamoDB Gateway | $0 | $0 | No charges |
| SSM Interface (2 AZs) | $14.60 | $175 | $0.01/hr per AZ |
| SSM Messages (2 AZs) | $14.60 | $175 | Required for SSM |
| EC2 Messages (2 AZs) | $14.60 | $175 | Required for SSM |
| **Subtotal** | **$43.80** | **$525** | Interface endpoints only |

## Elastic IPs
| Component | Monthly Cost | Annual Cost | Notes |
|-----------|--------------|-------------|-------|
| Allocated but unused | $0 | $0 | Attached to NAT Gateways |
| Additional EIPs | $3.65 each | $43.80 each | If not attached |
| **Subtotal** | **$0** | **$0** | All attached |

## VPC Flow Logs
| Component | Monthly Cost | Annual Cost | Storage Optimization |
|-----------|--------------|-------------|---------------------|
| CloudWatch Logs Ingestion | $5.00 | $60 | ~10GB/month |
| CloudWatch Logs Storage | $0.30 | $3.60 | 90-day retention |
| S3 Alternative | $0.25 | $3.00 | Cheaper for long-term |
| **Subtotal** | **$5.30** | **~$64** | Using CloudWatch |

## Data Transfer Costs
| Component | Monthly Cost | Annual Cost | Notes |
|-----------|--------------|-------------|-------|
| Same AZ | $0 | $0 | Always free |
| Cross-AZ (same region) | ~$10 | ~$120 | $0.01/GB |
| Cross-Region (peering) | ~$20 | ~$240 | $0.02/GB |
| Internet Egress | ~$9 | ~$108 | $0.09/GB after 1GB free |
| **Subtotal** | **$39** | **$468** | Varies with usage |

## Route Tables, Security Groups, NACLs
- **Cost**: $0 (No charges for these resources)
- **Scale**: 6 route tables, 6 security groups, 3 custom NACLs
- **Limits**: Soft limits that can be increased

## Total Lab 2 Costs
| Category | Monthly | Annual | % of Total |
|----------|---------|--------|------------|
| NAT Gateways | $176.40 | $2,116 | 66% |
| VPC Endpoints | $43.80 | $525 | 17% |
| Data Transfer | $39.00 | $468 | 15% |
| VPC Peering | $20.00 | $240 | 8% |
| Flow Logs | $5.30 | $64 | 2% |
| **Total** | **$284.50** | **$3,413** | 100% |

## Cost Optimization Strategies

### Immediate Savings
1. **Development Environment**: Use single NAT Gateway (-$65.70/month)
2. **Off-Hours**: Delete NAT Gateways in DR when not testing (-$65.70/month)
3. **VPC Endpoints**: S3 endpoint saves ~$45/month in NAT processing

### Architecture Alternatives
| Option | Monthly Cost | Savings | Trade-offs |
|--------|--------------|---------|------------|
| Single NAT Gateway | $219 | $65/month | No AZ redundancy |
| NAT Instance (t3.micro) | $158 | $126/month | Management overhead |
| No DR Region | $142 | $142/month | No disaster recovery |
| No VPC Endpoints | $241 | $44/month | Higher NAT costs |

### Long-term Optimizations
1. **Reserved Instances**: Not applicable for NAT Gateways
2. **Traffic Analysis**: Identify and reduce cross-AZ transfers
3. **Endpoint Expansion**: Add CloudWatch Logs endpoint if volume > 500GB/month
4. **Regional Consolidation**: Consider single-region for non-critical workloads

## Comparison with Transit Gateway
| Solution | Monthly | Annual | Break-even |
|----------|---------|--------|------------|
| VPC Peering (current) | $20 | $240 | N/A |
| Transit Gateway | $93 | $1,116 | 4+ VPCs |

## Cost per Environment
- **Production + DR**: $284.50/month
- **Production Only**: $142.25/month  
- **Development**: ~$80/month (single NAT, no DR)
- **Per Region**: ~$142/month

## Budget Recommendations
1. **Proof of Concept**: $150/month (single region, single NAT)
2. **Production Ready**: $285/month (current architecture)
3. **Enterprise Scale**: $400+/month (add regions, endpoints)

## In-Depth Architectural Cost Analysis

**For comprehensive multi-region networking cost analysis, refer to [Network Costs](../../../architecture/cost-analysis/network-costs.md).**