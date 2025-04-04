-- Step 1: Identify all orders with their IP addresses (with deduplication)
WITH order_events AS (
  SELECT
    shopifyOrderId,
    TIMESTAMP_MILLIS(CAST(timestamp AS INT64)) AS order_timestamp,
    DATE(shopifyOrderProcessedAt) AS order_datetime,
    shopifyOrderTotalPrice AS order_total,
    ip,
    ROW_NUMBER() OVER(PARTITION BY shopifyOrderId ORDER BY timestamp) AS row_num
  FROM growth.pixeldata
  WHERE 
    shopifyOrderId IS NOT NULL
    AND pagePath LIKE '%/thank_you'
    AND DATE(shopifyOrderProcessedAt) >= '2023-01-01'  -- Only include orders from January 1, 2023
),

-- Filter to include only unique orders
unique_orders AS (
  SELECT
    shopifyOrderId,
    order_timestamp,
    order_datetime,
    order_total,
    ip
  FROM order_events
  WHERE row_num = 1
),

-- Step 2: Get all pageviews within 30 days before each order
pre_purchase_events AS (
  SELECT
    o.shopifyOrderId,
    o.order_timestamp,
    o.order_datetime,
    o.order_total,
    o.ip,
    p.timestamp AS event_timestamp,
    TIMESTAMP_MILLIS(CAST(p.timestamp AS INT64)) AS event_timestamp_formatted,
    p.pagePath,
    p.utmSource,
    p.pageReferrer,
    COALESCE(p.utmSource, 
      CASE 
        WHEN p.pageReferrer IS NULL OR p.pageReferrer = '' OR p.pageReferrer LIKE '%almondcow.co%' THEN 'direct'
        ELSE REGEXP_EXTRACT(REGEXP_EXTRACT(p.pageReferrer, 'http[s]?://([^/]*)'), '([^.]+\\.[^.]+)$') 
      END) AS source
  FROM unique_orders o
  JOIN `polar-455513.growth.pixeldata` p
    ON o.ip = p.ip
    AND TIMESTAMP_MILLIS(CAST(p.timestamp AS INT64)) <= o.order_timestamp
    AND TIMESTAMP_MILLIS(CAST(p.timestamp AS INT64)) >= TIMESTAMP_SUB(o.order_timestamp, INTERVAL 30 DAY)
),

-- Step 3: Add previous timestamp to calculate gaps for session grouping
with_prev_timestamp AS (
  SELECT
    *,
    LAG(event_timestamp_formatted) OVER(PARTITION BY shopifyOrderId, ip ORDER BY event_timestamp) AS prev_timestamp
  FROM pre_purchase_events
),

-- Step 4: Mark session boundaries where gap > 30 minutes
session_boundaries AS (
  SELECT
    *,
    CASE 
      WHEN prev_timestamp IS NULL OR 
           TIMESTAMP_DIFF(event_timestamp_formatted, prev_timestamp, SECOND) > 1800 
      THEN 1 
      ELSE 0 
    END AS is_new_session
  FROM with_prev_timestamp
),

-- Step 5: Create session groups by cumulative sum of boundaries
session_groups AS (
  SELECT
    *,
    SUM(is_new_session) OVER(PARTITION BY shopifyOrderId, ip ORDER BY event_timestamp) AS session_number
  FROM session_boundaries
),

-- Step 6: Get first interaction of each session to determine source
session_sources AS (
  SELECT
    shopifyOrderId,
    ip,
    session_number,
    ARRAY_AGG(source ORDER BY event_timestamp ASC LIMIT 1)[OFFSET(0)] AS session_source,
    MIN(event_timestamp_formatted) AS session_start,
    MAX(event_timestamp_formatted) AS session_end,
    COUNT(*) AS interactions_in_session
  FROM session_groups
  GROUP BY shopifyOrderId, ip, session_number
),

-- Step 7: Count sessions per order
session_counts_per_order AS (
  SELECT
    shopifyOrderId,
    COUNT(*) AS session_count,
    STRING_AGG(session_source, ' > ' ORDER BY session_start) AS source_path
  FROM session_sources
  GROUP BY shopifyOrderId
),

-- Step 8: Create distribution of session counts
session_distribution AS (
  SELECT
    CASE 
      WHEN session_count >= 5 THEN '5+'
      ELSE CAST(session_count AS STRING)
    END AS session_count_group,
    COUNT(*) AS order_count,
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS percentage
  FROM session_counts_per_order
  GROUP BY session_count_group
)

-- Final results: Distribution of session counts
SELECT * FROM session_distribution
ORDER BY 
  CASE 
    WHEN session_count_group = '5+' THEN 5
    ELSE CAST(session_count_group AS INT64)
  END
