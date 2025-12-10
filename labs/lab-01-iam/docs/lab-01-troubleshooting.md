# Lab 1: IAM & Organizations - Troubleshooting Guide

This guide covers common issues encountered when setting up AWS Organizations, IAM roles, and cross-account access for Terminus Solutions.

## Table of Contents
- [AWS Organizations Issues](#aws-organizations-issues)
- [Account Creation Problems](#account-creation-problems)
- [Service Control Policy (SCP) Issues](#service-control-policy-scp-issues)
- [Cross-Account Access Problems](#cross-account-access-problems)
- [IAM Role and Policy Issues](#iam-role-and-policy-issues)
- [MFA and Password Policy Problems](#mfa-and-password-policy-problems)
- [CloudTrail Configuration Issues](#cloudtrail-configuration-issues)
- [Common Error Messages](#common-error-messages)
- [Best Practices for Debugging](#best-practices-for-debugging)

---

## AWS Organizations Issues

### Issue: "You are not authorized to access this resource"
**Symptoms**: Error when trying to create an organization or access Organizations features.

**Causes**:
- Not signed in with root account or account with Organizations permissions
- Account is already part of another organization
- Insufficient IAM permissions

**Solutions**:
1. Ensure you're signed in with the root account or an IAM user with `organizations:*` permissions
2. Check if the account is already in an organization:
   ```bash
   aws organizations describe-organization
   ```
3. If already in an organization, you must leave it first or use a different account

### Issue: Organizations shows "Consolidated Billing" instead of "All Features"
**Symptoms**: Cannot create SCPs or use advanced features.

**Solutions**:
1. Navigate to Organizations → Settings
2. Click "Enable all features"
3. Confirm via email sent to root account email address
4. Wait for all member accounts to accept the invitation

---

## Account Creation Problems

### Issue: Account creation stuck in "IN_PROGRESS" state
**Symptoms**: New accounts remain in creating state for over 30 minutes.

**Causes**:
- AWS internal delays
- Email verification not completed
- Service limits reached

**Solutions**:
1. Check email for verification messages - verify all accounts
2. Check service quotas:
   ```bash
   aws service-quotas get-service-quota \
     --service-code organizations \
     --quota-code accounts-per-organization
   ```
3. If stuck over 1 hour, contact AWS Support
4. Try creating accounts one at a time instead of multiple simultaneously

### Issue: "Email address is already associated with an AWS account"
**Symptoms**: Cannot create new member account with desired email.

**Solutions**:
1. Use email aliases (Gmail supports `+` aliases):
   - `yourname+prod@gmail.com`
   - `yourname+dev@gmail.com`
2. Check if the email is used in a closed account (90-day waiting period)
3. Use a different email domain or create new email addresses

### Issue: Cannot access newly created member accounts
**Symptoms**: Unable to sign in directly to member accounts.

**Explanation**: This is expected behavior - member accounts created via Organizations don't have root passwords set.

**Solutions**:
1. Access via cross-account role assumption:
   ```bash
   aws sts assume-role \
     --role-arn "arn:aws:iam::MEMBER-ACCOUNT-ID:role/OrganizationAccountAccessRole" \
     --role-session-name "TempAccess"
   ```
2. To set root password (if needed):
   - Use account recovery process with the member account email
   - AWS will send password reset instructions

---

## Service Control Policy (SCP) Issues

### Issue: SCP not taking effect immediately
**Symptoms**: Actions that should be denied by SCP are still allowed.

**Causes**:
- SCP propagation delay (5-10 minutes)
- Testing in management account (exempt from SCPs)
- Policy not attached to correct OU/account

**Solutions**:
1. Wait 10-15 minutes for propagation
2. Verify SCP attachment:
   ```bash
   aws organizations list-policies-for-target \
     --target-id ACCOUNT-OR-OU-ID \
     --filter SERVICE_CONTROL_POLICY
   ```
3. Test in member accounts, not management account
4. Clear browser cache and re-authenticate

### Issue: "Explicit deny in service control policy" error
**Symptoms**: Valid IAM permissions blocked by SCP.

**Debugging Steps**:
1. Check which SCP is blocking:
   ```bash
   aws organizations list-policies-for-target \
     --target-id $(aws sts get-caller-identity --query Account --output text) \
     --filter SERVICE_CONTROL_POLICY
   ```
2. Review the SCP content for deny statements
3. Check condition keys (regions, instance types, etc.)
4. Verify you're in an allowed region
5. Check resource tags if SCP requires tagging

### Issue: SCP JSON validation errors
**Symptoms**: Cannot save SCP due to syntax errors.

**Common JSON Mistakes**:
- Missing commas between statements
- Extra commas after last element
- Incorrect quotation marks (smart quotes vs regular)
- Invalid condition keys

**Solution Template**:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyRootAccess",
      "Effect": "Deny",
      "Action": "*",
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:PrincipalType": "Root"
        }
      }
    }
  ]
}
```

---

## Cross-Account Access Problems

### Issue: "Invalid principal in policy" when creating trust relationship
**Symptoms**: Cannot save role trust policy with cross-account principal.

**Solutions**:
1. Verify account ID is correct (12 digits, no hyphens)
2. Use proper ARN format:
   ```json
   {
     "Principal": {
       "AWS": "arn:aws:iam::123456789012:root"
     }
   }
   ```
3. Ensure the principal account exists and is active

### Issue: Cannot assume cross-account role
**Symptoms**: AccessDenied error when trying to switch roles.

**Common Causes & Solutions**:

1. **MFA not present** (if required):
   - Ensure MFA is activated on your user
   - Sign out and sign in again to refresh MFA token
   
2. **Trust relationship misconfigured**:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Principal": {
           "AWS": "arn:aws:iam::MANAGEMENT-ACCOUNT:root"
         },
         "Action": "sts:AssumeRole",
         "Condition": {
           "Bool": {
             "aws:MultiFactorAuthPresent": "true"
           }
         }
       }
     ]
   }
   ```

3. **Session tags or external ID mismatch**:
   - Remove conditions temporarily to test
   - Add conditions back one at a time

4. **SCP blocking assume role**:
   - Check for SCPs that might block `sts:AssumeRole`

### Issue: Role switching in console shows "Invalid information" error
**Symptoms**: Cannot switch roles via AWS Console dropdown.

**Solutions**:
1. Clear browser cache and cookies
2. Use direct switch role URL:
   ```
   https://signin.aws.amazon.com/switchrole?account=ACCOUNT-ID&roleName=ROLE-NAME
   ```
3. Verify exact role name (case-sensitive)
4. Try using AWS CLI to confirm role works:
   ```bash
   aws sts assume-role \
     --role-arn "arn:aws:iam::ACCOUNT-ID:role/ROLE-NAME" \
     --role-session-name "TestSession"
   ```

---

## IAM Role and Policy Issues

### Issue: IAM policy conditions not working as expected
**Symptoms**: Actions allowed or denied incorrectly based on conditions.

**Common Condition Problems**:

1. **Instance type conditions**:
   ```json
   {
     "Condition": {
       "StringEquals": {
         "ec2:InstanceType": ["t2.micro", "t3.micro"]
       }
     }
   }
   ```
   - Ensure you're using the correct condition key
   - Check if the action supports the condition

2. **Resource tag conditions**:
   - Tags must exist before the condition can evaluate
   - Use `StringLike` for wildcard matching:
   ```json
   {
     "Condition": {
       "StringLike": {
         "aws:RequestedTags/Environment": "dev*"
       }
     }
   }
   ```

### Issue: Policy size limit exceeded
**Symptoms**: "Policy document length exceeds maximum allowed size" error.

**Solutions**:
1. Maximum policy size is 6,144 characters
2. Split into multiple policies
3. Use policy variables to reduce repetition:
   ```json
   {
     "Resource": "arn:aws:s3:::${aws:username}/*"
   }
   ```
4. Create managed policies and attach multiple to role

---

## MFA and Password Policy Problems

### Issue: Cannot enable MFA - QR code not scanning
**Symptoms**: Authenticator app cannot read AWS MFA QR code.

**Solutions**:
1. Try manual entry option - click "Show secret key"
2. Ensure correct time on phone (TOTP is time-based)
3. Use a different authenticator app:
   - Google Authenticator
   - Authy
   - Microsoft Authenticator
4. Check phone camera permissions

### Issue: MFA device out of sync
**Symptoms**: MFA codes rejected as invalid.

**Solutions**:
1. Ensure device time is accurate (enable automatic time)
2. Try codes from 30 seconds before/after
3. Resync MFA device in IAM console:
   - Sign in with root account
   - IAM → Users → Security credentials
   - Manage MFA device → Resync

### Issue: Password policy not enforcing on existing users
**Symptoms**: Users can still use old passwords that don't meet new policy.

**Explanation**: Password policies only apply on next password change.

**Solution**:
1. Enable "Require password reset" for all users:
   ```bash
   aws iam update-login-profile \
     --user-name USERNAME \
     --password-reset-required
   ```
2. Users will be forced to change password on next login

---

## CloudTrail Configuration Issues

### Issue: CloudTrail logs not appearing in S3
**Symptoms**: S3 bucket empty despite CloudTrail being enabled.

**Common Causes**:

1. **S3 bucket policy blocking CloudTrail**:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Sid": "AWSCloudTrailAclCheck",
         "Effect": "Allow",
         "Principal": {
           "Service": "cloudtrail.amazonaws.com"
         },
         "Action": "s3:GetBucketAcl",
         "Resource": "arn:aws:s3:::BUCKET-NAME"
       },
       {
         "Sid": "AWSCloudTrailWrite",
         "Effect": "Allow",
         "Principal": {
           "Service": "cloudtrail.amazonaws.com"
         },
         "Action": "s3:PutObject",
         "Resource": "arn:aws:s3:::BUCKET-NAME/*",
         "Condition": {
           "StringEquals": {
             "s3:x-amz-acl": "bucket-owner-full-control"
           }
         }
       }
     ]
   }
   ```

2. **KMS key permissions** (if using encryption):
   - CloudTrail service needs decrypt permissions
   - Add CloudTrail service to KMS key policy

3. **Trail not started**:
   ```bash
   aws cloudtrail get-trail-status --name TRAIL-NAME
   ```

### Issue: Organization trail not capturing member account events
**Symptoms**: Only seeing management account events.

**Solutions**:
1. Verify organization trail is enabled:
   ```bash
   aws cloudtrail describe-trails --trail-name-list TRAIL-NAME
   ```
2. Check `IsOrganizationTrail` is true
3. Ensure all features enabled in Organizations
4. Member accounts must be active (not suspended)

---

## Common Error Messages

### "User: arn:aws:iam::XXX:user/YYY is not authorized to perform: organizations:CreateAccount"
**Cause**: IAM user lacks Organizations permissions.
**Solution**: Add `organizations:*` or specific permissions to IAM user/role.

### "The security token included in the request is invalid"
**Causes**:
- Temporary credentials expired
- Wrong region configured
- Invalid access keys

**Solutions**:
1. Re-authenticate or refresh credentials
2. Check AWS CLI configuration:
   ```bash
   aws configure list
   ```
3. For assumed roles, check session duration

### "Account XXX is not a member of an organization"
**Cause**: Trying to use Organizations features in standalone account.
**Solution**: Create organization first or accept invitation to existing organization.

---

## Best Practices for Debugging

### 1. Enable CloudTrail for Debugging
Even if your main trail isn't working, create a temporary trail to debug:
```bash
aws cloudtrail create-trail \
  --name debug-trail \
  --s3-bucket-name YOUR-BUCKET
```

### 2. Use AWS CLI for Detailed Errors
Console often hides detailed error messages. Use CLI for more info:
```bash
aws organizations create-account \
  --email test@example.com \
  --account-name "Test" \
  --debug
```

### 3. Check Multiple Layers
When access is denied, check in order:
1. IAM policies (user/role permissions)
2. SCPs (organizational controls)
3. Resource policies (S3, KMS, etc.)
4. Session policies (for assumed roles)
5. Permission boundaries

### 4. Document Working Configurations
Once something works, document:
- Exact JSON policies
- Role trust relationships
- Account IDs and role names
- Successful CLI commands

### 5. Test Incrementally
- Start with minimal policies
- Add restrictions one at a time
- Test after each change
- Use version control for policy documents

---

## Quick Reference Commands

### Check Current Identity
```bash
aws sts get-caller-identity
```

### List Organization Accounts
```bash
aws organizations list-accounts
```

### Check SCP Inheritance
```bash
aws organizations list-policies-for-target \
  --target-id ACCOUNT-OR-OU-ID \
  --filter SERVICE_CONTROL_POLICY
```

### Test Role Assumption
```bash
aws sts assume-role \
  --role-arn "arn:aws:iam::ACCOUNT:role/ROLE" \
  --role-session-name "TestSession"
```

### Verify CloudTrail Status
```bash
aws cloudtrail get-trail-status --name TRAIL-NAME
```

---

## When to Contact AWS Support

Contact support if:
- Account creation stuck > 2 hours
- Organization invitation emails not arriving
- Service quota increase needed
- Unexpected service behavior after confirming configuration is correct

Provide:
- Organization ID
- Account IDs involved
- Exact error messages
- Steps to reproduce
- CloudTrail event IDs if available