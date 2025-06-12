
<!--
Terminus Solutions AWS Enterprise Architecture
Copyright (c) 2025 Jared (Terminus Solutions) - jaredintech.com
Licensed under CC BY-SA 4.0 - Attribution required
See LICENSE-DOCS for details
-->

# <img src="./assets/logo.png" alt="Terminus Solutions" height="60"/> Terminus Solutions - Enterprise AWS Architecture

![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)
![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)
![CloudFormation](https://img.shields.io/badge/CloudFormation-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)
![Python](https://img.shields.io/badge/python-3670A0?style=for-the-badge&logo=python&logoColor=ffdd54)
![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=for-the-badge&logo=kubernetes&logoColor=white)

> Building a production-ready, multi-account AWS infrastructure for a technology consulting firm. This comprehensive project demonstrates enterprise cloud architecture best practices through 13 hands-on labs that I have developed after around 500 hours over the past 2 months, complete with detailed documentation, diagrams, screenshots, real-world cost analysis, and IaC.  I am also working on a YouTube channel to highlight this project as well as provide labs, tutorials, and all-encomassing personal and professional development strategies related to everything cloud.

## Project Highlights

- **Enterprise-Scale Architecture**: Multi-account, multi-region infrastructure supporting 99.99% availability
- **Security First**: Zero-trust architecture with defense in depth across all layers
- **Cost Optimized**: 92% cost savings compared to traditional enterprise solutions
- **Fully Documented**: Architecture Decision Records (ADRs), cost analysis, and implementation guides
- **Real Implementation**: Working infrastructure with proof of concepts, not just theory

## What I'm Building

This repository contains the complete implementation of an enterprise AWS infrastructure for **Terminus Solutions**, a fictional technology consulting firm that needs:

### Core Infrastructure
- ✅ **Multi-Account Strategy**: AWS Organizations with Production, Development, and Security accounts
- 🚧 **Global Networking**: Multi-region VPC architecture with Transit Gateway
- 📅 **Compute Platform**: Auto-scaling EC2 fleets with mixed instance policies
- 📅 **Data Layer**: Aurora Serverless with cross-region replication
- 📅 **Content Delivery**: CloudFront with Route53 for global performance

### Modern Application Architecture
- 📅 **Containerization**: ECS Fargate for serverless containers and EKS cluster for Kubernetes workloads
- 📅 **Serverless**: Lambda functions with API Gateway
- 📅 **Event-Driven**: SQS, SNS, and EventBridge for decoupling
- 📅 **Observability**: CloudWatch, X-Ray, and Systems Manager

### Enterprise Security & Governance
- ✅ **Identity & Access**: Cross-account roles with MFA enforcement
- ✅ **Compliance**: CloudTrail organization trail with 7-year retention
- 📅 **Threat Detection**: GuardDuty, Security Hub, and Config
- 📅 **Infrastructure as Code**: CloudFormation and Terraform

> **Security Note:** All AWS account IDs, email addresses, and sensitive information in this repository are **redacted or fictional** for security compliance.

## 🏗️ Architecture Overview (Before ECS and EKS migration)

![Architecture Overview](./architecture/diagrams/architecture-overview.png)


## 📊 Project Progress

| Lab | Component | Status | Key Achievements |
|-----|-----------|--------|------------------|
| 1 | [IAM & Organizations](./labs/lab-01-iam/) | ✅ Complete | Multi-account structure, SCPs, CloudTrail |
| 2 | [VPC & Networking](./labs/lab-02-vpc/) | 🚧 In Progress | Multi-region network backbone |
| 3 | EC2 & Auto Scaling | 📅 Planned | Mixed instance fleets, spot optimization |
| 4 | S3 & Storage Strategy | 📅 Planned | Lifecycle policies, intelligent tiering |
| 5 | RDS & Database Services | 📅 Planned | Aurora Serverless, read replicas |
| 6 | Route53 & CloudFront | 📅 Planned | Global content delivery |
| 7 | ELB & High Availability | 📅 Planned | Multi-tier load balancing |
| 8 | Lambda & API Gateway | 📅 Planned | Serverless microservices |
| 9 | SQS, SNS & EventBridge | 📅 Planned | Event-driven architecture |
| 10 | CloudWatch & Systems Manager | 📅 Planned | Comprehensive monitoring |
| 11 | CloudFormation IaC | 📅 Planned | Automated deployments |
| 12 | Security Services | 📅 Planned | GuardDuty, Security Hub |
| 13 | Container Services | 📅 Planned | ECS Fargate, EKS, service mesh |

## 💰 Cost Analysis

One of the key achievements of this project is demonstrating significant cost savings while maintaining enterprise-grade capabilities:

| Organization Size | Traditional Tools | This Architecture | Annual Savings |
|-------------------|-------------------|-------------------|----------------|
| Small (1-50 users) | $500K+ | $60 | 99.9% |
| Medium (50-500 users) | $1.5M+ | $1,020 | 99.9% |
| Enterprise (500+ users) | $4M+ | $27,600 | 99.3% |

See [detailed cost analysis](./architecture/cost-analysis/) for complete breakdowns and optimization strategies.

## 📚 Documentation Structure
```
terminus-solutions-aws-enterprise/
├── architecture/
│   ├── cost-analysis/     # Detailed cost projections and ROI
│   ├── decisions/         # Architecture Decision Records (ADRs)
│   └── diagrams/          # Visual architecture documentation
├── blog-posts/            # Deep-dive articles and lessons learned
├── documentation/
│   ├── compliance/        # Compliance and regulatory docs
│   ├── runbooks/          # Operational procedures
│   └── security/          # Security policies and procedures
├── infrastructure/
│   ├── cloudformation/    # AWS CloudFormation templates
│   ├── scripts/           # Automation and deployment scripts
│   └── terraform/         # Terraform modules and configs
├── labs/
│   └── lab-XX-name/       # Step-by-step implementation labs
│       ├── docs/          # Lab-specific documentation, troubleshooting, etc
│       ├── policies/      # IAM and SCP policies, if applicable
│       ├── screenshots/   # Implementation proof
│       └── README.md      # Lab walkthrough guide
└── videos/                # Demo videos and tutorials
```
## 🛠️ Technical Stack

### Core AWS Services
- **Compute**: EC2, Lambda
- **Storage**: S3, EBS, EFS
- **Database**: RDS Aurora, DynamoDB
- **Network**: VPC, Transit Gateway, Route 53, CloudFront
- **Security**: IAM, GuardDuty, Security Hub, KMS
- **Containerization**: ECS, EKS for Kubernetes

### Infrastructure as Code
- **CloudFormation**: Native AWS IaC
- **Terraform**: Multi-cloud ready
- **AWS CDK**: For complex constructs

### Languages & Tools
- **Python**: Lambda functions, automation scripts
- **Bash**: Infrastructure automation
- **JSON/YAML**: Configuration and policies
- **draw.io/SVG**: Architecture diagrams

## 🎯 Key Architectural Decisions

- **[ADR-001](./architecture/decisions/adr-001-multi-account-strategy.md)**: Multi-Account Strategy - Why separate accounts over VPC isolation
- **[ADR-002](./architecture/decisions/adr-002-vpc-networking.md)**: VPC & Networking Architecture - Implementing robust architecture (Coming Soon)
- **...and more**

See all [Architecture Decision Records](./architecture/decisions/).

## 📈 Success Metrics

| Metric | Target | Current Status |
|--------|--------|----------------|
| Availability | 99.99% | Architecture supports |
| RTO | < 15 minutes | Design complete |
| RPO | < 5 minutes | Design complete |
| Security Score | A+ | In progress |
| Cost vs Traditional | -90% | Achieved in design |

## 🤝 Connect With Me

I'm passionate about cloud architecture and always interested in discussing:
- Enterprise cloud strategies
- AI/ML integration
- Cost optimization techniques
- Security best practices
- Infrastructure automation

**Let's connect:**
- 📧 [Email](mailto:jared@jaredintech.com)
- 💼 [LinkedIn](https://linkedin.com/in/jaredrpeterson)
- 🌐 [Website](https://jaredintech.com)
- 📝 [Blog](https://jaredintech.com/blog) (Coming Soon)

## License

This project uses multiple licenses:

- **Code** (Terraform, CloudFormation, Scripts): MIT License
- **Documentation** (Guides, ADRs, Tutorials): [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/)
- **Architecture Diagrams & Designs**: [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/)

This means:
- ✅ You can use the code freely
- ✅ You must attribute documentation/designs
- ✅ Improvements must be shared back
- ✅ Commercial use is allowed with attribution

For commercial training or consulting based on this material, 
contact: jared@jaredintech.com

## 🙏 Acknowledgments

- AWS Documentation and Best Practices Guides
- AWS Well-Architected Framework
- Cloud architecture community for inspiration

---

*This project is in an active upload state. Star ⭐ the repository to follow along with updates!*