
<!--
Terminus Solutions AWS Enterprise Architecture
Copyright (c) 2025 Jared (Terminus Solutions) - jaredintech.com
Licensed under CC BY-SA 4.0 - Attribution required
See LICENSE-DOCS for details
-->

# ADR-001: Multi-Account Strategy with AWS Organizations for Terminus Solutions

## Date
2025-12-01

## Status
Accepted

## Context
Terminus Solutions is establishing its cloud infrastructure foundation on AWS. As a technology consulting company, we need to demonstrate enterprise-grade security, governance, and scalability from day one. 

Key requirements and constraints:
- Must support complete isolation between production and development environments
- Need centralized billing and cost allocation by department
- Require comprehensive audit trails for compliance (future SOC2, HIPAA readiness)
- Team size: Currently 15 people, expected to grow to 50+ within 18 months
- Limited dedicated security team (security is everyone's responsibility)
- Budget conscious - need to optimize for cost while maintaining security
- Must be able to onboard new developers quickly and safely
- Future requirement: Support client workload isolation

## Decision
We will implement AWS Organizations with a multi-account strategy using the following structure:
- **Management Account**: Billing, organization management, and CloudTrail aggregation only
- **Production Account**: Customer-facing workloads and production data
- **Development Account**: Development, testing, and experimentation
- **Security Account**: Security tools, audit logs, and compliance monitoring

We will use Service Control Policies (SCPs) for preventive controls and centralized CloudTrail for detective controls.

## Consequences

### Positive
- **Complete Blast Radius Isolation**: A compromise or misconfiguration in development cannot impact production resources
- **Clear Cost Attribution**: Each account's costs are separately tracked, enabling accurate departmental chargebacks
- **Simplified Compliance**: Account boundaries provide clear audit scope and data residency controls
- **Granular Access Control**: Different security policies can be applied at the account level via SCPs
- **Scalability**: Easy to add new accounts for future needs (client isolation, additional environments)
- **Industry Best Practice**: Aligns with AWS Well-Architected Framework and enterprise patterns

### Negative
- **Increased Complexity**: Cross-account access requires role assumption and trust relationships
- **Operational Overhead**: Managing multiple accounts requires more initial setup
- **Cost Implications**: Some services have per-account costs (though minimal)
- **Learning Curve**: Developers need to understand cross-account access patterns
- **Tool Integration**: Some third-party tools may not support multi-account well

### Mitigation Strategies
- **Complexity**: Document clear runbooks and automate common cross-account operations
- **Overhead**: Use Infrastructure as Code to manage account configurations
- **Learning**: Provide team training and clear documentation on account switching
- **Tools**: Evaluate all tools for multi-account support before adoption

## Alternatives Considered

### 1. Single Account with VPC Isolation
**Rejected because:**
- Insufficient isolation - IAM misconfigurations could impact all environments
- Cannot implement environment-specific SCPs
- Difficult to track costs by environment
- Single CloudTrail makes compliance scoping harder
- Does not scale well for future client workload isolation

### 2. Account per Team/Service
**Rejected because:**
- Too complex for current team size (would need 5-10 accounts immediately)
- Excessive operational overhead for small team
- More expensive (multiplicative service costs)
- Harder to manage shared services
- Can migrate to this model later if needed

### 3. Two Accounts (Prod/Non-Prod)
**Rejected because:**
- Security tooling mixed with development reduces security posture
- No dedicated space for security tools and audit logs
- Harder to implement least-privilege for security team
- Less flexibility for future growth

### 4. AWS Control Tower
**Considered but deferred:**
- Adds complexity we don't need yet
- More opinionated than our current requirements
- Can migrate to Control Tower later if needed
- Current approach gives more flexibility

## Implementation Details

### Organizational Unit Structure
```
Root Organization
├── Production OU
│   └── Production Account
├── Development OU
│   └── Development Account
└── Security OU
    └── Security Account
```

### Key SCPs to Implement
1. **Production OU**: Deny root user access, require encryption, restrict regions
2. **Development OU**: Limit expensive instance types, require tagging, time-based restrictions
3. **All OUs**: Deny disabling of CloudTrail, require MFA for sensitive operations

### Cross-Account Access Model
- `OrganizationAccountAccessRole`: Emergency access from management account
- `TerminusDeveloperRole`: Limited access for developers
- `TerminusReadOnlyRole`: Audit and troubleshooting access
- `TerminusSecurityAuditRole`: Security team cross-account access

## Implementation Timeline

### Phase 1: Foundation Setup (Week 1-2)
- [x] Create AWS Organizations with all features enabled
- [x] Create Production, Development, and Security OUs
- [x] Create member accounts for each OU
- [x] Verify email addresses for all accounts
- [x] Document account IDs and access patterns

### Phase 2: Security Controls (Week 2-3)
- [x] Implement Production OU SCPs (deny root, encryption requirements)
- [x] Implement Development OU SCPs (instance limits, cost controls)
- [x] Create cross-account IAM roles
- [x] Test role assumption from management account
- [x] Enable MFA requirements

### Phase 3: Audit & Monitoring (Week 3-4)
- [x] Configure organization-wide CloudTrail
- [x] Set up S3 bucket with lifecycle policies
- [x] Enable CloudWatch Logs integration
- [x] Configure SNS notifications for security events
- [x] Validate log aggregation across all accounts

### Phase 4: Operationalization (Week 4-5)
- [x] Create developer onboarding runbooks
- [x] Document account switching procedures
- [ ] Conduct team training sessions
- [x] Set up cost allocation tags
- [x] Milestone: First developer successfully onboarded

**Critical Path Items:**
- AWS Organizations setup (blocks all other work)
- Email verification (blocks account access)
- CloudTrail configuration (required for audit compliance)

**Total Implementation Time:** 5 weeks (completed in 5 hours during lab)

## Related Implementation
This decision was implemented in [Lab 1: IAM & Organizations Foundation](../../labs/lab-01-iam/README.md), which includes:
- Step-by-step setup instructions for AWS Organizations
- Actual SCP JSON policies for production and development controls
- Cross-account role configurations and trust relationships
- Testing procedures and validation steps
- Cost analysis and optimization strategies
- Troubleshooting guide for common issues

## Success Metrics
- **Security**: Zero account boundary breaches ✅
- **Cost**: <5% overhead vs single account ✅ (actual: $0 during implementation)
- **Efficiency**: <5 minutes to switch between accounts ✅ (actual: <1 minute)
- **Compliance**: 100% CloudTrail coverage across all accounts ✅
- **Developer Experience**: <30 minutes to onboard new developer ✅ (tested with mock developer)

## Review Date
2026-06-01 (6 months) - Evaluate if account structure still meets needs

## References
- [AWS Organizations Best Practices](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_best-practices.html)
- [AWS Multi-Account Strategy Whitepaper](https://docs.aws.amazon.com/whitepapers/latest/organizing-your-aws-environment/organizing-your-aws-environment.html)
- [AWS Well-Architected Framework - Security Pillar](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/welcome.html)
- **Implementation**: [Lab 1: IAM & Organizations Foundation](../../labs/lab-01-iam/README.md)

## Appendix: Decision Matrix

| Criteria | Single Account | 2 Accounts | 4 Accounts (Chosen) | Per-Service |
|----------|---------------|------------|---------------------|-------------|
| Isolation | ❌ Poor | 🟡 Fair | ✅ Excellent | ✅ Excellent |
| Complexity | ✅ Low | 🟡 Medium | 🟡 Medium | ❌ High |
| Cost | ✅ Lowest | ✅ Low | ✅ Low | ❌ Higher |
| Scalability | ❌ Poor | 🟡 Fair | ✅ Good | ✅ Excellent |
| Compliance | ❌ Difficult | 🟡 Fair | ✅ Good | ✅ Good |
| Team Fit | ❌ No | 🟡 Maybe | ✅ Yes | ❌ No |

---

*This decision will be revisited if:*
- Team grows beyond 50 people
- We need to host isolated client workloads
- AWS releases new multi-account management features
- Operational overhead becomes unmanageable