<!--
Terminus Solutions AWS Enterprise Architecture
Copyright (c) 2025 Jared (Terminus Solutions) - jaredintech.com
Licensed under CC BY-SA 4.0 - Attribution required
See LICENSE-DOCS for details
-->

# <img src="../../assets/logo.png" alt="Terminus Solutions" height="60"/> Architecture Decision Records

This directory contains all Architecture Decision Records (ADRs) for the Terminus Solutions project. ADRs capture important architectural decisions made along with their context, alternatives considered, and consequences.

> **Security Note:** All AWS account IDs, email addresses, and sensitive information in this repository are **redacted or fictional** for security compliance.

## Table of Contents

- [Index](#index)
- [ADR Process](#adr-process)
- [ADR Template](#adr-template)
- [Project Navigation](#-project-navigation)

## Index

### Foundation (Labs 1-2)

| ADR | Title | Status | Lab | Date |
|-----|-------|--------|-----|------|
| [001](./adr-001-multi-account-strategy.md) | Multi-Account Strategy with AWS Organizations | Accepted | Lab 1 | 2025-12-01 |
| [002](./adr-002-vpc-cidr-allocation-strategy.md) | VPC CIDR Allocation Strategy | Accepted | Lab 2 | 2025-12-01 |
| [003](./adr-003-network-segmentation-architecture.md) | Network Segmentation Architecture | Accepted | Lab 2 | 2025-12-01 |
| [004](./adr-004-multi-region-dr-network-design.md) | Multi-Region DR Network Design | Accepted | Lab 2 | 2025-12-01 |
| [005](./adr-005-network-security-controls-strategy.md) | Network Security Controls Strategy | Accepted | Lab 2 | 2025-12-01 |
| [006](./adr-006-vpc-endpoints-private-connectivity.md) | VPC Endpoints and Private Connectivity | Accepted | Lab 2 | 2025-12-01 |

### Compute & Storage (Labs 3-4)

| ADR | Title | Status | Lab | Date |
|-----|-------|--------|-----|------|
| [007](./adr-007-compute-platform-architecture.md) | Compute Platform Architecture | Accepted | Lab 3 | 2025-12-10 |
| [008](./adr-008-ami-management-strategy.md) | AMI Management Strategy | Accepted | Lab 3 | 2025-12-10 |
| [009](./adr-009-instance-profile-security.md) | Instance Profile Security | Accepted | Lab 3 | 2025-12-10 |
| [010](./adr-010-auto-scaling-strategy.md) | Auto Scaling Strategy | Accepted | Lab 3 | 2025-12-10 |
| [011](./adr-011-storage-performance-optimization.md) | Storage Performance Optimization | Accepted | Lab 3 | 2025-12-10 |
| [012](./adr-012-object-storage-strategy.md) | Object Storage Strategy | Accepted | Lab 4 | 2025-12-10 |
| [013](./adr-013-static-content-delivery.md) | Static Content Delivery | Accepted | Lab 4 | 2025-12-10 |
| [014](./adr-014-storage-lifecycle-management.md) | Storage Lifecycle Management | Accepted | Lab 4 | 2025-12-10 |
| [015](./adr-015-cross-region-data-replication.md) | Cross-Region Data Replication | Accepted | Lab 4 | 2025-12-10 |
| [016](./adr-016-event-driven-storage-processing.md) | Event-Driven Storage Processing | Accepted | Lab 4 | 2025-12-10 |

### Application Services (Labs 5-10)

| ADR | Title | Status | Lab | Date |
|-----|-------|--------|-----|------|
| 017 | Database Platform Selection | Planned | Lab 5 | - |
| 018 | Database High Availability Strategy | Planned | Lab 5 | - |
| 019 | DNS and Global Routing Strategy | Planned | Lab 6 | - |
| 020 | Load Balancing Architecture | Planned | Lab 7 | - |
| 021 | Serverless Computing Strategy | Planned | Lab 8 | - |
| 022 | Event-Driven Messaging Architecture | Planned | Lab 9 | - |
| 023 | Observability and Monitoring Strategy | Planned | Lab 10 | - |

### Operations & Modernization (Labs 11-13)

| ADR | Title | Status | Lab | Date |
|-----|-------|--------|-----|------|
| 024 | Infrastructure as Code Strategy | Planned | Lab 11 | - |
| 025 | Security Services Integration | Planned | Lab 12 | - |
| 026 | Container Orchestration Strategy | Planned | Lab 13 | - |

## ADR Process

### Creating a New ADR
1. Copy `adr-template.md` to `adr-NNN-brief-description.md`
2. Fill out all sections thoroughly
3. Status starts as "Proposed"
4. Update to "Accepted" after review
5. Link from relevant lab documentation
6. Update this index

### ADR Lifecycle
- **Proposed**: Initial draft, under discussion
- **Accepted**: Approved and implemented
- **Deprecated**: No longer valid, but kept for history
- **Superseded**: Replaced by another ADR (link to successor)

### Best Practices
- Keep titles concise but descriptive
- Include quantifiable metrics where possible
- Document all alternatives considered
- Link to related ADRs and implementation
- Update status when implementation changes

## ADR Template

```markdown
# ADR-XXX: [Decision Title]

## Date
YYYY-MM-DD

## Status
[Proposed | Accepted | Deprecated | Superseded by ADR-XXX]

## Context
[Describe the issue or opportunity that we're addressing. Include:]
- Current situation and problem statement
- Business drivers and constraints
- Technical requirements
- Team/organizational constraints
- Compliance or regulatory requirements
- Future considerations

## Decision
[State the decision clearly and concisely. Include:]
- What we will do
- High-level approach
- Key components or changes

## Consequences

### Positive
- **[Benefit Category]**: [Specific positive outcome with details]
- **[Benefit Category]**: [Specific positive outcome with details]
[List all significant benefits]

### Negative
- **[Challenge Category]**: [Specific negative outcome or risk]
- **[Challenge Category]**: [Specific negative outcome or risk]
[List all significant drawbacks]

### Mitigation Strategies
- **[Challenge]**: [How we'll address this challenge]
- **[Challenge]**: [How we'll address this challenge]
[For each negative consequence, explain mitigation]

## Alternatives Considered

### 1. [Alternative Option Name]
**Rejected because:**
- [Specific reason 1]
- [Specific reason 2]
[Explain why this wasn't chosen]

### 2. [Alternative Option Name]
**Rejected because:**
- [Specific reason 1]
- [Specific reason 2]

### 3. [Alternative Option Name]
**Considered but deferred:**
- [Reason for deferral]
- [Conditions for future reconsideration]

## Implementation Details

### [Implementation Category 1]
[Diagrams, code snippets, or structured details]

### [Implementation Category 2]
[Specific implementation guidance]

## Implementation Timeline

### Phase 1: [Phase Name] (Week 1-X)
- [ ] [Specific task with owner if applicable]
- [ ] [Specific task with dependencies noted]

### Phase 2: [Phase Name] (Week X-Y)
- [ ] [Specific task]
- [ ] [Milestone: Key deliverable]

**Total Implementation Time:** [X weeks/months]

## Related Implementation
This decision was implemented in [Lab X: Name](../../labs/lab-XX-name/README.md), which includes:
- [Key implementation aspect 1]
- [Key implementation aspect 2]

## Success Metrics
- **[Metric Category]**: [Specific measurable outcome]
- **[Metric Category]**: [Specific measurable outcome]

## Review Date
[YYYY-MM-DD] ([timeframe]) - [What we'll evaluate]

## References
- [Link to relevant documentation]
- [Link to relevant standards or best practices]
- [Link to related ADRs or decisions]

## Appendix: [Optional Supporting Material]

| Criteria | Option 1 | Option 2 | Option 3 |
|----------|----------|----------|----------|
| [Criterion] | [Rating] | [Rating] | [Rating] |

---

*This decision will be revisited if:*
- [Condition 1]
- [Condition 2]
- [Condition 3]
```

## ADR Summary by Category

### Security Decisions
- **ADR-001**: Multi-account isolation strategy
- **ADR-005**: Network security controls (NACLs, Security Groups)
- **ADR-006**: VPC endpoints for private connectivity
- **ADR-009**: Instance profile security (no stored credentials)

### Networking Decisions
- **ADR-002**: CIDR allocation strategy
- **ADR-003**: Three-tier network segmentation
- **ADR-004**: Multi-region DR network design
- **ADR-006**: VPC endpoints configuration

### Compute Decisions
- **ADR-007**: Multi-tier compute architecture
- **ADR-008**: Golden AMI management strategy
- **ADR-010**: Auto Scaling with target tracking
- **ADR-011**: EBS gp3 storage optimization

### Storage Decisions
- **ADR-012**: Multi-purpose S3 bucket architecture
- **ADR-013**: CloudFront CDN integration
- **ADR-014**: Lifecycle policies for cost optimization
- **ADR-015**: Cross-region replication for DR
- **ADR-016**: Event-driven processing with Lambda

---

### 📊 Project Navigation

| Lab | Component | Status | Documentation |
|-----|-----------|--------|---------------|
| 1 | IAM & Organizations | ✅ Complete | [View](../../labs/lab-01-iam/README.md) |
| 2 | VPC & Networking Core | ✅ Complete | [View](../../labs/lab-02-vpc/README.md) |
| 3 | EC2 & Auto Scaling Platform | ✅ Complete | [View](../../labs/lab-03-ec2/README.md) |
| 4 | S3 & Storage Strategy | ✅ Complete | [View](../../labs/lab-04-s3/README.md) |
| 5 | RDS & Database Services | 📅 Planned | - |
| 6 | Route53 & CloudFront Distribution | 📅 Planned | - |
| 7 | ELB & High Availability | 📅 Planned | - |
| 8 | Lambda & API Gateway Services | 📅 Planned | - |
| 9 | SQS, SNS & EventBridge Messaging | 📅 Planned | - |
| 10 | CloudWatch & Systems Manager Monitoring | 📅 Planned | - |
| 11 | CloudFormation Infrastructure as Code | 📅 Planned | - |
| 12 | Security Services Integration | 📅 Planned | - |
| 13 | Container Services (ECS/EKS) | 📅 Planned | - |

*Last Updated: December 10, 2025*