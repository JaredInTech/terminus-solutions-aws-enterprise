## High CPU Alarm Response

### Immediate Actions (0-5 minutes)
1. Acknowledge alarm
2. Check Performance Insights
3. Identify top SQL queries
4. Check current connection count

### Investigation (5-15 minutes)
1. Review slow query log
2. Check for backup operations
3. Analyze wait events
4. Review recent deployments

### Mitigation Options
1. Kill long-running queries
2. Disable non-critical batch jobs
3. Scale read traffic to replicas
4. Emergency instance resize

### Post-Incident
1. Document root cause
2. Update monitoring thresholds
3. Implement query optimization
4. Plan capacity upgrade