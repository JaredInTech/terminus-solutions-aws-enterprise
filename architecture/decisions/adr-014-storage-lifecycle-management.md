<!--
Terminus Solutions AWS Enterprise Architecture
Copyright (c) 2025 Jared (Terminus Solutions) - jaredintech.com
Licensed under CC BY-SA 4.0 - Attribution required
See LICENSE-DOCS for details
-->

# ADR-014: Storage Lifecycle Management

## Date
2025-07-01

## Status
Accepted

## Context
With our object storage strategy defined (ADR-012), Terminus Solutions needs an automated approach to manage data throughout its lifecycle. Storage costs grow linearly with data volume, but access patterns typically follow a predictable decay curve. We need to optimize costs while ensuring data remains accessible when needed and compliance requirements are met.

Key requirements and constraints:
- Must reduce storage costs by at least 50% within 6 months
- Need to maintain compliance with 7-year retention for certain data
- Require transparent access to archived data when needed
- Support immediate retrieval for recent data (< 30 days)
- Enable scheduled retrieval for older data (acceptable delay)
- Maintain data integrity throughout transitions
- Provide audit trail for all lifecycle actions
- Support both automatic and manual lifecycle triggers
- Consider retrieval costs in optimization strategy
- Budget target: Reduce storage costs from $500/month to $250/month

Current challenges:
- 80% of data accessed less than once after 30 days
- Manual archival processes prone to errors
- No consistent retention enforcement
- Growing storage costs (~50GB/day growth)
- Compliance requires long-term retention

## Decision
We will implement comprehensive S3 Lifecycle policies with intelligent tiering based on access patterns and compliance requirements.

**Lifecycle Architecture:**
```
Lifecycle Strategy:
├── Immediate Transitions
│   ├── Backups → Glacier Instant
│   ├── Archives → Deep Archive
│   └── Compliance → Glacier (locked)
├── Time-Based Transitions
│   ├── 30 days → Standard-IA
│   ├── 90 days → Intelligent-Tiering
│   ├── 180 days → Glacier Instant
│   └── 365 days → Glacier Flexible
├── Access-Based Transitions
│   ├── Intelligent-Tiering monitoring
│   ├── Automatic optimization
│   └── No retrieval charges
└── Expiration Policies
    ├── Temp files: 7 days
    ├── Logs: 1 year
    ├── Non-critical: 2 years
    └── Compliance: Never
```

**Policy Categories:**
1. **Hot Data** (0-30 days): Standard storage for frequent access
2. **Warm Data** (30-90 days): Standard-IA for occasional access
3. **Cool Data** (90-180 days): Intelligent-Tiering for unpredictable access
4. **Cold Data** (180+ days): Glacier for rare access
5. **Frozen Data** (365+ days): Deep Archive for compliance

## Consequences

### Positive
- **Cost Reduction**: 60-80% savings on storage costs
- **Automation**: No manual intervention required
- **Compliance**: Automatic retention enforcement
- **Flexibility**: Per-bucket and per-prefix policies
- **Optimization**: Intelligent-Tiering adapts to access patterns
- **Predictability**: Known costs based on age
- **Reversibility**: Can restore to original class if needed

### Negative
- **Retrieval Costs**: Glacier retrievals incur charges
- **Retrieval Time**: Cold data takes hours to retrieve
- **Complexity**: Multiple policies to manage
- **Minimum Duration**: Some classes have minimum storage duration
- **Transition Costs**: Small charge per object transitioned

### Mitigation Strategies
- **Retrieval Planning**: Bulk retrievals for cost efficiency
- **Policy Documentation**: Clear guidance on data classes
- **Monitoring**: Track retrieval patterns and costs
- **Intelligent-Tiering**: Use for unpredictable access patterns
- **Lifecycle Testing**: Validate policies in development first

## Alternatives Considered

### 1. Manual Archival Process
**Rejected because:**
- Labor intensive and error prone
- Inconsistent application
- No automatic optimization
- Difficult to scale
- Higher operational costs

### 2. Single Transition to Glacier
**Rejected because:**
- Not optimized for access patterns
- Miss intermediate savings opportunities
- All-or-nothing approach
- Difficult to reverse
- Poor user experience

### 3. Third-Party Lifecycle Tools
**Rejected because:**
- Additional costs
- External dependencies
- Less integration with S3
- Security considerations
- Native S3 features sufficient

### 4. Keep Everything in Standard
**Rejected because:**
- Prohibitively expensive at scale
- Wastes money on rarely accessed data
- No compliance enforcement
- Linear cost growth
- Against best practices

### 5. Immediate Deep Archive
**Rejected because:**
- 12-hour retrieval time unacceptable
- High retrieval costs
- Poor user experience
- Not suitable for all data types
- Over-optimization

## Implementation Details

### Lifecycle Policy Templates
```json
{
  "ApplicationDataLifecycle": {
    "Rules": [{
      "Id": "IntelligentTieringRule",
      "Status": "Enabled",
      "Filter": {"Prefix": "appdata/"},
      "Transitions": [
        {
          "Days": 30,
          "StorageClass": "STANDARD_IA"
        },
        {
          "Days": 90,
          "StorageClass": "INTELLIGENT_TIERING"
        },
        {
          "Days": 180,
          "StorageClass": "GLACIER_IR"
        }
      ],
      "NoncurrentVersionExpiration": {
        "NoncurrentDays": 90
      }
    }]
  }
}
```

### Storage Class Decision Matrix
```yaml
Access Pattern Guidelines:
  Daily Access:
    Storage Class: STANDARD
    Use Case: Active application data
    Cost: $0.023/GB
    
  Weekly Access:
    Storage Class: STANDARD_IA
    Use Case: Recent reports
    Cost: $0.0125/GB
    
  Monthly Access:
    Storage Class: INTELLIGENT_TIERING
    Use Case: Variable workloads
    Cost: $0.0125/GB + monitoring
    
  Quarterly Access:
    Storage Class: GLACIER_IR
    Use Case: Compliance data
    Cost: $0.004/GB
    
  Yearly Access:
    Storage Class: GLACIER_FLEXIBLE
    Use Case: Long-term backups
    Cost: $0.0036/GB
    
  Archive Only:
    Storage Class: DEEP_ARCHIVE
    Use Case: Regulatory archives
    Cost: $0.00099/GB
```

### Retrieval Strategy
```yaml
Glacier Instant Retrieval:
  Time: Milliseconds
  Cost: $0.03/GB
  Use: Recent backups
  
Glacier Flexible Retrieval:
  Expedited: 1-5 minutes ($0.03/GB)
  Standard: 3-5 hours ($0.01/GB)
  Bulk: 5-12 hours ($0.0025/GB)
  
Deep Archive Retrieval:
  Standard: 12 hours ($0.02/GB)
  Bulk: 48 hours ($0.0025/GB)
```

### Monitoring and Optimization
```yaml
CloudWatch Metrics:
  - Storage by class
  - Transition counts
  - Retrieval frequency
  - Cost by bucket
  
S3 Storage Lens:
  - Access patterns
  - Cost optimization opportunities
  - Lifecycle rule effectiveness
  
Monthly Reviews:
  - Adjust transition days
  - Review retrieval costs
  - Optimize policies
```

## Implementation Timeline

### Phase 1: Policy Design (Day 1)
- [x] Analyze access patterns
- [x] Define storage classes per data type
- [x] Create lifecycle templates
- [x] Calculate cost projections

### Phase 2: Implementation (Day 2)
- [x] Apply policies to test buckets
- [x] Configure Intelligent-Tiering
- [x] Set up expiration rules
- [x] Enable policy logging

### Phase 3: Validation (Week 1)
- [x] Monitor transitions
- [x] Test retrieval procedures
- [x] Verify cost reductions
- [x] Document procedures

### Phase 4: Optimization (Month 1)
- [ ] Analyze metrics
- [ ] Refine policies
- [ ] Implement automation
- [ ] Train team

**Total Implementation Time:** 1 month (completed core in 2 hours during lab)

## Related Implementation
This decision was implemented in [Lab 4: S3 & Storage Strategy](../../labs/lab-04-s3/README.md), which includes:
- Lifecycle policy configuration
- Cost analysis before/after
- Retrieval testing procedures
- Monitoring dashboard setup
- Team training materials

## Success Metrics
- **Cost Reduction**: >60% after 90 days ✅ (projected)
- **Policy Coverage**: 100% of buckets ✅
- **Compliance**: 100% retention adherence ✅
- **Retrieval SLA**: Meet all requirements ✅
- **Automation**: Zero manual archival ✅

## Review Date
2025-10-01 (3 months) - Review policy effectiveness and costs

## References
- [S3 Lifecycle Configuration](https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lifecycle-mgmt.html)
- [S3 Storage Classes](https://aws.amazon.com/s3/storage-classes/)
- [Intelligent-Tiering](https://aws.amazon.com/s3/storage-classes/intelligent-tiering/)
- **Implementation**: [Lab 4: S3 & Storage Strategy](../../labs/lab-04-s3/README.md)

## Appendix: Cost Optimization Model

### Storage Cost Progression (1TB Example)
| Age | Storage Class | Monthly Cost | Cumulative Savings |
|-----|---------------|--------------|-------------------|
| 0-30 days | STANDARD | $23.00 | $0 |
| 30-90 days | STANDARD_IA | $12.50 | $21.00 |
| 90-180 days | INTELLIGENT_TIERING | $12.80 | $51.60 |
| 180-365 days | GLACIER_IR | $4.00 | $119.25 |
| 365+ days | GLACIER_FLEXIBLE | $3.60 | $352.65/year |

### Break-Even Analysis
```
Transition Costs:
- To Standard-IA: $0.01/1000 objects
- To Glacier: $0.03/1000 objects

Break-even Duration:
- Standard to IA: 10 days
- IA to Glacier: 30 days
- Worth transitioning if stored longer than break-even
```

---

*This decision will be revisited if:*
- Access patterns change significantly
- New storage classes are introduced
- Retrieval costs exceed projections
- Compliance requirements change