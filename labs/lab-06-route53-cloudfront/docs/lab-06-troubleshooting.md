# Lab 6: Route 53 & CloudFront Distribution - Troubleshooting Guide

This guide covers common issues encountered when setting up Route 53 hosted zones, DNS routing policies, SSL/TLS certificates, CloudFront distributions, WAF rules, and global content delivery for Terminus Solutions.

## Table of Contents

- [Route 53 Hosted Zone Issues](#route-53-hosted-zone-issues)
- [DNS Propagation and Resolution Problems](#dns-propagation-and-resolution-problems)
- [Health Check Configuration Issues](#health-check-configuration-issues)
- [ACM Certificate Validation Problems](#acm-certificate-validation-problems)
- [CloudFront Distribution Issues](#cloudfront-distribution-issues)
- [Origin Access Control Problems](#origin-access-control-problems)
- [Cache and Invalidation Issues](#cache-and-invalidation-issues)
- [Cache Behavior Configuration Problems](#cache-behavior-configuration-problems)
- [WAF Configuration Issues](#waf-configuration-issues)
- [Lambda@Edge Problems](#lambdaedge-problems)
- [Routing Policy Issues](#routing-policy-issues)
- [SSL/TLS and HTTPS Problems](#ssltls-and-https-problems)
- [Performance and Latency Issues](#performance-and-latency-issues)
- [Monitoring and Alerting Problems](#monitoring-and-alerting-problems)
- [Common Error Messages](#common-error-messages)
- [Best Practices for DNS/CDN Debugging](#best-practices-for-dnscdn-debugging)
- [Quick Reference Commands](#quick-reference-commands)
- [When to Contact AWS Support](#when-to-contact-aws-support)

---

## Route 53 Hosted Zone Issues

### Issue: "Hosted zone already exists for this domain"
**Symptoms**: Cannot create hosted zone for domain.

**Console Solutions**:
1. **Check existing hosted zones**:
   - Go to **Route 53 Console** → **Hosted zones**
   - Search for your domain name
   - May have been created automatically during domain registration

2. **Use existing hosted zone**:
   - If hosted zone exists, use it instead of creating new
   - Check if NS records match domain registration
   - Delete and recreate if NS records are mismatched

3. **Check for delegation set conflicts**:
   - Multiple hosted zones can exist for same domain
   - Each has different NS records
   - Only one can be active for actual DNS resolution

### Issue: Nameservers not matching between domain and hosted zone
**Symptoms**: DNS resolution not working despite correct records.

**Console Solutions**:
1. **Compare NS records**:
   - **Route 53** → **Hosted zones** → Select zone
   - Note the NS record values (4 nameservers)
   - **Route 53** → **Registered domains** → Select domain
   - Check "Name servers" section

2. **Update domain nameservers**:
   - In **Registered domains**, click domain
   - **Actions** → **Edit name servers**
   - Enter all 4 NS values from hosted zone
   - Wait 24-48 hours for full propagation

3. **External registrar**:
   - If domain registered elsewhere (GoDaddy, Namecheap)
   - Update nameservers at that registrar
   - Point to Route 53 NS values

### Issue: Cannot delete hosted zone
**Symptoms**: Delete button fails or returns error.

**Console Solutions**:
1. **Delete all records first**:
   - Cannot delete zone with records (except NS and SOA)
   - Go to hosted zone → Select all records
   - Delete all A, AAAA, CNAME, MX, TXT records
   - NS and SOA records delete automatically with zone

2. **Check for associated resources**:
   - Health checks may reference zone records
   - CloudFront distributions may use zone for aliases
   - Delete associations first

---

## DNS Propagation and Resolution Problems

### Issue: DNS changes not taking effect
**Symptoms**: Old IP addresses still returned after record update.

**Console Solutions**:
1. **Check TTL values**:
   - Select the record → View TTL setting
   - High TTL = longer cache time
   - Reduce TTL before making changes (recommended: 60-300 seconds)
   - Wait for old TTL to expire before changes propagate

2. **Test with different DNS servers**:
   ```bash
   # Test with Google DNS
   nslookup terminus.solutions 8.8.8.8
   
   # Test with Cloudflare DNS
   nslookup terminus.solutions 1.1.1.1
   
   # Test directly with Route 53
   nslookup terminus.solutions ns-123.awsdns-45.com
   ```

3. **Clear local DNS cache**:
   - Windows: `ipconfig /flushdns`
   - macOS: `sudo dscacheutil -flushcache`
   - Chrome: `chrome://net-internals/#dns` → Clear host cache

4. **Use Route 53 test tool**:
   - **Route 53** → **Hosted zones** → Select zone
   - **Test record** button
   - Enter record name and type
   - See resolved values directly from Route 53

### Issue: "NXDOMAIN" or "Non-existent domain" errors
**Symptoms**: Domain not found by DNS queries.

**Console Solutions**:
1. **Verify record exists**:
   - Check exact record name (case-sensitive)
   - Include trailing dot for FQDN: `www.terminus.solutions.`
   - Check record type matches query type

2. **Check subdomain delegation**:
   - If querying subdomain, verify NS delegation
   - Parent zone must have NS records for subdomain zone

3. **Verify nameserver configuration**:
   - Domain must point to correct Route 53 nameservers
   - Check for typos in NS records at registrar

### Issue: "SERVFAIL" errors
**Symptoms**: DNS server failure responses.

**Console Solutions**:
1. **Check for DNSSEC issues**:
   - If DNSSEC enabled, verify DS records at registrar
   - Incorrect DS records cause validation failures
   - **Route 53** → **DNSSEC signing** → Check status

2. **Verify hosted zone integrity**:
   - Check for conflicting records
   - CNAME cannot coexist with other records at same name
   - Remove duplicate or conflicting entries

---

## Health Check Configuration Issues

### Issue: Health check showing "Unhealthy" status
**Symptoms**: All health checkers reporting failures.

**Console Solutions**:
1. **Verify endpoint accessibility**:
   - Go to **Route 53** → **Health checks**
   - Select health check → **Monitoring** tab
   - Check which regions are failing

2. **Check security group rules**:
   - Health checkers come from specific IP ranges
   - Must allow inbound from Route 53 health checker IPs
   - Download IP ranges from AWS documentation
   - Or allow 0.0.0.0/0 on health check port (less secure)

3. **Verify endpoint configuration**:
   - **Protocol**: Must match endpoint (HTTP/HTTPS/TCP)
   - **Port**: Correct port number
   - **Path**: For HTTP/HTTPS, path must return 2xx/3xx
   - **Host name**: Must resolve correctly

4. **Check response requirements**:
   - String matching: Response must contain expected string
   - Response timeout: Endpoint must respond within threshold
   - Failure threshold: Number of consecutive failures

### Issue: Health check flapping between Healthy and Unhealthy
**Symptoms**: Status changes frequently.

**Console Solutions**:
1. **Adjust threshold settings**:
   - Increase **Failure threshold** (e.g., 3 to 5)
   - Increase **Request interval** (e.g., 10 to 30 seconds)
   - Reduces sensitivity to transient issues

2. **Check endpoint stability**:
   - Application may be restarting
   - Load balancer health checks may be failing
   - Check CloudWatch metrics for endpoint

3. **Review health checker regions**:
   - Some regions may have connectivity issues
   - Customize which regions perform checks
   - Minimum 3 regions recommended

### Issue: Calculated health check not working correctly
**Symptoms**: Parent health check status incorrect.

**Console Solutions**:
1. **Verify child health checks**:
   - All referenced health checks must exist
   - Check IDs are correct
   - Child health checks must be accessible

2. **Check threshold calculation**:
   - "Health threshold" defines minimum healthy children
   - If threshold is 2 of 3, need at least 2 healthy
   - Adjust threshold based on requirements

---

## ACM Certificate Validation Problems

### Issue: Certificate stuck in "Pending validation" status
**Symptoms**: Certificate not validating after 24+ hours.

**Console Solutions**:
1. **For DNS validation**:
   - Go to **ACM Console** → Select certificate
   - Expand each domain in the certificate
   - Click **Create record in Route 53** for each domain
   - Verify CNAME records exist in hosted zone

2. **Check CNAME record accuracy**:
   - Go to **Route 53** → **Hosted zones**
   - Find the validation CNAME record
   - Name should match ACM requirement exactly
   - Value should match ACM requirement exactly
   - Include the trailing dots if shown

3. **Wildcard certificate issues**:
   - `*.terminus.solutions` requires CNAME for `_xxx.terminus.solutions`
   - Same validation record works for both apex and wildcard
   - Don't create duplicate records

4. **Wait for DNS propagation**:
   - DNS changes take time to propagate
   - ACM checks periodically (not instantly)
   - Can take up to 72 hours in some cases

### Issue: Certificate validation failed
**Symptoms**: Certificate shows "Failed" status.

**Console Solutions**:
1. **Check validation record still exists**:
   - Records may have been accidentally deleted
   - Recreate if missing
   - Request new certificate if too many failures

2. **Verify domain ownership**:
   - DNS validation requires control of DNS
   - If domain at external registrar, add records there
   - Check nameserver configuration

3. **Try email validation instead**:
   - Delete failed certificate
   - Request new certificate
   - Choose email validation method
   - Check admin@domain, hostmaster@domain, etc.

### Issue: CloudFront cannot find certificate
**Symptoms**: Certificate not appearing in CloudFront dropdown.

**Console Solutions**:
1. **Certificate must be in us-east-1**:
   - CloudFront only uses certificates from us-east-1
   - Check current region in ACM console
   - Request new certificate in us-east-1 if needed

2. **Certificate must be validated**:
   - Only "Issued" status certificates appear
   - Complete validation before configuring CloudFront

3. **Certificate must cover all CNAMEs**:
   - Certificate domains must match CloudFront alternate domain names
   - Use wildcard certificate for flexibility

---

## CloudFront Distribution Issues

### Issue: Distribution stuck in "Deploying" status
**Symptoms**: Distribution doesn't transition to "Deployed" after 30+ minutes.

**Console Solutions**:
1. **Check for configuration errors**:
   - Review distribution settings
   - Invalid origin configurations can cause delays
   - SSL certificate issues can cause delays

2. **Wait for global propagation**:
   - New distributions take 15-30 minutes typically
   - Changes to existing distributions also take time
   - Check CloudFront console for status updates

3. **Check AWS service health**:
   - Visit AWS Service Health Dashboard
   - CloudFront issues affect deployment times
   - No action needed if service disruption reported

### Issue: "AccessDenied" when accessing CloudFront URL
**Symptoms**: 403 Forbidden error on CloudFront distribution.

**Console Solutions**:
1. **Check S3 origin configuration**:
   - Verify Origin Access Control (OAC) is configured
   - Check S3 bucket policy allows CloudFront access
   - Ensure bucket policy uses correct distribution ID

2. **Verify default root object**:
   - **Distribution** → **General** → **Settings**
   - Check "Default root object" is set (e.g., `index.html`)
   - Without this, accessing `/` returns 403

3. **Check origin path**:
   - If origin path is set (e.g., `/static`)
   - Files must exist at that path in S3
   - Request for `/image.jpg` becomes `/static/image.jpg`

### Issue: "502 Bad Gateway" or "503 Service Unavailable"
**Symptoms**: CloudFront cannot reach origin.

**Console Solutions**:
1. **Verify origin is accessible**:
   - Test origin URL directly (bypass CloudFront)
   - Check origin server is running
   - Verify security groups allow CloudFront IPs

2. **Check origin protocol policy**:
   - **Origins** → Edit origin
   - Protocol must match origin capability
   - Use HTTPS if origin supports it
   - Match port numbers correctly

3. **Verify origin domain**:
   - For S3: Use correct bucket endpoint
   - Static website: `bucket.s3-website-region.amazonaws.com`
   - REST API: `bucket.s3.region.amazonaws.com`
   - For ALB: Use ALB DNS name

4. **Check origin timeouts**:
   - **Connection timeout**: Default 10 seconds
   - **Response timeout**: Default 30 seconds
   - Increase for slow-responding origins

---

## Origin Access Control Problems

### Issue: S3 returning 403 after OAC configuration
**Symptoms**: Access denied despite OAC setup.

**Console Solutions**:
1. **Update S3 bucket policy**:
   - Go to **S3** → Bucket → **Permissions** → **Bucket policy**
   - Add policy allowing CloudFront distribution:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Sid": "AllowCloudFrontServicePrincipal",
         "Effect": "Allow",
         "Principal": {
           "Service": "cloudfront.amazonaws.com"
         },
         "Action": "s3:GetObject",
         "Resource": "arn:aws:s3:::YOUR-BUCKET-NAME/*",
         "Condition": {
           "StringEquals": {
             "AWS:SourceArn": "arn:aws:cloudfront::ACCOUNT-ID:distribution/DISTRIBUTION-ID"
           }
         }
       }
     ]
   }
   ```

2. **Verify OAC is associated**:
   - **CloudFront** → Distribution → **Origins**
   - Edit origin → Check "Origin access control settings"
   - OAC must be selected, not "No"

3. **Check for conflicting policies**:
   - Remove any public access bucket policies
   - Block public access should be enabled
   - Only CloudFront should access bucket

### Issue: Migrating from OAI to OAC
**Symptoms**: Need to update legacy Origin Access Identity.

**Console Solutions**:
1. **Create new OAC**:
   - **CloudFront** → **Origin access** → **Create control setting**
   - Configure signing behavior

2. **Update distribution origin**:
   - Edit origin to use new OAC
   - Remove OAI association

3. **Update S3 bucket policy**:
   - Change from OAI principal to CloudFront service principal
   - Add SourceArn condition for security

---

## Cache and Invalidation Issues

### Issue: Changes not reflecting after content update
**Symptoms**: Old content still served despite S3 update.

**Console Solutions**:
1. **Create cache invalidation**:
   - Go to **CloudFront** → Distribution → **Invalidations**
   - **Create invalidation**
   - Enter paths: `/index.html` or `/*` for all content
   - Wait 10-15 minutes for completion

2. **Check cache headers**:
   - View content in browser dev tools
   - Check `x-cache` header (should show "Hit from cloudfront")
   - Check `cache-control` headers from origin

3. **Use versioned URLs**:
   - Better than invalidations: `style.css?v=2`
   - Or versioned paths: `/v2/style.css`
   - Immediately serves new content

### Issue: Low cache hit ratio
**Symptoms**: High origin load, high data transfer costs.

**Console Solutions**:
1. **Check cache policy**:
   - Go to **Behaviors** → Edit behavior
   - Use managed cache policies when possible
   - **CachingOptimized** for static content
   - Don't forward unnecessary headers/cookies

2. **Review query string handling**:
   - Forwarding all query strings reduces cache hits
   - Use allowlist for only necessary parameters
   - Or ignore query strings for static content

3. **Enable Origin Shield**:
   - **Origins** → Edit origin
   - Enable Origin Shield
   - Select region closest to origin
   - Consolidates requests, improves hit ratio

### Issue: Invalidation stuck in "In Progress"
**Symptoms**: Invalidation doesn't complete after 30+ minutes.

**Console Solutions**:
1. **Check invalidation paths**:
   - Paths must start with `/`
   - Wildcards: `/*` or `/images/*`
   - Case-sensitive on most origins

2. **Check CloudFront service status**:
   - Invalidations depend on edge propagation
   - Service issues can delay completion
   - Usually resolves automatically

3. **Create new invalidation**:
   - Old invalidation may be stuck
   - Create new invalidation request
   - Limit to 1000 paths per request

---

## Cache Behavior Configuration Problems

### Issue: Wrong content served for path pattern
**Symptoms**: API requests served from S3, or vice versa.

**Console Solutions**:
1. **Check behavior order**:
   - **Behaviors** tab shows priority order
   - More specific patterns should come first
   - `/api/*` should be before `/*`
   - Reorder using up/down arrows

2. **Verify path pattern syntax**:
   - Patterns are case-sensitive
   - Use `*` for wildcards
   - `/api/*` matches `/api/users` but not `/API/users`

3. **Test with specific requests**:
   - Use curl to test specific paths
   - Check response headers for origin information
   - `x-amz-cf-pop` shows edge location

### Issue: POST/PUT requests returning 403
**Symptoms**: Write operations fail through CloudFront.

**Console Solutions**:
1. **Check allowed HTTP methods**:
   - **Behaviors** → Edit behavior
   - "Allowed HTTP methods" setting
   - Select "GET, HEAD, OPTIONS, PUT, POST, PATCH, DELETE"

2. **Verify cache policy for dynamic content**:
   - Use **CachingDisabled** for API endpoints
   - Or custom policy with TTL=0

3. **Check origin request policy**:
   - May need to forward Authorization header
   - Check host header forwarding

---

## WAF Configuration Issues

### Issue: Legitimate traffic being blocked
**Symptoms**: Users getting 403 Forbidden from WAF.

**Console Solutions**:
1. **Check WAF logs**:
   - **WAF & Shield** → **Web ACLs** → Select ACL
   - **Logging and metrics** tab
   - Review blocked requests
   - Identify which rule is blocking

2. **Use Count mode for testing**:
   - Edit rule action from "Block" to "Count"
   - Monitor for false positives
   - Adjust rule before enabling Block

3. **Create exception rules**:
   - Add IP allowlist rule with higher priority
   - Create path-based exceptions
   - Priority 0 = highest priority (evaluated first)

### Issue: WAF rules not blocking attacks
**Symptoms**: Malicious traffic getting through.

**Console Solutions**:
1. **Verify WAF is associated**:
   - **CloudFront** → Distribution → **Security**
   - Check WAF web ACL is attached
   - Or **WAF** → **Web ACLs** → Check "Associated AWS resources"

2. **Check rule order and action**:
   - Rules with "Allow" action stop processing
   - Allowlist rules should be specific
   - Block rules should come after allowlists

3. **Review managed rule groups**:
   - Ensure relevant rule groups are added
   - **AWS Managed Rules** → **Core rule set** for basic protection
   - Enable all rules within groups

### Issue: Rate limiting not working
**Symptoms**: High-volume attacks not blocked.

**Console Solutions**:
1. **Verify rate-based rule configuration**:
   - Check rate limit threshold (requests per 5 minutes)
   - 100 = blocks after 100 requests in 5 minutes
   - Lower for stricter protection

2. **Check aggregation key**:
   - Default: Per IP address
   - Customize for header-based (e.g., API key)
   - Ensure key matches traffic pattern

---

## Lambda@Edge Problems

### Issue: Lambda@Edge function not executing
**Symptoms**: No logs, no effect on requests/responses.

**Console Solutions**:
1. **Verify function association**:
   - **CloudFront** → Distribution → **Behaviors**
   - Edit behavior → **Function associations**
   - Check function ARN includes version number
   - Cannot use $LATEST alias

2. **Check function region**:
   - Lambda@Edge functions must be in **us-east-1**
   - Function must be published (not just saved)

3. **Verify trigger event type**:
   - **Viewer request**: Before cache check
   - **Origin request**: On cache miss, before origin
   - **Origin response**: After origin response
   - **Viewer response**: Before returning to user

### Issue: Lambda@Edge returning errors
**Symptoms**: 502/503 errors, function execution failures.

**Console Solutions**:
1. **Check CloudWatch Logs**:
   - Logs appear in **region where request was processed**
   - Not in us-east-1, but in edge region
   - Log group: `/aws/lambda/us-east-1.function-name`

2. **Verify execution role**:
   - Role must allow `edgelambda.amazonaws.com`
   - Needs `logs:CreateLogGroup`, `logs:CreateLogStream`, `logs:PutLogEvents`

3. **Check function timeout**:
   - Viewer events: Max 5 seconds
   - Origin events: Max 30 seconds
   - Increase timeout if needed

4. **Validate response format**:
   - Response must match CloudFront expected format
   - Include status, statusDescription, headers
   - Body must be base64 encoded if binary

---

## Routing Policy Issues

### Issue: Latency-based routing not selecting nearest region
**Symptoms**: Users routed to distant regions.

**Console Solutions**:
1. **Verify health checks**:
   - Nearest region may be marked unhealthy
   - Check health check status for all endpoints
   - Unhealthy endpoints are excluded

2. **Check record configuration**:
   - All records must have same name
   - Different "Set ID" for each
   - Region must match actual resource location

3. **Understand latency measurement**:
   - Based on network latency, not geographic distance
   - AWS measures from user's DNS resolver location
   - VPN users may appear in different locations

### Issue: Failover not triggering
**Symptoms**: Primary is down but traffic not switching.

**Console Solutions**:
1. **Verify health check association**:
   - Primary record must have health check attached
   - Go to record → Edit → Check "Associate with health check"

2. **Check failover type assignment**:
   - Must have exactly one PRIMARY record
   - Must have one or more SECONDARY records
   - Check "Failover record type" setting

3. **Wait for health check failure**:
   - Default: 3 consecutive failures
   - At 30-second intervals = 90 seconds minimum
   - Plus DNS TTL for propagation

### Issue: Weighted routing not distributing correctly
**Symptoms**: Traffic skewed differently than weights suggest.

**Console Solutions**:
1. **Understand weight calculation**:
   - Weights are relative, not percentages
   - 70/30 split = weights 7 and 3, or 70 and 30
   - Weight 0 = no traffic (useful for draining)

2. **Account for DNS caching**:
   - Clients cache DNS responses
   - Distribution is per-query, not per-request
   - Short TTL for more accurate distribution

3. **Check all records**:
   - All weighted records must be healthy
   - Unhealthy records are excluded from calculation

---

## SSL/TLS and HTTPS Problems

### Issue: "NET::ERR_CERT_COMMON_NAME_INVALID"
**Symptoms**: Browser shows certificate warning.

**Console Solutions**:
1. **Verify certificate covers domain**:
   - Certificate must include the exact domain being accessed
   - `www.terminus.solutions` needs to be in certificate
   - Wildcard `*.terminus.solutions` covers subdomains, not apex

2. **Check CloudFront alternate domain names**:
   - **Distribution** → **General** → **Settings**
   - All CNAMEs must be covered by certificate
   - Add missing domains to certificate or remove from CNAMEs

3. **Match CNAME and certificate**:
   - If using `www.terminus.solutions` as CNAME
   - Certificate must include `www.terminus.solutions`
   - Or `*.terminus.solutions` wildcard

### Issue: Mixed content warnings
**Symptoms**: Browser shows insecure content warnings.

**Console Solutions**:
1. **Check viewer protocol policy**:
   - Set to "Redirect HTTP to HTTPS"
   - Ensures all CloudFront URLs use HTTPS

2. **Fix origin content**:
   - HTML may reference HTTP URLs
   - Update to use HTTPS or protocol-relative URLs
   - Use `//example.com/resource` instead of `http://`

3. **Configure origin protocol**:
   - Origin should also serve over HTTPS
   - Set origin protocol policy to "HTTPS Only"

### Issue: TLS handshake failures
**Symptoms**: Connection fails during SSL negotiation.

**Console Solutions**:
1. **Check security policy**:
   - **Distribution** → **General** → **Settings**
   - "Security policy" defines minimum TLS version
   - Older clients may not support TLS 1.2+
   - Use TLSv1.2_2021 for modern security

2. **Verify certificate chain**:
   - ACM certificates include full chain
   - Custom certificates need intermediate certs

---

## Performance and Latency Issues

### Issue: High Time to First Byte (TTFB)
**Symptoms**: Slow initial response times.

**Console Solutions**:
1. **Enable Origin Shield**:
   - Reduces origin requests
   - Choose region closest to origin
   - Improves cache hit ratio

2. **Optimize origin response**:
   - Check origin server performance
   - Enable keep-alive connections
   - Reduce origin processing time

3. **Review cache policy**:
   - Higher cache hit ratio = lower TTFB
   - Increase TTL for cacheable content
   - Use versioned URLs instead of short TTL

### Issue: Slow performance in specific regions
**Symptoms**: Users in certain locations report slowness.

**Console Solutions**:
1. **Check price class**:
   - **Distribution** → **General** → **Settings**
   - "Price class" limits edge locations
   - Use "All edge locations" for global coverage

2. **Enable latency-based routing**:
   - Deploy origins in multiple regions
   - Route 53 latency-based routing
   - Users automatically routed to fastest

3. **Review CloudWatch metrics**:
   - **CloudFront** → Distribution → **Monitoring**
   - Check cache hit ratio by edge location
   - Identify poorly-performing regions

---

## Monitoring and Alerting Problems

### Issue: CloudWatch metrics not appearing
**Symptoms**: No data in CloudFront dashboards.

**Console Solutions**:
1. **Check metrics availability**:
   - Basic metrics available by default
   - Additional metrics require enabling
   - **Distribution** → **General** → **Settings**
   - Enable "Additional metrics"

2. **Verify time range**:
   - Metrics may take 5-10 minutes to appear
   - Adjust dashboard time range
   - Use 1-minute granularity for recent data

3. **Check correct dimension**:
   - Filter by Distribution ID
   - Not all metrics available at all aggregations

### Issue: Alarms not triggering
**Symptoms**: No alerts despite threshold breach.

**Console Solutions**:
1. **Verify alarm configuration**:
   - Check threshold value and comparison
   - Verify evaluation periods
   - Check statistic (Average, Sum, Maximum)

2. **Confirm SNS topic setup**:
   - Alarm must have SNS action configured
   - SNS topic must have subscriptions
   - Subscriptions must be confirmed

3. **Check alarm state**:
   - "Insufficient data" = no metrics received
   - May need to adjust period or metric

---

## Common Error Messages

### "CNAMEAlreadyExists"
**Console Solution**:
1. CNAME already used by another distribution
2. Find which distribution uses it
3. Remove from old distribution before adding to new
4. Each CNAME can only be on one distribution globally

### "InvalidViewerCertificate"
**Console Solution**:
1. Certificate not in us-east-1
2. Certificate not validated
3. Certificate doesn't cover CNAME domains
4. Request new certificate in correct region

### "NoSuchOrigin"
**Console Solution**:
1. Origin referenced in behavior doesn't exist
2. Check origin ID matches exactly
3. Create missing origin before behavior

### "InvalidOriginAccessControl"
**Console Solution**:
1. OAC not properly configured
2. Check OAC exists and is enabled
3. Verify signing behavior is set

### "TooManyDistributionCNAMEs"
**Console Solution**:
1. Account limit for alternate domain names reached
2. Request limit increase from AWS Support
3. Remove unused CNAMEs from other distributions

### "InvalidLambdaFunctionAssociation"
**Console Solution**:
1. Lambda function ARN incorrect
2. Function must be published version (not $LATEST)
3. Function must be in us-east-1
4. Function must have correct execution role

### "The specified SSL certificate doesn't exist"
**Console Solution**:
1. Certificate was deleted
2. Certificate is in wrong region (must be us-east-1)
3. Request new certificate and update distribution

---

## Best Practices for DNS/CDN Debugging

### 1. Use DNS Testing Tools
**Online Tools**:
- **DNS Checker**: `dnschecker.org` for global propagation
- **MX Toolbox**: DNS, SSL, and health checks
- **What's My DNS**: Quick propagation check

**Command Line**:
```bash
# Direct query to Route 53
dig @ns-xxx.awsdns-xx.com terminus.solutions

# Trace DNS resolution
dig +trace terminus.solutions

# Check specific record type
dig terminus.solutions A
dig terminus.solutions CNAME
```

### 2. Test CloudFront Headers
**Useful Headers to Check**:
```bash
curl -I https://terminus.solutions

# Look for:
# x-cache: Hit from cloudfront (cached)
# x-cache: Miss from cloudfront (origin fetch)
# x-amz-cf-pop: Edge location code
# x-amz-cf-id: Request ID for debugging
```

### 3. Use CloudFront Logs
**Enable Standard Logging**:
- Logs delivered to S3 bucket
- Contains all request details
- Use Athena for analysis

**Real-time Logs**:
- Use for live debugging
- Stream to Kinesis Data Streams
- Higher cost but immediate visibility

### 4. Systematic Troubleshooting Order
1. **DNS Resolution**: Is domain resolving correctly?
2. **SSL/TLS**: Is certificate valid and trusted?
3. **CloudFront**: Is distribution deployed and healthy?
4. **Origin**: Is origin accessible and responding?
5. **WAF**: Are rules blocking legitimate traffic?
6. **Cache**: Is content being cached correctly?

### 5. Document Working Configurations
**Record for Future Reference**:
- Route 53 hosted zone configuration
- CloudFront distribution settings
- Certificate ARNs and validation status
- WAF rule configurations
- Working curl commands for testing

---

## Quick Reference Commands

### DNS Testing
```bash
# Query specific DNS server
nslookup terminus.solutions 8.8.8.8

# Get all DNS records
dig terminus.solutions ANY

# Check Route 53 health check IPs
curl https://ip-ranges.amazonaws.com/ip-ranges.json | jq '.prefixes[] | select(.service=="ROUTE53_HEALTHCHECKS")'
```

### CloudFront Testing
```bash
# Test with specific edge location
curl -H "Host: terminus.solutions" https://d111111abcdef8.cloudfront.net/

# Get distribution info
aws cloudfront get-distribution --id EDFDVBD6EXAMPLE

# Create invalidation
aws cloudfront create-invalidation \
  --distribution-id EDFDVBD6EXAMPLE \
  --paths "/*"
```

### Certificate Verification
```bash
# Check certificate details
openssl s_client -connect terminus.solutions:443 -servername terminus.solutions

# Verify certificate chain
openssl s_client -connect terminus.solutions:443 -showcerts

# Check ACM certificate
aws acm describe-certificate \
  --certificate-arn arn:aws:acm:us-east-1:123456789012:certificate/xxx \
  --region us-east-1
```

### WAF Queries
```bash
# List web ACLs for CloudFront
aws wafv2 list-web-acls --scope CLOUDFRONT --region us-east-1

# Get sampled requests
aws wafv2 get-sampled-requests \
  --web-acl-arn "arn:aws:wafv2:..." \
  --rule-metric-name "AWS-AWSManagedRulesCommonRuleSet" \
  --scope CLOUDFRONT \
  --time-window StartTime=2024-01-01T00:00:00Z,EndTime=2024-01-02T00:00:00Z \
  --max-items 100 \
  --region us-east-1
```

---

## When to Contact AWS Support

Contact support if:
- Distribution stuck in "Deploying" for over 2 hours
- Intermittent 502/503 errors with healthy origin
- Certificate validation failing despite correct DNS
- Health checks showing different status than expected
- Unexpected geographic restrictions on content
- Rate limiting affecting legitimate traffic patterns
- Need increased limits for distributions or CNAMEs

**Before contacting support**:
1. Document distribution ID and domain names
2. Capture request IDs from `x-amz-cf-id` headers
3. Note timestamps of issues
4. Screenshot console configurations
5. Export relevant CloudWatch metrics
6. Gather CloudFront access logs if available
