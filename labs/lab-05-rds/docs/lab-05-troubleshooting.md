# Lab 5: RDS & Database Services - Troubleshooting Guide

This guide covers common issues encountered when setting up RDS instances, Multi-AZ deployments, read replicas, automated backups, and database connectivity for Terminus Solutions.

## Table of Contents
- [RDS Instance Creation Issues](#rds-instance-creation-issues)
- [Database Connectivity Problems](#database-connectivity-problems)
- [Multi-AZ Deployment Issues](#multi-az-deployment-issues)
- [Read Replica Problems](#read-replica-problems)
- [Backup and Restore Issues](#backup-and-restore-issues)
- [Performance and Scaling Problems](#performance-and-scaling-problems)
- [Parameter Group Issues](#parameter-group-issues)
- [Subnet Group Problems](#subnet-group-problems)
- [Security Group Configuration](#security-group-configuration)
- [Encryption and KMS Issues](#encryption-and-kms-issues)
- [Aurora Specific Issues](#aurora-specific-issues)
- [Monitoring and CloudWatch Problems](#monitoring-and-cloudwatch-problems)
- [Common Error Messages](#common-error-messages)
- [Best Practices for RDS Debugging](#best-practices-for-rds-debugging)

---

## RDS Instance Creation Issues

### Issue: "DB Subnet group doesn't meet availability zone coverage requirement"
**Symptoms**: Cannot create RDS instance, subnet group error.

**Common Causes**:
- Subnet group has subnets in only one AZ
- Subnets not in different AZs
- Invalid subnet selection

**Console Solutions**:
1. **Create proper DB subnet group**:
   - Navigate to **RDS Console** → **Subnet groups**
   - Click **Create DB subnet group**
   - Select VPC (e.g., Terminus-Production-VPC)
   - Add subnets from at least 2 different AZs
   - Choose private data subnets only

2. **Verify subnet configuration**:
   - Each subnet must be in a different AZ
   - Minimum 2 subnets required
   - Subnets should be private (no IGW route)

3. **Check subnet availability**:
   - Go to **VPC Console** → **Subnets**
   - Verify selected subnets are in different AZs
   - Ensure adequate free IPs (RDS needs several)

### Issue: "The specified DB Instance class is not available in the requested Availability Zone"
**Symptoms**: Instance class not supported in selected AZ.

**Console Solutions**:
1. **Check instance class availability**:
   - Try different instance class (e.g., db.t3.medium instead of db.t2.medium)
   - Let RDS choose AZ automatically
   - Check AWS documentation for AZ limitations

2. **Use Multi-AZ for flexibility**:
   - Enable Multi-AZ deployment
   - RDS automatically selects compatible AZs
   - Provides HA as bonus

3. **Try different subnet group**:
   - Create subnet group with different AZ combination
   - Some older instance types have limited AZ support

### Issue: RDS instance stuck in "creating" state for over 30 minutes
**Symptoms**: Instance creation not progressing.

**Console Debugging**:
1. **Check CloudTrail for errors**:
   - Go to **CloudTrail** → **Event history**
   - Filter by "RDS" service
   - Look for CreateDBInstance events with errors

2. **Verify KMS key permissions** (if encrypted):
   - Check KMS key policy allows RDS service
   - Key must be in same region
   - Add RDS service principal if missing

3. **Review VPC configuration**:
   - Ensure DNS hostnames enabled on VPC
   - Check DNS resolution is enabled
   - Verify DHCP options set correctly

---

## Database Connectivity Problems

### Issue: Cannot connect to RDS instance from EC2
**Symptoms**: Connection timeout or refused when trying to connect.

**Console Solutions**:
1. **Verify endpoint and port**:
   - Go to **RDS Console** → Select instance
   - Copy endpoint from **Connectivity & security** tab
   - Note port number (3306 for MySQL, 5432 for PostgreSQL)
   - Test: `telnet endpoint-address port`

2. **Check security group rules**:
   - Click on VPC security groups in instance details
   - Verify inbound rule exists for database port
   - Source should be app server security group or CIDR
   - Common mistake: Using wrong port number

3. **Test from correct subnet**:
   - RDS in private subnet not accessible from internet
   - Test from EC2 instance in same VPC
   - Use Session Manager to access EC2 instance

4. **Verify network ACLs**:
   - Check subnet's network ACL
   - Ensure database port allowed
   - Remember ACLs are stateless (need return traffic rules)

### Issue: "Unknown MySQL server host" error
**Symptoms**: DNS resolution failing for RDS endpoint.

**Console Solutions**:
1. **Enable VPC DNS settings**:
   - Go to **VPC Console** → Select VPC
   - Actions → Edit DNS settings
   - Enable both DNS resolution and DNS hostnames
   - Changes take effect immediately

2. **Use IP address temporarily**:
   - Run `nslookup your-rds-endpoint.region.rds.amazonaws.com`
   - Use returned IP for testing
   - Note: IP may change during failover

3. **Check Route 53 private zones**:
   - If using custom DNS, verify configuration
   - Ensure RDS endpoint can be resolved
   - May need to add RDS DNS zones

### Issue: Authentication failures despite correct password
**Symptoms**: Access denied errors with correct credentials.

**Console Solutions**:
1. **Reset master password**:
   - Select RDS instance → **Modify**
   - Enter new master password
   - Apply immediately
   - Wait for instance to show "Available"

2. **Check from parameter group**:
   - Some parameters affect authentication
   - Review custom parameter group settings
   - Compare with default parameter group

3. **Verify username format**:
   - RDS doesn't use 'root', uses 'admin' or custom
   - Check exact username created with instance
   - Case sensitive on some engines

---

## Multi-AZ Deployment Issues

### Issue: Failover not working as expected
**Symptoms**: Database unavailable during maintenance or AZ failure.

**Console Solutions**:
1. **Verify Multi-AZ is enabled**:
   - Check instance details → **Configuration** tab
   - Look for "Multi-AZ: Yes"
   - If no, modify instance to enable

2. **Test failover manually**:
   - Select instance → **Actions** → **Reboot**
   - Check "Reboot with failover"
   - Monitor failover time (usually 1-2 minutes)
   - Check CloudWatch for failover events

3. **Review application connection settings**:
   - Use RDS endpoint (not IP address)
   - Implement connection retry logic
   - Set appropriate timeout values

### Issue: Performance degradation after Multi-AZ conversion
**Symptoms**: Slower writes after enabling Multi-AZ.

**Console Solutions**:
1. **Understand synchronous replication**:
   - Multi-AZ uses synchronous replication
   - Writes must complete on both instances
   - Small latency increase is normal

2. **Check CloudWatch metrics**:
   - Monitor WriteLatency metric
   - Compare before/after Multi-AZ
   - Look for network issues between AZs

3. **Optimize for Multi-AZ**:
   - Batch writes when possible
   - Use connection pooling
   - Consider Aurora for better Multi-AZ performance

---

## Read Replica Problems

### Issue: Read replica creation fails
**Symptoms**: "Read Replica Source Not Available" or creation fails.

**Console Solutions**:
1. **Enable automated backups first**:
   - Select source instance → **Modify**
   - Set backup retention period > 0
   - Apply changes
   - Wait for backup to complete

2. **Check source instance status**:
   - Must be "Available" state
   - No pending modifications
   - Not in backup window

3. **Verify region compatibility**:
   - For cross-region replicas, check region support
   - Some instance types not available everywhere
   - May need different instance class in target region

### Issue: Read replica lag increasing
**Symptoms**: Replica falling behind master, high lag values.

**Console Solutions**:
1. **Monitor lag metric**:
   - Check CloudWatch → ReplicaLag metric
   - Normal lag: few seconds
   - Problem if consistently increasing

2. **Check replica instance size**:
   - Replica should be same size or larger than master
   - Upgrade replica instance if undersized
   - Heavy writes need powerful replica

3. **Review workload**:
   - Large batch updates cause lag
   - Consider scaling writes over time
   - May need multiple read replicas

### Issue: Cannot promote read replica
**Symptoms**: Promote option grayed out or fails.

**Console Solutions**:
1. **Check replica status**:
   - Must be "Available" state
   - Replication must be active
   - No backup operations running

2. **Resolve replication errors**:
   - Check CloudWatch logs for errors
   - May need to recreate replica
   - Fix any data inconsistencies

3. **Understand promotion impact**:
   - Promotion breaks replication permanently
   - Cannot undo promotion
   - Other replicas unaffected

---

## Backup and Restore Issues

### Issue: Automated backups not running
**Symptoms**: No backup snapshots being created automatically.

**Console Solutions**:
1. **Check backup configuration**:
   - Select instance → **Maintenance & backups** tab
   - Verify retention period > 0
   - Check backup window timing
   - Ensure not disabled during creation

2. **Review backup window conflicts**:
   - Backup window shouldn't overlap maintenance window
   - Check for long-running transactions during backup
   - May need to adjust backup window

3. **Verify S3 permissions** (for exports):
   - RDS needs access to S3 bucket
   - Check bucket policy and IAM roles
   - Encryption keys must be accessible

### Issue: Cannot restore from snapshot
**Symptoms**: Restore fails or option unavailable.

**Console Solutions**:
1. **Check snapshot status**:
   - Go to **Snapshots** in RDS console
   - Status must be "Available"
   - Cannot use "Creating" snapshots

2. **Verify restore parameters**:
   - Some parameters cannot change during restore
   - Must restore to same or newer engine version
   - Check parameter group compatibility

3. **Understand restore limitations**:
   - Creates new instance (new endpoint)
   - Cannot restore to existing instance
   - Must update application connection strings

### Issue: Point-in-time restore not available
**Symptoms**: Cannot select desired restore time.

**Console Solutions**:
1. **Check backup retention**:
   - PITR only within retention period
   - Default is 7 days
   - Can extend up to 35 days

2. **Verify automated backups enabled**:
   - PITR requires automated backups
   - Not available with manual snapshots only
   - Check instance backup configuration

3. **Review RestorableTime window**:
   - Check earliest and latest restorable times
   - Shown in instance details
   - Cannot restore to future time

---

## Performance and Scaling Problems

### Issue: Database running out of storage space
**Symptoms**: Storage space alerts, write failures.

**Console Solutions**:
1. **Enable storage autoscaling**:
   - Select instance → **Modify**
   - Check "Enable storage autoscaling"
   - Set maximum storage limit
   - Applies without downtime

2. **Manually increase storage**:
   - Modify instance → Increase allocated storage
   - Can only increase (not decrease)
   - One increase per 6 hours limit

3. **Check storage metrics**:
   - CloudWatch → FreeStorageSpace metric
   - Set up alarms for proactive monitoring
   - Review what's consuming space

### Issue: High CPU/Memory utilization
**Symptoms**: Slow queries, connection timeouts.

**Console Solutions**:
1. **Scale up instance**:
   - Select instance → **Modify**
   - Choose larger instance class
   - Apply immediately or during maintenance
   - Monitor metrics after change

2. **Enable Performance Insights**:
   - Provides detailed performance metrics
   - Shows top SQL queries
   - Identifies wait events
   - Free for 7 days retention

3. **Review slow query logs**:
   - Enable in parameter group
   - Download logs from console
   - Identify problematic queries
   - May need query optimization

---

## Parameter Group Issues

### Issue: Parameter changes not taking effect
**Symptoms**: Changed parameters but behavior unchanged.

**Console Solutions**:
1. **Check parameter apply method**:
   - Some parameters require reboot
   - Look for "Pending reboot" status
   - Static parameters need restart

2. **Verify parameter group association**:
   - Check instance uses correct parameter group
   - Not using default parameter group
   - May need to modify instance

3. **Reboot if required**:
   - Select instance → **Actions** → **Reboot**
   - Check "Reboot with failover" for Multi-AZ
   - Monitor for parameter application

### Issue: Cannot modify default parameter group
**Symptoms**: Edit options disabled for parameter group.

**Console Solutions**:
1. **Create custom parameter group**:
   - **Parameter groups** → **Create parameter group**
   - Select same family as instance
   - Copy settings from default
   - Modify as needed

2. **Associate with instance**:
   - Select instance → **Modify**
   - Change parameter group
   - Apply changes
   - May require reboot

---

## Subnet Group Problems

### Issue: Cannot delete subnet group
**Symptoms**: "Subnet group is in use" error.

**Console Solutions**:
1. **Check for instances using it**:
   - List all RDS instances
   - Check subnet group for each
   - Must remove all associations

2. **Check for deleted instances**:
   - Recently deleted instances may hold reference
   - Wait 5-10 minutes and retry
   - Check automated backups

3. **Use different subnet group**:
   - Create new subnet group
   - Modify instances to use new group
   - Then delete old group

---

## Security Group Configuration

### Issue: Security group changes not working
**Symptoms**: Updated rules but connections still blocked.

**Console Solutions**:
1. **Check correct security group**:
   - RDS instance may have multiple SGs
   - Verify modifying correct one
   - Changes are immediate

2. **Source security group references**:
   - When using SG as source, must be same VPC
   - Cross-VPC SG references don't work
   - Use CIDR blocks for peered VPCs

3. **Check application security group**:
   - Source (app) SG needs outbound rules
   - Target (RDS) SG needs inbound rules
   - Both directions must allow traffic

---

## Encryption and KMS Issues

### Issue: Cannot enable encryption on existing instance
**Symptoms**: Encryption option grayed out.

**Console Solutions**:
1. **Create encrypted snapshot**:
   - Create snapshot of unencrypted instance
   - Copy snapshot with encryption enabled
   - Restore from encrypted snapshot

2. **Choose KMS key**:
   - Can use AWS managed or customer managed
   - Customer managed allows key rotation control
   - Key must be in same region

3. **Understand encryption limitations**:
   - Cannot disable encryption once enabled
   - All snapshots inherit encryption
   - Read replicas must use same key

### Issue: KMS key access denied
**Symptoms**: Cannot create encrypted instance or access encrypted snapshots.

**Console Solutions**:
1. **Check key policy**:
   - Go to **KMS Console** → Select key
   - Key policy must allow RDS service
   - Add RDS service principal if missing

2. **Verify key region**:
   - KMS keys are region-specific
   - Must be in same region as RDS
   - For cross-region replicas, need key in each region

3. **Grant IAM permissions**:
   - User/role needs KMS permissions
   - Add kms:Decrypt, kms:GenerateDataKey
   - Check both IAM and key policies

---

## Aurora Specific Issues

### Issue: Aurora cluster endpoint not distributing reads
**Symptoms**: All reads going to single instance.

**Console Solutions**:
1. **Use reader endpoint**:
   - Cluster has multiple endpoints
   - Writer endpoint: For writes only
   - Reader endpoint: Load balances reads
   - Instance endpoints: Direct connection

2. **Check reader instances**:
   - Ensure multiple reader instances exist
   - All must be "Available" state
   - Check instance class compatibility

3. **Review connection pooling**:
   - Aurora uses DNS for load balancing
   - Short DNS TTL (1 second)
   - Connection pools may cache DNS

### Issue: Aurora Serverless not scaling
**Symptoms**: Capacity not adjusting to load.

**Console Solutions**:
1. **Check scaling configuration**:
   - Review min/max capacity units
   - Check scaling conditions
   - May need wider capacity range

2. **Monitor scaling metrics**:
   - CloudWatch shows scaling events
   - Check ServerlessDatabaseCapacity metric
   - Look for scaling timeout events

3. **Understand scaling limitations**:
   - Cannot scale during long transactions
   - DDL operations prevent scaling
   - May need to force capacity change

---

## Monitoring and CloudWatch Problems

### Issue: No CloudWatch metrics appearing
**Symptoms**: Metrics missing or delayed.

**Console Solutions**:
1. **Check Enhanced Monitoring**:
   - Not enabled by default
   - Select instance → **Modify**
   - Enable Enhanced Monitoring
   - Choose granularity (1-60 seconds)

2. **Verify IAM role**:
   - Enhanced Monitoring needs IAM role
   - RDS can create automatically
   - Or select existing role

3. **Wait for metrics**:
   - Basic metrics: 1-minute delay
   - Enhanced metrics: Based on granularity
   - New instances: Up to 15 minutes for first metrics

---

## Common Error Messages

### "The DB instance and EC2 security group are in different VPCs"
**Console Solution**: 
1. Verify RDS and EC2 in same VPC
2. Security group must be from same VPC
3. Cannot reference cross-VPC security groups
4. Use CIDR blocks for different VPCs

### "Cannot find version x.x for aurora-mysql"
**Console Fix**: 
1. Check supported Aurora versions in region
2. Some versions deprecated
3. Use "compatible with MySQL x.x" format
4. Let RDS choose compatible version

### "DB Security Groups can only be associated with VPC DB Instances using API version 2012-01-15 through 2012-09-17"
**Console Solutions**:
1. Use VPC security groups (not DB security groups)
2. DB security groups are legacy (EC2-Classic)
3. Create new VPC security group
4. Associate with RDS instance

### "The parameter group x is in use and can't be deleted"
**Console Debugging**:
1. Check all RDS instances for parameter group usage
2. Include deleted instances (retained backups)
3. Modify instances to use different parameter group
4. Wait for backups to expire or delete manually

### "Incompatible network info: The specified DB subnet group and EC2 instance are in different VPCs"
**Console Fix**:
1. Verify subnet group VPC matches instance VPC
2. Create new subnet group in correct VPC
3. Cannot move existing RDS to different VPC
4. Must snapshot and restore to new VPC

---

## Best Practices for RDS Debugging

### 1. Use CloudWatch Logs
**Console Access**:
- **RDS Console** → Select instance
- **Logs & events** tab
- Download or view in CloudWatch
- Enable slow query logs for performance

### 2. Enable Performance Insights
**Console Steps**:
- Free tier available (7 days retention)
- Shows database load and top SQL
- Identifies bottlenecks quickly
- Enable during instance creation or modify

### 3. Test with RDS Proxy
**For Connection Issues**:
- Manages connection pooling
- Reduces connection overhead
- Improves failover time
- Good for Lambda connections

### 4. Create Manual Snapshots Before Changes
**Quick Backup**:
- Select instance → **Actions** → **Take snapshot**
- Name with date and change description
- Can quickly restore if issues
- Delete old snapshots to save costs

### 5. Use Read Replicas for Testing
**Safe Testing**:
- Create read replica for experiments
- Test queries without affecting production
- Can promote if successful
- Delete if not needed

---

## Quick Console Navigation Tips

### RDS Dashboard Customization
- Pin frequently used instances
- Create custom CloudWatch dashboard
- Set up SNS notifications
- Use tags for organization

### Useful Filters
- **Engine**: MySQL, PostgreSQL, Aurora
- **Status**: Available, Creating, Modifying
- **VPC**: Filter by specific VPC
- **Tag filters**: Environment=Production

### Bulk Operations
- Select multiple instances for tagging
- Apply same modifications to multiple instances
- Bulk snapshot operations
- Group by cluster for Aurora

### Cost Management Views
- **Reserved Instances**: Utilization report
- **Snapshot storage**: Identify old snapshots
- **Cross-region replicas**: Data transfer costs
- **Storage autoscaling**: Growth trends

---

## When to Contact AWS Support

Contact support if:
- RDS instance stuck in "Incompatible-network" state over 1 hour
- Automated backups failing consistently with no clear error
- Multi-AZ failover taking longer than 5 minutes repeatedly
- Parameter group changes not applying after multiple reboots
- Aurora cluster showing split-brain symptoms

**Before contacting support**:
1. Document all error messages with timestamps
2. Export recent CloudWatch metrics
3. Save CloudTrail events for RDS API calls
4. List all troubleshooting steps attempted
5. Gather instance identifiers, subnet groups, and parameter groups