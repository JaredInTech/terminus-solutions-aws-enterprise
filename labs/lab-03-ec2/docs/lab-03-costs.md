## Table of Contents

- [Cost Summary](#-cost-summary)
- [EC2 Instance Costs](-ec2-instance-costs)
- [Application Load Balancer Costs](#-application-load-balancer-costs)
- [Storage Costs](#-storage-costs)
- [Monitoring Costs](#-monitoring-costs)
- [Data Transfer Costs](#-data-transfer-costs)
- [Scaling Cost Scenarios](#-scaling-cost-scenarios)
- [Cost Optimization Strategies](#-cost-optimization-strategies)
- [TCO Comparison](#-tco-comparison)
- [Cost Monitoring](#-cost-monitoring)
- [Cost Review Checklist](#-cost-review-checklist)
- [Budget Recommendations](#-budget-recommendations)

# Lab 3: EC2 & Auto Scaling Platform - Cost Analysis

This document provides a detailed breakdown of costs associated with the EC2 compute infrastructure and Auto Scaling platform implemented in Lab 3.

## 📊 Cost Summary

| Component | Monthly Cost | Annual Cost | Notes |
|-----------|--------------|-------------|-------|
| EC2 Instances (Web Tier) | $15.18 | $182.16 | 2× t3.micro (minimum) |
| EC2 Instances (App Tier) | $30.36 | $364.32 | 2× t3.small |
| Application Load Balancer | $18.25 | $219.00 | $0.025/hour + LCU |
| EBS Storage (gp3) | $4.80 | $57.60 | 60GB total |
| EBS Snapshots | $1.50 | $18.00 | Daily snapshots with lifecycle |
| CloudWatch Detailed Monitoring | $6.00 | $72.00 | $0.30 per instance |
| Systems Manager | $0.00 | $0.00 | Free tier usage |
| Data Transfer | $5.00 | $60.00 | Inter-AZ and internet |
| **Total Estimated** | **$81.09** | **$973.08** | Baseline with minimum instances |

## 💻 EC2 Instance Costs

### Web Tier (Auto Scaling Group)
```
Instance Configuration:
├── Type: t3.micro
├── vCPUs: 2
├── Memory: 1 GB
├── Network: Up to 5 Gbps
├── Cost: $0.0104/hour

Auto Scaling Settings:
├── Minimum: 2 instances
├── Desired: 2 instances
├── Maximum: 6 instances
└── Scaling Based on: CPU utilization (70%)

Monthly Cost Scenarios:
├── Minimum (2 instances): 2 × 744hrs × $0.0104 = $15.48
├── Average (3 instances): 3 × 744hrs × $0.0104 = $23.21
├── Peak (6 instances): 6 × 744hrs × $0.0104 = $46.43
└── Estimated Average: $22.00/month
```

### Application Tier (Static Instances)
```
Instance Configuration:
├── Type: t3.small
├── vCPUs: 2
├── Memory: 2 GB
├── Network: Up to 5 Gbps
├── Cost: $0.0208/hour

Deployment:
├── Instances: 2 (one per AZ)
├── Monthly Cost: 2 × 744hrs × $0.0208 = $30.92
└── Annual Cost: $371.04
```

### Scaling Cost Analysis
```
Hourly Scaling Patterns:
├── Off-Peak (8 PM - 8 AM): 2 instances
├── Business Hours (8 AM - 6 PM): 3-4 instances
├── Peak Load (10 AM - 2 PM): 4-6 instances
└── Weekend: 2 instances

Monthly Instance Hours:
├── 2 instances: 400 hours (base)
├── 3 instances: 200 hours
├── 4 instances: 100 hours
├── 5+ instances: 44 hours (spikes)
└── Total: ~1,888 instance hours

Optimized Monthly Cost: ~$19.64
```

## 🔧 Application Load Balancer Costs

### ALB Pricing Components
```
Fixed Costs:
├── Hourly charge: $0.025/hour
├── Monthly: 744 × $0.025 = $18.60
└── Annual: $223.20

Variable Costs (LCU - Load Balancer Capacity Units):
├── New connections: 25/second = 0.004 LCU
├── Active connections: 3,000/minute = 0.004 LCU
├── Processed bytes: 1GB/hour = 0.004 LCU
├── Rule evaluations: 1,000/second = 0.001 LCU
└── Hourly LCU: ~0.013 × $0.008 = $0.0001

Estimated Total:
├── Fixed: $18.60/month
├── Variable: ~$0.60/month
└── Total ALB: $19.20/month
```

## 💾 Storage Costs

### EBS Volume Pricing
```
Volume Configuration:
├── Web Tier: 2 × 8GB gp3 = 16GB
├── App Tier: 2 × 20GB gp3 = 40GB
├── Total Storage: 56GB
└── Additional for scaling: ~20GB

gp3 Pricing:
├── Storage: $0.08/GB/month
├── Base IOPS: 3,000 (free)
├── Base Throughput: 125 MB/s (free)
└── Total: 76GB × $0.08 = $6.08/month

Performance Options (if needed):
├── Additional IOPS: $0.005/IOPS/month
├── Additional throughput: $0.04/MB/s/month
└── Current: Using base performance (free)
```

### EBS Snapshot Costs
```
Snapshot Strategy:
├── Daily snapshots: 7-day retention
├── Weekly snapshots: 4-week retention
├── Snapshot size: ~20GB incremental/month

Storage Calculation:
├── Daily: 7 × 5GB = 35GB
├── Weekly: 4 × 10GB = 40GB
├── Total: 75GB × $0.05/GB = $3.75/month
└── With lifecycle: ~$1.50/month
```

## 📊 Monitoring Costs

### CloudWatch Metrics
```
Detailed Monitoring:
├── Cost: $0.30/instance/month
├── Web Tier: 2-6 instances avg 3 = $0.90
├── App Tier: 2 instances = $0.60
├── Total: ~$1.50/month

Custom Metrics:
├── First 10,000 metrics: Free
├── Application metrics: ~5,000/month
├── Cost: $0 (within free tier)

Alarms:
├── First 10 alarms: Free
├── Additional: $0.10/alarm/month
├── Current usage: 8 alarms = Free
```

### CloudWatch Logs
```
Log Groups:
├── /aws/ec2/web-tier
├── /aws/ec2/app-tier
├── /aws/ssm/session-logs

Volume and Costs:
├── Ingestion: ~10GB/month
├── First 5GB: Free
├── Additional 5GB: 5 × $0.50 = $2.50
├── Storage (30 days): 10GB × $0.03 = $0.30
└── Total: $2.80/month
```

## 💸 Data Transfer Costs

### Inter-AZ Transfer
```
Traffic Patterns:
├── ALB to EC2: ~100GB/month
├── EC2 to EC2: ~50GB/month
├── Total Cross-AZ: 150GB
└── Cost: 150GB × $0.01/GB = $1.50/month
```

### Internet Data Transfer
```
Inbound: Free (always)
Outbound Pricing:
├── First 1GB: Free
├── Next 9.999TB: $0.09/GB
├── Monthly estimate: 50GB
└── Cost: 49GB × $0.09 = $4.41/month
```

## 📈 Scaling Cost Scenarios

### Minimum Cost (Development)
```
Configuration:
├── 1 web instance (no HA)
├── 1 app instance
├── No ALB (direct access)
├── Basic monitoring
└── Monthly Cost: ~$25.00
```

### Current Setup (Production Baseline)
```
Configuration:
├── 2-6 web instances (ASG)
├── 2 app instances (HA)
├── ALB for distribution
├── Detailed monitoring
└── Monthly Cost: ~$81.09
```

### High Traffic (Scaled)
```
Configuration:
├── 6 web instances (sustained)
├── 4 app instances
├── ALB with high LCU
├── Enhanced monitoring
└── Monthly Cost: ~$140.00
```

### Enterprise Scale
```
Configuration:
├── 20+ web instances
├── 10+ app instances
├── Multiple ALBs
├── Reserved Instances
└── Monthly Cost: ~$800.00 (with 40% RI discount)
```

## 💡 Cost Optimization Strategies

### Immediate Optimizations

1. **Scheduled Scaling**
   ```bash
   # Scale down during off-hours
   aws autoscaling put-scheduled-action \
     --auto-scaling-group-name Terminus-Web-ASG \
     --scheduled-action-name scale-down-night \
     --recurrence "0 20 * * *" \
     --min-size 1 \
     --desired-capacity 1
   
   # Savings: ~$7.75/month (50% during nights/weekends)
   ```

2. **Right-Sizing Analysis**
   ```bash
   # Check actual CPU utilization
   aws cloudwatch get-metric-statistics \
     --namespace AWS/EC2 \
     --metric-name CPUUtilization \
     --dimensions Name=InstanceId,Value=i-xxxxx \
     --statistics Average \
     --start-time 2025-07-01T00:00:00Z \
     --end-time 2025-07-07T00:00:00Z \
     --period 3600
   
   # If consistently <20%, consider t3.nano
   # Savings: ~$7.50/month per instance
   ```

3. **Spot Instances for Development**
   ```yaml
   # Mixed instances policy
   OnDemandPercentageAboveBaseCapacity: 20
   SpotAllocationStrategy: "capacity-optimized"
   # Savings: 70-90% on development instances
   ```

### Long-Term Optimizations

1. **Reserved Instances**
   ```
   Standard 1-year term: 40% discount
   Standard 3-year term: 60% discount
   
   Example (2 t3.small):
   ├── On-Demand: $30.92/month
   ├── 1-year RI: $18.55/month
   └── Savings: $148.44/year
   ```

2. **Savings Plans**
   ```
   Compute Savings Plan:
   ├── 1-year commitment: Up to 54% off
   ├── 3-year commitment: Up to 66% off
   ├── Flexibility: Change instance types
   └── Recommended for variable workloads
   ```

3. **Auto Scaling Optimization**
   ```yaml
   Target Tracking Improvements:
   ├── Current target: 70% CPU
   ├── Optimized target: 80% CPU
   ├── Result: Fewer instances needed
   └── Savings: ~15% on compute costs
   ```

## 📊 TCO Comparison

### Current Architecture vs Alternatives

| Solution | Monthly Cost | HA | Scalability | Management |
|----------|--------------|-----|-------------|------------|
| This Lab | $81.09 | Yes | Auto | Medium |
| Single EC2 | $15.48 | No | Manual | High |
| Elastic Beanstalk | ~$85.00 | Yes | Auto | Low |
| ECS Fargate | ~$120.00 | Yes | Auto | Low |
| Traditional Hosting | $500+ | Maybe | Manual | High |

## 🔍 Cost Monitoring

### Cost Allocation Tags
```bash
# Ensure all resources are tagged
aws ec2 create-tags \
  --resources i-xxxxx \
  --tags Key=Environment,Value=Production \
         Key=Application,Value=TerminusWeb \
         Key=CostCenter,Value=Engineering
```

### Monthly Cost Report
```bash
# Get EC2 costs by tag
aws ce get-cost-and-usage \
  --time-period Start=2025-07-01,End=2025-07-31 \
  --granularity MONTHLY \
  --metrics "UnblendedCost" \
  --group-by Type=TAG,Key=Environment \
  --filter '{
    "Dimensions": {
      "Key": "SERVICE",
      "Values": ["Amazon Elastic Compute Cloud - Compute"]
    }
  }'
```

## 📋 Cost Review Checklist

- [ ] Review Auto Scaling metrics for right-sizing
- [ ] Check for instances running 24/7 unnecessarily
- [ ] Analyze EBS volumes for unused storage
- [ ] Evaluate ALB traffic for optimization
- [ ] Consider Reserved Instances for baseline
- [ ] Review CloudWatch log retention
- [ ] Validate snapshot retention policies
- [ ] Check for unattached EBS volumes
- [ ] Monitor data transfer patterns

## 🎯 Budget Recommendations

### Development/Testing
- Budget: $25-40/month
- Single instances (no HA)
- Spot instances
- Basic monitoring
- Aggressive scaling down

### Production (Current)
- Budget: $80-100/month
- HA configuration
- Auto Scaling active
- Detailed monitoring
- Standard instances

### Growth Phase
- Budget: $150-200/month
- Increased traffic handling
- More instances
- Consider RIs
- Enhanced monitoring

### Enterprise Scale
- Budget: $500-1000/month
- Reserved Instances
- Multiple ASGs
- Cross-region deployment
- Comprehensive monitoring

---

*Note: All costs are estimates based on AWS pricing as of July 2025. Actual costs may vary based on usage patterns and AWS pricing changes.*