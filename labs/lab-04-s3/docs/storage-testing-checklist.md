# Lab 4: S3 & Storage Strategy - Testing Checklist

## Table of Contents

- [Pre-Testing Requirements](#pre-testing-requirements)
- [S3 Bucket Configuration Testing](#s3-bucket-configuration-testing)
- [Static Website Functionality](#static-website-functionality)
- [Lifecycle Policy Validation](#lifecycle-policy-validation)
- [Cross-Region Replication Testing](#cross-region-replication-testing)
- [CloudFront CDN Validation](#cloudfront-cdn-validation)
- [S3 Event Notifications Testing](#s3-event-notifications-testing)
- [Transfer Acceleration Testing](#transfer-acceleration-testing)
- [Security and Access Control](#security-and-access-control)
- [Performance Testing](#performance-testing)
- [Cost Optimization Validation](#cost-optimization-validation)
- [Disaster Recovery Testing](#disaster-recovery-testing)
- [Final Validation Checklist](#final-validation-checklist)

---

## Pre-Testing Requirements

- [ ] All Lab 1-3 components are functioning correctly
- [ ] Access to both us-east-1 and us-west-2 regions
- [ ] Sample files ready for testing:
  - [ ] HTML files (index.html, error.html)
  - [ ] Images (JPG/PNG, various sizes)
  - [ ] Large file >100MB for transfer tests
  - [ ] Multiple small files for lifecycle testing
- [ ] CloudWatch dashboard access
- [ ] Note bucket names for reference

---

## S3 Bucket Configuration Testing

### Bucket Creation and Naming

#### 1. Verify All Buckets Created
- [ ] **In S3 Console:**
  1. Navigate to **S3 Console**
  2. In the search bar, type "terminus" to filter
  3. Verify these buckets exist:
     - `terminus-static-[random]` (us-east-1)
     - `terminus-app-data-[random]` (us-east-1)
     - `terminus-backups-[random]` (us-east-1)
     - `terminus-logs-[random]` (us-east-1)
  4. Switch region selector to **us-west-2**
  5. Verify DR bucket exists:
     - `terminus-dr-[random]` (us-west-2)

#### 2. Test Bucket Properties
- [ ] **Check versioning status:**
  1. Click on `terminus-app-data-[random]`
  2. Go to **Properties** tab
  3. Scroll to **Bucket Versioning**
  4. ✅ Should show "Bucket Versioning is enabled"
  5. Repeat for backup and DR buckets

- [ ] **Verify encryption:**
  1. Stay in **Properties** tab
  2. Scroll to **Default encryption**
  3. Verify settings:
     - Static bucket: "SSE-S3" ✅
     - App/Backup buckets: "SSE-KMS" with key ARN ✅
     - Logs bucket: "SSE-S3" ✅

#### 3. Test Object Upload
- [ ] **Upload test file:**
  1. Click **Upload** button
  2. Add files → Select a test image
  3. Expand **Properties** section
  4. Verify encryption shows correctly
  5. Click **Upload**
  6. ✅ File should upload successfully

### Tags and Metadata

#### 1. Verify Bucket Tags
- [ ] **Check tagging:**
  1. Select bucket → **Properties** tab
  2. Scroll to **Tags** section
  3. Verify tags exist:
     - Environment: Production
     - DataClassification: (Public/Private/Confidential)
     - CostCenter: IT-Storage
     - Purpose: (Static/Application/Backup/Logs)

---

## Static Website Functionality

### Website Configuration

#### 1. Verify Static Website Hosting
- [ ] **In Console:**
  1. Go to `terminus-static-[random]` bucket
  2. Click **Properties** tab
  3. Scroll to **Static website hosting**
  4. Click to expand
  5. Verify:
     - Hosting: "Enabled" ✅
     - Hosting type: "Host a static website"
     - Index document: "index.html"
     - Error document: "error.html"
  6. Copy the **Bucket website endpoint** URL

#### 2. Upload Website Content
- [ ] **Upload files via Console:**
  1. Click **Objects** tab
  2. Click **Upload**
  3. Drag and drop all website files:
     - index.html
     - error.html
     - demo.html
     - style.css
     - images folder
  4. Click **Upload**

#### 3. Test Website Access
- [ ] **Test in browser:**
  1. Open new browser tab
  2. Paste the bucket website endpoint
  3. ✅ Should see Terminus Solutions homepage
  4. Test navigation:
     - Click links to verify they work
     - Try non-existent page (should show error.html)
     - Check images load properly

### Public Access Configuration

#### 1. Verify Public Access Settings
- [ ] **In Console:**
  1. Go to static bucket → **Permissions** tab
  2. Check **Block public access** section
  3. Should show "Block all public access: Off"
  4. Specific settings:
     - Block new public ACLs: On ✅
     - Block public access via ACLs: On ✅
     - Block new public policies: Off ✅
     - Block public access via policies: Off ✅

---

## Lifecycle Policy Validation

### Policy Configuration

#### 1. Verify Lifecycle Rules
- [ ] **Check app data bucket lifecycle:**
  1. Go to `terminus-app-data-[random]`
  2. Click **Management** tab
  3. Under **Lifecycle rules**, verify rule exists
  4. Click on rule name to view details
  5. Verify transitions:
     - After 30 days → Standard-IA ✅
     - After 90 days → Intelligent-Tiering ✅
     - After 180 days → Glacier Instant ✅

- [ ] **Check backup bucket lifecycle:**
  1. Go to `terminus-backups-[random]`
  2. **Management** → **Lifecycle rules**
  3. Verify immediate Glacier transition

#### 2. Test Lifecycle Transitions
- [ ] **Upload test objects:**
  1. Create test files with different dates:
     ```bash
     echo "30 day test" > lifecycle-test-30d.txt
     echo "90 day test" > lifecycle-test-90d.txt
     ```
  2. Upload to app data bucket
  3. **Note**: Actual transitions take time, verify configuration only

#### 3. Monitor Lifecycle Actions
- [ ] **Check lifecycle status:**
  1. Go to **CloudWatch Console**
  2. Navigate to **Metrics** → **S3**
  3. Look for lifecycle transition metrics
  4. ✅ Should see transition counts over time

---

## Cross-Region Replication Testing

### Replication Configuration

#### 1. Verify Replication Rules
- [ ] **In source bucket (us-east-1):**
  1. Go to `terminus-app-data-[random]`
  2. Click **Management** tab
  3. Scroll to **Replication rules**
  4. Verify rule exists and is "Enabled"
  5. Click rule to check:
     - Destination: terminus-dr-[random]
     - Destination region: us-west-2
     - Storage class: Standard-IA ✅

#### 2. Test Replication
- [ ] **Upload and verify:**
  1. Upload new file to source bucket:
     - Name: `replication-test-$(date +%s).txt`
  2. Note upload time
  3. Switch region to **us-west-2**
  4. Go to `terminus-dr-[random]` bucket
  5. Refresh and look for replicated file
  6. ✅ Should appear within 15 minutes

#### 3. Verify Replication Metrics
- [ ] **Check replication status:**
  1. In source bucket → **Metrics** tab
  2. Look for "Replication latency"
  3. ✅ Should show latency < 15 minutes
  4. Check "Bytes pending replication"
  5. ✅ Should trend toward zero

### Delete Marker Replication

#### 1. Test Delete Replication
- [ ] **Delete test:**
  1. In source bucket, select a replicated file
  2. Click **Delete**
  3. Confirm deletion
  4. Switch to DR bucket
  5. ✅ File should be deleted there too

---

## CloudFront CDN Validation

### Distribution Configuration

#### 1. Verify CloudFront Setup
- [ ] **In CloudFront Console:**
  1. Navigate to **CloudFront Console**
  2. Find distribution with origin `terminus-static-[random]`
  3. Click distribution ID
  4. Verify **General** settings:
     - Status: "Deployed" ✅
     - State: "Enabled" ✅
     - Price class: "Use Only North America and Europe"

#### 2. Test Origin Access Identity
- [ ] **Verify OAI configuration:**
  1. Click **Origins** tab
  2. Select S3 origin → **Edit**
  3. Verify:
     - Origin access: "Origin access identity"
     - OAI is selected ✅
     - Bucket policy: "Yes, update the bucket policy"

#### 3. Test CDN Access
- [ ] **Access content via CloudFront:**
  1. Copy CloudFront domain name (e.g., d1234567.cloudfront.net)
  2. Test URLs:
     - `https://[domain]/index.html`
     - `https://[domain]/images/logo.png`
  3. ✅ Content should load with HTTPS
  4. Check browser developer tools:
     - Look for `x-cache: Hit from cloudfront` header

### Cache Behavior Testing

#### 1. Verify Cache Settings
- [ ] **Check behaviors:**
  1. In distribution → **Behaviors** tab
  2. Select default behavior → **Edit**
  3. Verify cache settings:
     - Viewer protocol policy: "Redirect HTTP to HTTPS" ✅
     - Allowed HTTP methods: "GET, HEAD" ✅
     - Cache policy: Configured with TTLs

#### 2. Test Cache Invalidation
- [ ] **Create invalidation:**
  1. Go to **Invalidations** tab
  2. Click **Create invalidation**
  3. Add path: `/index.html`
  4. Click **Create invalidation**
  5. Wait for "Completed" status
  6. ✅ Updated content should be visible

---

## S3 Event Notifications Testing

### Lambda Function Configuration

#### 1. Verify Event Configuration
- [ ] **In S3 Console:**
  1. Go to `terminus-app-data-[random]`
  2. Click **Properties** tab
  3. Scroll to **Event notifications**
  4. Verify notification exists:
     - Event types: "All object create events" ✅
     - Destination: Lambda function ✅
     - Prefix filter: "uploads/" ✅
     - Suffix filter: ".jpg" ✅

#### 2. Test Event Processing
- [ ] **Upload trigger file:**
  1. Click **Upload**
  2. Create folder "uploads" first
  3. Upload a .jpg file to uploads/
  4. Go to **Lambda Console**
  5. Find processing function
  6. Click **Monitor** → **Logs**
  7. ✅ Should see processing logs

#### 3. Verify Processing Results
- [ ] **Check CloudWatch Logs:**
  1. In Lambda function → **Monitor** → **View logs in CloudWatch**
  2. Click latest log stream
  3. Verify:
     - Event received ✅
     - File processed ✅
     - No errors ✅

---

## Transfer Acceleration Testing

### Enable and Configure

#### 1. Verify Transfer Acceleration
- [ ] **In S3 Console:**
  1. Go to `terminus-app-data-[random]`
  2. Click **Properties** tab
  3. Find **Transfer acceleration**
  4. ✅ Should show "Enabled"
  5. Copy accelerated endpoint URL

#### 2. Test Accelerated Upload
- [ ] **Compare speeds:**
  1. Note regular upload time for large file
  2. Use AWS CLI with acceleration:
     ```bash
     aws s3 cp large-file.zip s3://terminus-app-data-xxxx/ --endpoint-url https://terminus-app-data-xxxx.s3-accelerate.amazonaws.com
     ```
  3. ✅ Should see improved upload speed
  4. Check CloudWatch for acceleration metrics

---

## Security and Access Control

### Bucket Policies

#### 1. Test Access Restrictions
- [ ] **Verify private bucket access:**
  1. Copy S3 URL for object in app-data bucket
  2. Open in incognito browser window
  3. ❌ Should get "Access Denied"
  4. Sign in to AWS Console
  5. Try same URL
  6. ✅ Should download successfully

#### 2. Test IAM Role Access
- [ ] **From EC2 instance (Lab 3):**
  1. Connect to instance via Session Manager
  2. Test S3 access:
     ```bash
     aws s3 ls s3://terminus-app-data-xxxx/
     aws s3 cp test.txt s3://terminus-app-data-xxxx/
     ```
  3. ✅ Should work with instance profile
  4. Try wrong bucket:
     ```bash
     aws s3 ls s3://some-other-bucket/
     ```
  5. ❌ Should get "Access Denied"

### Encryption Validation

#### 1. Verify Encryption at Rest
- [ ] **Check object encryption:**
  1. Select any object in app-data bucket
  2. Click object name → **Properties** tab
  3. Check **Server-side encryption settings**
  4. ✅ Should show KMS key ID
  5. Click on key ID link
  6. ✅ Verify key exists in KMS

---

## Performance Testing

### CloudFront Performance

#### 1. Test Global Latency
- [ ] **Using browser tools:**
  1. Open Chrome DevTools (F12)
  2. Go to **Network** tab
  3. Load CloudFront URL
  4. Check **Time** column
  5. ✅ Static assets should load < 100ms
  6. Look for "cf-cache-status: HIT" header

#### 2. Compare Direct vs CDN
- [ ] **Performance comparison:**
  1. Test S3 website endpoint: `http://bucket.s3-website.region.amazonaws.com`
  2. Test CloudFront: `https://distribution.cloudfront.net`
  3. ✅ CloudFront should be 50-80% faster
  4. Check from different locations using VPN

### Transfer Metrics

#### 1. Monitor S3 Request Metrics
- [ ] **In S3 Console:**
  1. Select bucket → **Metrics** tab
  2. View request metrics:
     - Total requests
     - GET requests
     - PUT requests
  3. ✅ Verify metrics match testing activity

---

## Cost Optimization Validation

### Storage Class Analysis

#### 1. Verify Intelligent-Tiering
- [ ] **Check configuration:**
  1. Go to test bucket with Intelligent-Tiering
  2. **Properties** → **Intelligent-Tiering configurations**
  3. Verify archive configurations:
     - Archive Access: 90 days ✅
     - Deep Archive: 180 days ✅

#### 2. Review Storage Metrics
- [ ] **Check S3 Storage Lens:**
  1. Go to **S3 Console** → **Storage Lens**
  2. Click on default dashboard
  3. Review:
     - Storage by class distribution
     - Cost optimization opportunities
     - Incomplete multipart uploads

### Cost Monitoring

#### 1. Verify Cost Allocation Tags
- [ ] **In Cost Explorer:**
  1. Go to **AWS Cost Management** → **Cost Explorer**
  2. Filter by tag "Project: TerminusSolutions"
  3. ✅ Should see S3 costs tracked
  4. Check breakdown by:
     - Storage class
     - Data transfer
     - Requests

---

## Disaster Recovery Testing

### Failover Simulation

#### 1. Test DR Bucket Access
- [ ] **Verify DR readiness:**
  1. Switch to **us-west-2** region
  2. Go to `terminus-dr-[random]` bucket
  3. Verify replicated objects exist
  4. Download sample file
  5. ✅ Verify content integrity

#### 2. Test Recovery Procedures
- [ ] **Simulate primary failure:**
  1. Document current CloudFront origin
  2. In CloudFront → **Origins** → **Edit**
  3. Change origin to DR bucket (don't save)
  4. ✅ Verify you know the process
  5. Cancel without saving

### Backup Validation

#### 1. Verify Backup Bucket
- [ ] **Check Glacier storage:**
  1. Go to `terminus-backups-[random]`
  2. Select an object → **Properties**
  3. ✅ Verify storage class is "Glacier Instant"
  4. Note restoration options available

---

## Final Validation Checklist

### Console Verification Summary
- [ ] All 5 buckets created and properly configured
- [ ] Static website accessible via S3 and CloudFront
- [ ] Lifecycle policies active on appropriate buckets
- [ ] Cross-region replication functioning
- [ ] Event notifications triggering Lambda
- [ ] Transfer acceleration enabled
- [ ] All security controls in place
- [ ] Performance metrics meeting targets
- [ ] Cost optimization features configured
- [ ] DR bucket receiving replicated data

### Documentation
- [ ] Screenshot bucket list showing all buckets
- [ ] Document static website URL
- [ ] Document CloudFront distribution URL
- [ ] Note replication lag observed
- [ ] Record performance metrics
- [ ] Calculate estimated monthly costs

### Sign-off
- [ ] All tests passed successfully
- [ ] No security vulnerabilities identified
- [ ] Performance meets requirements
- [ ] Cost projections within budget
- [ ] DR strategy validated

---

*Testing completed on: ________________*  
*Tested by: ________________*  
*All tests passed: Yes ☐ No ☐*