
<!--
Terminus Solutions AWS Enterprise Architecture
Copyright (c) 2025 Jared (Terminus Solutions) - jaredintech.com
Licensed under CC BY-SA 4.0 - Attribution required
See LICENSE-DOCS for details
-->

# ADR-006: VPC Endpoints and Private Connectivity

## Date
2025-12-01

## Status
Accepted

## Context
With our network security controls defined (ADR-005), Terminus Solutions needs to determine how to enable private connectivity to AWS services. Our data tier has no internet routes for security, and our application tier incurs NAT Gateway charges for all internet-bound traffic. VPC endpoints can provide secure, cost-effective access to AWS services without internet routing.

Key requirements and constraints:
- Data tier must access S3 for backups without internet connectivity
- Need to manage EC2 instances in private subnets without bastion hosts
- Reduce NAT Gateway data processing charges (~$0.045/GB)
- Maintain security posture - no internet exposure for sensitive operations
- Support future serverless architectures requiring AWS service access
- Budget conscious - balance endpoint costs vs data transfer savings
- Limited operational overhead tolerance
- Must support disaster recovery region with similar configuration
- Compliance requires all AWS API calls to stay within AWS network

Current challenges:
- High NAT Gateway costs from S3 traffic (~$200/month)
- Cannot use Systems Manager Session Manager in private subnets
- Database backups to S3 require complex networking
- CloudWatch logs from private instances need internet routing
- Security concerns with AWS API calls over internet

## Decision
We will implement VPC endpoints for critical AWS services, using Gateway endpoints for high-volume services and Interface endpoints for management services.

**Endpoint Strategy:**
1. **Gateway Endpoints** (no hourly cost):
   - S3 - High-volume data transfer
   - DynamoDB - Future application data

2. **Interface Endpoints** ($0.01/hour each):
   - Systems Manager (SSM) - Instance management
   - EC2 Messages - Systems Manager dependency
   - SSM Messages - Systems Manager dependency

3. **Future Considerations** (not implemented yet):
   - CloudWatch Logs - When log volume justifies cost
   - Secrets Manager - When adopted for credential management
   - ECR - When using container workloads

**Cost/Benefit Analysis:**
```
Current S3 Traffic via NAT: ~4TB/month
NAT Gateway Processing: 4TB × $0.045 = $180/month
S3 Gateway Endpoint Cost: $0/month
Savings: $180/month

Interface Endpoints: 3 × $0.01 × 730 hours = $22/month
Net Savings: $158/month
```

## Consequences

### Positive
- **Cost Reduction**: Eliminate NAT Gateway charges for S3/DynamoDB
- **Security Enhancement**: AWS API traffic stays within AWS network
- **Performance**: Lower latency, higher bandwidth to AWS services
- **Compliance**: All traffic auditable, no internet exposure
- **Operational Efficiency**: Direct private access to AWS services
- **Data Tier Access**: Databases can backup to S3 without internet routes
- **Simplified Architecture**: No bastion hosts needed with SSM

### Negative
- **Interface Endpoint Costs**: $7.30/month per endpoint per AZ
- **Complexity**: Additional DNS and routing considerations
- **AZ Specific**: Interface endpoints needed per AZ for HA
- **Security Group Management**: Endpoints need security groups
- **Limited Service Support**: Not all AWS services have endpoints
- **Cross-Region Limitations**: Endpoints don't work across regions

### Mitigation Strategies
- **Cost Management**: Only deploy interface endpoints for essential services
- **Documentation**: Maintain clear endpoint inventory
- **Automation**: Use IaC to ensure consistent deployment
- **Monitoring**: Track endpoint usage and costs
- **Phased Approach**: Add endpoints as usage justifies

## Alternatives Considered

### 1. NAT Gateway Only (No Endpoints)
**Rejected because:**
- Ongoing high data transfer costs
- All AWS traffic traverses internet
- Security concerns with internet routing
- Does not meet compliance requirements
- Monthly costs continue to grow with usage

### 2. NAT Instance Instead of NAT Gateway
**Rejected because:**
- Single point of failure
- Management overhead
- Performance limitations
- No built-in high availability
- Minimal cost savings vs operational burden

### 3. Internet Gateway for All Subnets
**Rejected because:**
- Violates security architecture
- Exposes private resources to internet
- Fails compliance requirements
- Increases attack surface
- Against best practices

### 4. All Possible VPC Endpoints
**Rejected because:**
- Excessive monthly costs (~$200+)
- Many endpoints unused
- Operational complexity
- No ROI for low-volume services
- Over-engineering for current needs

### 5. Private Link for Everything
**Rejected because:**
- Requires service provider support
- Complex setup for each service
- Higher costs than VPC endpoints
- Overkill for AWS native services
- Better for third-party SaaS

## Implementation Details

### Gateway Endpoint Configuration

**S3 Endpoint:**
```yaml
Name: Terminus-S3-Endpoint
Service: com.amazonaws.us-east-1.s3
Type: Gateway
VPC: Terminus-Production-VPC
Route Tables: 
  - All private route tables
Policy: Full access (restrict in production)
Cost: $0/month

Automatic Route Added:
Destination: s3 prefix list → Target: vpce-xxxxx
```

### Interface Endpoint Configuration

**Systems Manager Endpoints:**
```yaml
SSM Endpoint:
  Name: Terminus-SSM-Endpoint
  Service: com.amazonaws.us-east-1.ssm
  Type: Interface
  Subnets: Private application subnets (multi-AZ)
  Security Group: Terminus-VPCEndpoint-SG
  Private DNS: Enabled
  Cost: $7.30/month

EC2 Messages Endpoint:
  Name: Terminus-EC2Messages-Endpoint
  Service: com.amazonaws.us-east-1.ec2messages
  [Similar configuration]

SSM Messages Endpoint:
  Name: Terminus-SSMMessages-Endpoint
  Service: com.amazonaws.us-east-1.ssmmessages
  [Similar configuration]
```

### Endpoint Security Group
```yaml
Name: Terminus-VPCEndpoint-SG
Inbound Rules:
  - HTTPS (443) from 10.0.11.0/24 (App subnet 1)
  - HTTPS (443) from 10.0.12.0/24 (App subnet 2)
  - HTTPS (443) from 10.0.21.0/24 (Data subnet 1)
  - HTTPS (443) from 10.0.22.0/24 (Data subnet 2)
Outbound Rules:
  - None (endpoints don't initiate connections)
```

### Endpoint Policy (S3 Example)
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": "*",
    "Action": [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket"
    ],
    "Resource": [
      "arn:aws:s3:::terminus-*/*",
      "arn:aws:s3:::terminus-*"
    ],
    "Condition": {
      "StringEquals": {
        "aws:PrincipalAccount": ["123456789012"]
      }
    }
  }]
}
```

### DNS Resolution
- Gateway endpoints: Automatic DNS resolution
- Interface endpoints: Private hosted zone created
- Applications use standard AWS service URLs
- No application changes required

## Implementation Timeline

### Phase 1: Gateway Endpoints (Week 1)
- [x] Deploy S3 gateway endpoint
- [x] Update route tables automatically
- [x] Test S3 access from private subnets
- [x] Validate cost reduction

### Phase 2: Interface Endpoints (Week 2)
- [x] Create endpoint security group
- [x] Deploy SSM interface endpoints
- [x] Deploy EC2/SSM Messages endpoints
- [x] Test Session Manager access

### Phase 3: Validation (Week 3)
- [x] Verify private subnet connectivity
- [x] Test DR region requirements
- [x] Monitor data transfer costs
- [x] Document access patterns

### Phase 4: Optimization (Week 4)
- [ ] Analyze CloudWatch metrics
- [ ] Identify additional endpoint candidates
- [ ] Refine endpoint policies
- [ ] Plan future expansions

**Total Implementation Time:** 4 weeks (completed core in 1 hour during lab)

## Related Implementation
This decision was implemented in [Lab 2: VPC & Networking Core](../../labs/lab-02-vpc/README.md), which includes:
- Step-by-step endpoint creation
- Route table updates for gateway endpoints
- Security group configuration
- Testing procedures for private access
- Cost analysis and monitoring
- Troubleshooting guide

## Success Metrics
- **Cost Reduction**: >$150/month savings ✅ (estimated)
- **Security**: Zero internet-routed AWS API calls ✅
- **Availability**: 100% endpoint uptime ✅
- **Performance**: <10ms latency to S3 ✅
- **Adoption**: All private instances use endpoints ✅

## Review Date
2026-03-01 (3 months) - Analyze usage patterns and costs

## References
- [AWS VPC Endpoints Documentation](https://docs.aws.amazon.com/vpc/latest/privatelink/vpc-endpoints.html)
- [Gateway vs Interface Endpoints](https://docs.aws.amazon.com/vpc/latest/privatelink/vpce-gateway.html)
- [VPC Endpoint Policies](https://docs.aws.amazon.com/vpc/latest/privatelink/vpc-endpoints-access.html)
- **Implementation**: [Lab 2: VPC & Networking Core](../../labs/lab-02-vpc/README.md)

## Appendix: Service Endpoint Analysis

| AWS Service | Monthly Traffic | NAT Cost | Endpoint Type | Endpoint Cost | Deploy? |
|-------------|----------------|----------|---------------|---------------|---------|
| S3 | 4TB | $180 | Gateway | $0 | ✅ Yes |
| DynamoDB | Future | TBD | Gateway | $0 | ✅ Yes |
| SSM | <1GB | <$1 | Interface | $22 | ✅ Yes |
| CloudWatch | 500GB | $23 | Interface | $22 | 🟡 Maybe |
| ECR | Future | TBD | Interface | $22 | ❌ Later |
| Lambda | Minimal | <$1 | Interface | $22 | ❌ No |

### Endpoint Decision Framework
```
Should I create a VPC endpoint?
├── Is monthly NAT cost > $30?
│   └── Yes → Deploy endpoint
├── Is it a security requirement?
│   └── Yes → Deploy endpoint
├── Is it a Gateway endpoint?
│   └── Yes → Deploy (free)
└── Otherwise → Monitor and revisit
```

### Common Endpoint Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| S3 access fails | Missing route | Check route tables for prefix list |
| SSM not working | Missing endpoints | Need all 3 SSM-related endpoints |
| High latency | Wrong region endpoint | Use same-region endpoints |
| Access denied | Endpoint policy | Review and adjust policy |
| DNS not resolving | Private DNS disabled | Enable private DNS on interface endpoints |

---

*This decision will be revisited if:*
- Monthly NAT charges exceed $500
- New AWS services require private access
- Container workloads need ECR access
- Serverless adoption increases significantly