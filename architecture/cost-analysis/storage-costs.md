<!--
Terminus Solutions AWS Enterprise Architecture
Copyright (c) 2025 Jared (Terminus Solutions) - jaredintech.com
Licensed under CC BY-SA 4.0 - Attribution required
See LICENSE-DOCS for details
-->

## <img src="../../assets/logo.png" alt="Terminus Solutions" height="60"/> Storage Cost Considerations - Detailed Analysis

### 🆓 Free Storage Services Used
```
S3 Free Tier (First Year):
├── Storage: 5GB Standard storage free
├── Requests: 20,000 GET / 2,000 PUT free
├── Data Transfer: 15GB out free
└── Note: After first year, all usage charged

EBS Free Tier (First Year):
├── Storage: 30GB General Purpose SSD
├── Snapshots: 1GB snapshot storage
├── IOPS: 2 million I/Os
└── Note: gp2 or gp3 eligible

AWS Backup Free Tier:
├── Backup Storage: 5GB free
├── Restore: 10GB free per month
└── Note: Applies to supported services
```

### 📈 Cost Projections - Storage Services

#### 🏢 Small Organization (Basic Storage Needs)
```
Monthly Storage Costs:
├── S3 Storage (500GB mixed): $8.50/month
│   ├── Standard (100GB): $2.30
│   ├── Standard-IA (200GB): $2.50
│   ├── Glacier Instant (150GB): $0.60
│   └── Intelligent-Tiering (50GB): $0.64
├── EBS Volumes (200GB gp3): $16.00/month
│   ├── Web tier: 4 × 20GB = $6.40
│   └── App tier: 4 × 30GB = $9.60
├── EBS Snapshots (100GB): $5.00/month
│   └── Daily incrementals with lifecycle
├── Data Transfer: $5.00/month
│   └── S3 to EC2, cross-AZ
└── Total Estimated: $34.50/month ($414/year)

Annual Cost: ~$414 USD
```

#### 🏭 Medium Organization (Multi-Region, Growing Data)
```
Monthly Storage Costs:
├── S3 Storage (10TB mixed): $85.00/month
│   ├── Standard (2TB): $46.00
│   ├── Standard-IA (3TB): $37.50
│   ├── Intelligent-Tiering (3TB): $38.40
│   ├── Glacier Instant (1.5TB): $6.00
│   └── Glacier Flexible (500GB): $1.80
├── S3 Replication: $40.00/month
│   ├── Cross-region transfer: 2TB × $0.02
│   └── Destination storage (IA): Included above
├── EBS Volumes (2TB total): $160.00/month
│   ├── Production: 1TB gp3 = $80
│   └── Development: 1TB gp3 = $80
├── EBS Snapshots (500GB): $25.00/month
│   ├── Daily, weekly, monthly cycles
│   └── Cross-region copies for DR
├── CloudFront CDN: $35.00/month
│   ├── 500GB transfer × $0.085
│   └── 10M requests included
├── Data Transfer: $50.00/month
│   ├── S3 via NAT Gateway: 500GB
│   ├── Cross-AZ transfer: 1TB
│   └── Internet egress: 100GB
└── Total Estimated: $395.00/month ($4,740/year)

Annual Cost: $4,740 USD
```

#### 🏛️ Enterprise Organization (Global, Multi-Region, Compliance)
```
Monthly Storage Costs:
├── S3 Storage (100TB mixed): $580.00/month
│   ├── Standard (10TB): $230.00
│   ├── Standard-IA (20TB): $250.00
│   ├── Intelligent-Tiering (30TB): $384.00
│   ├── Glacier Instant (25TB): $100.00
│   ├── Glacier Flexible (10TB): $36.00
│   └── Deep Archive (5TB): $5.00
├── S3 Features: $250.00/month
│   ├── Cross-region replication: 10TB
│   ├── Transfer Acceleration: 5TB
│   ├── S3 Inventory: 100M objects
│   └── Object Lock compliance: 20TB
├── EBS Volumes (20TB): $1,600.00/month
│   ├── gp3 SSD: 15TB × $80 = $1,200
│   ├── io2 Provisioned: 5TB × $125 = $625
│   └── Additional IOPS: 50K × $0.065 = $325
├── EBS Snapshots (10TB): $500.00/month
│   ├── Automated lifecycle policies
│   ├── Cross-region DR copies
│   └── Long-term retention
├── AWS Backup: $400.00/month
│   ├── Centralized backup: 20TB
│   ├── Cross-region copies
│   └── Compliance retention
├── CloudFront CDN: $425.00/month
│   ├── 5TB global transfer
│   ├── 100M requests
│   └── Origin shield enabled
├── Storage Gateway: $250.00/month
│   ├── File Gateway for hybrid
│   └── Volume Gateway for backup
└── Total Estimated: $4,005.00/month ($48,060/year)

Annual Cost: $48,060 USD
```

### 🛠️ Cost Optimization Strategies

#### ⚡ Immediate Optimizations (Quick Wins)
```bash
# 1. Enable S3 Intelligent-Tiering for variable access patterns
aws s3api put-bucket-intelligent-tiering-configuration \
  --bucket my-bucket \
  --id optimize-all \
  --intelligent-tiering-configuration '{
    "Id": "optimize-all",
    "Status": "Enabled",
    "Tierings": [{
      "Days": 90,
      "AccessTier": "ARCHIVE_ACCESS"
    },{
      "Days": 180,
      "AccessTier": "DEEP_ARCHIVE_ACCESS"
    }]
  }'
# Savings: 40-70% on eligible data

# 2. Implement S3 Lifecycle Policies
aws s3api put-bucket-lifecycle-configuration \
  --bucket my-bucket \
  --lifecycle-configuration '{
    "Rules": [{
      "Status": "Enabled",
      "Transitions": [{
        "Days": 30,
        "StorageClass": "STANDARD_IA"
      },{
        "Days": 90,
        "StorageClass": "GLACIER"
      }]
    }]
  }'
# Savings: 50-95% on archived data

# 3. Delete unattached EBS volumes
aws ec2 describe-volumes \
  --filters "Name=status,Values=available" \
  --query 'Volumes[*].[VolumeId,Size,CreateTime]' \
  --output table
# Savings: $80/TB/month

# 4. Optimize EBS volume types
# Convert gp2 to gp3 for same performance at lower cost
aws ec2 modify-volume \
  --volume-id vol-xxxxx \
  --volume-type gp3
# Savings: 20% on EBS costs
```

#### 📊 Storage Class Optimization Matrix
```python
def calculate_storage_optimization(data_profile):
    """Determine optimal storage class based on access patterns"""
    
    optimizations = {
        'hot_data': {  # Accessed daily
            'current': 'STANDARD',
            'recommended': 'STANDARD',
            'savings': '0%',
            'action': 'No change needed'
        },
        'warm_data': {  # Accessed weekly
            'current': 'STANDARD',
            'recommended': 'STANDARD_IA',
            'savings': '45%',
            'action': 'Lifecycle after 30 days'
        },
        'cool_data': {  # Accessed monthly
            'current': 'STANDARD',
            'recommended': 'INTELLIGENT_TIERING',
            'savings': '40-70%',
            'action': 'Enable Intelligent-Tiering'
        },
        'cold_data': {  # Accessed quarterly
            'current': 'STANDARD',
            'recommended': 'GLACIER_IR',
            'savings': '83%',
            'action': 'Lifecycle after 90 days'
        },
        'frozen_data': {  # Accessed yearly
            'current': 'STANDARD',
            'recommended': 'DEEP_ARCHIVE',
            'savings': '95%',
            'action': 'Archive after 180 days'
        }
    }
    
    return optimizations
```

#### 📅 Progressive Cost Reduction Plan
```yaml
Month 1-3: "Foundation Optimization"
  Actions:
    - Identify unattached volumes: -$200/month
    - Convert gp2 to gp3: -$50/month
    - Basic lifecycle policies: -$150/month
  Total Savings: $400/month

Month 4-6: "Advanced Optimization"  
  Actions:
    - Intelligent-Tiering adoption: -$300/month
    - Snapshot retention cleanup: -$100/month
    - Right-size over-provisioned volumes: -$200/month
  Total Savings: $1,000/month

Month 7-12: "Enterprise Optimization"
  Actions:
    - Implement Storage Lens insights: -$200/month
    - Cross-region optimization: -$150/month
    - Reserved capacity planning: -$400/month
  Total Savings: $1,750/month
```

### 🏆 Storage Architecture Cost Comparison

#### 🔀 Storage Solution Comparison
```
Option 1: All S3 Standard
├── Setup Cost: Minimal
├── Monthly Cost: $2,300/TB
├── Performance: Excellent
├── Complexity: Low
└── Use Case: Frequently accessed data only

Option 2: Lifecycle Optimized (Current)
├── Setup Cost: Medium (policy creation)
├── Monthly Cost: $800/TB average
├── Performance: Good with retrieval delays
├── Complexity: Medium
└── Use Case: Mixed access patterns

Option 3: Manual Tiering
├── Setup Cost: High (operational overhead)
├── Monthly Cost: $600/TB average
├── Performance: Poor (manual moves)
├── Complexity: High
└── Use Case: Not recommended

Option 4: All Glacier
├── Setup Cost: Low
├── Monthly Cost: $100/TB
├── Performance: Poor (retrieval delays)
├── Complexity: Low
└── Use Case: Archive only
```

#### 💵 EBS vs Instance Store vs EFS Comparison
```
EBS gp3 (Chosen for most workloads):
├── Cost: $80/TB/month
├── Performance: 3,000 IOPS baseline
├── Durability: 99.999%
├── Features: Snapshots, encryption, resize
└── Best For: General purpose, databases

Instance Store:
├── Cost: Included with instance
├── Performance: Very high (NVMe)
├── Durability: Ephemeral (data loss on stop)
├── Features: Highest IOPS/throughput
└── Best For: Temporary data, caches

EFS:
├── Cost: $300/TB/month (Standard)
├── Performance: Burstable or provisioned
├── Durability: 99.999999999%
├── Features: Multi-AZ, shared access
└── Best For: Shared content, containers

FSx:
├── Cost: $200-500/TB/month
├── Performance: Varies by type
├── Durability: 99.99%+
├── Features: Fully managed, protocol-specific
└── Best For: Windows workloads, HPC
```

### 📊 Real-World Budget Planning

#### 💼 Storage Budget Allocation Guidelines
```
Cloud Infrastructure Storage Impact:
├── Storage Services: 20-40% of total AWS spend
├── Breakdown by Service:
│   ├── S3: 40-60% of storage budget
│   ├── EBS: 30-40% of storage budget
│   ├── Snapshots: 10-15% of storage budget
│   └── Other (EFS, FSx): 5-10% of storage budget
├── Growth Rate: 30-50% annually
└── Optimization Potential: 40-60% savings

Typical Enterprise AWS Storage Budget:
Small Org (<1TB): $50-200/month
Medium Org (1-50TB): $500-5K/month
Large Org (50TB+): $5K-50K/month
```

#### 📈 Storage Cost Justification Framework
```markdown
## Business Case for Optimized Storage Architecture

### Quantifiable Benefits:
├── Reduced Storage Costs: $2K/month (60% reduction)
├── Eliminated Downtime: $50K/year (snapshot recovery)
├── Improved Performance: $30K/year (productivity)
├── Compliance Achievement: $100K/year (automated retention)
└── Operational Efficiency: $20K/year (automation)

Total Annual Benefits: $224K
Total Annual Storage Costs: $48K  
ROI: 367% annually

### Strategic Value:
├── Infinite scalability without infrastructure
├── Global data availability
├── Automated disaster recovery
├── Built-in compliance features
└── Pay-per-use flexibility
```

### 🚨 Storage Cost Monitoring and Alerting

#### 📢 Cost Anomaly Detection
```bash
# S3 Storage Class Analysis
aws s3 ls s3://my-bucket --recursive --human-readable --summarize \
  | awk '/Total Size:/ {print $3, $4}'

# S3 Storage Lens for cost insights
aws s3control get-storage-lens-configuration \
  --config-id cost-optimization-dashboard \
  --account-id 123456789012

# EBS Volume utilization check
aws ec2 describe-volumes \
  --query 'Volumes[*].[VolumeId,Size,VolumeType,State,Attachments[0].InstanceId]' \
  --output table

# Cost Explorer for storage trends
aws ce get-cost-and-usage \
  --time-period Start=2025-01-01,End=2025-07-31 \
  --granularity MONTHLY \
  --metrics "UnblendedCost" \
  --group-by Type=DIMENSION,Key=SERVICE \
  --filter '{
    "Dimensions": {
      "Key": "SERVICE",
      "Values": ["Amazon Simple Storage Service", "Amazon Elastic Block Store"]
    }
  }'
```

#### 🤖 Automated Storage Optimization
```python
# Lambda function for automated storage optimization
import boto3
import json
from datetime import datetime, timedelta

def optimize_storage_costs(event, context):
    """Automated storage cost optimization"""
    
    s3 = boto3.client('s3')
    ec2 = boto3.client('ec2')
    cloudwatch = boto3.client('cloudwatch')
    
    optimizations = []
    
    # Check S3 buckets for lifecycle opportunities
    buckets = s3.list_buckets()
    for bucket in buckets['Buckets']:
        # Analyze access patterns
        try:
            metrics = get_bucket_metrics(bucket['Name'])
            if metrics['days_since_last_access'] > 30:
                # Recommend lifecycle policy
                optimizations.append({
                    'type': 'S3 Lifecycle',
                    'resource': bucket['Name'],
                    'action': 'Add lifecycle policy',
                    'savings': calculate_savings(metrics)
                })
        except:
            pass
    
    # Check for unattached EBS volumes
    volumes = ec2.describe_volumes(
        Filters=[{'Name': 'status', 'Values': ['available']}]
    )
    
    for volume in volumes['Volumes']:
        optimizations.append({
            'type': 'Unattached EBS',
            'resource': volume['VolumeId'],
            'action': 'Delete or snapshot',
            'savings': volume['Size'] * 0.08  # $0.08/GB/month
        })
    
    # Send optimization report
    send_optimization_report(optimizations)
    
    return {
        'statusCode': 200,
        'body': json.dumps(f'Found {len(optimizations)} optimization opportunities')
    }
```

### 📊 Storage Cost Dashboard Metrics
```yaml
Key Storage Metrics to Track:
├── S3 Metrics:
│   ├── Storage by class (GB and $)
│   ├── Request patterns and costs
│   ├── Transfer costs by type
│   ├── Lifecycle transitions count
│   └── Replication lag and costs
├── EBS Metrics:
│   ├── Volume utilization %
│   ├── Unattached volume costs
│   ├── IOPS utilization vs provisioned
│   ├── Snapshot storage growth
│   └── Volume type distribution
├── Data Transfer:
│   ├── S3 to EC2 transfer costs
│   ├── Cross-region replication
│   ├── CloudFront distribution costs
│   └── Internet egress by service
└── Optimization Metrics:
    ├── Storage class distribution
    ├── Lifecycle policy effectiveness
    ├── Cost per GB by service
    ├── Month-over-month growth
    └── Savings from optimizations
```

### 💡 Advanced Cost Optimization Techniques

#### S3 Request Optimization
```yaml
Request Cost Reduction:
  Batch Operations:
    Instead: 1000 individual PUTs
    Use: S3 Batch Operations
    Savings: 90% on request costs
    
  Multipart Uploads:
    Threshold: >100MB files
    Benefit: Resumable, parallel
    Cost: Same as regular PUT
    
  Transfer Acceleration:
    Use When: Upload time savings > 50%
    Cost: $0.04/GB extra
    ROI: Faster time-to-market
```

#### EBS Optimization Strategies
```yaml
Volume Optimization:
  gp2 to gp3 Migration:
    Action: Modify volume type
    Savings: 20% lower cost
    Benefit: Better performance control
    
  Right-sizing:
    Monitor: CloudWatch metrics
    Threshold: <20% utilization
    Action: Shrink volume
    
  Snapshot Optimization:
    Incremental: Automatic
    Lifecycle: Delete old snapshots
    Cross-region: Only critical data
```

### 📈 Cost Projection Models

#### Storage Growth Modeling
```python
def project_storage_costs(current_tb, growth_rate, months):
    """Project storage costs with growth"""
    
    costs = []
    storage = current_tb
    
    for month in range(months):
        # Apply growth
        storage *= (1 + growth_rate)
        
        # Calculate tiered costs
        standard_cost = min(storage * 0.3, 10) * 23  # 30% hot data
        ia_cost = min(storage * 0.4, 40) * 12.5      # 40% warm data
        glacier_cost = storage * 0.3 * 4              # 30% cold data
        
        total_cost = standard_cost + ia_cost + glacier_cost
        costs.append({
            'month': month + 1,
            'storage_tb': round(storage, 2),
            'cost': round(total_cost, 2)
        })
    
    return costs

# Example: 10TB growing at 5% monthly
projections = project_storage_costs(10, 0.05, 12)
# Month 12: 17.96TB costing $412/month
```

---

*Note: All costs are estimates based on AWS pricing as of July 2025. Actual costs may vary based on usage patterns, AWS pricing changes, and specific configurations.*