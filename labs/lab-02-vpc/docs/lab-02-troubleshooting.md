# Lab 2: VPC & Networking Core - Troubleshooting Guide

This guide covers common issues encountered when setting up VPCs, subnets, routing, security controls, and cross-region connectivity for Terminus Solutions.

## Table of Contents
- [VPC Creation Issues](#vpc-creation-issues)
- [Subnet Configuration Problems](#subnet-configuration-problems)
- [Internet Connectivity Issues](#internet-connectivity-issues)
- [NAT Gateway Problems](#nat-gateway-problems)
- [Route Table Issues](#route-table-issues)
- [Security Group Problems](#security-group-problems)
- [Network ACL Issues](#network-acl-issues)
- [VPC Peering Problems](#vpc-peering-problems)
- [VPC Endpoint Issues](#vpc-endpoint-issues)
- [Flow Logs Configuration](#flow-logs-configuration)
- [Common Error Messages](#common-error-messages)
- [Best Practices for Network Debugging](#best-practices-for-network-debugging)

---

## VPC Creation Issues

### Issue: "The CIDR block x.x.x.x/xx conflicts with a CIDR block from another VPC"
**Symptoms**: Cannot create VPC with desired CIDR block.

**Causes**:
- CIDR overlaps with existing VPC in same region
- Secondary CIDR already assigned
- Peering connection exists with conflicting CIDR

**Console Solutions**:
1. **Check existing VPCs**:
   - Navigate to **VPC Console** → **Your VPCs**
   - Review the "IPv4 CIDR" column for all VPCs
   - Note all existing CIDR blocks

2. **Choose non-overlapping CIDR**:
   - Production: 10.0.0.0/16
   - DR: 10.1.0.0/16
   - Development: 10.2.0.0/16

3. **Check peering connections**:
   - Go to **Peering Connections** in left sidebar
   - Click each connection to view connected VPC CIDRs

### Issue: "VPC and more" creation fails
**Symptoms**: Multi-resource VPC creation partially completes then fails.

**Common Failure Points**:
- NAT Gateway creation (Elastic IP limit)
- Route table associations
- Internet Gateway attachment

**Console Solutions**:
1. **Check Elastic IP quota**:
   - Navigate to **EC2 Console** → **Elastic IPs**
   - Count existing EIPs (default limit is 5)
   - Click **"Limits"** in left sidebar to view quota

2. **Clean up partial resources**:
   - Go to **VPC Console** → **Your VPCs**
   - Select the partially created VPC
   - Check "Description" tab for associated resources
   - Delete in order: NAT Gateways → Subnets → VPC

3. **Create resources individually**:
   - Create VPC first without additional resources
   - Add components one by one for better control

---

## Subnet Configuration Problems

### Issue: Cannot create subnet - "CIDR block x.x.x.x/xx is not within the CIDR block of VPC"
**Symptoms**: Subnet CIDR rejected as invalid.

**Common Mistakes**:
- Subnet CIDR outside VPC CIDR range
- Subnet CIDR overlaps with existing subnet
- Invalid subnet mask (AWS reserves 5 IPs)

**Console Solutions**:
1. **Verify subnet is within VPC CIDR**:
   - In **VPC Console** → **Your VPCs**
   - Select your VPC and note the CIDR (e.g., 10.0.0.0/16)
   - Valid subnet example: 10.0.1.0/24 ✓
   - Invalid subnet example: 10.1.1.0/24 ✗

2. **Check existing subnets**:
   - Click **Subnets** in left sidebar
   - Filter by VPC using the search box
   - Review "IPv4 CIDR" column for conflicts

3. **Use the Visual Subnet Calculator**:
   - When creating subnet, console shows available ranges
   - Green = available, Red = in use
   - Remember: AWS reserves first 4 and last 1 IP

### Issue: Cannot delete subnet
**Symptoms**: "The subnet 'subnet-xxxxx' has dependencies and cannot be deleted."

**Common Dependencies**:
- EC2 instances
- Network interfaces
- Lambda functions
- RDS instances
- Load balancers

**Console Solutions**:
1. **Find dependencies**:
   - Select the subnet in **Subnets** view
   - Click **"Network interfaces"** tab
   - Review all interfaces using this subnet

2. **Delete dependencies**:
   - Click each network interface to see details
   - Note the "Description" field (shows resource type)
   - Navigate to respective service console to delete

3. **For Lambda ENIs**:
   - These show as "AWS Lambda VPC ENI"
   - Cannot delete manually - wait 40-45 minutes
   - They auto-delete after function idle period

---

## Internet Connectivity Issues

### Issue: EC2 instance in public subnet cannot reach internet
**Symptoms**: Cannot ping 8.8.8.8, no outbound connectivity.

**Console Checklist**:

1. **Public IP assigned?**
   - Go to **EC2 Console** → **Instances**
   - Select instance and check "Public IPv4 address" field
   - If blank, stop instance → Actions → Networking → Manage IP addresses

2. **Internet Gateway attached?**
   - Navigate to **VPC Console** → **Internet gateways**
   - Find IGW for your VPC
   - Check "State" = Attached
   - If detached: Select IGW → Actions → Attach to VPC

3. **Route table has IGW route?**
   - Go to **Route tables**
   - Find route table for public subnet
   - Click **Routes** tab
   - Should see: 0.0.0.0/0 → igw-xxxxx
   - If missing: Edit routes → Add route → 0.0.0.0/0 → Internet Gateway

4. **Security group allows outbound?**
   - In EC2 instance details, click security group
   - Check **Outbound rules** tab
   - Default allows all outbound
   - If removed: Edit outbound rules → Add rule → All traffic → 0.0.0.0/0

5. **Network ACL allows traffic?**
   - Go to **Network ACLs**
   - Find NACL for subnet
   - Check both **Inbound** and **Outbound** rules
   - Remember ephemeral ports (1024-65535) for return traffic

### Issue: Private subnet cannot access internet via NAT Gateway
**Symptoms**: Instances in private subnet cannot download updates or reach external APIs.

**Console Debugging Steps**:

1. **Verify NAT Gateway status**:
   - Navigate to **VPC Console** → **NAT gateways**
   - Check "Status" column = Available
   - Note which subnet it's in (must be PUBLIC)
   - Check "Elastic IP address" is assigned

2. **Check route table**:
   - Go to **Route tables**
   - Find route table for private subnet
   - Click **Routes** tab
   - Should have: 0.0.0.0/0 → nat-xxxxx
   - If missing: Edit routes → Add route → 0.0.0.0/0 → NAT Gateway

3. **Verify subnet associations**:
   - In route table, click **Subnet associations** tab
   - Ensure private subnet is associated
   - If not: Edit subnet associations → Select subnet → Save

4. **Test from EC2 console**:
   - Use **EC2 Instance Connect** or **Session Manager**
   - No need for SSH keys or bastion hosts
   - Run: `curl https://checkip.amazonaws.com`

---

## NAT Gateway Problems

### Issue: NAT Gateway creation fails
**Symptoms**: "The maximum number of addresses has been reached" or creation stuck in "Pending" state.

**Causes**:
- Elastic IP limit reached (5 per region default)
- Subnet doesn't have available IPs
- No internet gateway in VPC

**Console Solutions**:
1. **Check Elastic IP allocation**:
   - Go to **EC2 Console** → **Elastic IPs**
   - Look for unassociated EIPs (Association ID = blank)
   - Release unused: Select EIP → Actions → Release Elastic IP address

2. **Request limit increase**:
   - Click **Limits** in EC2 left sidebar
   - Search for "EC2-VPC Elastic IPs"
   - Click **Request limit increase**
   - Justify need and submit request

3. **Verify subnet capacity**:
   - In **VPC Console** → **Subnets**
   - Select subnet and check "Available IPv4 addresses"
   - NAT Gateway needs 1 available IP

### Issue: High NAT Gateway costs
**Symptoms**: Unexpected charges for NAT Gateway data processing.

**Console Analysis**:
1. **Check CloudWatch metrics**:
   - Go to **CloudWatch Console** → **Metrics**
   - Navigate to EC2 → Per-NAT Gateway Metrics
   - Select NAT Gateway → BytesOutToDestination
   - Adjust time range to identify spikes

2. **Enable VPC Flow Logs for analysis**:
   - In **VPC Console**, select VPC
   - Actions → Create flow log
   - Destination: CloudWatch Logs
   - Filter: ALL
   - Create new IAM role if needed

3. **Cost optimization strategies**:
   - **Development**: Delete NAT Gateway after hours
   - **Production**: Implement VPC endpoints for AWS services
   - **Monitoring**: Set up billing alerts in Billing Console

---

## Route Table Issues

### Issue: "A route in the route table has a destination CIDR block that overlaps an existing route"
**Symptoms**: Cannot add new route to route table.

**Common Conflicts**:
- Multiple default routes (0.0.0.0/0)
- Overlapping specific routes
- Local route conflicts

**Console Solutions**:
1. **Review existing routes**:
   - Navigate to **Route tables**
   - Select route table and click **Routes** tab
   - Look for overlapping CIDR blocks
   - Note: Most specific route wins

2. **Edit routes properly**:
   - Click **Edit routes**
   - Remove conflicting route first
   - Add new route
   - Save changes

3. **Route precedence rules**:
   - Local routes (10.0.0.0/16) cannot be modified
   - More specific routes override general ones
   - Example: 10.0.1.0/24 overrides 10.0.0.0/16

### Issue: Traffic not routing as expected
**Symptoms**: Packets going to wrong destination or being dropped.

**Console Debugging**:
1. **Check effective routes**:
   - Go to **Route tables**
   - Use filter to find subnet's route table
   - Click **Routes** tab
   - Verify destination and target

2. **Verify subnet associations**:
   - Click **Subnet associations** tab
   - Ensure correct subnets are associated
   - Check both explicit and main route table

3. **Use VPC Reachability Analyzer**:
   - Go to **VPC** → **Reachability Analyzer**
   - Click **Create and analyze path**
   - Select source and destination
   - Review the analysis results

---

## Security Group Problems

### Issue: Cannot connect despite correct security group rules
**Symptoms**: Connection timeouts even with allow rules in place.

**Console Debugging**:

1. **Verify correct security group**:
   - Go to **EC2 Console** → **Instances**
   - Select instance → **Security** tab
   - Click on security group name
   - Verify it's the intended group

2. **Check inbound rules**:
   - In security group, click **Inbound rules** tab
   - Verify:
     - Port number is correct
     - Protocol matches (TCP/UDP)
     - Source is correct (CIDR or security group)

3. **Common issues**:
   - **Wrong source**: 0.0.0.0/0 vs specific IP
   - **Port mismatch**: 8080 vs 80
   - **Protocol mismatch**: TCP vs UDP
   - **Security group reference**: Must be in same VPC

4. **Test with temporary rule**:
   - Edit inbound rules
   - Add: All traffic from My IP
   - Test connection
   - If works, narrow down the specific rule needed

### Issue: "RulesPerSecurityGroupLimitExceeded" error
**Symptoms**: Cannot add more rules to security group.

**Limits**:
- Inbound rules: 60 (default)
- Outbound rules: 60 (default)
- Security groups per instance: 5 (default)

**Console Solutions**:
1. **Consolidate rules**:
   - Edit security group
   - Combine multiple IPs into CIDR ranges
   - Use comma-separated ports: 80,443,8080

2. **Create additional security groups**:
   - Create new security group for additional rules
   - Attach multiple groups to instance
   - Edit instance → Actions → Security → Change security groups

3. **Request limit increase**:
   - Go to **Service Quotas** console
   - Search "VPC security group rules"
   - Request increase with justification

### Issue: Cross-region security group references not working
**Symptoms**: Cannot reference security group from another region in VPC peering setup.

**Console Solution**:
1. **Use CIDR blocks instead**:
   - Edit security group rules
   - Instead of security group reference, use:
     - Source: 10.1.11.0/24 (DR app subnet 1)
     - Description: "DR app subnet 1 access"

2. **Document IP ranges**:
   - Create descriptions for each CIDR
   - Maintain consistency across regions
   - Use tags to track cross-region rules

---

## Network ACL Issues

### Issue: Stateless NACL rules blocking return traffic
**Symptoms**: Outbound requests work but responses are blocked.

**Common Mistake**: Forgetting ephemeral port rules for return traffic.

**Console Configuration**:
1. **Navigate to Network ACLs**:
   - **VPC Console** → **Network ACLs**
   - Select the NACL for your subnet

2. **Add inbound ephemeral ports**:
   - Click **Inbound rules** tab → **Edit inbound rules**
   - Add rule:
     - Rule #: 130
     - Type: Custom TCP
     - Protocol: TCP
     - Port range: 1024-65535
     - Source: 0.0.0.0/0
     - Allow/Deny: ALLOW

3. **Add outbound rules**:
   - Click **Outbound rules** tab
   - Add standard outbound (80, 443)
   - Add ephemeral ports for responses

4. **Rule numbering best practice**:
   - Use increments of 10 or 100
   - Leave gaps for future rules
   - Lower numbers = higher priority

### Issue: NACL rules not taking effect
**Symptoms**: Traffic patterns don't match NACL configuration.

**Console Debugging**:
1. **Check subnet associations**:
   - In Network ACLs, click your NACL
   - Click **Subnet associations** tab
   - Verify correct subnets are associated

2. **Review rule order**:
   - Rules evaluated in numerical order
   - First match wins
   - Check for conflicting rules

3. **Default NACL check**:
   - Each subnet must have a NACL
   - If custom NACL not associated, uses default
   - Default NACL allows all traffic

### Issue: Cannot delete Network ACL
**Symptoms**: "The network ACL 'acl-xxxxx' has dependencies and cannot be deleted."

**Console Solution**:
1. **Check associations**:
   - Select NACL → **Subnet associations** tab
   - Note associated subnets

2. **Move subnets to different NACL**:
   - Click **Edit subnet associations**
   - Uncheck all subnets
   - Save changes

3. **Delete NACL**:
   - Once no associations, select NACL
   - Actions → Delete network ACL

---

## VPC Peering Problems

### Issue: VPC peering connection stuck in "Pending Acceptance"
**Symptoms**: Peering request created but not active.

**Console Solutions**:
1. **Accept the connection**:
   - Switch to target region (top-right region selector)
   - Go to **VPC Console** → **Peering Connections**
   - Select pending connection
   - Actions → Accept Request

2. **Check for expiration**:
   - Pending requests expire after 7 days
   - Check creation date in details
   - If expired, must create new request

### Issue: Cannot create VPC peering - "CIDR block overlaps"
**Symptoms**: Peering creation fails due to overlapping IP ranges.

**Console Verification**:
1. **Check both VPCs**:
   - Note CIDR of requester VPC
   - Switch regions
   - Note CIDR of accepter VPC
   - Ensure no overlap

2. **Common overlap issues**:
   - 10.0.0.0/16 and 10.0.0.0/24 overlap
   - Cannot peer overlapping CIDRs
   - Must plan IP addressing in advance

### Issue: Peered VPCs cannot communicate
**Symptoms**: Peering active but no connectivity between VPCs.

**Console Checklist**:

1. **Update route tables in BOTH VPCs**:
   - Go to **Route tables**
   - Select each route table
   - Edit routes → Add route
   - Destination: Remote VPC CIDR
   - Target: Select "Peering Connection" → pcx-xxxxx

2. **Enable DNS resolution**:
   - Select peering connection
   - Actions → Edit DNS Settings
   - Check both:
     - Allow DNS resolution from requester VPC
     - Allow DNS resolution from accepter VPC

3. **Update security groups**:
   - Must use CIDR blocks (not SG references)
   - Edit security groups in both VPCs
   - Add rules for remote VPC subnets

4. **Check NACLs**:
   - Verify NACLs allow cross-VPC traffic
   - Add rules for remote CIDR blocks

---

## VPC Endpoint Issues

### Issue: S3 VPC endpoint not working
**Symptoms**: S3 requests still going through NAT Gateway.

**Console Validation**:

1. **Check endpoint creation**:
   - Go to **VPC Console** → **Endpoints**
   - Verify S3 endpoint exists and is "Available"
   - Note the route table associations

2. **Verify route tables**:
   - Go to **Route tables**
   - Select private subnet route tables
   - Check **Routes** tab for "pl-xxxxx" (prefix list) entry
   - If missing: Edit endpoint → Modify route tables

3. **Check endpoint policy**:
   - Select endpoint → **Policy** tab
   - Verify it allows required S3 actions
   - Default is full access

4. **Test S3 access**:
   - From EC2 instance in private subnet
   - Use Session Manager (no bastion needed)
   - Run: `aws s3 ls`
   - Check NAT Gateway metrics - should show reduced traffic

### Issue: Interface endpoint DNS not resolving
**Symptoms**: Cannot reach AWS service through interface endpoint.

**Console Requirements**:
1. **Check VPC DNS settings**:
   - Select VPC → Actions → Edit DNS settings
   - Enable both:
     - Enable DNS resolution ✓
     - Enable DNS hostnames ✓

2. **Verify endpoint settings**:
   - Go to **Endpoints**
   - Select interface endpoint
   - Check **Details** tab
   - "Private DNS names enabled" should be Yes

3. **Security group check**:
   - Note endpoint's security group
   - Must allow HTTPS (443) from your subnets
   - Edit if needed

### Issue: "Access Denied" through VPC endpoint
**Symptoms**: Same request works via internet but fails through endpoint.

**Console Solutions**:
1. **Check endpoint policy**:
   - Select endpoint → **Policy** tab
   - Click **Edit Policy**
   - For testing, use full access policy
   - Restrict later based on needs

2. **S3 bucket policy update**:
   - Go to **S3 Console**
   - Select bucket → **Permissions** → **Bucket Policy**
   - Add condition for VPC endpoint:
   ```json
   "Condition": {
     "StringEquals": {
       "aws:SourceVpce": "vpce-xxxxx"
     }
   }
   ```

---

## Flow Logs Configuration

### Issue: VPC Flow Logs not appearing in CloudWatch
**Symptoms**: Log group empty despite Flow Logs enabled.

**Console Setup**:

1. **Create Flow Log correctly**:
   - Select VPC → Actions → Create flow log
   - Filter: ALL
   - Destination: Send to CloudWatch Logs
   - Log group: Create new or select existing
   - IAM role: Create new role (console will help)

2. **Verify IAM role**:
   - If using existing role, go to **IAM Console**
   - Check role has trust policy for vpc-flow-logs.amazonaws.com
   - Check role has CloudWatch Logs permissions

3. **Check log group**:
   - Go to **CloudWatch Console** → **Log groups**
   - Search for your flow log group
   - May take 5-10 minutes for first logs

4. **Verify flow log status**:
   - In VPC Console → Select VPC
   - Click **Flow logs** tab
   - Status should be "Active"

### Issue: Flow Logs showing only partial traffic
**Symptoms**: Some connections missing from logs.

**Console Checks**:
1. **Verify filter setting**:
   - Select VPC → **Flow logs** tab
   - Check "Filter" column
   - Should be "ALL" not just ACCEPT or REJECT

2. **Check aggregation interval**:
   - Shorter intervals (1 minute) capture more detail
   - Longer intervals (10 minutes) may miss short connections

3. **Review CloudWatch Insights**:
   - Go to **CloudWatch** → **Insights**
   - Select flow log group
   - Run query to check data:
   ```
   fields @timestamp, srcaddr, dstaddr, action
   | limit 20
   ```

---

## Common Error Messages

### "Network interface 'eni-xxxxx' is in use"
**Console Solution**: 
1. Go to **EC2 Console** → **Network Interfaces**
2. Search for the ENI ID
3. Check "Description" to see what's using it
4. Delete or detach the associated resource first

### "The vpc 'vpc-xxxxx' has dependencies and cannot be deleted"
**Console Deletion Order**:
1. **EC2 Console**: Terminate all instances
2. **RDS Console**: Delete DB instances
3. **ELB Console**: Delete load balancers
4. **VPC Console** → **NAT gateways**: Delete all
5. **VPC Console** → **Endpoints**: Delete all
6. **EC2 Console** → **Network Interfaces**: Delete detached ENIs
7. **VPC Console** → **Subnets**: Delete all
8. **VPC Console** → **Route tables**: Delete custom ones
9. **VPC Console** → **Internet gateways**: Detach and delete
10. **VPC Console** → **Peering connections**: Delete
11. Finally delete the VPC

### "Invalid value for portRange. Must specify both from and to ports with TCP/UDP"
**Console Fix**: 
- When adding security group rule
- Even for single port, fill both "Port range" fields
- Example: HTTP = From: 80, To: 80

---

## Best Practices for Network Debugging

### 1. Use VPC Reachability Analyzer
**Console Steps**:
- **VPC Console** → **Reachability Analyzer**
- Click **Create and analyze path**
- Select source (instance/ENI/IGW)
- Select destination
- Choose protocol and port
- Analyze results showing exact failure point

### 2. Enable VPC Flow Logs Temporarily
**Quick Enable**:
- Select VPC → Actions → Create flow log
- Use for debugging, delete when done
- Analyze in CloudWatch Insights

### 3. Test Connectivity Layer by Layer
1. **Same subnet**: Test security groups only
2. **Cross subnet**: Add routing checks
3. **Cross AZ**: Include NACL verification
4. **Cross region**: Test peering and all components

### 4. Use Session Manager for Testing
**No Bastion Needed**:
- **Systems Manager** → **Session Manager**
- Start session to private instance
- Run connectivity tests directly
- No SSH keys or public IPs required

### 5. Document Working Configurations
**Console Screenshots**:
- Take screenshots of working configs
- Document security group rules
- Save route table configurations
- Export NACL rules for reference

---

## Quick Console Navigation Tips

### Keyboard Shortcuts
- **`/`**: Focus on search box
- **`?`**: Show keyboard shortcuts
- **`n`**: Create new resource (context sensitive)

### Useful Filters
- In any list view, use search box
- Filter by tags: "tag:Environment=Production"
- Filter by VPC: Select VPC ID from dropdown
- Multi-select with checkboxes for bulk actions

### Console Features
- **Resource Groups**: Create groups for related resources
- **Tag Editor**: Bulk edit tags across resources
- **CloudFormation**: Export existing resources as templates
- **Resource Map**: Visual view of VPC resources

---

## When to Contact AWS Support

Contact support if:
- NAT Gateway stuck in "Failed" state over 15 minutes
- VPC peering showing "Active" in one region but "Pending" in another
- Intermittent connectivity with no configuration changes
- Console showing inconsistent information
- Need limit increases beyond Service Quotas

**Before contacting support**:
1. Take screenshots of all relevant console pages
2. Note all resource IDs
3. Document when issue started
4. Export VPC Flow Logs if available
5. Try in different browser/incognito mode