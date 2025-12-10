# Lab 3: EC2 & Auto Scaling Platform - Troubleshooting Guide

This guide covers common issues encountered when setting up EC2 instances, Auto Scaling Groups, Launch Templates, AMIs, and instance profiles for Terminus Solutions.

## Table of Contents
- [EC2 Instance Launch Issues](#ec2-instance-launch-issues)
- [Instance Profile and IAM Role Problems](#instance-profile-and-iam-role-problems)
- [AMI Creation and Management Issues](#ami-creation-and-management-issues)
- [Launch Template Problems](#launch-template-problems)
- [Auto Scaling Group Issues](#auto-scaling-group-issues)
- [Scaling Policy Problems](#scaling-policy-problems)
- [Health Check Failures](#health-check-failures)
- [CloudWatch Agent Issues](#cloudwatch-agent-issues)
- [Systems Manager Problems](#systems-manager-problems)
- [Storage and EBS Issues](#storage-and-ebs-issues)
- [Placement Group Problems](#placement-group-problems)
- [Instance Metadata Service Issues](#instance-metadata-service-issues)
- [Common Error Messages](#common-error-messages)
- [Best Practices for EC2 Debugging](#best-practices-for-ec2-debugging)

---

## EC2 Instance Launch Issues

### Issue: "Failed to start instances: Invalid value for parameter"
**Symptoms**: Instance fails to launch with parameter errors.

**Common Causes**:
- Instance type not available in selected AZ
- AMI not available in region
- Incompatible instance type and AMI architecture

**Console Solutions**:
1. **Check instance type availability**:
   - Navigate to **EC2 Console** → **Instance Types**
   - Search for your instance type (e.g., t3.medium)
   - Click on instance type → **Availability Zones** tab
   - Verify it's available in your target AZ

2. **Verify AMI compatibility**:
   - Go to **Images** → **AMIs**
   - Select your AMI
   - Check "Architecture" (x86_64 vs arm64)
   - Ensure instance type matches architecture

3. **Try different AZ**:
   - In launch wizard, expand **Network settings**
   - Try different subnet in another AZ
   - Some instance types have limited AZ availability

### Issue: "Instance limit exceeded for instance type"
**Symptoms**: Cannot launch more instances of specific type.

**Console Solutions**:
1. **Check current limits**:
   - Go to **EC2 Console** → **Limits** (left sidebar)
   - Search for your instance type
   - View "Current limit" vs "Current usage"

2. **Request limit increase**:
   - Click **Request limit increase**
   - Select instance type
   - Specify new limit and region
   - Provide business justification

3. **Use different instance type**:
   - Check limits for similar types
   - t3.medium → t3a.medium (AMD variant)
   - Consider burstable vs fixed performance

### Issue: Instance stuck in "pending" state
**Symptoms**: Instance doesn't transition to "running" after 5+ minutes.

**Console Debugging**:
1. **Check system status checks**:
   - Select instance → **Status checks** tab
   - Look for specific failure messages
   - Click **Actions** → **Monitor and troubleshoot** → **Get system log**

2. **Review user data script**:
   - Select instance → **Actions** → **Instance settings** → **Edit user data**
   - Check for syntax errors or hanging commands
   - Add error handling and logging

3. **Verify security group allows outbound**:
   - Some user data scripts need internet access
   - Check security group has outbound rules
   - Especially important for package downloads

---

## Instance Profile and IAM Role Problems

### Issue: "Unable to assign IAM role to instance"
**Symptoms**: Cannot attach instance profile during launch or after.

**Console Solutions**:
1. **Verify instance profile exists**:
   - Go to **IAM Console** → **Roles**
   - Search for your role (e.g., TerminusEC2ServiceRole)
   - Click role → **Trust relationships** tab
   - Must include ec2.amazonaws.com

2. **Check trust policy**:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [{
       "Effect": "Allow",
       "Principal": {
         "Service": "ec2.amazonaws.com"
       },
       "Action": "sts:AssumeRole"
     }]
   }
   ```

3. **Create instance profile if missing**:
   - In IAM Console → **Roles**
   - Select role → **Add permissions** → **Create inline policy**
   - After creating role, instance profile auto-creates
   - May take 1-2 minutes to propagate

### Issue: "Access Denied" when accessing AWS services from EC2
**Symptoms**: Instance cannot access S3, CloudWatch, etc. despite role attached.

**Console Debugging**:
1. **Verify role attachment**:
   - Select instance → **Security** tab
   - Check "IAM role" field is populated
   - Click role name to view permissions

2. **Check role permissions**:
   - In IAM Console, select the role
   - Review attached policies
   - Use **Policy simulator** to test specific actions

3. **Test from instance**:
   - Connect via Session Manager
   - Run: `aws sts get-caller-identity`
   - Should show role ARN, not instance ID
   - Run: `curl http://169.254.169.254/latest/meta-data/iam/security-credentials/`

4. **Common permission issues**:
   - S3: Missing bucket permissions (not just object)
   - CloudWatch: Need both PutMetricData and CreateLogGroup
   - Secrets Manager: Need both GetSecretValue and DescribeSecret

### Issue: Instance profile not appearing in EC2 launch wizard
**Symptoms**: IAM role exists but not selectable during instance launch.

**Console Solutions**:
1. **Wait for propagation**:
   - New instance profiles take 1-2 minutes
   - Refresh browser page
   - Try incognito/private browsing mode

2. **Check role naming**:
   - Instance profile name must match role name
   - Go to IAM → Roles → select role
   - Note the "Instance profile ARN"

3. **Manual attachment**:
   - Launch instance without role
   - After running: Actions → Security → Modify IAM role
   - Select role from dropdown

---

## AMI Creation and Management Issues

### Issue: AMI creation taking extremely long (>1 hour)
**Symptoms**: AMI creation stuck at 0% or progressing very slowly.

**Console Solutions**:
1. **Check snapshot progress**:
   - Go to **EC2 Console** → **Snapshots**
   - Filter by "Started" in last hour
   - Check progress percentage
   - Large root volumes take longer

2. **Reduce AMI size**:
   - Stop instance before creating AMI
   - Clean unnecessary files:
     ```bash
     sudo apt-get clean
     sudo rm -rf /var/log/*
     sudo rm -rf /tmp/*
     ```
   - Consider excluding data volumes

3. **Use incremental approach**:
   - Create base AMI with OS only
   - Create new AMI after each major change
   - Snapshots are incremental (faster)

### Issue: "AMI not found" when launching from custom AMI
**Symptoms**: Custom AMI disappears or cannot be selected.

**Console Checks**:
1. **Verify correct region**:
   - AMIs are region-specific
   - Check region selector (top-right)
   - Copy AMI to other regions if needed

2. **Check AMI permissions**:
   - Go to **AMIs** → Select AMI
   - **Permissions** tab
   - Ensure account has access
   - For cross-account: Add account ID

3. **AMI state verification**:
   - AMI must be "available" not "pending"
   - Check for "deprecated" or "deregistered"
   - Deregistered AMIs cannot be used

### Issue: Instances from AMI missing expected software
**Symptoms**: Software installed before AMI creation not present on new instances.

**Console Solutions**:
1. **Verify AMI contents**:
   - Launch test instance from AMI
   - Connect and check installed software
   - Some software tied to instance ID may fail

2. **Check user data execution**:
   - Select instance → **Actions** → **Monitor and troubleshoot** → **Get system log**
   - Look for user data script output
   - Cloud-init logs: `/var/log/cloud-init-output.log`

3. **Common AMI creation mistakes**:
   - Not stopping instance first (file consistency)
   - Including instance-specific data
   - Hardcoded IPs or hostnames
   - Temporary credentials in files

---

## Launch Template Problems

### Issue: "Invalid launch template" error
**Symptoms**: Cannot create or use launch template.

**Console Solutions**:
1. **Review template settings**:
   - Go to **EC2 Console** → **Launch Templates**
   - Select template → **Details** tab
   - Check for missing required fields
   - Common: subnet ID, security group

2. **Version management**:
   - Click **Versions** tab
   - Set default version explicitly
   - Delete failed versions
   - Maximum 1000 versions per template

3. **Parameter conflicts**:
   - Instance type must support features:
     - EBS optimization
     - Enhanced networking
     - Placement groups
   - Remove incompatible options

### Issue: Launch template changes not taking effect
**Symptoms**: ASG launches instances with old configuration.

**Console Solutions**:
1. **Check ASG template version**:
   - Go to **Auto Scaling Groups**
   - Select ASG → **Details** tab
   - Check "Launch template version"
   - Often set to specific version, not $Latest

2. **Update ASG configuration**:
   - Select ASG → **Edit**
   - Change version to $Latest or new version
   - Save changes

3. **Instance refresh**:
   - Select ASG → **Instance refresh** tab
   - Start instance refresh
   - Set minimum healthy percentage
   - Monitors automatic replacement

### Issue: Cannot modify launch template
**Symptoms**: Edit button grayed out or changes fail.

**Console Solutions**:
1. **Create new version**:
   - Cannot modify existing versions
   - Select template → **Actions** → **Create new version**
   - Make changes in new version
   - Set as default version

2. **Copy and modify**:
   - Actions → **Copy launch template**
   - New template with changes
   - Update ASG to use new template

---

## Auto Scaling Group Issues

### Issue: ASG not launching any instances
**Symptoms**: Desired capacity set but no instances launching.

**Console Debugging**:
1. **Check Activity History**:
   - Select ASG → **Activity** tab
   - Look for failed launches
   - Expand details for specific errors
   - Common: "Could not launch instances"

2. **Verify capacity settings**:
   - **Details** tab → **Group details**
   - Check Min, Desired, Max capacity
   - Desired must be ≥ Min and ≤ Max

3. **Subnet availability**:
   - **Network** section
   - Verify at least one subnet selected
   - Check subnets exist and have IPs
   - Try adding more subnets/AZs

4. **Service-linked role**:
   - ASG needs AWSServiceRoleForAutoScaling
   - Usually created automatically
   - IAM → Roles → Search for it
   - Create manually if missing

### Issue: ASG repeatedly terminates and launches instances
**Symptoms**: Instance cycling, never stabilizes.

**Console Analysis**:
1. **Check health check settings**:
   - Select ASG → **Details** tab
   - Note "Health check type" (EC2 vs ELB)
   - Check "Health check grace period"
   - Increase grace period for slow-starting apps

2. **Review scaling policies**:
   - **Automatic scaling** tab
   - Look for conflicting policies
   - Check "Cooldown" periods
   - Disable policies temporarily to test

3. **Instance logs**:
   - Select terminated instance ID from Activity
   - Even terminated instances keep logs briefly
   - Actions → Monitor and troubleshoot → Get system log

### Issue: ASG not respecting availability zones
**Symptoms**: All instances launching in single AZ.

**Console Solutions**:
1. **Check AZ configuration**:
   - Select ASG → **Network** section
   - Verify multiple subnets selected
   - Each subnet should be different AZ

2. **Review AZ capacity**:
   - Some instance types limited in certain AZs
   - Try different instance type
   - Or remove problematic AZ

3. **Capacity Rebalancing**:
   - Edit ASG → Advanced options
   - Enable "Capacity Rebalancing"
   - Helps maintain AZ balance

---

## Scaling Policy Problems

### Issue: Auto Scaling not triggering despite high CPU
**Symptoms**: CPU above threshold but no scale-out activity.

**Console Debugging**:
1. **Verify CloudWatch alarm**:
   - Go to **CloudWatch Console** → **Alarms**
   - Find alarm for your ASG
   - Check state (OK/ALARM/INSUFFICIENT_DATA)
   - Click alarm for detailed graph

2. **Check alarm configuration**:
   - Period and evaluation periods
   - Example: 5 minutes × 2 periods = 10 minutes before trigger
   - Statistic (Average vs Maximum)
   - Missing data treatment

3. **ASG cooldown interference**:
   - Select ASG → **Details** → **Advanced**
   - Note "Default cooldown" (seconds)
   - During cooldown, no scaling activities
   - Target tracking policies ignore cooldown

4. **Scaling policy conflicts**:
   - Multiple policies can interfere
   - Target tracking + Simple scaling = conflicts
   - Disable other policies to test

### Issue: Scale-in happening too aggressively
**Symptoms**: Instances terminated too quickly after load decreases.

**Console Solutions**:
1. **Adjust scale-in protection**:
   - Select ASG → **Automatic scaling** tab
   - Edit target tracking policy
   - Check "Disable scale-in"
   - Or increase "Scale-in cooldown"

2. **Instance protection**:
   - Select instances → **Actions** → **Instance settings**
   - **Set scale-in protection**
   - Prevents termination by scale-in

3. **Termination policy**:
   - Edit ASG → **Advanced options**
   - Change termination policy
   - OldestInstance vs NewestInstance
   - Consider OldestLaunchTemplate

### Issue: Scheduled scaling not working
**Symptoms**: Instances not scaling at scheduled times.

**Console Solutions**:
1. **Check schedule configuration**:
   - Select ASG → **Automatic scaling** → **Scheduled actions**
   - Verify timezone (UTC by default)
   - Check recurrence expression
   - Start time must be in future

2. **Capacity conflicts**:
   - Scheduled action capacity must be within Min/Max
   - Other policies may override
   - Set specific Min/Max in scheduled action

3. **CloudWatch Events**:
   - Go to **CloudWatch** → **Events** → **Rules**
   - Look for ASG scheduled rules
   - Check execution history

---

## Health Check Failures

### Issue: Instances failing ELB health checks
**Symptoms**: Instances marked unhealthy and terminated by ASG.

**Console Debugging**:
1. **Test health check manually**:
   - Find instance public/private IP
   - From another instance: `curl http://IP:port/health`
   - Check response code and time
   - Must return 200 within timeout

2. **Adjust health check settings**:
   - Go to **EC2** → **Target Groups** (if using ALB)
   - **Health checks** tab → **Edit**
   - Increase timeout and interval
   - Reduce healthy/unhealthy thresholds

3. **Security group rules**:
   - Instance security group must allow health check
   - Source: Load balancer security group
   - Port: Application port
   - Common mistake: Only allowing port 80, not 8080

### Issue: EC2 health checks passing but application not ready
**Symptoms**: Instances marked healthy but application returns errors.

**Console Solutions**:
1. **Switch to ELB health checks**:
   - Edit ASG → **Health checks**
   - Change type from EC2 to ELB
   - Add grace period for app startup

2. **Create custom health check**:
   - Implement `/health` endpoint
   - Check all dependencies:
     - Database connectivity
     - Required services
     - Configuration loaded

3. **Use lifecycle hooks**:
   - Edit ASG → **Advanced options**
   - Add lifecycle hook for launching
   - Complete hook only when app ready
   - Prevents premature traffic

---

## CloudWatch Agent Issues

### Issue: No metrics appearing from CloudWatch Agent
**Symptoms**: Custom metrics and logs not appearing in CloudWatch.

**Console Solutions**:
1. **Verify agent installation**:
   - Connect to instance via Session Manager
   - Check agent status:
     ```bash
     sudo systemctl status amazon-cloudwatch-agent
     ```

2. **Check agent configuration**:
   - Review config file:
     ```bash
     sudo cat /opt/aws/amazon-cloudwatch-agent/etc/config.json
     ```
   - Validate JSON syntax
   - Ensure correct region specified

3. **IAM permissions**:
   - Instance role needs:
     - CloudWatchAgentServerPolicy
     - Or custom policy with PutMetricData
   - Test: `aws cloudwatch put-metric-data --namespace Test --metric-name Test --value 1`

4. **Restart agent**:
   - After config changes:
     ```bash
     sudo systemctl restart amazon-cloudwatch-agent
     ```

### Issue: CloudWatch Logs not receiving application logs
**Symptoms**: Log groups empty or missing log streams.

**Console Solutions**:
1. **Verify log group exists**:
   - Go to **CloudWatch** → **Log groups**
   - Create if missing
   - Note exact name (case-sensitive)

2. **Check agent configuration**:
   - Log file path must be absolute
   - Ensure app writes to specified path
   - Check file permissions (agent must read)

3. **Common configuration issues**:
   ```json
   {
     "logs": {
       "logs_collected": {
         "files": {
           "collect_list": [{
             "file_path": "/var/log/app/*.log",
             "log_group_name": "/aws/ec2/app",
             "log_stream_name": "{instance_id}"
           }]
         }
       }
     }
   }
   ```

---

## Systems Manager Problems

### Issue: Cannot connect via Session Manager
**Symptoms**: "Unable to start session" error.

**Console Solutions**:
1. **Verify SSM agent**:
   - Most recent AMIs include it
   - For custom AMIs, install manually
   - Must be running: `sudo systemctl status amazon-ssm-agent`

2. **Check instance profile**:
   - Needs AmazonSSMManagedInstanceCore policy
   - Or custom policy with ssm:* permissions
   - Also needs ssmmessages:* for Session Manager

3. **VPC endpoints (for private subnets)**:
   - Create VPC endpoints for:
     - com.amazonaws.region.ssm
     - com.amazonaws.region.ssmmessages
     - com.amazonaws.region.ec2messages
   - Associate with private subnet route tables

4. **Systems Manager activation**:
   - Go to **Systems Manager** → **Fleet Manager**
   - Instance should appear within 5 minutes
   - If not, check CloudWatch Logs for SSM agent

### Issue: Patch Manager not working
**Symptoms**: Patches not installing during maintenance window.

**Console Solutions**:
1. **Verify maintenance window**:
   - **Systems Manager** → **Maintenance Windows**
   - Check schedule and duration
   - Ensure targets include your instances

2. **Check patch baseline**:
   - **Patch Manager** → **Patch baselines**
   - Verify OS version matches
   - Check approval rules

3. **IAM permissions**:
   - Instance needs S3 access for patch repository
   - Add AmazonSSMPatchAssociation policy
   - Check CloudWatch Logs for errors

---

## Storage and EBS Issues

### Issue: EBS volumes not achieving expected IOPS
**Symptoms**: Application performance degraded, storage bottleneck.

**Console Solutions**:
1. **Verify volume configuration**:
   - Select instance → **Storage** tab
   - Click volume ID
   - Check type (gp3 vs gp2)
   - For gp3: Check provisioned IOPS

2. **Enable EBS optimization**:
   - Stop instance
   - Actions → Instance settings → Change instance type
   - Ensure "EBS optimized" is enabled
   - Not all instance types support it

3. **CloudWatch metrics**:
   - **CloudWatch** → **Metrics** → **EBS**
   - Check VolumeReadOps, VolumeWriteOps
   - Look for VolumeQueueLength > 1
   - BurstBalance for gp2 volumes

### Issue: Cannot create AMI - "Instance has multiple root devices"
**Symptoms**: AMI creation fails with device mapping errors.

**Console Solutions**:
1. **Check block device mapping**:
   - Select instance → **Storage** tab
   - Identify root device (typically /dev/xvda)
   - Only one device should be marked as root

2. **Create with specific devices**:
   - When creating AMI, click **Advanced**
   - Uncheck additional volumes if not needed
   - Or specify correct root device

### Issue: Snapshot creation very slow
**Symptoms**: EBS snapshots taking hours for small volumes.

**Console Solutions**:
1. **Check volume activity**:
   - High I/O during snapshot slows process
   - Consider stopping instance first
   - Or schedule during low activity

2. **Use snapshot lifecycle**:
   - **EC2** → **Lifecycle Manager**
   - Create policy for automated snapshots
   - Spreads load over time

3. **Monitor progress**:
   - **Snapshots** → Select snapshot
   - Check progress percentage
   - First snapshot always slower (full copy)

---

## Placement Group Problems

### Issue: "Insufficient capacity" when launching in placement group
**Symptoms**: Cannot launch instances in cluster placement group.

**Console Solutions**:
1. **Launch all at once**:
   - Cluster groups need simultaneous launch
   - Use ASG with immediate desired capacity
   - Or launch multiple via EC2 console

2. **Try different instance type**:
   - Some types have limited placement capacity
   - Use same instance family when possible
   - Avoid mixing instance generations

3. **Stop and restart**:
   - Stop all instances in group
   - Start all simultaneously
   - May relocate to area with capacity

### Issue: Not seeing expected network performance
**Symptoms**: Cluster placement group not improving network speed.

**Console Solutions**:
1. **Verify placement**:
   - Select instances → **Details**
   - Check "Placement group" field
   - All instances must be in same group

2. **Check instance features**:
   - Must support enhanced networking
   - Enable SR-IOV:
   - Actions → Instance settings → Change instance attribute
   - Check "Enhanced networking"

3. **Same AZ requirement**:
   - Cluster groups must be single AZ
   - Spread/Partition can span AZs
   - Check instance AZs match

---

## Instance Metadata Service Issues

### Issue: IMDSv2 403 errors
**Symptoms**: Metadata requests return 403 Forbidden.

**Console Solutions**:
1. **Check IMDS version**:
   - Select instance → **Details** → **Advanced details**
   - Look for "Metadata version"
   - If v2, requires token-based access

2. **Update application code**:
   ```bash
   # Get token first
   TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" \
     -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
   
   # Use token for requests
   curl -H "X-aws-ec2-metadata-token: $TOKEN" \
     http://169.254.169.254/latest/meta-data/
   ```

3. **Allow IMDSv1 temporarily**:
   - Stop instance
   - Actions → Instance settings → Modify instance metadata options
   - Change to "IMDSv1 and IMDSv2"
   - Update code then enforce v2

### Issue: Cannot access instance metadata at all
**Symptoms**: Timeouts reaching 169.254.169.254.

**Console Solutions**:
1. **Check metadata service enabled**:
   - Select instance → **Actions** → **Instance settings**
   - **Modify instance metadata options**
   - Ensure "Enabled" is selected

2. **Hop limit for containers**:
   - Default hop limit is 1
   - Containers need 2
   - Increase in metadata options

3. **Security group not blocking**:
   - Metadata service is local
   - But security groups can interfere
   - Don't explicitly block 169.254.0.0/16

---

## Common Error Messages

### "The instance configuration for this AWS Marketplace product is not supported"
**Console Solution**: 
1. Check Marketplace subscription active
2. Verify instance type allowed by product
3. Some products region-specific
4. Review product documentation for requirements

### "Invalid IamInstanceProfile"
**Console Fix**: 
1. Go to IAM → Roles
2. Ensure instance profile exists
3. Name must match role name
4. Wait 2 minutes for propagation
5. Try in different browser/incognito

### "InsufficientInstanceCapacity"
**Console Solutions**:
1. Try different AZ (change subnet)
2. Try different instance type in same family
3. Try at different time (capacity varies)
4. Consider Reserved Instances for guarantee

### "Instance terminates immediately"
**Console Debugging**:
1. Check **State transition reason**
2. Common: "User initiated shutdown"
3. Review user data for shutdown commands
4. Check for configuration management tools

### "Client.VolumeLimitExceeded"
**Console Fix**:
1. Check current EBS volumes count
2. Default limit varies by instance type
3. Detach unused volumes
4. Request limit increase if needed

---

## Best Practices for EC2 Debugging

### 1. Use Systems Manager Session Manager
**Console Access**:
- **Systems Manager** → **Session Manager**
- No SSH keys or bastion hosts needed
- Works with private instances
- Full audit trail in CloudTrail

### 2. Enable Detailed Monitoring During Testing
**Console Steps**:
- Launch instance → **Advanced details**
- Enable "Detailed CloudWatch monitoring"
- 1-minute metrics vs 5-minute
- Disable after debugging (costs more)

### 3. Use EC2 Serial Console
**For Boot Issues**:
- **EC2 Console** → Select instance
- **Actions** → **Monitor and troubleshoot** → **EC2 Serial Console**
- Must enable for account first
- See boot messages and kernel panics

### 4. Create AMI Before Major Changes
**Quick Backup**:
- Select instance → **Actions** → **Image and templates** → **Create image**
- Name with date/version
- Can quickly restore if needed
- Delete old AMIs to save costs

### 5. Use Tags for Everything
**Tagging Strategy**:
- Environment: Production/Development
- Owner: Team or individual
- Purpose: Web/App/Database
- Cost Center: For billing
- Auto Scaling Group: For grouped operations

---

## Quick Console Navigation Tips

### EC2 Dashboard Customization
- Click **Manage dashboard** (top right)
- Add widgets for common tasks
- Pin frequently used instance types
- Create custom CloudWatch dashboard

### Useful Filters and Views
- **Instance state**: running, stopped, terminated
- **Tag filters**: `tag:Environment=Production`
- **Instance type filter**: `instance-type=t3.*`
- Save filters with names for reuse

### Bulk Operations
- Select multiple instances with checkboxes
- Actions apply to all selected
- Use tags for larger scale operations
- CloudFormation for repeatable deployments

### Cost Management Views
- **Cost Explorer** integration
- Group by tags for department billing
- Reserved Instance utilization
- Spot Instance savings summary

---

## When to Contact AWS Support

Contact support if:
- Auto Scaling service-linked role won't create
- Placement group capacity issues persist across multiple attempts
- Instance profile appears in IAM but not EC2 console after 30 minutes
- CloudWatch Agent installation fails on supported AMI
- Seeing "Internal Error" messages consistently

**Before contacting support**:
1. Screenshot all error messages
2. Note exact timestamps
3. Export CloudTrail events for the time period
4. Document all troubleshooting steps tried
5. Gather instance IDs, AMI IDs, and other resource identifiers