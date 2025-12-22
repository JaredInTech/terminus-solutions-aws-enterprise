<!--
Terminus Solutions AWS Enterprise Architecture
Copyright (c) 2025 Jared (Terminus Solutions) - jaredintech.com
Licensed under CC BY-SA 4.0 - Attribution required
See LICENSE-DOCS for details
-->

# ADR-020: Caching Strategy

## Date
2025-12-22

## Status
Accepted

## Context
With our database platform, high availability, and security frameworks established (ADR-017 through ADR-019), Terminus Solutions needs to implement a caching strategy to optimize performance and reduce database load. This decision determines our approach to in-memory caching, cache invalidation, and integration with our database architecture.

Key requirements and constraints:
- Must reduce database query load by at least 50%
- Require sub-millisecond response times for cached data
- Need high availability for caching layer
- Support cache invalidation on data updates
- Integrate with existing VPC and security architecture
- Minimize complexity while maximizing performance gains
- Support both key-value and structured data caching
- Budget conscious—optimize cost vs. performance
- Enable horizontal scaling as traffic grows

Current performance challenges:
- Repeated queries for same data hit primary database
- Reporting queries compete with transactional workloads
- Session lookups add latency to every request
- No query result caching between requests
- Database CPU utilization spikes during peak hours

## Decision
We will implement Amazon ElastiCache for Redis as our primary caching layer, using a cache-aside pattern for query results and direct Redis storage for session data, with automatic failover for high availability.

**Caching Architecture:**
```
                    ┌──────────────────────────────────────────────────────────┐
                    │                   Application Tier                        │
                    │                                                          │
                    │  ┌────────────────────────────────────────────────────┐  │
                    │  │              Cache-Aside Pattern                   │  │
                    │  │                                                    │  │
                    │  │  1. Check cache  ──────────────────────┐           │  │
                    │  │       │                                │           │  │
                    │  │       ▼                                ▼           │  │
                    │  │  ┌─────────┐                    ┌──────────┐       │  │
                    │  │  │ Cache   │ ←── Cache Miss ──→ │ Database │       │  │
                    │  │  │ (Redis) │                    │ (MySQL)  │       │  │
                    │  │  └────┬────┘                    └────┬─────┘       │  │
                    │  │       │                              │             │  │
                    │  │       │ 2. Cache Hit                 │ 3. Query   │  │
                    │  │       │    (sub-ms)                  │    + Cache │  │
                    │  │       ▼                              ▼             │  │
                    │  │  ┌─────────────────────────────────────────────┐   │  │
                    │  │  │              Application Response           │   │  │
                    │  │  └─────────────────────────────────────────────┘   │  │
                    │  └────────────────────────────────────────────────────┘  │
                    └──────────────────────────────────────────────────────────┘

                    ┌──────────────────────────────────────────────────────────┐
                    │                   ElastiCache Cluster                     │
                    │                                                          │
                    │  ┌──────────────────┐    ┌──────────────────┐            │
                    │  │  Primary Node    │───▶│  Replica Node    │            │
                    │  │  (us-east-1a)    │    │  (us-east-1b)    │            │
                    │  │  Read + Write    │    │  Read-only       │            │
                    │  └──────────────────┘    └──────────────────┘            │
                    │                                                          │
                    │  Automatic Failover: Replica promoted on primary failure │
                    └──────────────────────────────────────────────────────────┘
```

**Caching Strategy by Data Type:**

| Data Type | Cache Location | TTL | Invalidation | Priority |
|-----------|---------------|-----|--------------|----------|
| User Sessions | DynamoDB + Redis | 24h | On logout | Critical |
| Query Results | Redis | 5-60 min | On data change | High |
| Reference Data | Redis | 24h | On update | Medium |
| Computed Results | Redis | 15-30 min | Time-based | Medium |
| Static Content | CloudFront | 1 year | On deploy | Low |

**Cache Key Strategy:**
```
Key Format: {namespace}:{entity}:{identifier}:{version}

Examples:
- user:profile:12345:v1
- product:list:category_electronics:v2
- query:dashboard_stats:2025-12-22:v1
- session:user:abc123:v1
```

## Consequences

### Positive
- **Performance Improvement**: 75% reduction in database queries
- **Sub-Millisecond Latency**: Redis provides <1ms response times
- **Database Offloading**: Primary database handles only cache misses
- **Scalability**: Cache layer scales independently of database
- **High Availability**: Automatic failover with replica
- **Flexibility**: Supports multiple data structures (strings, hashes, lists)
- **Cost Efficiency**: Reduces need for larger database instances

### Negative
- **Data Staleness**: Cached data may be outdated briefly
- **Complexity**: Cache invalidation logic required
- **Additional Infrastructure**: Another service to manage
- **Memory Limits**: Cache size bounded by instance memory
- **Cold Start**: Empty cache after restart impacts performance

### Mitigation Strategies
- **TTL Tuning**: Set appropriate expiration for each data type
- **Invalidation Events**: Publish cache invalidation on writes
- **Cache Warming**: Pre-populate cache after deployments
- **Memory Monitoring**: Alerts before memory exhaustion
- **Fallback**: Application gracefully handles cache unavailability

## Alternatives Considered

### 1. Application-Level Caching Only
**Rejected because:**
- Not shared across application instances
- Memory consumed on application servers
- Cache lost on instance termination
- No high availability
- Doesn't scale with Auto Scaling

### 2. Memcached Instead of Redis
**Rejected because:**
- No persistence or replication
- Limited data structures
- No pub/sub for invalidation
- No automatic failover
- Less operational visibility

### 3. DAX (DynamoDB Accelerator)
**Rejected because:**
- Only works with DynamoDB
- Cannot cache RDS queries
- Higher cost for use case
- Limited to DynamoDB access patterns
- Less flexible than Redis

### 4. Read Replicas Only (No Cache)
**Rejected because:**
- Still requires database query per request
- Higher latency than in-memory cache
- More expensive to scale
- Cannot cache computed results
- Limited to database data

### 5. CloudFront with Lambda@Edge
**Rejected because:**
- Not suitable for user-specific data
- Complex for dynamic content
- Higher latency than local cache
- Better for static content only
- Over-engineered for this use case

## Implementation Details

### ElastiCache Configuration
```yaml
ElastiCache Redis Cluster:
  Cluster ID: terminus-redis-cache
  Engine: Redis 7.0
  Node Type: cache.t3.micro
  Number of Nodes: 2 (primary + replica)
  
  Multi-AZ: Enabled
  Auto Failover: Enabled
  
  Subnet Group: terminus-cache-subnet-group
  Security Group: terminus-elasticache-sg
  
  Parameter Group:
    maxmemory-policy: allkeys-lru
    timeout: 300
    
  Encryption:
    At Rest: Enabled (KMS)
    In Transit: Enabled (TLS)
    
  Maintenance Window: sun:03:00-sun:04:00
  Snapshot Window: 02:00-03:00
  Snapshot Retention: 1 day
```

### Cache-Aside Implementation
```python
import redis
import json
import hashlib

class CacheService:
    def __init__(self, redis_client, default_ttl=300):
        self.redis = redis_client
        self.default_ttl = default_ttl
    
    def get_or_compute(self, key, compute_fn, ttl=None):
        """Cache-aside pattern implementation"""
        # Try cache first
        cached = self.redis.get(key)
        if cached:
            return json.loads(cached)
        
        # Cache miss - compute and store
        result = compute_fn()
        self.redis.setex(
            key, 
            ttl or self.default_ttl, 
            json.dumps(result)
        )
        return result
    
    def invalidate(self, pattern):
        """Invalidate keys matching pattern"""
        keys = self.redis.keys(pattern)
        if keys:
            self.redis.delete(*keys)
    
    def generate_key(self, namespace, entity, identifier, **kwargs):
        """Generate consistent cache key"""
        params_hash = hashlib.md5(
            json.dumps(kwargs, sort_keys=True).encode()
        ).hexdigest()[:8]
        return f"{namespace}:{entity}:{identifier}:{params_hash}"
```

### Session Caching Pattern
```python
class SessionStore:
    """Hybrid session storage with DynamoDB and Redis"""
    
    def get_session(self, session_id):
        # Check Redis first (hot cache)
        session = self.redis.get(f"session:{session_id}")
        if session:
            return json.loads(session)
        
        # Fallback to DynamoDB (persistent)
        response = self.dynamodb.get_item(
            TableName='TerminusUserSessions',
            Key={'session_id': {'S': session_id}}
        )
        
        if 'Item' in response:
            session = self._deserialize(response['Item'])
            # Warm Redis cache
            self.redis.setex(
                f"session:{session_id}",
                3600,  # 1 hour hot cache
                json.dumps(session)
            )
            return session
        
        return None
    
    def set_session(self, session_id, data, ttl=86400):
        # Write to both DynamoDB and Redis
        self.dynamodb.put_item(
            TableName='TerminusUserSessions',
            Item=self._serialize(session_id, data, ttl)
        )
        self.redis.setex(
            f"session:{session_id}",
            min(ttl, 3600),  # Redis TTL capped at 1 hour
            json.dumps(data)
        )
```

### Cache Invalidation Events
```python
class CacheInvalidator:
    """Event-driven cache invalidation"""
    
    def on_user_update(self, user_id):
        """Invalidate all user-related cache entries"""
        patterns = [
            f"user:profile:{user_id}:*",
            f"user:preferences:{user_id}:*",
            f"query:*:user_{user_id}:*"
        ]
        for pattern in patterns:
            self.cache.invalidate(pattern)
    
    def on_product_update(self, product_id, category_id):
        """Invalidate product and related caches"""
        self.cache.invalidate(f"product:detail:{product_id}:*")
        self.cache.invalidate(f"product:list:category_{category_id}:*")
        self.cache.invalidate("product:featured:*")
```

### Monitoring Configuration
```yaml
CloudWatch Alarms:
  Cache Hit Ratio:
    Metric: CacheHitRate
    Threshold: < 80%
    Period: 300 seconds
    Action: SNS notification
    
  Memory Usage:
    Metric: DatabaseMemoryUsagePercentage
    Threshold: > 80%
    Period: 60 seconds
    Action: SNS notification
    
  Evictions:
    Metric: Evictions
    Threshold: > 100 per minute
    Period: 60 seconds
    Action: SNS notification
    
  Replication Lag:
    Metric: ReplicationLag
    Threshold: > 1 second
    Period: 60 seconds
    Action: SNS notification
```

### Performance Benchmarks
```
Expected Performance:

Cache Hit (Redis):
├── Latency: <1ms (p99)
├── Throughput: 100,000+ ops/sec
└── Memory: ~0.5 GB for 1M keys

Cache Miss (Database):
├── Latency: 5-15ms (p99)
├── Query execution + cache write
└── Acceptable for cold data

Target Metrics:
├── Cache Hit Rate: >80%
├── Database Query Reduction: >75%
├── Response Time Improvement: 5-10x for cached data
└── Database CPU Reduction: >40%
```

## Implementation Timeline

### Phase 1: Infrastructure Setup (Week 1)
- [ ] Create ElastiCache subnet group
- [ ] Configure security groups
- [ ] Deploy Redis cluster with replica
- [ ] Enable encryption at rest and in transit

### Phase 2: Basic Caching (Week 1-2)
- [ ] Implement cache service class
- [ ] Add caching for user profiles
- [ ] Add caching for reference data
- [ ] Set up cache key strategy

### Phase 3: Advanced Patterns (Week 2-3)
- [ ] Implement session caching
- [ ] Add query result caching
- [ ] Build cache invalidation events
- [ ] Create cache warming scripts

### Phase 4: Monitoring and Tuning (Week 3-4)
- [ ] Configure CloudWatch alarms
- [ ] Create performance dashboard
- [ ] Tune TTL values based on metrics
- [ ] Document caching patterns

**Total Implementation Time:** 4 weeks

## Related Implementation
This decision was implemented in [Lab 5: RDS & Database Services](../../labs/lab-05-rds/README.md), which includes:
- ElastiCache Redis cluster deployment
- Security group configuration
- Encryption configuration
- Monitoring setup

## Success Metrics
- **Cache Hit Rate**: >80% for query caching
- **Latency Improvement**: <1ms for cached responses (vs. 10ms uncached)
- **Database Load Reduction**: >50% reduction in query volume
- **Memory Efficiency**: <70% memory utilization
- **Availability**: 99.95% cache availability

## Review Date
2026-06-22 (6 months) - Review cache performance and sizing

## References
- [ElastiCache for Redis](https://aws.amazon.com/elasticache/redis/)
- [Caching Strategies](https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/Strategies.html)
- [Redis Best Practices](https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/BestPractices.html)
- [Cache-Aside Pattern](https://docs.microsoft.com/en-us/azure/architecture/patterns/cache-aside)

## Appendix: Cache Strategy Decision Matrix

| Criteria | Redis | Memcached | DAX | App Cache |
|----------|-------|-----------|-----|-----------|
| Data Structures | ✅ Rich | ⚠️ Basic | ⚠️ Basic | ⚠️ Basic |
| Persistence | ✅ Yes | ❌ No | ⚠️ N/A | ❌ No |
| Replication | ✅ Yes | ❌ No | ✅ Yes | ❌ No |
| Pub/Sub | ✅ Yes | ❌ No | ❌ No | ❌ No |
| Multi-AZ | ✅ Yes | ❌ No | ✅ Yes | ❌ No |
| RDS Caching | ✅ Yes | ✅ Yes | ❌ No | ✅ Yes |
| **Score** | **6/6** | **2/6** | **3/6** | **2/6** |

---

*This decision will be revisited if:*
- Cache hit rate drops below 70%
- Memory requirements exceed current instance capacity
- Need for Redis cluster mode (sharding)
- Global caching requirements emerge
