# Lab 4: S3 & Storage Strategy - Troubleshooting Guide

## Table of Contents

- [S3 Bucket Creation Issues](#s3-bucket-creation-issues)
- [Static Website Hosting Problems](#static-website-hosting-problems)
- [Bucket Policy and Permissions Issues](#bucket-policy-and-permissions-issues)
- [Lifecycle Policy Problems](#lifecycle-policy-problems)
- [Cross-Region Replication Issues](#cross-region-replication-issues)
- [CloudFront Distribution Problems](#cloudfront-distribution-problems)
- [S3 Event Notification Issues](#s3-event-notification-issues)
- [Transfer Acceleration Problems](#transfer-acceleration-problems)
- [Encryption and Security Issues](#encryption-and-security-issues)
- [Performance and Cost Issues](#performance-and-cost-issues)
- [Data Upload and Download Problems](#data-upload-and-download-problems)
- [Intelligent-Tiering Issues](#intelligent-tiering-issues)
- [Common Error Messages](#common-error-messages)
- [Best Practices for S3 Debugging](#best-practices-for-s3-debugging)

---

## S3 Bucket Creation Issues

### Issue: "Bucket name already exists" error
**Symptoms**: Cannot create bucket with desired name.

**Console Solutions**:
1. **Understand bucket naming**:
   - S3 bucket names are globally unique across ALL AWS accounts
   - Not just unique to your account

2. **Fix the issue**:
   - Add random suffix: `terminus-static-prod-7h3x9`
   - Add timestamp: `terminus-static-20250701`
   - Add your initials: `terminus-static-jrt`

3. **Check existing buckets**:
   ```bash
   # See if name exists (will fail if not yours)
   aws s3api head-bucket --bucket desired-name
   ```

### Issue: "Access Denied" when creating bucket
**Symptoms**: IAM user cannot create buckets.

**Console Solutions**:
1. **Check IAM permissions**:
   - Go to **IAM Console** → **Users**
   - Click your username → **Permissions** tab
   - Look for S3 permissions
   - Need `s3:CreateBucket` action

2. **Check Service Control Policies**:
   - Go to **Organizations** → **Policies**
   - Check SCPs on your account
   - May restrict regions or require tags

3. **Use correct region**:
   - Check top-right region selector
   - Some organizations limit bucket creation to specific regions
   - Try us-east-1 if restricted

### Issue: Cannot create bucket in desired region
**Symptoms**: Region not available or grayed out.

**Console Solutions**:
1. **Check regional availability**:
   - Not all regions support all features
   - Newer regions may have restrictions

2. **Verify account access**:
   - Go to **Account** → **AWS Regions**
   - Enable desired region if disabled
   - May require root account access

---

## Static Website Hosting Problems

### Issue: "403 Forbidden" when accessing static website
**Symptoms**: Website URL returns 403 error.

**Console Debugging**:
1. **Check website hosting enabled**:
   - Go to bucket → **Properties** tab
   - Scroll to **Static website hosting**
   - Must show "Enabled"
   - Note the endpoint URL

2. **Verify public access settings**:
   - Go to **Permissions** tab
   - **Block public access** section
   - These must be OFF for static hosting:
     - "Block public access to buckets and objects granted through new public bucket or access point policies"
     - "Block public and cross-account access to buckets and objects through any public bucket or access point policies"

3. **Check bucket policy**:
   - Still in **Permissions** tab
   - Click **Bucket policy**
   - Must have policy allowing public GetObject:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [{
       "Sid": "PublicReadGetObject",
       "Effect": "Allow",
       "Principal": "*",
       "Action": "s3:GetObject",
       "Resource": "arn:aws:s3:::your-bucket-name/*"
     }]
   }
   ```

4. **Fix object permissions**:
   - Go to **Objects** tab
   - Select all website files
   - **Actions** → **Make public**
   - Confirm the action

### Issue: "404 Not Found" for existing files
**Symptoms**: Files exist in bucket but return 404.

**Console Solutions**:
1. **Check file location**:
   - Files must be in bucket root (not in folders) unless path included in URL
   - `index.html` must be at root level

2. **Verify exact filename**:
   - S3 is case-sensitive
   - `Index.html` ≠ `index.html`
   - Check for extra spaces or characters

3. **Check index document setting**:
   - **Properties** → **Static website hosting**
   - Index document must match exactly
   - Default is `index.html` not `index.htm`

### Issue: Website works via S3 URL but not custom domain
**Symptoms**: s3-website URL works, custom domain doesn't.

**Console Solutions**:
1. **For CloudFront distribution**:
   - Go to **CloudFront Console**
   - Click your distribution
   - **Origins** tab → Edit origin
   - Origin Domain: Must use website endpoint, not REST endpoint
   - Format: `bucket-name.s3-website-region.amazonaws.com`
   - NOT: `bucket-name.s3.amazonaws.com`

2. **Check Route 53** (if using):
   - Verify CNAME or ALIAS record
   - Points to CloudFront distribution
   - Not directly to S3

---

## Bucket Policy and Permissions Issues

### Issue: "Invalid principal in policy" error
**Symptoms**: Cannot save bucket policy.

**Console Solutions**:
1. **Check principal format**:
   - For public access: `"Principal": "*"`
   - For AWS service: `"Principal": {"Service": "cloudfront.amazonaws.com"}`
   - For specific account: `"Principal": {"AWS": "arn:aws:iam::123456789012:root"}`

2. **Validate JSON syntax**:
   - Use policy editor's **Validate policy** button
   - Check for missing commas, quotes
   - Ensure proper brackets

3. **Check resource ARN**:
   ```json
   "Resource": "arn:aws:s3:::bucket-name/*"  // For objects
   "Resource": "arn:aws:s3:::bucket-name"    // For bucket
   ```

### Issue: CloudFront OAI access denied
**Symptoms**: CloudFront cannot access S3 objects.

**Console Solutions**:
1. **Verify OAI configuration**:
   - Go to **CloudFront** → Distribution → **Origins**
   - Edit S3 origin
   - Ensure "Origin access identity" is selected
   - Note the OAI ID

2. **Update bucket policy**:
   - Go to S3 bucket → **Permissions** → **Bucket policy**
   - Add CloudFront OAI access:
   ```json
   {
     "Statement": [{
       "Effect": "Allow",
       "Principal": {
         "AWS": "arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity ABCDEFG1234567"
       },
       "Action": "s3:GetObject",
       "Resource": "arn:aws:s3:::bucket-name/*"
     }]
   }
   ```

3. **Remove public access**:
   - Can now block public access
   - CloudFront OAI provides access

### Issue: IAM role cannot access bucket
**Symptoms**: EC2 instances get access denied.

**Console Solutions**:
1. **Check bucket policy**:
   - May need to explicitly allow IAM role
   - Add statement for EC2 role:
   ```json
   {
     "Effect": "Allow",
     "Principal": {
       "AWS": "arn:aws:iam::123456789012:role/TerminusEC2ServiceRole"
     },
     "Action": ["s3:GetObject", "s3:PutObject"],
     "Resource": "arn:aws:s3:::bucket-name/*"
   }
   ```

2. **Verify IAM role permissions**:
   - Go to **IAM** → **Roles**
   - Find EC2 role → **Permissions** tab
   - Must have S3 permissions for specific bucket

---

## Lifecycle Policy Problems

### Issue: Lifecycle transitions not occurring
**Symptoms**: Objects remain in Standard storage class.

**Console Solutions**:
1. **Check lifecycle rule status**:
   - Go to bucket → **Management** tab
   - **Lifecycle rules** section
   - Status must show "Enabled"
   - Click rule name for details

2. **Verify rule filters**:
   - Check prefix filters match your objects
   - Empty prefix = applies to all objects
   - Check tag filters if used

3. **Understand timing**:
   - Transitions occur at midnight UTC
   - Based on object creation date, not upload date
   - May take 24-48 hours to see transitions

4. **Check minimum storage duration**:
   - Standard to Standard-IA: Minimum 30 days
   - Cannot transition before minimum duration

### Issue: "Invalid lifecycle configuration" error
**Symptoms**: Cannot save lifecycle policy.

**Console Solutions**:
1. **Check transition order**:
   - Must go from more expensive to less expensive
   - Valid: Standard → Standard-IA → Glacier
   - Invalid: Standard → Glacier → Standard-IA

2. **Verify storage class compatibility**:
   - Some transitions not allowed
   - Cannot transition from Glacier back to Standard-IA
   - Check AWS documentation for valid paths

3. **Fix day values**:
   - Days must increase for each transition
   - Example: 30 days → IA, 90 days → Glacier
   - Not: 30 days → IA, 25 days → Glacier

### Issue: Unexpected lifecycle costs
**Symptoms**: Higher than expected charges.

**Console Solutions**:
1. **Check transition costs**:
   - Go to **AWS Cost Explorer**
   - Filter by S3 lifecycle transitions
   - Each transition has small per-object fee

2. **Review minimum storage**:
   - Objects deleted before minimum duration incur early deletion fees
   - Standard-IA: 30-day minimum
   - Glacier: 90-day minimum

3. **Optimize lifecycle rules**:
   - Don't transition small objects (<128KB)
   - Overhead may exceed savings
   - Use size-based filters

---

## Cross-Region Replication Issues

### Issue: Replication not starting
**Symptoms**: Objects not appearing in destination bucket.

**Console Solutions**:
1. **Verify replication status**:
   - Go to source bucket → **Management** tab
   - **Replication rules** section
   - Status must show "Enabled"

2. **Check versioning**:
   - **Both** source and destination must have versioning enabled
   - Go to **Properties** → **Bucket Versioning**
   - Enable if not already

3. **Verify IAM role**:
   - Click on replication rule
   - Check IAM role has permissions
   - Must have read on source, write on destination

4. **Understand what replicates**:
   - Only new objects after rule creation
   - Existing objects need S3 Batch Replication
   - Deletes may or may not replicate based on settings

### Issue: Replication lag too high
**Symptoms**: Objects take hours to replicate.

**Console Solutions**:
1. **Check replication metrics**:
   - Go to source bucket → **Metrics** tab
   - View "Replication latency"
   - Normal: <15 minutes

2. **Enable RTC (Replication Time Control)**:
   - Edit replication rule
   - Enable "Replication Time Control"
   - Provides 15-minute SLA
   - Additional charges apply

3. **Check destination bucket events**:
   - Large objects take longer
   - Check network between regions
   - May be throttled if too many objects

### Issue: Replication failing for specific objects
**Symptoms**: Some objects replicate, others don't.

**Console Solutions**:
1. **Check object size**:
   - Maximum object size: 5TB
   - Large objects may timeout

2. **Verify object eligibility**:
   - Objects must match rule filters
   - Check prefix and tag filters
   - Encrypted objects need KMS permissions

3. **Check failed replication**:
   - Go to **CloudWatch** → **Metrics**
   - Search for S3 replication metrics
   - Look for failed operation count

---

## CloudFront Distribution Problems

### Issue: CloudFront returns "Access Denied"
**Symptoms**: S3 works directly, CloudFront doesn't.

**Console Solutions**:
1. **Check origin configuration**:
   - Go to **CloudFront Console**
   - Select distribution → **Origins** tab
   - Edit origin settings
   - For website: Use website endpoint
   - For private: Ensure OAI configured

2. **Verify origin access identity**:
   - In origin settings
   - "Origin access" → "Origin access identity"
   - Should show OAI created
   - "Update bucket policy" → Yes

3. **Wait for deployment**:
   - Check distribution status
   - Must show "Deployed"
   - Can take 15-20 minutes
   - Check **Last modified** time

### Issue: Content not updating after changes
**Symptoms**: Old content still served after S3 update.

**Console Solutions**:
1. **Create cache invalidation**:
   - Go to distribution → **Invalidations** tab
   - Click **Create invalidation**
   - Add paths to invalidate:
     - `/*` for everything (costs more)
     - `/index.html` for specific file
   - Submit and wait for completion

2. **Check cache headers**:
   - Browser developer tools → Network tab
   - Look for `x-cache: Hit from cloudfront`
   - Check `cache-control` headers
   - May need to update S3 object metadata

3. **Adjust cache behavior**:
   - **Behaviors** tab → Edit behavior
   - Reduce default TTL for testing
   - Can set to 0 for development

### Issue: HTTPS redirect not working
**Symptoms**: HTTP URLs not redirecting to HTTPS.

**Console Solutions**:
1. **Check viewer protocol policy**:
   - Go to **Behaviors** tab
   - Edit default behavior
   - "Viewer protocol policy"
   - Set to "Redirect HTTP to HTTPS"

2. **Verify certificate**:
   - **General** tab → **Settings**
   - Must have SSL certificate
   - Default CloudFront cert works for *.cloudfront.net

---

## S3 Event Notification Issues

### Issue: Lambda not triggering on S3 upload
**Symptoms**: Files uploaded but Lambda doesn't execute.

**Console Solutions**:
1. **Verify event configuration**:
   - Go to bucket → **Properties** tab
   - Scroll to **Event notifications**
   - Check notification exists and enabled

2. **Check event filters**:
   - Click on event notification
   - Verify prefix/suffix filters
   - Upload must match filters exactly
   - Example: prefix "uploads/" means root files won't trigger

3. **Verify Lambda permissions**:
   - Lambda needs permission from S3
   - Go to **Lambda Console**
   - Check function's resource-based policy
   - Must allow S3 to invoke

4. **Test with exact match**:
   - If filter is prefix: "uploads/" suffix: ".jpg"
   - Test file must be: "uploads/test.jpg"
   - Not: "test.jpg" or "uploads/test.png"

### Issue: Multiple Lambda invocations for single upload
**Symptoms**: Lambda runs multiple times per file.

**Console Solutions**:
1. **Check for multiple rules**:
   - May have overlapping event configurations
   - Review all event notifications
   - Ensure no duplicate triggers

2. **Check for versioning**:
   - With versioning, may trigger for version creation
   - Normal behavior if intended

3. **Review Lambda timeout**:
   - If Lambda times out, S3 retries
   - Check Lambda logs for timeouts
   - Increase timeout if needed

---

## Transfer Acceleration Problems

### Issue: Transfer acceleration not improving speed
**Symptoms**: Same upload speed with acceleration endpoint.

**Console Solutions**:
1. **Verify acceleration enabled**:
   - Go to bucket → **Properties** tab
   - Find **Transfer acceleration**
   - Must show "Enabled"

2. **Use speed comparison tool**:
   - AWS provides comparison tool
   - URL: `https://s3-accelerate-speedtest.s3-accelerate.amazonaws.com/en/accelerate-speed-comparsion.html`
   - Test from your location

3. **Understand when it helps**:
   - Best for far geographic distances
   - Large files (>10MB)
   - May not help if already close to region

4. **Check CloudWatch metrics**:
   - Look for acceleration metrics
   - Shows if uploads using accelerated endpoint
   - Compare speeds

### Issue: "Transfer acceleration not supported" error
**Symptoms**: Cannot enable acceleration.

**Console Solutions**:
1. **Check bucket name compliance**:
   - No dots in bucket name
   - Must be DNS-compliant
   - Example: `my-bucket` works, `my.bucket` doesn't

2. **Verify region support**:
   - Not all regions support acceleration
   - Check AWS documentation

---

## Encryption and Security Issues

### Issue: "KMS key access denied" errors
**Symptoms**: Cannot upload/download encrypted objects.

**Console Solutions**:
1. **Check KMS key permissions**:
   - Go to **KMS Console**
   - Find the key → **Key policy** tab
   - IAM role/user needs:
     - `kms:Decrypt` for download
     - `kms:GenerateDataKey` for upload

2. **Verify key is in same region**:
   - KMS keys are regional
   - Key must be in same region as bucket

3. **Check default encryption**:
   - Bucket → **Properties** → **Default encryption**
   - If using customer-managed key, verify access

### Issue: Cannot enforce encryption on bucket
**Symptoms**: Unencrypted uploads still succeed.

**Console Solutions**:
1. **Add bucket policy to deny unencrypted**:
   ```json
   {
     "Statement": [{
       "Effect": "Deny",
       "Principal": "*",
       "Action": "s3:PutObject",
       "Resource": "arn:aws:s3:::bucket-name/*",
       "Condition": {
         "StringNotEquals": {
           "s3:x-amz-server-side-encryption": "AES256"
         }
       }
     }]
   }
   ```

2. **Enable default encryption**:
   - This encrypts if not specified
   - But doesn't enforce encryption

---

## Performance and Cost Issues

### Issue: High S3 request charges
**Symptoms**: Unexpected costs in bill.

**Console Solutions**:
1. **Check request metrics**:
   - Go to bucket → **Metrics** tab
   - View request metrics
   - Look for unusual spikes

2. **Enable request logging**:
   - **Properties** → **Server access logging**
   - Enable to see all requests
   - Analyze for unnecessary requests

3. **Review lifecycle transitions**:
   - Each transition is a billable request
   - Don't transition small files
   - Consolidate files if possible

### Issue: Slow download speeds from S3
**Symptoms**: Direct S3 downloads are slow.

**Console Solutions**:
1. **Enable Transfer Acceleration**:
   - For uploads to improve ingestion
   - Downloads still use standard

2. **Use CloudFront for downloads**:
   - Creates edge cache
   - Much faster for repeated access

3. **Check S3 request limits**:
   - S3 has per-prefix limits
   - Spread files across prefixes
   - Use random prefixes for high throughput

---

## Data Upload and Download Problems

### Issue: Large file uploads failing
**Symptoms**: Uploads timeout or fail for files >100MB.

**Console Solutions**:
1. **Use multipart upload**:
   - Console automatically uses for large files
   - For CLI/SDK, configure threshold

2. **Check incomplete uploads**:
   - Bucket → **Management** → **Lifecycle rules**
   - Add rule to delete incomplete multipart uploads after 7 days
   - Prevents storage charges

3. **Browser limitations**:
   - Browser may timeout for very large files
   - Use AWS CLI for files >5GB
   - Or use S3 Transfer Acceleration

### Issue: "Slow Down" errors (503)
**Symptoms**: Getting rate limit errors.

**Console Solutions**:
1. **Implement exponential backoff**:
   - Retry with increasing delays
   - S3 is protecting itself

2. **Distribute load**:
   - Use random prefixes
   - Spread requests over time
   - Request limit increase from AWS Support

---

## Intelligent-Tiering Issues

### Issue: Not seeing cost savings from Intelligent-Tiering
**Symptoms**: Costs remain high despite enabling.

**Console Solutions**:
1. **Check monitoring fees**:
   - Small monitoring fee per object
   - Not cost-effective for small objects (<128KB)
   - Or frequently accessed objects

2. **Verify configuration**:
   - Bucket → **Properties** → **Intelligent-Tiering configurations**
   - Check archive settings are configured
   - Default only moves between Frequent/Infrequent

3. **Wait for transitions**:
   - Takes 30 days to see initial movement
   - Check Storage Lens for insights

---

## Common Error Messages

### "The bucket you are attempting to access must be addressed using the specified endpoint"
**Console Solution**: 
1. You're in wrong region
2. Check bucket region: **Properties** → **AWS Region**
3. Switch console to that region
4. Or specify region in CLI/SDK calls

### "The specified bucket does not exist"
**Console Solution**:
1. Check exact bucket name (case-sensitive)
2. Verify you're in correct AWS account
3. Check region if using CLI
4. May have been deleted

### "Invalid Location Constraint"
**Console Solution**:
1. Creating bucket in region not matching constraint
2. Check your selected region
3. Some regions have specific names (eu-west-1 vs EU)

### "Bucket name must not contain uppercase characters"
**Console Solution**:
1. S3 bucket names must be lowercase
2. Convert: `MyBucket` → `mybucket` or `my-bucket`
3. Follow DNS naming conventions

### "Access Denied" with correct permissions
**Console Solution**:
1. Check bucket policy (may have explicit deny)
2. Check S3 Block Public Access settings
3. Check VPC endpoint policies if using
4. Check service control policies (SCPs)
5. MFA may be required for sensitive operations

---

## Best Practices for S3 Debugging

### 1. Use CloudTrail for API Debugging
**Console Access**:
1. Go to **CloudTrail** → **Event history**
2. Filter by:
   - Event name: `PutObject`, `GetObject`, etc.
   - Resource type: S3 bucket
   - Time range: Last hour
3. Look for error codes and details

### 2. Enable S3 Access Logging
**Console Steps**:
1. Bucket → **Properties** → **Server access logging**
2. Enable and specify target bucket
3. Analyze logs for:
   - 403/404 errors
   - Unusual access patterns
   - Performance issues

### 3. Use S3 Storage Lens
**Console Access**:
1. **S3 Console** → **Storage Lens**
2. Create dashboard for insights:
   - Cost optimization opportunities
   - Security findings
   - Access patterns
   - Performance metrics

### 4. Test with AWS CLI
**Why CLI helps**:
- More detailed error messages
- `--debug` flag shows full request/response
- Easier to test specific scenarios
- Can script test cases

### 5. Monitor with CloudWatch
**Key Metrics**:
1. **S3 Console** → Bucket → **Metrics** tab
2. Set up alarms for:
   - 4xx errors (client issues)
   - 5xx errors (service issues)
   - Request counts
   - Latency

---

## Quick Console Navigation Tips

### S3 Console Shortcuts
- **Alt + Shift + B**: Go to buckets list
- **/** : Quick search in current view
- **Shift + ?**: Show keyboard shortcuts

### Useful Console Features
- **S3 Select**: Query data without downloading
- **Object actions**: Batch operations on multiple objects
- **Storage class analysis**: Recommendations for lifecycle
- **Inventory reports**: Complete object listings

### Console URL Patterns
- Bucket: `https://s3.console.aws.amazon.com/s3/buckets/bucket-name`
- Object: `https://s3.console.aws.amazon.com/s3/object/bucket-name?prefix=path/to/object`
- Share these for quick team debugging

---

## When to Contact AWS Support

Contact support if:
- Replication stuck for over 24 hours
- Getting consistent 500/503 errors
- Transfer Acceleration not available in your region
- Need to increase service quotas
- Seeing unexpected data transfer charges

**Before contacting support**:
1. Document error messages and request IDs
2. Note affected bucket names and regions
3. Capture CloudTrail events
4. Screenshot console errors
5. Test with AWS CLI for detailed errors

---

*Last Updated: July 2025*