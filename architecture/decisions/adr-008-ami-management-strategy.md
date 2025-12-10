
<!--
Terminus Solutions AWS Enterprise Architecture
Copyright (c) 2025 Jared (Terminus Solutions) - jaredintech.com
Licensed under CC BY-SA 4.0 - Attribution required
See LICENSE-DOCS for details
-->

# ADR-008: AMI Management Strategy

## Date
2025-06-13

## Status
Accepted

## Context
With our compute platform architecture defined (ADR-007), Terminus Solutions needs a strategy for building, managing, and maintaining Amazon Machine Images (AMIs). Custom AMIs are critical for rapid scaling, consistent deployments, and security compliance, but require careful management to avoid technical debt and security vulnerabilities.

Key requirements and constraints:
- Must enable rapid instance launches (< 60 seconds)
- Need consistent configuration across all instances
- Require regular security patching and updates
- Support multiple application tiers with different requirements
- Enable rollback capabilities for failed deployments
- Maintain compliance with security standards
- Minimize storage costs for AMI artifacts
- Support both production and development environments
- Limited operations team for manual processes

Current challenges:
- Configuration drift between instances
- Slow deployment times with runtime configuration
- Inconsistent software versions across fleet
- Security patching delays and gaps
- No standardized build process

## Decision
We will implement a structured AMI management strategy with automated building, versioning, and lifecycle management.

**AMI Strategy Components:**
1. **Golden AMI** approach with pre-installed software
2. **Semantic versioning** for AMI tracking
3. **Automated build pipeline** (future CI/CD integration)
4. **Monthly refresh cycle** for security updates
5. **Tier-specific AMIs** for optimized configurations
6. **Cross-region replication** for DR readiness

**AMI Structure:**
```
Base Layer (AWS Linux 2023):
├── OS and security updates
├── CloudWatch Agent
├── Systems Manager Agent
├── Basic monitoring scripts
└── Security hardening

Web Tier Additions:
├── Apache HTTP Server
├── PHP runtime
├── Application code structure
└── Web-specific monitoring

Application Tier Additions:
├── Java 17 runtime
├── Python 3 environment
├── Node.js runtime
├── Application frameworks
└── Performance monitoring tools
```

## Consequences

### Positive
- **Deployment Speed**: 30-60 second instance launches vs 5-10 minutes
- **Consistency**: Identical configuration across all instances
- **Security**: Regular patching cycle with compliance tracking
- **Reliability**: Tested configurations before production
- **Rollback**: Previous AMI versions available for quick rollback
- **Cost Efficiency**: Minimal runtime configuration reduces compute time
- **Operational Efficiency**: Reduced troubleshooting from consistency

### Negative
- **Storage Costs**: Multiple AMI versions consume EBS snapshot storage
- **Build Time**: Initial AMI creation takes 20-30 minutes
- **Maintenance Overhead**: Regular rebuild cycle required
- **Version Sprawl**: Multiple versions to track and manage
- **Regional Management**: Must replicate to multiple regions

### Mitigation Strategies
- **Retention Policy**: Keep only last 3 versions per tier
- **Automated Building**: Scheduled builds reduce manual effort
- **Version Tracking**: Clear tagging and documentation
- **Automated Testing**: Validate AMIs before production use
- **Cross-region Sync**: Automated replication for DR

## Alternatives Considered

### 1. Runtime Configuration Only
**Rejected because:**
- Slow instance launch times (5-10 minutes)
- Increased failure points during scaling
- Higher complexity in user data scripts
- Inconsistent results from package updates
- Poor Auto Scaling response time

### 2. Container Images Instead
**Rejected because:**
- Application not containerized yet
- Additional orchestration complexity
- Team lacks container expertise
- Timeline doesn't allow refactoring
- Can migrate to containers later

### 3. Third-Party Configuration Management
**Rejected because:**
- Additional tool complexity (Ansible, Puppet)
- Requires agent installation and management
- Learning curve for team
- Runtime configuration still needed
- Licensing costs for enterprise features

### 4. Single Universal AMI
**Rejected because:**
- Bloated image size
- Unnecessary software per tier
- Security concerns (larger attack surface)
- Slower launch times
- Violates principle of least privilege

### 5. AWS Systems Manager Only
**Rejected because:**
- Still requires base configuration
- Slower than pre-built AMIs
- More complex troubleshooting
- Dependency on Systems Manager availability
- Not suitable for rapid scaling

## Implementation Details

### AMI Naming Convention
```
Pattern: Terminus-[Tier]-[OS]-[Version]-[BuildDate]

Examples:
- Terminus-Web-AL2023-v1.0-20250613
- Terminus-App-AL2023-v1.0-20250613
- Terminus-Base-AL2023-v1.0-20250613
```

### Versioning Strategy
```yaml
Major Version (1.x.x):
  - OS version changes
  - Major software updates
  - Architecture changes

Minor Version (x.1.x):
  - New software additions
  - Configuration changes
  - Feature additions

Patch Version (x.x.1):
  - Security updates
  - Bug fixes
  - Minor adjustments
```

### Build Process
```bash
# 1. Launch builder instance
# 2. Apply base configurations
# 3. Install tier-specific software
# 4. Run security hardening
# 5. Clean up temporary files
# 6. Create AMI
# 7. Tag with metadata
# 8. Test AMI launch
# 9. Replicate to DR region
# 10. Update launch templates
```

### Tagging Strategy
```yaml
Required Tags:
  - Name: AMI name following convention
  - Version: Semantic version number
  - Tier: Web|App|Base
  - BuildDate: YYYY-MM-DD
  - Environment: Production|Development
  - SecurityPatch: Latest patch date
  - SourceAMI: Parent AMI ID
  - Builder: Automated|Manual
  - Tested: true|false
  - Approved: true|false
```

## Implementation Timeline

### Phase 1: Base AMI Development (Day 1)
- [x] Define base AMI requirements
- [x] Create hardening scripts
- [x] Install monitoring agents
- [x] Test base configuration

### Phase 2: Tier-Specific AMIs (Day 2)
- [x] Build web server AMI
- [x] Build application server AMI
- [x] Document configurations
- [x] Test launch times

### Phase 3: Process Establishment (Day 3)
- [x] Create versioning standards
- [x] Document build process
- [x] Set up tagging strategy
- [ ] Implement automated building

### Phase 4: Lifecycle Management (Week 2)
- [ ] Create retention policies
- [ ] Automate cross-region replication
- [ ] Set up compliance scanning
- [ ] Implement automated testing

**Total Implementation Time:** 2 weeks (completed core in 1 day during lab)

## Related Implementation
This decision was implemented in [Lab 3: EC2 & Auto Scaling Platform](../../labs/lab-03-ec2/README.md), which includes:
- Base AMI configuration scripts
- Web and application tier AMI builds
- AMI testing procedures
- Launch template integration
- Cross-region replication setup

## Success Metrics
- **Build Time**: < 30 minutes per AMI ✅
- **Launch Time**: < 60 seconds to ready state ✅
- **Patch Currency**: 100% instances patched within 30 days ✅ (process defined)
- **Version Control**: All AMIs properly tagged and tracked ✅
- **Rollback Speed**: < 10 minutes to previous version ✅ (tested)

## Review Date
2025-09-13 (3 months) - Evaluate build frequency and storage costs

## References
- [AWS AMI Best Practices](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html)
- [EC2 Image Builder](https://aws.amazon.com/image-builder/)
- [CIS Amazon Linux 2023 Benchmark](https://www.cisecurity.org/benchmark/amazon_linux)
- **Implementation**: [Lab 3: EC2 & Auto Scaling Platform](../../labs/lab-03-ec2/README.md)

## Appendix: AMI Lifecycle

| Phase | Duration | Actions | Automation |
|-------|----------|---------|------------|
| Build | 30 min | Create, configure, test | Partial |
| Test | 1 hour | Launch, validate, approve | Manual |
| Deploy | 5 min | Update launch templates | Manual |
| Monitor | Ongoing | Track usage and issues | Automated |
| Retire | 5 min | Deregister, delete snapshots | Manual |

### Monthly Maintenance Schedule
```
Week 1: Security scanning and planning
Week 2: Build new AMI versions
Week 3: Testing and validation
Week 4: Production deployment
```

---

*This decision will be revisited if:*
- EC2 Image Builder becomes cost-effective for our scale
- Container adoption makes AMIs obsolete
- Maintenance overhead becomes unsustainable
- Security requirements change significantly