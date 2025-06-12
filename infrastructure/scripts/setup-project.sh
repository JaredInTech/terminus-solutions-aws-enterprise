#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_header() {
    echo -e "\n${BLUE}$1${NC}"
    echo "=================================================="
}

# Main setup function
main() {
    echo -e "${BLUE}🚀 Setting up Terminus Solutions AWS Enterprise Project${NC}"
    echo "=================================================="
    
    # Check if we're in the right directory
    if [ -d ".git" ] && [ -f "README.md" ]; then
        print_info "Git repository detected. Proceeding with setup..."
    else
        print_error "Warning: No git repository detected. Make sure you're in the project root."
        read -p "Continue anyway? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi

    # Create main directory structure
    print_header "📁 Creating main directories..."
    
    mkdir -p architecture/{diagrams,decisions,cost-analysis}
    print_status "Created architecture directories"
    
    mkdir -p infrastructure/{cloudformation,terraform,scripts}
    print_status "Created infrastructure directories"
    
    mkdir -p documentation/{runbooks,troubleshooting,security,compliance}
    print_status "Created documentation directories"
    
    mkdir -p blog-posts/{published,drafts}
    print_status "Created blog-posts directories"
    
    mkdir -p demo/{screenshots,videos}
    print_status "Created demo directories"
    
    mkdir -p .github/{workflows,ISSUE_TEMPLATE}
    print_status "Created GitHub directories"

    # Create all lab directories
    print_header "🔬 Creating lab directories..."
    
    # Define lab names
    declare -A lab_names=(
        [01]="iam"
        [02]="vpc"
        [03]="ec2"
        [04]="s3"
        [05]="rds"
        [06]="route53-cloudfront"
        [07]="elb"
        [08]="lambda-api"
        [09]="messaging"
        [10]="monitoring"
        [11]="cloudformation"
        [12]="security"
        [13]="containers"
    )
    
    declare -A lab_full_names=(
        [01]="IAM & Organizations"
        [02]="VPC & Networking Core"
        [03]="EC2 & Auto Scaling Platform"
        [04]="S3 & Storage Strategy"
        [05]="RDS & Database Services"
        [06]="Route53 & CloudFront Distribution"
        [07]="ELB & High Availability"
        [08]="Lambda & API Gateway Services"
        [09]="SQS, SNS & EventBridge Messaging"
        [10]="CloudWatch & Systems Manager Monitoring"
        [11]="CloudFormation Infrastructure as Code"
        [12]="Security Services Integration"
        [13]="Container Services (ECS/EKS)"
    )
    
    for i in {01..13}; do
        lab_dir="labs/lab-${i}-${lab_names[$i]}"
        mkdir -p "$lab_dir"
        print_status "Created $lab_dir"
    done

    # Create CloudFormation template structure
    print_header "☁️  Creating CloudFormation structure..."
    
    mkdir -p infrastructure/cloudformation/{templates,modules,parameters}
    mkdir -p infrastructure/cloudformation/templates/{networking,compute,security,data}
    print_status "Created CloudFormation directory structure"

    # Create Terraform module structure
    print_header "🏗️  Creating Terraform structure..."
    
    mkdir -p infrastructure/terraform/{modules,environments}
    mkdir -p infrastructure/terraform/modules/{vpc,ec2,rds,s3,iam}
    mkdir -p infrastructure/terraform/environments/{dev,staging,prod}
    print_status "Created Terraform directory structure"

    # Create placeholder files
    print_header "📄 Creating placeholder files..."

    # Root level files
    touch ARCHITECTURE.md
    touch IMPLEMENTATION_GUIDE.md
    touch CHANGELOG.md
    touch CONTRIBUTING.md
    touch .github/pull_request_template.md
    print_status "Created root level documentation files"

    # Create script files
    cat > infrastructure/scripts/deploy.sh << 'EOF'
#!/bin/bash
# Deployment script for Terminus Solutions infrastructure

set -e

echo "🚀 Deploying Terminus Solutions Infrastructure"
echo "============================================="

# Add deployment logic here
echo "Deployment script - to be implemented"
EOF

    cat > infrastructure/scripts/destroy.sh << 'EOF'
#!/bin/bash
# Teardown script for Terminus Solutions infrastructure

set -e

echo "🗑️  Destroying Terminus Solutions Infrastructure"
echo "=============================================="

# Add teardown logic here
echo "Destroy script - to be implemented"
EOF

    cat > infrastructure/scripts/validate.sh << 'EOF'
#!/bin/bash
# Validation script for infrastructure code

set -e

echo "✅ Validating Terminus Solutions Infrastructure"
echo "=============================================="

# Add validation logic here
echo "Validation script - to be implemented"
EOF

    chmod +x infrastructure/scripts/*.sh
    print_status "Created and made executable: deploy.sh, destroy.sh, validate.sh"

    # Create Architecture Decision Records README
    cat > architecture/decisions/README.md << 'EOF'
# Architecture Decision Records

This directory contains all Architecture Decision Records (ADRs) for the Terminus Solutions project.

## What is an ADR?

An Architecture Decision Record captures an important architectural decision made along with its context and consequences.

## ADR Template

```markdown
# ADR-XXX: [Decision Title]

## Status
[Proposed | Accepted | Deprecated | Superseded]

## Context
[What is the issue we're facing?]

## Decision
[What have we decided to do?]

## Consequences
### Positive
- [Positive outcome 1]
- [Positive outcome 2]

### Negative
- [Negative outcome 1]
- [Negative outcome 2]

## Alternatives Considered
1. [Alternative 1]
   - Pros: [...]
   - Cons: [...]
2. [Alternative 2]
   - Pros: [...]
   - Cons: [...]
```

## Index

- [ADR-001: Multi-Account Strategy](./ADR-001-multi-account-strategy.md)
- [ADR-002: Network Topology](./ADR-002-network-topology.md) (Coming Soon)
- [ADR-003: Compute Platform Selection](./ADR-003-compute-platform.md) (Coming Soon)
- [ADR-004: Data Storage Strategy](./ADR-004-data-storage.md) (Coming Soon)
EOF
    print_status "Created Architecture Decision Records README"

    # Create GitHub PR template
    cat > .github/pull_request_template.md << 'EOF'
## Description

Brief description of what this PR does.

## Type of Change

- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update
- [ ] Infrastructure change

## Lab Affected

- [ ] Lab 1: IAM & Organizations
- [ ] Lab 2: VPC & Networking Core
- [ ] Lab 3: EC2 & Auto Scaling Platform
- [ ] Lab 4: S3 & Storage Strategy
- [ ] Lab 5: RDS & Database Services
- [ ] Lab 6: Route53 & CloudFront Distribution
- [ ] Lab 7: ELB & High Availability
- [ ] Lab 8: Lambda & API Gateway Services
- [ ] Lab 9: SQS, SNS & EventBridge Messaging
- [ ] Lab 10: CloudWatch & Systems Manager Monitoring
- [ ] Lab 11: CloudFormation Infrastructure as Code
- [ ] Lab 12: Security Services Integration
- [ ] Lab 13: Container Services (ECS/EKS)

## Testing

- [ ] I have tested the infrastructure changes
- [ ] I have updated the documentation
- [ ] I have added/updated tests as appropriate

## Checklist

- [ ] My code follows the project's style guidelines
- [ ] I have performed a self-review of my own code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
- [ ] Any dependent changes have been merged and published
EOF
    print_status "Created GitHub PR template"

    # Create lab READMEs
    print_header "📚 Creating lab documentation..."
    
    for i in {01..13}; do
        lab_dir="labs/lab-${i}-${lab_names[$i]}"
        lab_name="${lab_full_names[$i]}"
        
        if [ "$i" == "01" ]; then
            # Skip Lab 1 as it already exists
            print_info "Skipping Lab 1 README (already exists)"
            continue
        fi
        
        cat > "$lab_dir/README.md" << EOF
# Lab $i - $lab_name

## Overview

This lab implements $lab_name for Terminus Solutions.

## Status

📅 Planned

## Prerequisites

- Completion of previous labs
- AWS CLI configured
- Appropriate IAM permissions

## Objectives

- [ ] Objective 1 (to be defined)
- [ ] Objective 2 (to be defined)
- [ ] Objective 3 (to be defined)

## Architecture

![Lab $i Architecture](../../demo/lab-${i}-architecture.png)

*Architecture diagram to be added*

## Implementation Steps

### Step 1: [Step Title]

\`\`\`bash
# Commands to be added
\`\`\`

### Step 2: [Step Title]

\`\`\`bash
# Commands to be added
\`\`\`

## Testing

### Test Case 1: [Test Name]

**Expected Result:**
- [ ] Criterion 1
- [ ] Criterion 2

### Test Case 2: [Test Name]

**Expected Result:**
- [ ] Criterion 1
- [ ] Criterion 2

## Cost Analysis

| Resource | Quantity | Cost/Month |
|----------|----------|------------|
| TBD      | TBD      | TBD        |

**Total Estimated Cost:** \$TBD/month

## Security Considerations

- [ ] Security consideration 1
- [ ] Security consideration 2
- [ ] Security consideration 3

## Lessons Learned

To be documented upon completion...

## Resources

- [AWS Documentation](https://docs.aws.amazon.com/)
- [Related Blog Post](../../blog-posts/published/lab-${i}.md)

## Next Steps

After completing this lab, proceed to [Lab $((i+1))](../lab-$((i+1))-${lab_names[$((i+1))]}/README.md)
EOF
        print_status "Created $lab_dir/README.md"
    done

    # Create .gitignore if it doesn't exist
    if [ ! -f .gitignore ]; then
        print_header "🚫 Creating .gitignore..."
        cat > .gitignore << 'EOF'
# AWS
.aws-sam/
*.pem
*.ppk

# Terraform
*.tfstate
*.tfstate.*
.terraform/
.terraform.lock.hcl
*.tfvars
*.auto.tfvars
override.tf
override.tf.json
*_override.tf
*_override.tf.json
crash.log
crash.*.log

# CloudFormation
packaged-template.yaml
samconfig.toml

# Environment variables
.env
.env.local
.env.*.local
*-secrets.yaml
*-credentials.json
*-secrets.json

# IDE
.vscode/
.idea/
*.swp
*.swo
*~
.project
.classpath

# OS
.DS_Store
Thumbs.db
desktop.ini

# Python
__pycache__/
*.py[cod]
*$py.class
venv/
env/
.Python
pip-log.txt
pip-delete-this-directory.txt

# Node
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Logs
*.log
logs/
*.log.*

# Temporary files
tmp/
temp/
*.tmp
*.bak
*.cache

# Build artifacts
dist/
build/
*.zip

# AWS CDK
cdk.out/
.cdk.staging/
EOF
        print_status "Created .gitignore"
    else
        print_info ".gitignore already exists, skipping..."
    fi

    # Create .gitkeep files for empty directories
    print_header "🔒 Creating .gitkeep files for empty directories..."
    find . -type d -empty -not -path "./.git/*" -exec touch {}/.gitkeep \;
    print_status "Created .gitkeep files in empty directories"

    # Final summary
    print_header "✅ Project structure created successfully!"
    
    echo -e "\n${GREEN}Summary:${NC}"
    echo "- Created $(find . -type d -not -path "./.git/*" | wc -l) directories"
    echo "- Created $(find . -type f -name "*.md" -o -name "*.sh" | wc -l) files"
    
    echo -e "\n${YELLOW}Next steps:${NC}"
    echo "1. Copy your Lab 1 documentation to labs/lab-01-iam/"
    echo "2. Review and customize the generated files"
    echo "3. Add and commit all files:"
    echo "   git add ."
    echo "   git commit -m 'feat: initial project structure with all 13 labs'"
    echo "4. Push to GitHub:"
    echo "   git push origin main"
    echo ""
    echo "5. Start working on Lab 2!"
    
    echo -e "\n${GREEN}Happy building! 🚀${NC}"
}

# Run the main function
main