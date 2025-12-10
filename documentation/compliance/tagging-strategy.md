
## Complete Tagging Strategy 

### **Network/Infrastructure Resources:**

## Complete Resource Tagging Checklist:

- [ ] **Name** (always)
- [ ] **Environment** (always)
- [ ] **Project** (always)
- [ ] **ManagedBy** (always)
- [ ] **CostCenter** (always)
- [ ] **Purpose** (Primary/DR)
- [ ] **Tier** (for network resources)
- [ ] **AZ** (for AZ-specific resources)
- [ ] **Component** (for security groups)

## **Examples**

### **For a Public Subnet:**
```yaml
Name: Terminus-Public-1A
Environment: Production
Project: TerminusSolutions
ManagedBy: InfrastructureTeam
CostCenter: Operations
Purpose: Primary
Tier: Public  
AZ: us-east-1a
```

### **For a Database Security Group:**
```yaml
Name: Terminus-Database-SG
Environment: Production
Project: TerminusSolutions
ManagedBy: InfrastructureTeam
CostCenter: Operations
Purpose: Primary
Tier: Data  # 
Component: RDS
```

### **For an Application Subnet:**
```yaml
Name: Terminus-Private-App-1A
Environment: Production
Project: TerminusSolutions
ManagedBy: InfrastructureTeam
CostCenter: Operations
Purpose: Primary
Tier: Application  
AZ: us-east-1a
```
