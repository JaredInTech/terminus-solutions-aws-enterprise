# Lab 5: RDS & Database Services - Testing Checklist

This comprehensive checklist ensures all database components are properly configured, secured, and performing as expected. Each test includes console-based validation steps and connection testing procedures.

## Pre-Testing Requirements
- [ ] Lab 1-4 infrastructure is complete and validated
- [ ] VPC with private data subnets in multiple AZs
- [ ] EC2 instances in application tier for testing connections
- [ ] Security groups configured for database access
- [ ] Database client tools installed (MySQL Workbench, pgAdmin, or CLI tools)

---

## 🔐 Database Security Testing

### Subnet Group Configuration

#### 1. Verify DB Subnet Group Setup
- [ ] **In RDS Console:**
  - Navigate to **RDS Console** → **Subnet groups**
  - Select `terminus-db-subnet-group`
  - Verify minimum 2 subnets in different AZs
  - Confirm all subnets are private (no IGW route)

- [ ] **Validate subnet isolation:**
  ```bash
  # From application instance
  aws ec2 describe-route-tables \
    --filters "Name=association.subnet-id,Values=subnet-xxxxx" \
    --query 'RouteTables[*].Routes[?GatewayId!=`local`]'
  ```
  - ❌ Should return no routes to IGW
  - ✅ Should only have local routes

#### 2. Test Security Group Rules
- [ ] **Database security group validation:**
  - Go to **EC2 Console** → **Security Groups**
  - Select `Terminus-Database-SG`
  - Verify inbound rules:
    - MySQL/Aurora (3306) from app tier SG only
    - PostgreSQL (5432) from app tier SG only
    - No 0.0.0.0/0 rules

- [ ] **Connection matrix testing:**
  ```bash
  # From application server - should succeed
  nc -zv database-endpoint.region.rds.amazonaws.com 3306
  
  # From bastion/public subnet - should fail
  nc -zv database-endpoint.region.rds.amazonaws.com 3306
  ```

### Encryption Validation

#### 1. Verify Encryption at Rest
- [ ] **In RDS Console:**
  - Select database instance → **Configuration** tab
  - Verify "Encryption: Enabled"
  - Note KMS key ID
  - Check "Storage encrypted: Yes"

- [ ] **Validate KMS key permissions:**
  - Go to **KMS Console** → **Customer managed keys**
  - Select the encryption key
  - Verify key policy includes RDS service principal
  - Check key is in same region as database

#### 2. Test Encryption in Transit
- [ ] **SSL/TLS connection testing:**
  ```bash
  # MySQL SSL connection test
  mysql -h endpoint.rds.amazonaws.com -u admin -p \
    --ssl-mode=REQUIRED \
    -e "SHOW STATUS LIKE 'Ssl_cipher';"
  
  # PostgreSQL SSL test
  psql "host=endpoint.rds.amazonaws.com \
    user=admin dbname=postgres sslmode=require" \
    -c "SELECT ssl_is_used();"
  ```
  - ✅ Should show SSL cipher in use
  - ✅ PostgreSQL should return 't' (true)

---

## 🗄️ Database Instance Testing

### Primary Instance Validation

#### 1. Verify Instance Configuration
- [ ] **In RDS Console:**
  - Select primary instance
  - Check **Configuration** tab:
    - Instance class: db.t3.medium (or as designed)
    - Storage type: gp3 with 3000 IOPS
    - Multi-AZ: Enabled
    - Automated backups: Enabled

- [ ] **Test basic connectivity:**
  ```bash
  # Get instance endpoint
  aws rds describe-db-instances \
    --db-instance-identifier terminus-production-db \
    --query 'DBInstances[0].Endpoint'
  
  # Test connection
  mysql -h endpoint -u admin -p -e "SELECT 1;"
  ```

#### 2. Verify Database Creation
- [ ] **Create test database and tables:**
  ```sql
  -- Connect to instance
  CREATE DATABASE terminus_app;
  USE terminus_app;
  
  -- Create test table
  CREATE TABLE health_check (
    id INT PRIMARY KEY AUTO_INCREMENT,
    status VARCHAR(50),
    checked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );
  
  -- Insert test data
  INSERT INTO health_check (status) VALUES ('healthy');
  
  -- Verify
  SELECT * FROM health_check;
  ```

### Multi-AZ Failover Testing

#### 1. Verify Multi-AZ Configuration
- [ ] **Check Multi-AZ status:**
  - In RDS instance details → **Configuration** tab
  - Verify "Multi-AZ: Yes"
  - Note secondary AZ location

- [ ] **Monitor failover metrics:**
  - Go to **CloudWatch** → **Metrics** → **RDS**
  - Add widgets for:
    - DBInstance → ReadLatency
    - DBInstance → WriteLatency
    - DBInstance → DatabaseConnections

#### 2. Test Failover Process
- [ ] **Initiate manual failover:**
  - Select instance → **Actions** → **Reboot**
  - Check "Reboot with failover"
  - Click **Confirm**

- [ ] **Monitor failover progress:**
  ```bash
  # Watch instance status
  watch -n 5 'aws rds describe-db-instances \
    --db-instance-identifier terminus-production-db \
    --query "DBInstances[0].[DBInstanceStatus,AvailabilityZone]"'
  ```
  - ✅ Status changes: rebooting → available
  - ✅ AZ should change to secondary
  - ✅ Total time should be < 2 minutes

- [ ] **Verify application connectivity during failover:**
  ```bash
  # Run continuous connection test
  while true; do
    date
    mysql -h endpoint -u admin -ppassword \
      -e "SELECT NOW();" 2>&1
    sleep 1
  done
  ```
  - ✅ Brief interruption (30-60 seconds)
  - ✅ Automatic reconnection after failover

---

## 📊 Read Replica Testing

### Read Replica Creation

#### 1. Create Read Replica
- [ ] **In RDS Console:**
  - Select source database → **Actions** → **Create read replica**
  - Configure:
    - DB instance identifier: `terminus-production-db-read1`
    - Instance class: Same as primary or smaller
    - Different AZ from primary
    - Same subnet group

- [ ] **Monitor creation progress:**
  - Check **Status** column
  - Wait for "Available" status
  - Verify "Replica source" shows primary

#### 2. Test Read Replica Connectivity
- [ ] **Connect to read replica:**
  ```bash
  # Get read replica endpoint
  aws rds describe-db-instances \
    --db-instance-identifier terminus-production-db-read1 \
    --query 'DBInstances[0].Endpoint.Address'
  
  # Connect and verify read-only
  mysql -h replica-endpoint -u admin -p \
    -e "SELECT @@read_only;"
  ```
  - ✅ Should return 1 (read-only enabled)

#### 3. Verify Replication Lag
- [ ] **Check replication status:**
  ```sql
  -- On read replica
  SHOW SLAVE STATUS\G
  
  -- Check key fields:
  -- Slave_IO_Running: Yes
  -- Slave_SQL_Running: Yes
  -- Seconds_Behind_Master: < 5
  ```

- [ ] **Monitor lag in CloudWatch:**
  - Go to **CloudWatch** → **Metrics** → **RDS**
  - Select read replica → **ReplicaLag** metric
  - ✅ Should be consistently < 5 seconds

### Cross-Region Read Replica

#### 1. Create Cross-Region Replica
- [ ] **Create replica in DR region:**
  - Source: Production database (us-east-1)
  - Target region: us-west-2
  - Subnet group: Pre-created in DR region
  - Security group: Configure for cross-region access

- [ ] **Test cross-region connectivity:**
  ```bash
  # From DR region EC2 instance
  mysql -h dr-replica-endpoint -u admin -p \
    -e "SELECT NOW(), @@hostname;"
  ```

---

## 💾 Backup and Recovery Testing

### Automated Backup Validation

#### 1. Verify Backup Configuration
- [ ] **Check backup settings:**
  - Select instance → **Maintenance & backups** tab
  - Verify:
    - Backup retention: 7 days
    - Backup window: During low activity
    - Latest backup: Within last 24 hours

- [ ] **List available snapshots:**
  ```bash
  aws rds describe-db-snapshots \
    --db-instance-identifier terminus-production-db \
    --query 'DBSnapshots[*].[DBSnapshotIdentifier,SnapshotCreateTime,Status]' \
    --output table
  ```

#### 2. Test Manual Snapshot
- [ ] **Create manual snapshot:**
  - Select instance → **Actions** → **Take snapshot**
  - Snapshot name: `terminus-db-manual-test-$(date +%Y%m%d)`
  - Wait for completion

- [ ] **Verify snapshot details:**
  - Go to **Snapshots** in RDS console
  - Check snapshot status: "Available"
  - Note size and creation time

### Point-in-Time Recovery Testing

#### 1. Test PITR Capability
- [ ] **Create test data with timestamps:**
  ```sql
  -- Create test table
  CREATE TABLE pitr_test (
    id INT AUTO_INCREMENT PRIMARY KEY,
    data VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );
  
  -- Insert data with 5-minute intervals
  INSERT INTO pitr_test (data) VALUES ('Record 1');
  -- Wait 5 minutes
  INSERT INTO pitr_test (data) VALUES ('Record 2');
  -- Wait 5 minutes
  INSERT INTO pitr_test (data) VALUES ('Record 3');
  ```

- [ ] **Perform point-in-time restore:**
  - Select instance → **Actions** → **Restore to point in time**
  - Choose specific time (between Record 2 and 3)
  - New instance identifier: `terminus-db-pitr-test`
  - Same configuration as source

- [ ] **Verify restored data:**
  ```sql
  -- Connect to restored instance
  SELECT * FROM pitr_test;
  -- Should show only Record 1 and 2, not 3
  ```

### Snapshot Restore Testing

#### 1. Restore from Snapshot
- [ ] **Restore process:**
  - Go to **Snapshots** → Select snapshot
  - **Actions** → **Restore snapshot**
  - New identifier: `terminus-db-restored-test`
  - Verify all settings match original

- [ ] **Validate restored database:**
  ```bash
  # Compare data between original and restored
  # Original
  mysql -h original-endpoint -u admin -p \
    -e "SELECT COUNT(*) FROM terminus_app.health_check;"
  
  # Restored
  mysql -h restored-endpoint -u admin -p \
    -e "SELECT COUNT(*) FROM terminus_app.health_check;"
  ```
  - ✅ Counts should match

---

## 🚀 Performance Testing

### Baseline Performance Metrics

#### 1. Establish Performance Baseline
- [ ] **Run sysbench tests:**
  ```bash
  # Install sysbench on test instance
  sudo yum install -y sysbench
  
  # Prepare test database
  sysbench oltp_read_write \
    --mysql-host=endpoint \
    --mysql-user=admin \
    --mysql-password=password \
    --mysql-db=test \
    --tables=10 \
    --table-size=100000 \
    prepare
  
  # Run benchmark
  sysbench oltp_read_write \
    --mysql-host=endpoint \
    --mysql-user=admin \
    --mysql-password=password \
    --mysql-db=test \
    --tables=10 \
    --table-size=100000 \
    --threads=16 \
    --time=300 \
    run
  ```

- [ ] **Record baseline metrics:**
  - Transactions per second: _______
  - Average latency: _______ ms
  - 95th percentile latency: _______ ms

#### 2. Monitor Performance Insights
- [ ] **Enable Performance Insights:**
  - Select instance → **Modify**
  - Enable Performance Insights
  - Retention: 7 days (free tier)
  - Apply immediately

- [ ] **Review performance data:**
  - Click **Performance Insights** in instance details
  - Check:
    - Top SQL statements
    - Wait events
    - Database load

### Storage Performance Testing

#### 1. Test Storage IOPS
- [ ] **Verify gp3 performance:**
  ```sql
  -- Create large table for IO testing
  CREATE TABLE io_test (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    data VARCHAR(255),
    padding CHAR(200)
  );
  
  -- Insert large dataset
  INSERT INTO io_test (data, padding)
  SELECT 
    CONCAT('Test data ', n),
    REPEAT('X', 200)
  FROM (
    SELECT a.N + b.N * 10 + c.N * 100 AS n
    FROM 
      (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) a,
      (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) b,
      (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) c
  ) numbers;
  ```

- [ ] **Monitor IOPS in CloudWatch:**
  - Check **ReadIOPS** and **WriteIOPS** metrics
  - ✅ Should see up to 3000 IOPS (gp3 baseline)

#### 2. Test Storage Auto-scaling
- [ ] **Fill storage to trigger auto-scaling:**
  - Monitor **FreeStorageSpace** metric
  - When < 10% free, auto-scaling should trigger
  - ✅ Storage should increase automatically
  - ✅ No downtime during scaling

---

## 📈 Monitoring and Alerting

### CloudWatch Alarms Configuration

#### 1. Create Critical Alarms
- [ ] **High CPU alarm:**
  - Metric: CPUUtilization > 80%
  - Period: 5 minutes
  - Evaluation: 2 consecutive periods
  - Action: SNS notification

- [ ] **Storage space alarm:**
  - Metric: FreeStorageSpace < 10%
  - Period: 5 minutes
  - Action: SNS notification + Auto-scaling

- [ ] **Read replica lag alarm:**
  - Metric: ReplicaLag > 30 seconds
  - Period: 5 minutes
  - Action: SNS notification

#### 2. Test Alarm Functionality
- [ ] **Trigger test alarm:**
  ```sql
  -- Generate high CPU load
  SELECT BENCHMARK(100000000, MD5('test'));
  ```
  - ✅ Should receive SNS notification
  - ✅ Check CloudWatch alarm state change

### Enhanced Monitoring Validation

#### 1. Verify Enhanced Monitoring
- [ ] **Check metrics availability:**
  - Go to instance → **Monitoring** tab
  - Select "Enhanced monitoring"
  - Verify OS-level metrics:
    - CPU utilization by process
    - Memory usage
    - File system usage
    - Process list

---

## 🔄 High Availability Testing

### Connection Failover Testing

#### 1. Test Application Resilience
- [ ] **Configure connection retry:**
  ```python
  # Python example with retry logic
  import pymysql
  from time import sleep
  
  def get_connection():
      retries = 5
      while retries > 0:
          try:
              return pymysql.connect(
                  host='endpoint.rds.amazonaws.com',
                  user='admin',
                  password='password',
                  database='terminus_app',
                  connect_timeout=5
              )
          except Exception as e:
              print(f"Connection failed: {e}")
              retries -= 1
              sleep(2)
      raise Exception("Could not connect after retries")
  ```

- [ ] **Test during maintenance:**
  - Schedule minor version upgrade
  - Run connection test during upgrade
  - ✅ Application should reconnect automatically

### Disaster Recovery Testing

#### 1. Simulate Region Failure
- [ ] **Promote read replica to standalone:**
  - Select cross-region replica
  - **Actions** → **Promote read replica**
  - Wait for promotion completion

- [ ] **Update application endpoints:**
  ```bash
  # Test connection to promoted instance
  mysql -h promoted-endpoint -u admin -p \
    -e "SELECT @@read_only;"
  ```
  - ✅ Should return 0 (read-write enabled)

#### 2. Test Backup Restoration in DR Region
- [ ] **Copy snapshot to DR region:**
  - Select snapshot → **Actions** → **Copy snapshot**
  - Destination region: us-west-2
  - Encryption: Use default key in destination

- [ ] **Restore in DR region:**
  - Switch to DR region console
  - Restore copied snapshot
  - Verify data integrity

---

## ✅ Final Validation Checklist

### Security Validation
- [ ] All databases in private subnets only
- [ ] No public accessibility enabled
- [ ] Encryption at rest verified
- [ ] SSL/TLS connections enforced
- [ ] Security groups follow least privilege

### High Availability Validation
- [ ] Multi-AZ deployment active
- [ ] Automated backups running daily
- [ ] Read replicas synchronized
- [ ] Cross-region replica operational
- [ ] Failover tested successfully

### Performance Validation
- [ ] Baseline metrics documented
- [ ] Performance Insights enabled
- [ ] IOPS meeting requirements
- [ ] Storage auto-scaling tested
- [ ] No performance bottlenecks identified

### Monitoring Validation
- [ ] All CloudWatch alarms active
- [ ] Enhanced monitoring enabled
- [ ] SNS notifications working
- [ ] Metrics retention appropriate
- [ ] Dashboard created for monitoring

### Documentation
- [ ] Connection strings documented
- [ ] Failover procedures written
- [ ] Recovery time objectives met
- [ ] Backup/restore procedures tested
- [ ] Runbooks updated

---

*Testing completed on: ________________*  
*Tested by: ________________*  
*All tests passed: Yes ☐ No ☐*