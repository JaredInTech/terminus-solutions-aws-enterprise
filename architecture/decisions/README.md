<!--
Terminus Solutions AWS Enterprise Architecture
Copyright (c) 2025 Jared (Terminus Solutions) - jaredintech.com
Licensed under CC BY-SA 4.0 - Attribution required
See LICENSE-DOCS for details
-->

# <img src="../../assets/logo.png" alt="Terminus Solutions" height="60"/> Architecture Decision Records

This directory contains all Architecture Decision Records (ADRs) for the Terminus Solutions project.

## Index

| ADR | Title | Status | Lab | Date |
|-----|-------|--------|-----|------|
| [001](./adr-001-multi-account-strategy.md) | Multi-Account Strategy with AWS Organizations | Accepted | Lab 1 | 2025-12-01 |
| [002](./adr-002-vpc-cidr-allocation-strategy.md) | VPC CIDR Allocation Strategy | Accepted | Lab 2 | 2025-12-01 |
| [003](./adr-003-network-segmentation-architecture.md) | Network Segmentation Architecture | Accepted | Lab 2 | 2025-12-01 |
| [004](./adr-004-multi-region-dr-network-design.md) | Multi-Region DR Network Design | Accepted | Lab 2 | 2025-12-01 |
| [005](./adr-005-network-security-controls-strategy.md) | Network Security Controls Strategy | Accepted | Lab 2 | 2025-12-01 |
| [006](./adr-006-vpc-endpoints-private-connectivity.md) | VPC Endpoints and Private Connectivity | Accepted | Lab 2 | 2025-12-01 |


## ADR Process
1. Copy `adr-template.md` to `adr-NNN-brief-description.md`
2. Fill out all sections
3. Status starts as "Proposed"
4. Update to "Accepted" after review
5. Link from relevant lab documentation

## ADR Template

```markdown
# ADR-XXX: [Decision Title]

## Date
YYYY-MM-DD

## Status
[Proposed | Accepted | Deprecated | Superseded by ADR-XXX]

## Context
[Describe the issue or opportunity that we're addressing. Include:]s
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

### [Implementation Category 3]
- [Implementation point 1]
- [Implementation point 2]

## Implementation Timeline

### Phase 1: [Phase Name] (Week 1-X)
- [ ] [Specific task with owner if applicable]
- [ ] [Specific task with dependencies noted]
- [ ] [Specific task with completion criteria]

### Phase 2: [Phase Name] (Week X-Y)
- [ ] [Specific task]
- [ ] [Specific task]
- [ ] [Milestone: Key deliverable]

### Phase 3: [Phase Name] (Week Y-Z)
- [ ] [Specific task]
- [ ] [Specific task]
- [ ] [Final validation and documentation]

**Critical Path Items:**
- [Task that blocks other work]
- [Task with external dependencies]

**Total Implementation Time:** [X weeks/months]

## Related Implementation
[If this decision has been implemented, reference the specific lab or code]
This decision was implemented in [Lab X: Name](../../labs/lab-XX-name/README.md), which includes:
- [Key implementation aspect 1]
- [Key implementation aspect 2]
- [Key implementation aspect 3]
- [Key implementation aspect 4]

[OR if not yet implemented:]
This decision will be implemented in the following labs:
- [Lab X: Name] - [What aspect will be implemented]
- [Lab Y: Name] - [What aspect will be implemented]

## Success Metrics
- **[Metric Category]**: [Specific measurable outcome]
- **[Metric Category]**: [Specific measurable outcome]
[Define how we'll know this decision was successful]

## Review Date
[YYYY-MM-DD] ([timeframe]) - [What we'll evaluate]

## References
- [Link to relevant documentation]
- [Link to relevant standards or best practices]
- [Link to related ADRs or decisions]

## Appendix: [Optional Supporting Material]

[Decision matrices, detailed analysis, calculations, etc.]

| Criteria | Option 1 | Option 2 | Option 3 |
|----------|----------|----------|----------|
| [Criterion] | [Rating] | [Rating] | [Rating] |

---

*This decision will be revisited if:*
- [Condition 1]
- [Condition 2]
- [Condition 3]
```
---

### 📊 Project Navigation

| Lab | Component | Status | Documentation |
|-----|-----------|--------|---------------|
| 1 | IAM & Organizations | ✅ Complete | [View](/labs/lab-01-iam/README.md) |
| 2 | VPC & Networking Core | ✅ Complete | [View](/labs/lab-02-vpc/README.md) |
| 3 | EC2 & Auto Scaling Platform | 🚧 In Progress | - |
| 4 | S3 & Storage Strategy | 📅 Planned | - |
| 5 | RDS & Database Services | 📅 Planned | - |
| 6 | Route53 & CloudFront Distribution | 📅 Planned | - |
| 7 | ELB & High Availability | 📅 Planned | - |
| 8 | Lambda & API Gateway Services | 📅 Planned | - |
| 9 | SQS, SNS & EventBridge Messaging | 📅 Planned | - |
| 10 | CloudWatch & Systems Manager Monitoring | 📅 Planned | - |
| 11 | CloudFormation Infrastructure as Code | 📅 Planned | - |
| 12 | Security Services Integration | 📅 Planned | - |
| 13 | Container Services (ECS/EKS) | 📅 Planned | - |

*Last Updated: December 3rd, 2025*