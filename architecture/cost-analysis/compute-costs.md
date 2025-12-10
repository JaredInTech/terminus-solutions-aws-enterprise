<!--
Terminus Solutions AWS Enterprise Architecture
Copyright (c) 2025 Jared (Terminus Solutions) - jaredintech.com
Licensed under CC BY-SA 4.0 - Attribution required
See LICENSE-DOCS for details
-->

# <img src="../../assets/logo.png" alt="Terminus Solutions" height="60"/> Lab-03 Compute Cost Considerations - Detailed Analysis

## Table of Contents

- [Free Tier Services Used](#-free-tier-services-used)
- [Cost Projections - Production Compute](#-cost-projections---production-compute)
  - [Small Organization](#-small-organization-single-region-minimal-ha)
  - [Medium Organization](#-medium-organization-multi-tier-full-ha)
  - [Enterprise Organization](#%EF%B8%8F-enterprise-organization-global-multi-region)
- [Cost Optimization Strategies](#%EF%B8%8F-cost-optimization-strategies)
  - [Immediate Optimizations](#-immediate-optimizations-quick-wins)
  - [Purchasing Strategy Optimizations](#-purchasing-strategy-optimizations)
  - [Progressive Cost Reduction Plan](#-progressive-cost-reduction-plan)
- [Compute Architecture Cost Comparison](#-compute-architecture-cost-comparison)
  - [Platform Options Analysis](#-platform-options-analysis)
  - [Total Compute TCO](#-total-compute-tco-3-year-projection)
- [Real-World Budget Planning](#-real-world-budget-planning)
  - [Compute Budget Allocation Guidelines](#-compute-budget-allocation-guidelines)
  - [Compute Cost Justification Framework](#-compute-cost-justification-framework)
- [Compute Cost Monitoring and Alerting](#-compute-cost-monitoring-and-alerting)
  - [Cost Anomaly Detection](#-cost-anomaly-detection)
  - [Automated Cost Optimization](#-automated-cost-optimization)
- [Compute Cost Dashboard Metrics](#-compute-cost-dashboard-metrics)

---

### 🆓 Free Tier Services Used
```
EC2 Free Tier (First 12 months):
├── t2.micro/t3.micro: 750 hours/month
├── EBS Storage: 30 GB/month (gp2/gp3)
├── Data Transfer: 15 GB outbound/month
├── Elastic IP: 1 free (when attached)
└── Note: Auto Scaling may exceed free tier

Systems Manager (Always Free):
├── Session Manager: Free (no SSH needed)
├── Run Command: Free
├── Parameter Store: 10,000 standard parameters
├── Patch Manager: Free
└── Inventory: Free

CloudWatch (Limited Free Tier):
├── Basic Monitoring: Free (5-minute metrics)
├── 10 Custom Metrics: Free
├── 10 Alarms: Free
├── 5 GB Logs Ingestion: Free
├── 5 GB Logs Storage: Free (first month)
└── 3 Dashboards: Free (up to 50 metrics)

Auto Scaling (Always Free):
├── Auto Scaling Groups: Free
├── Launch Templates: Free
├── Scaling Policies: Free
├── Scheduled Actions: Free
└── Note: Only pay for launched instances

Application Load Balancer:
├── No free tier
├── Charged hourly + LCU
└── ~$18-25/month minimum
```

### 📈 Cost Projections - Production Compute

#### 🏢 Small Organization (Single Region, Minimal HA)
```
Monthly Compute Costs:
├── EC2 Instances: $30.92/month
│   ├── 2× t3.micro web tier: $15.48
│   │   └── 2 × 744hrs × $0.0104/hr
│   └── 2× t3.micro app tier: $15.48
│       └── Minimal footprint
├── Application Load Balancer: $21.90/month
│   ├── Hourly: 744 × $0.0225 = $16.74
│   └── LCU estimate: ~$5.16
├── EBS Storage (gp3): $4.80/month
│   ├── 4× 8GB root volumes: 32GB
│   └── 32GB × $0.08/GB = $2.56
│   └── 4× 20GB app volumes: ~$6.40
├── EBS Snapshots: $1.50/month
│   └── ~30GB incremental/month
├── CloudWatch: $1.20/month
│   └── Basic monitoring (4 instances)
├── Data Transfer: $3.00/month
│   └── ~30GB cross-AZ traffic
└── Total Estimated: $63.32/month ($760/year)

Annual Cost: ~$760 USD
Use Case: Development, staging, or small production
```

#### 🏭 Medium Organization (Multi-Tier, Full HA)
```
Monthly Compute Costs:
├── EC2 Web Tier (ASG): $46.43/month
│   ├── Min 2, Max 6 instances
│   ├── Average 3× t3.micro running
│   └── 3 × 744hrs × $0.0104/hr × 2 (HA)
├── EC2 App Tier (Static HA): $61.84/month
│   ├── 2× t3.small per AZ
│   └── 4 × 744hrs × $0.0208/hr
├── Application Load Balancer: $27.00/month
│   ├── Hourly: $16.74
│   └── LCU (moderate traffic): $10.26
├── EBS Storage (gp3): $16.00/month
│   ├── Web tier: 6× 8GB = 48GB
│   ├── App tier: 4× 20GB = 80GB
│   ├── Additional IOPS: $0 (baseline)
│   └── 128GB × $0.08/GB + buffer
├── EBS Snapshots: $5.00/month
│   ├── Daily retention: 7 days
│   ├── Weekly retention: 4 weeks
│   └── ~100GB incremental storage
├── CloudWatch Detailed Monitoring: $6.00/month
│   ├── $0.30/instance × 10 instances avg
│   └── 1-minute metrics enabled
├── CloudWatch Logs: $5.00/month
│   ├── Web access/error logs
│   ├── App tier logs
│   └── ~10GB ingestion/month
├── Data Transfer: $15.00/month
│   ├── Cross-AZ: 500GB × $0.01 = $5.00
│   ├── Internet out: 100GB × $0.09 = $9.00
│   └── ALB to instances: Included
├── Systems Manager: $0.00/month
│   └── Session Manager free
└── Total Estimated: $182.27/month ($2,187/year)

Annual Cost: ~$2,187 USD
Use Case: Production workloads with HA requirements
```

#### 🏛️ Enterprise Organization (Global, Multi-Region)
```
Monthly Compute Costs:
├── EC2 Web Tier (Multi-Region ASG): $350.00/month
│   ├── Primary Region: 6-12 instances avg
│   ├── DR Region: 2-4 instances standby
│   ├── Mix of t3.medium and c5.large
│   └── Reserved Instance coverage: 60%
├── EC2 App Tier (Multi-Region HA): $480.00/month
│   ├── Primary: 6× c5.large
│   ├── DR: 4× c5.large (warm standby)
│   ├── c5.large: $0.085/hr
│   └── Compute-optimized for processing
├── Application Load Balancers: $95.00/month
│   ├── Primary ALB: $45.00
│   ├── DR ALB: $35.00
│   ├── Internal ALB: $15.00
│   └── High LCU consumption
├── EBS Storage (gp3 optimized): $120.00/month
│   ├── Web tier: 20× 20GB = 400GB
│   ├── App tier: 10× 100GB = 1,000GB
│   ├── Provisioned IOPS: 5,000 extra
│   └── Throughput optimized: 250 MB/s
├── EBS Snapshots (Cross-Region): $50.00/month
│   ├── Daily snapshots: 30-day retention
│   ├── Cross-region copy to DR
│   └── ~1TB total snapshot storage
├── CloudWatch Comprehensive: $85.00/month
│   ├── Detailed monitoring: 30 instances
│   ├── Custom metrics: 100+
│   ├── Contributor Insights: Enabled
│   └── 15+ alarms active
├── CloudWatch Logs: $45.00/month
│   ├── 100GB ingestion/month
│   ├── 30-day retention
│   └── Log Insights queries
├── Data Transfer: $200.00/month
│   ├── Cross-AZ: 2TB × $0.01 = $20
│   ├── Cross-region (DR): 1TB × $0.02 = $20
│   ├── Internet egress: 1.5TB × $0.09 = $135
│   └── CloudFront origin: Reduced rate
├── Elastic IPs: $10.00/month
│   ├── 3 EIPs for NAT/Bastion
│   └── Charges when unattached
├── Launch Template Versions: $0.00/month
│   └── Unlimited versions free
└── Total Estimated: $1,435.00/month ($17,220/year)

Annual Cost: ~$17,220 USD (before RI discounts)
With Reserved Instances: ~$10,332/year (40% savings)
Use Case: Enterprise production with DR requirements
```

### 🛠️ Cost Optimization Strategies

#### ⚡ Immediate Optimizations (Quick Wins)
```bash
# 1. Right-Size Underutilized Instances
# Check CPU utilization over 14 days
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=InstanceId,Value=i-xxxxx \
  --statistics Average Maximum \
  --start-time $(date -d '14 days ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date +%Y-%m-%dT%H:%M:%S) \
  --period 3600

# If avg CPU < 20%, consider downsizing:
# t3.small → t3.micro: Save ~$11/month per instance
# t3.medium → t3.small: Save ~$15/month per instance

# 2. Implement Scheduled Scaling for Dev/Test
# Scale down at night (6 PM - 8 AM)
aws autoscaling put-scheduled-action \
  --auto-scaling-group-name Terminus-Web-ASG \
  --scheduled-action-name scale-down-evening \
  --recurrence "0 18 * * MON-FRI" \
  --min-size 1 \
  --desired-capacity 1

aws autoscaling put-scheduled-action \
  --auto-scaling-group-name Terminus-Web-ASG \
  --scheduled-action-name scale-up-morning \
  --recurrence "0 8 * * MON-FRI" \
  --min-size 2 \
  --desired-capacity 2

# Savings: ~40% on compute ($30/month for 2-instance ASG)

# 3. Enable gp3 Volume Optimization
# gp3 provides 3000 IOPS baseline (gp2 requires larger volume)
# Convert gp2 to gp3 for cost savings
aws ec2 modify-volume \
  --volume-id vol-xxxxx \
  --volume-type gp3

# 100GB volume savings: ~$2/month (gp2: $10 vs gp3: $8)
# Plus free 3000 IOPS vs paying for them

# 4. Delete Unattached EBS Volumes
aws ec2 describe-volumes \
  --filters "Name=status,Values=available" \
  --query 'Volumes[*].[VolumeId,Size,CreateTime]' \
  --output table

# Each orphaned 20GB volume: $1.60/month wasted
```

#### 💰 Purchasing Strategy Optimizations
```
Reserved Instances Analysis:

Standard Reserved Instances (1-year):
├── t3.micro: $0.0062/hr (40% savings)
│   └── Monthly: $4.61 vs $7.74 On-Demand
├── t3.small: $0.0124/hr (40% savings)
│   └── Monthly: $9.23 vs $15.48 On-Demand
├── t3.medium: $0.0248/hr (40% savings)
│   └── Monthly: $18.45 vs $30.80 On-Demand
└── Break-even: 7.2 months

Standard Reserved Instances (3-year):
├── t3.micro: $0.0041/hr (60% savings)
│   └── Monthly: $3.05 vs $7.74 On-Demand
├── t3.small: $0.0082/hr (60% savings)
│   └── Monthly: $6.10 vs $15.48 On-Demand
└── Break-even: 14.4 months

Compute Savings Plans (Recommended):
├── 1-year commitment: 54% discount
├── 3-year commitment: 66% discount
├── Flexibility: Change instance types
├── Applies to: EC2, Fargate, Lambda
└── Best for: Variable workloads, modernization plans

Spot Instances (Development/Testing):
├── t3.micro spot: ~$0.0031/hr (70% savings)
├── t3.small spot: ~$0.0062/hr (70% savings)
├── Best for: Stateless workloads, batch processing
├── Risk: 2-minute interruption notice
└── Mixed ASG: 20% On-Demand, 80% Spot
```

#### 📉 Progressive Cost Reduction Plan
```
Month 1 - Quick Wins:
├── Enable gp3 for all volumes: -$5/month
├── Delete orphaned volumes: -$3/month
├── Implement scheduled scaling: -$30/month
└── Total Savings: $38/month

Month 2 - Right-Sizing:
├── Analyze CloudWatch metrics
├── Downsize over-provisioned instances: -$25/month
├── Optimize EBS snapshot retention: -$5/month
└── Total Savings: $30/month

Month 3 - Purchasing Optimization:
├── Purchase Savings Plans for baseline: -$40/month
├── Implement Spot for dev ASG: -$20/month
└── Total Savings: $60/month

Month 6 - Architecture Optimization:
├── Consider Graviton (t4g) instances: -15% compute
├── Evaluate containerization (Fargate): Variable
├── Implement predictive scaling: -10% over-provisioning
└── Total Savings: $50/month

Annual Optimization Impact:
├── Starting Cost: $182/month ($2,184/year)
├── After Quick Wins: $144/month
├── After Right-Sizing: $114/month  
├── After Purchasing: $74/month
├── Final Optimized: $74/month ($888/year)
└── Total Annual Savings: $1,296 (59% reduction)
```

### 🏆 Compute Architecture Cost Comparison

#### 🔀 Platform Options Analysis
```
Option 1: EC2 Auto Scaling (Current Architecture)
├── Setup Cost: $0
├── Monthly Baseline: $80-180
├── Scaling: Automatic
├── Management: Medium
├── Flexibility: High
└── Best for: Variable traffic, full control needed

Option 2: Elastic Beanstalk
├── Setup Cost: $0
├── Monthly Baseline: $85-190 (same instances)
├── Scaling: Automatic
├── Management: Low
├── Flexibility: Medium
└── Best for: Rapid deployment, managed platform

Option 3: ECS on EC2
├── Setup Cost: $0
├── Monthly Baseline: $100-220
├── Scaling: Automatic
├── Management: Medium
├── Flexibility: High
└── Best for: Container workloads, microservices

Option 4: ECS Fargate
├── Setup Cost: $0
├── Monthly Baseline: $120-280
├── Scaling: Automatic
├── Management: Very Low
├── Flexibility: Medium
└── Best for: Serverless containers, variable load

Option 5: EKS (Kubernetes)
├── Setup Cost: $0
├── Monthly Baseline: $175+ (includes $75 EKS fee)
├── Scaling: Automatic (with config)
├── Management: High
├── Flexibility: Very High
└── Best for: Multi-cloud, existing K8s investment

Option 6: Lambda + API Gateway
├── Setup Cost: $0
├── Monthly Baseline: $5-50 (request-based)
├── Scaling: Automatic (instant)
├── Management: Very Low
├── Flexibility: Limited
└── Best for: Event-driven, low-medium traffic
```

#### 💵 Total Compute TCO (3-Year Projection)
```
Current Architecture (EC2 Auto Scaling with HA):
Year 1: $2,187 (compute) + $15K (engineer time) = $17,187
Year 2: $2,400 (growth) + $5K (maintenance) = $7,400
Year 3: $2,600 (scale) + $5K (maintenance) = $7,600
Total 3-year TCO: $32,187

With Reserved Instances:
Year 1: $1,312 (40% RI) + $15K (setup) = $16,312
Year 2: $1,440 (RI) + $5K (maintenance) = $6,440
Year 3: $1,560 (RI) + $5K (maintenance) = $6,560
Total 3-year TCO: $29,312
Savings: $2,875 (9%)

Containerized Architecture (ECS Fargate):
Year 1: $3,360 + $25K (migration) = $28,360
Year 2: $3,500 + $3K (operations) = $6,500
Year 3: $3,700 + $3K (operations) = $6,700
Total 3-year TCO: $41,560
Premium: $9,373 (29% more expensive)
Benefits: Zero server management, faster deployments

Traditional On-Premises Equivalent:
Hardware (servers, networking): $50,000
Software licenses: $15,000
Data center (3 years): $36,000
IT staff (portion): $150,000
Total 3-year TCO: $251,000

Cloud vs On-Premises Savings:
├── EC2 Architecture: $32,187 (87% savings)
├── Fargate Architecture: $41,560 (83% savings)
└── Breakeven: Never (cloud always cheaper at this scale)
```

### 📊 Real-World Budget Planning

#### 💼 Compute Budget Allocation Guidelines
```
Cloud Infrastructure Budget Impact:
├── Compute Services: 40-60% of total AWS spend
│   ├── EC2 Instances: 60-70% of compute budget
│   ├── Load Balancers: 10-15% of compute budget
│   ├── Storage (EBS): 10-15% of compute budget
│   └── Monitoring: 5-10% of compute budget
├── Typical Ratios by Organization Size:
│   ├── Startup (<$5K/month AWS): 50% compute
│   ├── SMB ($5-50K/month AWS): 45% compute
│   └── Enterprise (>$50K/month AWS): 35% compute
└── Note: Larger orgs shift to data/analytics spend

Typical Enterprise AWS Compute Budget:
Small Org (<$10K/month AWS): $3-5K/month compute
Medium Org ($10-100K/month AWS): $15-40K/month compute
Large Org (>$100K/month AWS): $50-150K/month compute
```

#### 📈 Compute Cost Justification Framework
```markdown
## Business Case for Auto Scaling Architecture

### Quantifiable Benefits:
├── Reduced Downtime: $300K/year (99.99% vs 99.9% SLA)
├── Elastic Capacity: $150K/year (no over-provisioning)
├── Faster Time-to-Market: $200K/year (deployment velocity)
├── Security Improvements: $100K/year (patching automation)
└── Operational Efficiency: $75K/year (reduced manual work)

Total Annual Benefits: $825K
Total Annual Compute Costs: $25K
ROI: 3,200% annually

### Strategic Value:
├── Instant scaling for demand spikes
├── Automatic failure recovery
├── Consistent deployment patterns
└── Foundation for containerization
```

### 🚨 Compute Cost Monitoring and Alerting

#### 📢 Cost Anomaly Detection
```bash
# CloudWatch Alarm for unexpected instance launches
aws cloudwatch put-metric-alarm \
  --alarm-name "Terminus-Unexpected-Instance-Count" \
  --alarm-description "Alert when instance count exceeds threshold" \
  --metric-name GroupTotalInstances \
  --namespace AWS/AutoScaling \
  --dimensions Name=AutoScalingGroupName,Value=Terminus-Web-ASG \
  --statistic Maximum \
  --period 300 \
  --threshold 8 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2 \
  --alarm-actions arn:aws:sns:us-east-1:ACCOUNT:alerts

# CloudWatch Alarm for high ALB costs (LCU spike)
aws cloudwatch put-metric-alarm \
  --alarm-name "Terminus-High-ALB-LCU" \
  --alarm-description "Alert when ALB LCU consumption is high" \
  --metric-name ConsumedLCUs \
  --namespace AWS/ApplicationELB \
  --dimensions Name=LoadBalancer,Value=app/Terminus-Web-ALB/xxxxx \
  --statistic Average \
  --period 3600 \
  --threshold 10 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2

# Cost Explorer API for compute cost analysis
aws ce get-cost-and-usage \
  --time-period Start=2025-06-01,End=2025-06-30 \
  --granularity DAILY \
  --metrics "UnblendedCost" \
  --group-by Type=DIMENSION,Key=SERVICE \
  --filter '{
    "Dimensions": {
      "Key": "SERVICE",
      "Values": [
        "Amazon Elastic Compute Cloud - Compute",
        "EC2 - Other",
        "Elastic Load Balancing"
      ]
    }
  }'

# Get cost by instance type
aws ce get-cost-and-usage \
  --time-period Start=2025-06-01,End=2025-06-30 \
  --granularity MONTHLY \
  --metrics "UnblendedCost" "UsageQuantity" \
  --group-by Type=DIMENSION,Key=INSTANCE_TYPE \
  --filter '{
    "Dimensions": {
      "Key": "SERVICE",
      "Values": ["Amazon Elastic Compute Cloud - Compute"]
    }
  }'
```

#### 🤖 Automated Cost Optimization
```python
# Lambda function for automated compute cost optimization
import boto3
import json
from datetime import datetime, timedelta

def optimize_compute_costs(event, context):
    """Automated compute cost optimization"""
    
    ec2 = boto3.client('ec2')
    cloudwatch = boto3.client('cloudwatch')
    autoscaling = boto3.client('autoscaling')
    
    recommendations = []
    
    # 1. Check for underutilized instances
    instances = ec2.describe_instances(
        Filters=[
            {'Name': 'instance-state-name', 'Values': ['running']},
            {'Name': 'tag:Environment', 'Values': ['Production']}
        ]
    )
    
    for reservation in instances['Reservations']:
        for instance in reservation['Instances']:
            instance_id = instance['InstanceId']
            instance_type = instance['InstanceType']
            
            # Get CPU utilization
            response = cloudwatch.get_metric_statistics(
                Namespace='AWS/EC2',
                MetricName='CPUUtilization',
                Dimensions=[{'Name': 'InstanceId', 'Value': instance_id}],
                StartTime=datetime.now() - timedelta(days=14),
                EndTime=datetime.now(),
                Period=86400,
                Statistics=['Average']
            )
            
            if response['Datapoints']:
                avg_cpu = sum(d['Average'] for d in response['Datapoints']) / len(response['Datapoints'])
                
                if avg_cpu < 10:
                    recommendations.append({
                        'instance_id': instance_id,
                        'current_type': instance_type,
                        'avg_cpu': avg_cpu,
                        'recommendation': 'Consider downsizing or terminating',
                        'potential_savings': '40-60%'
                    })
                elif avg_cpu < 20:
                    recommendations.append({
                        'instance_id': instance_id,
                        'current_type': instance_type,
                        'avg_cpu': avg_cpu,
                        'recommendation': 'Consider downsizing one tier',
                        'potential_savings': '20-30%'
                    })
    
    # 2. Check for unattached EBS volumes
    volumes = ec2.describe_volumes(
        Filters=[{'Name': 'status', 'Values': ['available']}]
    )
    
    for volume in volumes['Volumes']:
        age_days = (datetime.now(volume['CreateTime'].tzinfo) - volume['CreateTime']).days
        if age_days > 7:
            recommendations.append({
                'resource_type': 'EBS Volume',
                'volume_id': volume['VolumeId'],
                'size_gb': volume['Size'],
                'age_days': age_days,
                'recommendation': 'Delete orphaned volume',
                'monthly_savings': f"${volume['Size'] * 0.08:.2f}"
            })
    
    # 3. Check Auto Scaling efficiency
    asgs = autoscaling.describe_auto_scaling_groups()
    
    for asg in asgs['AutoScalingGroups']:
        if 'Terminus' in asg['AutoScalingGroupName']:
            current = len(asg['Instances'])
            desired = asg['DesiredCapacity']
            max_size = asg['MaxSize']
            
            # Check if consistently at minimum
            if current == asg['MinSize'] and max_size > current * 2:
                recommendations.append({
                    'resource_type': 'Auto Scaling Group',
                    'asg_name': asg['AutoScalingGroupName'],
                    'recommendation': 'Consider reducing MaxSize',
                    'current_max': max_size,
                    'suggested_max': current * 2
                })
    
    return {
        'statusCode': 200,
        'body': json.dumps({
            'timestamp': datetime.now().isoformat(),
            'recommendations_count': len(recommendations),
            'recommendations': recommendations
        })
    }
```

### 📊 Compute Cost Dashboard Metrics
```yaml
Key Compute Metrics to Track:
├── Instance Costs:
│   ├── Cost per instance type
│   ├── On-Demand vs Reserved vs Spot usage
│   ├── Instance utilization (CPU, Memory)
│   └── Cost per application tier
├── Auto Scaling Efficiency:
│   ├── Scaling events frequency
│   ├── Time at minimum vs maximum capacity
│   ├── Scaling policy effectiveness
│   └── Instance launch/terminate patterns
├── Load Balancer Metrics:
│   ├── LCU consumption trends
│   ├── Request count vs cost ratio
│   ├── Target response time
│   └── Healthy host count
├── Storage Metrics:
│   ├── EBS volume utilization
│   ├── IOPS consumption vs provisioned
│   ├── Snapshot storage growth
│   └── Orphaned volume detection
└── Cost Efficiency Ratios:
    ├── Cost per request
    ├── Cost per active user
    ├── Infrastructure cost vs revenue
    └── Reserved capacity utilization

Dashboard Alert Thresholds:
├── CPU Utilization: Alert if <15% or >85% sustained
├── Instance Count: Alert if exceeds 150% of baseline
├── LCU Consumption: Alert if >2x normal
├── EBS Spend: Alert if >120% of budget
└── Unattached Resources: Alert if any orphaned >7 days
```

---

### 📋 Monthly Cost Review Checklist

- [ ] Review Auto Scaling group metrics for right-sizing opportunities
- [ ] Check for instances running 24/7 unnecessarily
- [ ] Analyze EBS volumes for unused or over-provisioned storage
- [ ] Evaluate ALB traffic patterns for optimization
- [ ] Consider Reserved Instances for baseline capacity
- [ ] Review CloudWatch log retention policies
- [ ] Validate snapshot retention and cross-region copy necessity
- [ ] Check for unattached EBS volumes and Elastic IPs
- [ ] Monitor Spot Instance interruption rates
- [ ] Compare actual vs projected compute costs
- [ ] Identify candidates for Graviton (ARM) migration

---

### 🎯 Budget Recommendations

#### Development/Testing
- Budget: $25-50/month
- Single instances (no HA)
- Spot instances where possible
- Basic CloudWatch monitoring
- Aggressive scheduled scaling (off-hours shutdown)
- No Reserved Instance commitment

#### Production (Current Lab Setup)
- Budget: $80-120/month
- Multi-AZ HA configuration
- Auto Scaling active (2-6 instances)
- Detailed CloudWatch monitoring
- Standard On-Demand instances
- Consider 1-year Savings Plan after traffic stabilizes

#### Growth Phase
- Budget: $150-250/month
- Increased instance sizes (t3.small → t3.medium)
- More aggressive scaling policies
- Enhanced monitoring and alerting
- Mixed Reserved + On-Demand strategy
- Consider Graviton instances for cost reduction

#### Enterprise Scale
- Budget: $500-2,000/month
- Reserved Instances for 70%+ of baseline
- Multi-region deployment with DR
- Comprehensive monitoring stack
- Dedicated operations team allocation
- Savings Plans for maximum flexibility

---

### 💰 ROI Justification

#### High Availability Value
```
Downtime Cost Analysis:
├── Revenue per hour: $10,000 (example)
├── Single AZ availability: 99.9% (8.76 hours/year downtime)
├── Multi-AZ availability: 99.99% (0.88 hours/year downtime)
├── Prevented downtime: 7.88 hours/year
├── Value generated: $78,800/year
├── Multi-AZ cost premium: ~$400/year
└── ROI: 19,600%

Auto Scaling Value:
├── Over-provisioning without scaling: 50% waste
├── Typical monthly compute: $200
├── Without scaling: $300 (50% buffer)
├── With Auto Scaling: $200 (right-sized)
├── Monthly savings: $100
├── Annual savings: $1,200
└── ROI: Immediate (no additional cost for Auto Scaling)
```

#### Performance Benefits
```
Launch Template + Custom AMI:
├── Generic AMI + User Data: 5-10 minute launch
├── Custom AMI (Pre-baked): 1-2 minute launch
├── Scaling response improvement: 4-5x faster
├── User experience impact: Faster capacity during spikes
└── Business value: Reduced abandoned sessions

Instance Profile Security:
├── Traditional credentials: Manual rotation, exposure risk
├── Instance profiles: Automatic rotation, no stored secrets
├── Security incident prevention: Priceless
├── Compliance audit efficiency: 80% time reduction
└── Annual compliance value: $50,000+ (audit cost reduction)
```

---

*Note: All costs are estimates based on AWS pricing as of December 2025. Actual costs may vary based on usage patterns, region, and AWS pricing changes. Prices are for us-east-1 unless otherwise noted.*