## Table of Contents

- [Cost Summary](#-cost-summary)
- [Network Architecture Costs](#-network-architecture-costs)
- [Data Transfer Costs](#d-ata-transfer-costs)
- [Scaling Cost Projections](#-scaling-cost-projections)
- [Cost Optimization Strategies](#-cost-optimization-strategies)
- [Cost Comparison Analysis](#-cost-comparison-analysis)
- [Cost Monitoring Commands](#-cost-monitoring-commands)
- [Monthly Cost Review Checklist](#-monthly-cost-review-checklist)
- [Budget Recommendations](#-budget-recommendations)
- [ROI Justification](#-roi-justification)

# Lab 2: VPC & Networking Core - Cost Analysis

This document provides a detailed breakdown of costs associated with the VPC and networking infrastructure implemented in Lab 2.

## 📊 Cost Summary

| Component | Monthly Cost | Annual Cost | Notes |
|-----------|--------------|-------------|-------|
| VPCs (2 regions) | $0.00 | $0.00 | VPCs are free |
| NAT Gateways (4 total) | $131.40 | $1,576.80 | $0.045/hour each |
| NAT Gateway Data Processing | $45.00 | $540.00 | ~1TB/month @ $0.045/GB |
| VPC Peering | $0.00 | $0.00 | No hourly charges |
| Cross-Region Data Transfer | $20.00 | $240.00 | ~1TB @ $0.02/GB |
| VPC Endpoints (Interface) | $43.80 | $525.60 | 3 endpoints × 2 AZs |
| VPC Flow Logs | $5.30 | $63.60 | CloudWatch Logs storage |
| **Total Estimated** | **$245.50** | **$2,946.00** | Multi-region HA setup |

## 🔐 Network Architecture Costs

### VPC Components (Free)
```
Free Resources Created:
├── VPCs: 2 (Production, DR)
├── Subnets: 12 total (6 per VPC)
├── Route Tables: 6 custom
├── Internet Gateways: 2
├── Security Groups: 6
├── Network ACLs: 3 custom
├── VPC Peering Connection: 1
└── DHCP Option Sets: 2
```

### NAT Gateway Costs (Highest Cost Component)
```
Configuration:
├── Production (us-east-1): 2 NAT Gateways
│   ├── AZ-1a: $32.85/month
│   └── AZ-1b: $32.85/month
├── DR (us-west-2): 2 NAT Gateways
│   ├── AZ-2a: $32.85/month
│   └── AZ-2b: $32.85/month
└── Total: $131.40/month

Data Processing:
├── Estimated outbound: 1TB/month
├── Cost per GB: $0.045
├── Monthly cost: $45.00
└── Note: Charges for processed bytes only
```

### VPC Endpoints Breakdown
```
Interface Endpoints (us-east-1):
├── com.amazonaws.us-east-1.ssm
│   └── 2 AZs × $0.01/hour = $14.60/month
├── com.amazonaws.us-east-1.ssmmessages
│   └── 2 AZs × $0.01/hour = $14.60/month
├── com.amazonaws.us-east-1.ec2messages
│   └── 2 AZs × $0.01/hour = $14.60/month
└── Total: $43.80/month

Gateway Endpoints (Free):
├── com.amazonaws.us-east-1.s3
└── com.amazonaws.us-east-1.dynamodb
```

## 💸 Data Transfer Costs

### Cross-Region VPC Peering
```
Traffic Pattern:
├── Source: us-east-1 (Production)
├── Destination: us-west-2 (DR)
├── Monthly Volume: ~1TB
├── Use Case: Database replication, backups
└── Cost: 1,000GB × $0.02/GB = $20.00/month
```

### Intra-Region Data Transfer
```
Same AZ: Free
Cross-AZ Transfer:
├── Monthly Volume: ~500GB
├── Cost: 500GB × $0.01/GB = $5.00/month
├── Use Cases:
│   ├── Load balancer to instances
│   ├── Instance to instance
│   └── Instance to RDS
└── Optimization: Place related resources in same AZ
```

### Internet Data Transfer
```
Inbound: Free (always)
Outbound via NAT Gateway:
├── First 1GB/month: Free
├── Next 9.999TB: $0.09/GB
├── Actual usage: Minimal (updates only)
└── Covered under NAT processing fees
```

## 📈 Scaling Cost Projections

### Current Setup (Development Scale)
```
Configuration:
├── 2 Regions (Prod + DR)
├── 4 NAT Gateways (HA)
├── Full monitoring
├── Monthly Cost: $245.50
└── Annual Cost: $2,946.00
```

### Small Production (Single Region)
```
Optimized Configuration:
├── 1 Region only
├── 2 NAT Gateways (HA)
├── No DR setup
├── Reduced endpoints
├── Monthly Cost: ~$85.00
└── Annual Savings: $1,926.00
```

### Medium Enterprise (Multi-Region + Transit Gateway)
```
Enhanced Configuration:
├── 3 Regions
├── Transit Gateway: $109.50/month
├── 6 NAT Gateways
├── Additional endpoints
├── Monthly Cost: ~$485.00
└── Better connectivity at scale
```

### Large Enterprise (Global Deployment)
```
Global Configuration:
├── 5+ Regions
├── Transit Gateway mesh
├── Direct Connect: $500+/month
├── Network Firewall: $395/month
├── Monthly Cost: ~$2,500.00
└── Enterprise-grade networking
```

## 💡 Cost Optimization Strategies

### Immediate Savings Opportunities

1. **Development Environment NAT Gateway**
   ```bash
   # Delete NAT Gateways during off-hours
   # Savings: $65.70/month (50% reduction)
   
   # Create script for scheduled deletion
   #!/bin/bash
   aws ec2 delete-nat-gateway --nat-gateway-id nat-xxxxx
   ```

2. **Single NAT Gateway for Non-Critical**
   ```yaml
   # Instead of Multi-AZ NAT Gateways:
   Before: 2 NAT GW = $65.70/month
   After: 1 NAT GW = $32.85/month
   Savings: $32.85/month per environment
   Trade-off: No HA for NAT
   ```

3. **VPC Endpoint Optimization**
   ```bash
   # Remove Interface Endpoints if not needed
   # Use Gateway Endpoints (free) where possible
   # Savings: $14.60/month per endpoint
   ```

### Advanced Optimizations

1. **NAT Instance Alternative**
   ```yaml
   NAT Gateway: $32.85/month + $0.045/GB
   NAT Instance (t3.micro): $7.59/month + EC2 bandwidth
   Savings: ~$25/month per AZ
   Trade-offs:
   - Manual HA configuration
   - Self-managed updates
   - Bandwidth limitations
   ```

2. **Regional Consolidation**
   ```yaml
   Current: DR in us-west-2
   Alternative: DR in us-east-2 (same region)
   Savings:
   - Reduced data transfer costs
   - Simpler networking
   - ~$20/month cross-region transfer
   ```

3. **Traffic Analysis and Optimization**
   ```bash
   # Analyze VPC Flow Logs for optimization
   aws logs insights query \
     --log-group-name /aws/vpc/flowlogs \
     --query-string 'fields @timestamp, srcaddr, dstaddr, bytes
     | stats sum(bytes) by srcaddr, dstaddr
     | sort bytes desc'
   ```

## 📊 Cost Comparison Analysis

### NAT Gateway vs NAT Instance

| Feature | NAT Gateway | NAT Instance | Savings |
|---------|-------------|--------------|---------|
| Monthly Cost | $32.85 | $7.59 | $25.26 |
| Bandwidth | 45 Gbps | 5 Gbps | - |
| Availability | 99.99% | 99.0% | - |
| Maintenance | AWS Managed | Self-managed | Time cost |
| Scaling | Automatic | Manual | - |

### VPC Peering vs Transit Gateway

| Scale | VPC Peering | Transit Gateway | Break-even |
|-------|-------------|-----------------|------------|
| 2 VPCs | $0/month | $73/month | Never |
| 4 VPCs | $0/month | $146/month | Never |
| 10 VPCs | Complex mesh | $365/month | 8+ VPCs |
| Features | Basic routing | Advanced routing | - |

## 🔍 Cost Monitoring Commands

### Check NAT Gateway Usage
```bash
# Get NAT Gateway metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name BytesOutToDestination \
  --dimensions Name=NatGatewayId,Value=nat-xxxxx \
  --statistics Sum \
  --start-time 2025-07-01T00:00:00Z \
  --end-time 2025-07-31T23:59:59Z \
  --period 86400

# List all NAT Gateways with pricing
aws ec2 describe-nat-gateways \
  --query 'NatGateways[*].[NatGatewayId,State,CreateTime]' \
  --output table
```

### Monitor Data Transfer
```bash
# VPC peering data transfer
aws ec2 describe-vpc-peering-connections \
  --filters "Name=status-code,Values=active" \
  --query 'VpcPeeringConnections[*].[VpcPeeringConnectionId,Status.Code]'

# Check VPC endpoint usage
aws ec2 describe-vpc-endpoints \
  --query 'VpcEndpoints[*].[VpcEndpointId,ServiceName,State]' \
  --output table
```

## 📋 Monthly Cost Review Checklist

- [ ] Review NAT Gateway data processing trends
- [ ] Check for idle NAT Gateways
- [ ] Analyze cross-region transfer volumes
- [ ] Verify VPC endpoint utilization
- [ ] Review Flow Logs storage growth
- [ ] Identify optimization opportunities
- [ ] Compare multi-AZ traffic patterns
- [ ] Validate DR region necessity

## 🎯 Budget Recommendations

### Development/Testing
- Budget: $50/month
- Single NAT Gateway
- No DR region
- Minimal endpoints
- Spot instances for testing

### Production (Current)
- Budget: $250/month
- Multi-AZ NAT Gateways
- DR region with peering
- Essential endpoints only
- Flow logs enabled

### Enterprise Scale
- Budget: $500-2,500/month
- Transit Gateway architecture
- Multiple regions
- Comprehensive endpoints
- Network Firewall
- Direct Connect

## 💰 ROI Justification

### High Availability Value
```
Downtime Cost (per hour): $10,000
NAT Gateway HA Cost: $32.85/month
Availability Improvement: 99.9% → 99.99%
Prevented Downtime: ~0.7 hours/month
Value Generated: $7,000/month
ROI: 21,200%
```

### Performance Benefits
```
Without Endpoints:
- S3 transfer via NAT: $45/month
- Latency: 20-50ms

With Endpoints:
- S3 transfer direct: $0
- Latency: 5-10ms
- Monthly Savings: $45
- Performance: 4x faster
```

---

*Note: All costs are estimates based on AWS pricing as of December 2025. Actual costs may vary based on usage patterns and AWS pricing changes.*