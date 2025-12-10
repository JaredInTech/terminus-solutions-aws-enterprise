## Table of Contents

## Table of Contents

- [Pre-Testing Requirements](#-pre-testing-requirements)
- [IAM Instance Profile Testing](#-iam-instance-profile-testing)
- [AMI Validation Testing](#-ami-validation-testing)
- [Launch Template Testing](#-launch-template-testing)
- [Auto Scaling Group Testing](#-auto-scaling-group-testing)
- [Scaling Policy Testing](#-scaling-policy-testing)
- [CloudWatch Integration Testing](#-cloudwatch-integration-testing)
- [Security Validation](#-security-validation)
- [Performance Validation](#-performance-validation)
- [Final Validation Checklist](#-final-validation-checklist)

# Lab 3: EC2 & Auto Scaling Platform - Testing Checklist

This comprehensive checklist ensures all compute platform components are properly configured, secured, and performing as expected. Each test includes console-based validation steps.

## Pre-Testing Requirements
- [ ] Lab 2 VPC infrastructure is complete and validated
- [ ] IAM roles and instance profiles are created
- [ ] CloudWatch Log Groups are configured
- [ ] Test load generation tool is ready (Apache Bench or similar)

---

## 🔐 IAM Instance Profile Testing

### Instance Profile Functionality

#### 1. Verify Instance Profile Attachment
- [ ] **In EC2 Console:**
  - Navigate to **EC2 Console** → **Instances**
  - Select your test instance
  - Click **Security** tab
  - Verify "IAM role" shows `TerminusEC2ServiceRole`
  - Click the role name to view attached policies

- [ ] **Test via Session Manager:**
  - Go to **Systems Manager** → **Session Manager**
  - Click **Start session**
  - Select your instance and connect
  - Run command:
    ```bash
    aws sts get-caller-identity
    ```
  - ✅ Should return role ARN like: `arn:aws:sts::123456789012:assumed-role/TerminusEC2ServiceRole/i-xxxxx`

#### 2. Test S3 Access Permissions
- [ ] **From Session Manager session:**
  ```bash
  # List S3 buckets
  aws s3 ls
  
  # Test specific bucket access
  aws s3 ls s3://terminus-production-data/
  
  # Test write permissions
  echo "test" > test.txt
  aws s3 cp test.txt s3://terminus-production-data/test/
  ```
  - ✅ Should succeed without entering credentials

#### 3. Verify CloudWatch Permissions
- [ ] **Test metric publishing:**
  ```bash
  aws cloudwatch put-metric-data \
    --namespace "Terminus/Testing" \
    --metric-name "TestMetric" \
    --value 1 \
    --unit Count
  ```
- [ ] **Verify in Console:**
  - Go to **CloudWatch** → **Metrics** → **All metrics**
  - Look for "Terminus/Testing" namespace
  - ✅ TestMetric should appear within 1 minute

#### 4. Check Systems Manager Access
- [ ] **Verify instance registration:**
  - Go to **Systems Manager** → **Fleet Manager**
  - Your instance should appear in the list
  - Status should be "Online"
  - Click instance ID to view details

### Cross-Environment Isolation Testing
- [ ] **Test Production instance:**
  ```bash
  # Should fail - no access to dev bucket
  aws s3 ls s3://terminus-development-data/
  ```
  - ❌ Expected: Access Denied error

- [ ] **Check CloudTrail for verification:**
  - Go to **CloudTrail** → **Event history**
  - Filter by Resource type: "AWS::S3::Bucket"
  - Look for AccessDenied events
  - ✅ Confirms proper isolation

---

## 🖼️ AMI Validation Testing

### AMI Content Verification

#### 1. Launch Test Instances from AMIs
- [ ] **In EC2 Console:**
  - Click **Launch instances**
  - Choose **My AMIs** tab
  - Select `Terminus-Web-Server-AMI-v1.0`
  - Launch in test subnet with minimal config
  - Repeat for `Terminus-App-Server-AMI-v1.0`

- [ ] **Monitor launch progress:**
  - Go to **Instances** view
  - Check "Status check" column
  - ✅ Both should show "2/2 checks passed" within 2 minutes

#### 2. Verify Pre-installed Software
- [ ] **Connect via Session Manager to Web Server:**
  ```bash
  # Check web server
  sudo systemctl status apache2  # or httpd for Amazon Linux
  apache2 -v
  
  # Check PHP
  php -v
  php -m | grep -E "(mysqli|pdo_mysql)"
  
  # Check MySQL client
  mysql --version
  ```

- [ ] **Connect to Application Server:**
  ```bash
  # Check Java
  java -version
  which java
  
  # Check Python
  python3 --version
  pip3 list | grep -E "(flask|boto3)"
  
  # Check Node.js
  node --version
  npm --version
  ```

#### 3. Validate Agent Installations
- [ ] **Check CloudWatch Agent:**
  ```bash
  # Status check
  sudo systemctl status amazon-cloudwatch-agent
  
  # Configuration location
  sudo cat /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
  ```
  - ✅ Status should show "active (running)"

- [ ] **Check SSM Agent:**
  ```bash
  sudo systemctl status amazon-ssm-agent
  sudo systemctl is-enabled amazon-ssm-agent
  ```
  - ✅ Should be active and enabled

#### 4. Verify Custom Configurations
- [ ] **Test health check endpoint:**
  ```bash
  curl http://localhost/health
  # or
  curl http://localhost:8080/api/health
  ```
  - ✅ Should return JSON with status "ok"

### AMI Security Validation
- [ ] **Check for security issues:**
  ```bash
  # No SSH keys present
  sudo cat /home/ec2-user/.ssh/authorized_keys
  
  # Command history cleared
  history
  
  # No credentials in environment
  env | grep -E "(KEY|SECRET|PASSWORD)"
  
  # Temp files cleaned
  ls -la /tmp/
  ls -la /var/tmp/
  ```

---

## 🚀 Launch Template Testing

### Template Functionality Verification

#### 1. Test Template Versions
- [ ] **In EC2 Console:**
  - Go to **Launch Templates**
  - Select `Terminus-Web-Server-LT`
  - Click **Actions** → **Launch instance from template**
  - Try with different versions:
    - Default version
    - Latest version ($Latest)
    - Specific version number

#### 2. Verify Advanced Settings
- [ ] **Check EBS Optimization:**
  - Select launched instance → **Description** tab
  - Scroll to "EBS-optimized"
  - ✅ Should show "true"

- [ ] **Verify in CLI:**
  ```bash
  aws ec2 describe-instances \
    --instance-ids i-xxxxx \
    --query 'Reservations[0].Instances[0].[EbsOptimized,EnaSupport]'
  ```
  - ✅ Should return [true, true]

#### 3. Validate User Data Execution
- [ ] **Check cloud-init logs:**
  ```bash
  # View user data output
  sudo cat /var/log/cloud-init-output.log
  
  # Check for errors
  sudo grep ERROR /var/log/cloud-init.log
  ```

- [ ] **In Console - Get system log:**
  - Select instance → **Actions** → **Monitor and troubleshoot** → **Get system log**
  - Search for "user-data" execution
  - ✅ Should show successful completion

### Storage Configuration Testing
- [ ] **Verify EBS settings:**
  - Select instance → **Storage** tab
  - Check each volume:
    - ✅ Type: gp3
    - ✅ Encryption: Encrypted
    - ✅ IOPS: 3000
    - ✅ Throughput: 125 MB/s

- [ ] **Test performance:**
  ```bash
  # Install fio if needed
  sudo yum install -y fio  # or apt-get
  
  # Test IOPS
  sudo fio --name=randrw --ioengine=libaio --direct=1 \
    --bs=4k --numjobs=4 --size=1G --runtime=30 \
    --group_reporting --time_based --rw=randrw
  ```

---

## 📈 Auto Scaling Group Testing

### Basic ASG Functionality

#### 1. Verify Initial Deployment
- [ ] **In Auto Scaling Console:**
  - Go to **EC2** → **Auto Scaling Groups**
  - Select your ASG (e.g., `Terminus-Web-ASG`)
  - Check **Details** tab:
    - ✅ Desired capacity matches configuration
    - ✅ Current capacity equals desired
    - ✅ Instances distributed across AZs

#### 2. Test Manual Scaling
- [ ] **Scale up via Console:**
  - In ASG details, click **Edit**
  - Change "Desired capacity" from 2 to 3
  - Click **Update**
  - Go to **Activity** tab
  - ✅ Should see "Launching a new EC2 instance"

- [ ] **Monitor in Instance Management:**
  - Click **Instance management** tab
  - Watch new instance launch
  - ✅ Should be in different AZ for balance

#### 3. Test Instance Replacement
- [ ] **Terminate an instance:**
  - In **Instance management** tab
  - Select one instance
  - Click **Actions** → **Terminate**
  - Confirm termination

- [ ] **Monitor replacement:**
  - Go to **Activity** tab
  - ✅ Should see termination followed by launch
  - ✅ New instance should launch within 5 minutes

### Health Check Validation

#### 1. Configure Health Check Settings
- [ ] **Review current settings:**
  - In ASG → **Details** → **Health checks**
  - Note type (EC2 or ELB)
  - Note grace period (300 seconds recommended)

#### 2. Test Unhealthy Instance Replacement
- [ ] **Simulate failure (Session Manager):**
  ```bash
  # Stop the web service
  sudo systemctl stop apache2
  
  # Or simulate high load
  stress --cpu 8 --timeout 600s
  ```

- [ ] **Monitor health status:**
  - In **Instance management** tab
  - Watch "Health status" column
  - ✅ Should change to "Unhealthy"
  - ✅ Instance should be replaced

### Multi-AZ Testing
- [ ] **Check distribution:**
  - In **Instance management** tab
  - Note "Availability Zone" column
  - ✅ Instances should be evenly distributed
  - ✅ No single AZ should have all instances

---

## 📊 Scaling Policy Testing

### Target Tracking Scaling

#### 1. Generate CPU Load
- [ ] **Connect to instances and run:**
  ```bash
  # Install stress tool
  sudo yum install -y stress  # or apt-get
  
  # Generate 80% CPU load
  stress --cpu 4 --timeout 600s
  ```

#### 2. Monitor Scaling Activity
- [ ] **Check CloudWatch Alarms:**
  - Go to **CloudWatch** → **Alarms**
  - Find alarm like "TargetTracking-Terminus-Web-ASG"
  - ✅ Should transition to "In alarm" state

- [ ] **Watch ASG Activity:**
  - Return to ASG → **Activity** tab
  - ✅ Should see "Launching a new EC2 instance" after ~5 minutes
  - Note the reason mentions "target tracking policy"

#### 3. Verify Scale-in
- [ ] **Stop load generation**
- [ ] **Monitor scale-in:**
  - After 15 minutes of low CPU
  - ✅ ASG should terminate excess instances
  - ✅ Activity log shows scale-in reason

### Step Scaling Testing

#### 1. Configure Step Scaling
- [ ] **In ASG → Automatic scaling tab:**
  - Click **Create dynamic scaling policy**
  - Choose "Step scaling"
  - Configure steps:
    - 70-85% CPU: +1 instance
    - 85-95% CPU: +2 instances
    - >95% CPU: +3 instances

#### 2. Test Rapid Scaling
- [ ] **Generate intense load:**
  ```bash
  # From multiple sessions simultaneously
  stress --cpu 8 --vm 4 --vm-bytes 1G --timeout 300s
  ```

- [ ] **Verify step scaling:**
  - ✅ Should scale faster than target tracking
  - ✅ Multiple instances launch for high load
  - ✅ Activity log shows step policy triggered

### Scheduled Scaling Testing

#### 1. Create Test Schedule
- [ ] **In ASG → Automatic scaling → Scheduled actions:**
  - Click **Create scheduled action**
  - Name: "Test-Scale-Up"
  - Desired capacity: 4
  - Start time: 5 minutes from now
  - Time zone: Your local timezone

#### 2. Verify Execution
- [ ] **Monitor at scheduled time:**
  - Check **Activity** tab at scheduled time
  - ✅ Should see scaling activity
  - ✅ Reason mentions scheduled action

---

## 🔍 CloudWatch Integration Testing

### Agent Functionality

#### 1. Verify Metrics Collection
- [ ] **In CloudWatch Console:**
  - Go to **Metrics** → **All metrics**
  - Look for "CWAgent" namespace
  - ✅ Should see host-level metrics:
    - CPU utilization by core
    - Memory utilization
    - Disk usage
    - Network statistics

#### 2. Test Custom Metrics
- [ ] **Publish test metric:**
  ```bash
  aws cloudwatch put-metric-data \
    --namespace "Terminus/Application" \
    --metric-name "RequestCount" \
    --value 100 \
    --dimensions Environment=Production,Tier=Web
  ```

- [ ] **Create test alarm:**
  - Go to **Alarms** → **Create alarm**
  - Select your custom metric
  - Set threshold and notification

### Log Streaming Validation

#### 1. Check Log Groups
- [ ] **In CloudWatch Logs:**
  - Verify these log groups exist:
    - `/aws/ec2/web-tier`
    - `/aws/ec2/app-tier`
    - `/aws/ssm/session-manager`

#### 2. Generate and Verify Logs
- [ ] **Create test log entries:**
  ```bash
  # Application log
  echo "$(date) - Test log entry" >> /var/log/application.log
  
  # System log
  logger -t terminus-test "Test system log message"
  ```

- [ ] **Verify in Console:**
  - Go to appropriate log group
  - Click on log stream (instance ID)
  - ✅ Should see test entries within 1 minute

---

## 🛡️ Security Validation

### Instance Metadata Service v2
- [ ] **Test IMDSv2 enforcement:**
  ```bash
  # This should fail (v1 method)
  curl http://169.254.169.254/latest/meta-data/
  
  # This should work (v2 method)
  TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" \
    -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
  
  curl -H "X-aws-ec2-metadata-token: $TOKEN" \
    http://169.254.169.254/latest/meta-data/
  ```

### Security Group Validation
- [ ] **Test connectivity matrix:**
  - From public subnet → Web tier port 80: ✅ Allow
  - From internet → App tier: ❌ Deny
  - From Web tier → App tier port 8080: ✅ Allow
  - From App tier → Database port 3306: ✅ Allow

---

## 📋 Performance Validation

### Load Testing
- [ ] **Run comprehensive load test:**
  ```bash
  # From bastion or external host
  ab -n 10000 -c 100 http://web-tier-ip/health
  ```

- [ ] **Monitor during test:**
  - CloudWatch dashboard for real-time metrics
  - ASG scaling activities
  - Instance health status
  - ✅ No failed requests
  - ✅ Response time < 100ms
  - ✅ Auto scaling responds appropriately

### Placement Group Testing
- [ ] **Verify placement:**
  - Select instances in same tier
  - Check **Details** → **Placement group**
  - ✅ Web tier: partition placement
  - ✅ App tier: cluster placement

- [ ] **Test network performance:**
  ```bash
  # Between instances in cluster placement
  iperf3 -s  # on one instance
  iperf3 -c <private-ip>  # on another
  ```
  - ✅ Should see 5+ Gbps throughput

---

## ✅ Final Validation Checklist

### Console Verification
- [ ] All instances healthy in target groups
- [ ] CloudWatch dashboards showing data
- [ ] No failed scaling activities in past 24h
- [ ] All alarms in OK state
- [ ] Logs streaming successfully

### Cost Optimization Check
- [ ] Instances using Spot where appropriate
- [ ] EBS volumes using gp3 (not gp2)
- [ ] Unutilized instances terminated
- [ ] Snapshots have lifecycle policies
- [ ] Detailed monitoring only where needed

### Documentation
- [ ] Screenshot key configurations
- [ ] Document scaling test results
- [ ] Note any deviations from plan
- [ ] Update runbooks with findings

---

*Testing completed on: ________________*  
*Tested by: ________________*  
*All tests passed: Yes ☐ No ☐*