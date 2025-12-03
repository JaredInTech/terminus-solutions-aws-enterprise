## Table of Contents

- [Pre-Testing Verification](#-pre-testing-verification)
- [Connectivity Testing Scenarios](#-connectivity-testing-scenarios)
- [Security Testing](#-security-testing)
- [Performance Testing](#-performance-testing)
- [Disaster Recovery Testing](#-disaster-recovery-testing)
- [Compliance and Audit Testing](#-compliance-and-audit-testing)
- [Documentation and Cleanup](#-documentation-and-cleanup)
- [Troubleshooting Guide](#-troubleshooting-guide)
- [Success Criteria](#-success-criteria)

# Network Connectivity Testing Checklist

## 🔍 Pre-Testing Verification

### Infrastructure Validation ✓

#### VPC Components
- [ ] All VPCs created successfully in both regions
  - [ ] Production VPC (10.0.0.0/16) in us-east-1
  - [ ] DR VPC (10.1.0.0/16) in us-west-2
- [ ] Subnets properly configured with correct CIDR blocks
  - [ ] 6 subnets per VPC (2 public, 2 app, 2 data)
  - [ ] Proper naming convention applied
  - [ ] Correct AZ distribution
- [ ] Internet Gateways attached to VPCs
  - [ ] IGW attached to Production VPC
  - [ ] IGW attached to DR VPC
  - [ ] Route tables updated with IGW routes
- [ ] NAT Gateways deployed in each availability zone
  - [ ] 2 NAT Gateways in Production (one per AZ)
  - [ ] 2 NAT Gateways in DR (one per AZ)
  - [ ] Elastic IPs allocated and associated
- [ ] VPC Peering connection established and accepted
  - [ ] Connection status: Active
  - [ ] DNS resolution enabled both ways

### DNS Configuration ✓
- [ ] DNS hostnames enabled on all VPCs
- [ ] DNS resolution enabled on all VPCs
- [ ] VPC peering DNS resolution configured
- [ ] Private hosted zones created (if applicable)

### Security Components ✓
- [ ] ALB security groups allow HTTP/HTTPS from internet (0.0.0.0/0)
- [ ] Web tier security groups allow traffic from ALB security group
- [ ] Database security groups allow traffic from application tier only
- [ ] Cross-region database access configured for DR (CIDR-based rules)
- [ ] VPC endpoint security group allows HTTPS from private subnets

### Routing Configuration ✓
- [ ] Public subnet route tables point to Internet Gateway
- [ ] Private subnet route tables point to NAT Gateway (same AZ)
- [ ] Data subnet route tables have local routes only (no internet)
- [ ] Peering routes added to all route tables (10.1.0.0/16 ↔ 10.0.0.0/16)

## 🧪 Connectivity Testing Scenarios

### 1. Public Subnet Internet Access

**Test Setup**: Launch temporary EC2 instance in public subnet

```bash
# Launch test instance
aws ec2 run-instances \
  --image-id ami-0c94855ba95c71c0a \
  --instance-type t2.micro \
  --key-name terminus-test-key \
  --subnet-id subnet-xxxxx \
  --security-group-ids sg-xxxxx \
  --associate-public-ip-address
```

**Validation Steps**:
- [ ] Instance receives public IP address automatically
- [ ] Can ping external addresses
  ```bash
  ping -c 4 8.8.8.8
  ping -c 4 google.com
  ```
- [ ] Can download packages from internet repositories
  ```bash
  sudo yum update -y
  curl -I https://www.example.com
  ```
- [ ] SSH access works from approved IP addresses
  ```bash
  ssh -i terminus-test-key.pem ec2-user@<public-ip>
  ```

**Expected Results**: All connectivity tests pass, latency < 50ms

---

### 2. Private Subnet NAT Gateway Access

**Test Setup**: Launch temporary EC2 instance in private application subnet

**Validation Steps**:
- [ ] Instance receives private IP only (no public IP)
  ```bash
  # Verify no public IP assigned
  curl http://169.254.169.254/latest/meta-data/public-ipv4
  # Should return 404
  ```
- [ ] Can reach internet via NAT Gateway for outbound traffic
  ```bash
  # Test outbound connectivity
  ping -c 4 8.8.8.8
  curl -I https://www.amazonaws.com
  ```
- [ ] Cannot be reached directly from internet
  ```bash
  # From external host - should timeout
  nc -zv <private-ip> 22
  ```
- [ ] Can download software updates and packages
  ```bash
  sudo yum install -y htop
  pip install requests
  ```

**Expected Results**: Outbound works, inbound blocked

---

### 3. Application to Database Connectivity

**Test Setup**: Test network connectivity between tiers

**Validation Steps**:
- [ ] Application subnet can reach database subnet on port 3306
  ```bash
  # From app instance
  nc -zv 10.0.21.5 3306
  telnet 10.0.21.5 3306
  ```
- [ ] Database subnet cannot initiate outbound internet connections
  ```bash
  # From data subnet instance - should fail
  ping 8.8.8.8
  curl https://www.google.com
  ```
- [ ] Security groups properly restrict access to database ports
  ```bash
  # From public subnet - should fail
  nc -zv 10.0.21.5 3306
  ```
- [ ] Network ACLs allow necessary traffic patterns
  ```bash
  # Verify NACL rules with VPC Flow Logs
  ```

**Expected Results**: Only app tier can reach database tier

---

### 4. Cross-Region VPC Peering

**Test Setup**: Test inter-region communication via peering

**Validation Steps**:
- [ ] Production VPC can reach DR VPC subnets
  ```bash
  # From production instance
  ping -c 4 10.1.11.5
  ```
- [ ] DR VPC can reach production VPC subnets
  ```bash
  # From DR instance
  ping -c 4 10.0.11.5
  ```
- [ ] Route tables properly configured for cross-region traffic
  ```bash
  # Verify routes
  ip route | grep 10.1
  ```
- [ ] Security groups allow necessary cross-region access
  ```bash
  # Test database replication port
  nc -zv 10.1.21.5 3306
  ```

**Expected Results**: Bidirectional connectivity with ~67ms latency

---

### 5. VPC Endpoints Functionality

**Test Setup**: Test private AWS service access

**Validation Steps**:
- [ ] S3 access works without internet routing
  ```bash
  # Should not go through NAT Gateway
  aws s3 ls
  traceroute s3.amazonaws.com
  ```
- [ ] Systems Manager endpoints enable private instance management
  ```bash
  # Start SSM session from console
  # Should work without internet access
  ```
- [ ] CloudWatch logging works through VPC endpoints
  ```bash
  # Logs should appear without NAT traffic
  aws logs put-log-events ...
  ```
- [ ] No NAT Gateway charges for VPC endpoint traffic
  ```bash
  # Monitor NAT Gateway metrics
  ```

**Expected Results**: AWS services accessible without internet routing

## 🛡️ Security Testing

### Network ACL Validation

**Test Scenarios**:
- [ ] Public NACLs allow web traffic but restrict other access
  - [ ] HTTP/HTTPS allowed from 0.0.0.0/0
  - [ ] SSH allowed only from admin IPs
  - [ ] Other ports blocked
- [ ] Application NACLs prevent direct internet access
  - [ ] No inbound rules from 0.0.0.0/0
  - [ ] Outbound allows specific ports only
- [ ] Database NACLs only allow application tier access
  - [ ] MySQL port only from app subnets
  - [ ] No outbound internet rules
- [ ] Ephemeral port rules configured correctly
  - [ ] Return traffic for allowed connections works
  - [ ] Stateless nature properly handled

---

### Security Group Testing

**Test Scenarios**:
- [ ] Web servers accept traffic only from load balancers
  ```bash
  # From unauthorized source - should fail
  curl http://<web-server-ip>
  ```
- [ ] Database servers accept connections only from application tier
  ```bash
  # Test from different security groups
  ```
- [ ] No overly permissive rules (0.0.0.0/0 where inappropriate)
  ```bash
  # Audit security group rules
  aws ec2 describe-security-groups --query 'SecurityGroups[?IpPermissions[?IpRanges[?CidrIp==`0.0.0.0/0`]]]'
  ```
- [ ] Cross-region access properly restricted
  - [ ] Uses CIDR blocks, not security group references

---

### Flow Log Verification

**Test Scenarios**:
- [ ] VPC Flow Logs capturing all traffic types
  ```bash
  # Check CloudWatch Logs
  aws logs tail /aws/vpc/flowlogs/terminus-production
  ```
- [ ] Logs appearing in CloudWatch with correct format
- [ ] Can query logs for security analysis
  ```sql
  fields @timestamp, srcaddr, dstaddr, action
  | filter action = "REJECT"
  | stats count() by srcaddr
  ```
- [ ] Rejected connections properly logged for monitoring

## 🚀 Performance Testing

### Network Latency

**Test Scenarios**:
- [ ] Same-AZ communication shows minimal latency
  ```bash
  # Expected: <1ms
  ping -c 100 <same-az-instance>
  ```
- [ ] Cross-AZ communication acceptable for application needs
  ```bash
  # Expected: 1-2ms
  ping -c 100 <cross-az-instance>
  ```
- [ ] Cross-region latency suitable for database replication
  ```bash
  # Expected: ~67ms (us-east-1 to us-west-2)
  ping -c 100 <cross-region-instance>
  ```
- [ ] VPC peering doesn't add significant overhead
  ```bash
  # Compare direct vs peered latency
  ```

  ---

### Throughput Testing

**Test Tools**: iperf3, dd, AWS CLI

**Test Scenarios**:
- [ ] Instance-to-instance transfers meet performance requirements
  ```bash
  # Test bandwidth between instances
  iperf3 -s  # On target
  iperf3 -c <target-ip> -t 30  # On source
  ```
- [ ] NAT Gateway throughput adequate for application needs
  ```bash
  # Test outbound bandwidth
  curl -o /dev/null http://speedtest.tele2.net/1GB.zip
  ```
- [ ] Cross-region bandwidth sufficient for DR replication
  ```bash
  # Test VPC peering bandwidth
  dd if=/dev/zero bs=1M count=1000 | ssh <dr-instance> "cat > /dev/null"
  ```
- [ ] VPC endpoint performance satisfactory
  ```bash
  # Compare S3 performance via endpoint vs NAT
  time aws s3 cp s3://bucket/large-file /tmp/
  ```

## 🔄 Disaster Recovery Testing

### Failover Connectivity

**Test Scenarios**:
- [ ] DR VPC subnets properly configured
  - [ ] All subnets accessible
  - [ ] Routing works correctly
- [ ] Cross-region database replication connectivity working
  ```bash
  # Test replication ports
  nc -zv <dr-db-ip> 3306
  ```
- [ ] Route 53 health checks can reach both regions
  ```bash
  # Verify health check endpoints respond
  ```
- [ ] Application can connect to DR database when needed
  ```bash
  # Test connection string failover
  ```

### Network Isolation Testing

**Test Scenarios**:
- [ ] DR environment isolated from production traffic
- [ ] Cross-region access limited to necessary services
- [ ] No unintended production-DR network dependencies
- [ ] Emergency procedures for network-level failover documented

## 📊 Compliance and Audit Testing

### Access Control Validation

**Test Scenarios**:
- [ ] Database tier has no internet connectivity
  ```bash
  # Verify no routes to IGW or NAT
  ```
- [ ] Application tier internet access properly controlled
  ```bash
  # Check outbound rules
  ```
- [ ] Administrative access requires appropriate authentication
- [ ] Cross-region access logged and monitored

---

### Monitoring and Alerting

**Test Scenarios**:
- [ ] Suspicious traffic patterns trigger alerts
  ```bash
  # Generate test traffic to trigger alerts
  ```
- [ ] Failed connection attempts properly logged
- [ ] Real-time monitoring dashboards functional
- [ ] Compliance reporting capabilities verified

## 📝 Documentation and Cleanup

### Test Documentation
- [ ] All test results documented with screenshots
- [ ] Network connectivity matrix completed
- [ ] Performance metrics recorded for baseline
- [ ] Issues identified and resolution plans created

### Resource Cleanup
- [ ] Test EC2 instances terminated
  ```bash
  aws ec2 terminate-instances --instance-ids i-xxxxx
  ```
- [ ] Temporary security group rules removed
- [ ] Test data cleaned up from monitoring systems
- [ ] Billing impact of test resources assessed

## 🔧 Troubleshooting Guide

### Common Issues and Solutions

**Issue**: Instance can't reach internet
- Check route table for default route to NAT Gateway
- Verify security group outbound rules
- Confirm NACL allows outbound traffic on required ports
- Ensure NAT Gateway is in public subnet with IGW route

**Issue**: Cross-region connectivity fails
- Verify VPC peering connection status (Active)
- Check route table entries for remote VPC CIDR
- Validate security groups allow cross-region IP ranges
- Confirm NACLs allow traffic in both directions

**Issue**: Database connections fail
- Check security group rules for database port (3306)
- Verify NACL rules for database subnet
- Confirm application and database are in correct subnets
- Test with telnet/nc before application connection

**Issue**: VPC endpoint not working
- Verify endpoint policy allows required actions
- Check route table entries for endpoint routes (Gateway)
- Confirm security groups allow HTTPS (443) to endpoints
- Ensure DNS resolution is enabled on the VPC

## ✅ Success Criteria

### Minimum Viable Network
- [ ] All three tiers can communicate as designed
- [ ] Internet connectivity works where required
- [ ] Security controls prevent unauthorized access
- [ ] Cross-region connectivity functional for DR

### Production Ready Network
- [ ] High availability validated across multiple AZs
- [ ] Security monitoring and alerting operational
- [ ] Performance meets application requirements
- [ ] Disaster recovery network validated

### Enterprise Grade Network
- [ ] Compliance requirements met and validated
- [ ] Comprehensive monitoring and logging enabled
- [ ] Cost optimization measures implemented
- [ ] Documentation complete and current

---

_Use this checklist to systematically validate the network infrastructure before proceeding to application deployment_