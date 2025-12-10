
<!--
Terminus Solutions AWS Enterprise Architecture
Copyright (c) 2025 Jared (Terminus Solutions) - jaredintech.com
Licensed under CC BY-SA 4.0 - Attribution required
See LICENSE-DOCS for details
-->

# ADR-010: Auto Scaling Strategy

## Date
2025-06-13

## Status
Accepted

## Context
With our compute platform architecture established (ADR-007), Terminus Solutions needs a comprehensive Auto Scaling strategy that balances performance, availability, and cost. The strategy must handle variable traffic patterns, ensure rapid response to demand changes, and maintain application performance while optimizing costs.

Key requirements and constraints:
- Must handle 10x traffic spikes within 5 minutes
- Need to maintain 70% CPU utilization target for cost efficiency
- Require protection against cascading failures
- Support both predictable and unpredictable traffic patterns
- Minimize costs during low-traffic periods
- Ensure zero-downtime during scaling events
- Prevent scaling oscillation (thrashing)
- Support scheduled scaling for known patterns
- Integrate with future load balancers (Lab 7)

Current challenges:
- Unknown baseline traffic patterns
- Unpredictable spike timing and magnitude
- Balance between response time and stability
- Cost optimization vs. performance guarantee
- Different scaling needs per tier

## Decision
We will implement a multi-dimensional Auto Scaling strategy using a combination of target tracking, step scaling, and scheduled scaling policies.

**Scaling Architecture:**
```
Multi-Policy Approach:
├── Target Tracking (Primary)
│   ├── Metric: CPU Utilization
│   ├── Target: 70%
│   └── Handles: Gradual changes
├── Step Scaling (Secondary)
│   ├── Trigger: >85% CPU
│   ├── Action: Aggressive scale-out
│   └── Handles: Sudden spikes
├── Scheduled Scaling (Predictive)
│   ├── Business hours capacity
│   ├── Weekend reduction
│   └── Handles: Known patterns
└── Lifecycle Hooks (Operational)
    ├── Launch: Configuration verification
    └── Terminate: Graceful shutdown
```

**Tier-Specific Strategies:**
```yaml
Web Tier:
  Min: 1 (cost optimization)
  Desired: 2 (high availability)
  Max: 6 (spike handling)
  Scale-out: Fast (60s cooldown)
  Scale-in: Slow (300s cooldown)

Application Tier:
  Min: 1 (always available)
  Desired: 1 (normal load)
  Max: 4 (processing capacity)
  Scale-out: Moderate (180s cooldown)
  Scale-in: Very slow (600s cooldown)
```

## Consequences

### Positive
- **Responsive Scaling**: Multiple policies handle different scenarios
- **Cost Efficiency**: Scale down aggressively during low traffic
- **Spike Protection**: Step scaling handles sudden load
- **Predictable Costs**: Scheduled scaling for known patterns
- **High Availability**: Minimum instances ensure availability
- **Operational Safety**: Cooldowns prevent oscillation
- **Future Ready**: Supports load balancer integration

### Negative
- **Complexity**: Multiple policies to manage and tune
- **Tuning Required**: Initial thresholds may need adjustment
- **Cost Variability**: Auto Scaling creates variable bills
- **Over-provisioning Risk**: Conservative settings increase cost
- **Monitoring Overhead**: Requires comprehensive metrics

### Mitigation Strategies
- **Monitoring**: CloudWatch dashboards for scaling behavior
- **Alerting**: Notifications for unusual scaling activity
- **Cost Controls**: Maximum instance limits
- **Testing**: Regular load testing to validate policies
- **Documentation**: Clear scaling behavior documentation

## Alternatives Considered

### 1. Simple CPU-Based Scaling Only
**Rejected because:**
- Too slow for traffic spikes
- Single metric insufficient
- No predictive capability
- Reactive only, not proactive
- Limited optimization potential

### 2. Manual Scaling
**Rejected because:**
- Requires 24/7 operations
- Human reaction time too slow
- Error-prone and inconsistent
- Against cloud-native principles
- Expensive operational overhead

### 3. Time-Based Scaling Only
**Rejected because:**
- Cannot handle unexpected spikes
- Wasteful during quiet periods
- No response to actual load
- Inflexible for changes
- Poor cost optimization

### 4. Custom Metrics Only
**Rejected because:**
- Complex implementation
- Requires application changes
- Harder to troubleshoot
- Additional development time
- CPU still primary indicator

### 5. Aggressive Scaling (No Limits)
**Rejected because:**
- Cost explosion risk
- Potential for runaway scaling
- Thundering herd problems
- Account limit issues
- Difficult to control

## Implementation Details

### Target Tracking Configuration
```yaml
Primary Scaling Policy:
  Type: TargetTrackingScaling
  TargetValue: 70.0
  PredefinedMetricType: ASGAverageCPUUtilization
  ScaleInCooldown: 300
  ScaleOutCooldown: 60
  DisableScaleIn: false
  
Behavior:
  - Maintains 70% CPU average
  - Adds instances when >70%
  - Removes instances when <70%
  - Built-in dampening logic
```

### Step Scaling Configuration
```yaml
High CPU Response:
  MetricAlarm:
    MetricName: CPUUtilization
    Statistic: Average
    Period: 60
    EvaluationPeriods: 2
    Threshold: 85
    
  ScalingAdjustments:
    - LowerBound: 0      # 85-95% CPU
      UpperBound: 10
      ScalingAdjustment: 2
    - LowerBound: 10     # >95% CPU
      ScalingAdjustment: 4
```

### Scheduled Scaling Configuration
```yaml
Business Hours:
  Schedule: "0 8 * * MON-FRI"
  MinSize: 2
  DesiredCapacity: 4
  MaxSize: 8

After Hours:
  Schedule: "0 18 * * MON-FRI"
  MinSize: 1
  DesiredCapacity: 2
  MaxSize: 6

Weekend:
  Schedule: "0 0 * * SAT"
  MinSize: 1
  DesiredCapacity: 1
  MaxSize: 4
```

### Health Check Strategy
```yaml
HealthCheckType: EC2  # Until ELB available
HealthCheckGracePeriod: 300
DefaultCooldown: 300

Instance Warmup:
  Web Tier: 180 seconds
  App Tier: 300 seconds
```

## Implementation Timeline

### Phase 1: Basic Auto Scaling (Day 1)
- [x] Create Auto Scaling groups
- [x] Configure target tracking
- [x] Set capacity limits
- [x] Test basic scaling

### Phase 2: Advanced Policies (Day 2)
- [x] Add step scaling policies
- [x] Configure scheduled actions
- [x] Set up notifications
- [x] Test policy interactions

### Phase 3: Optimization (Week 2)
- [x] Load testing validation
- [x] Threshold tuning
- [x] Cost analysis
- [ ] Production deployment

### Phase 4: Monitoring (Ongoing)
- [ ] Scaling pattern analysis
- [ ] Cost optimization
- [ ] Policy refinement
- [ ] Capacity planning

**Total Implementation Time:** 2 weeks (completed core in 3 hours during lab)

## Related Implementation
This decision was implemented in [Lab 3: EC2 & Auto Scaling Platform](../../labs/lab-03-ec2/README.md), which includes:
- Auto Scaling group configuration
- Scaling policy implementation
- CloudWatch alarm setup
- Load testing procedures
- Monitoring dashboard creation

## Success Metrics
- **Scale-out speed**: < 5 minutes to handle 10x load ✅ (tested at 4 min)
- **Scale-in efficiency**: Return to baseline within 15 minutes ✅
- **Cost optimization**: 40% savings vs. peak provisioning ✅ (projected)
- **Availability**: Zero downtime during scaling ✅
- **Stability**: No scaling oscillation observed ✅

## Review Date
2025-09-13 (3 months) - Analyze scaling patterns and optimize

## References
- [AWS Auto Scaling User Guide](https://docs.aws.amazon.com/autoscaling/ec2/userguide/)
- [Target Tracking Scaling Policies](https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-scaling-target-tracking.html)
- [Predictive Scaling](https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-predictive-scaling.html)
- **Implementation**: [Lab 3: EC2 & Auto Scaling Platform](../../labs/lab-03-ec2/README.md)

## Appendix: Scaling Decision Matrix

| Traffic Change | Response Time | Policy Used | Instance Change |
|----------------|---------------|-------------|-----------------|
| Gradual +20% | 3-5 min | Target Tracking | +1 instance |
| Spike +100% | 2-3 min | Step Scaling | +2-4 instances |
| Daily pattern | Proactive | Scheduled | Per schedule |
| Gradual -30% | 10-15 min | Target Tracking | -1 instance |
| Off-hours | Scheduled | Scheduled | Minimum capacity |

### Scaling Math
```
Current: 2 instances at 70% CPU
Load doubles: 140% aggregate CPU needed
Target tracking: Scales to 3 instances (46% each)
Step scaling: May add 4th instance if >85%
Result: 3-4 instances handling double load
```

---

*This decision will be revisited if:*
- Traffic patterns stabilize allowing simplification
- New scaling metrics become available
- Cost optimization requirements change
- Application architecture changes significantly