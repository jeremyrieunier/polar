-- Step 1: Identify all orders with their IP addresses (with deduplication and date filter)
WITH order_events AS (
  SELECT
    shopifyOrderId,
    TIMESTAMP_MILLIS(CAST(timestamp AS INT64)) AS order_timestamp,
    shopifyOrderProcessedAt AS order_datetime,
    shopifyOrderTotalPrice AS order_total,
    FORMAT_DATE('%Y-%m', DATE(shopifyOrderProcessedAt)) AS order_month,
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
    order_month,
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
    o.order_month,
    o.ip,
    p.timestamp AS event_timestamp,
    TIMESTAMP_MILLIS(CAST(p.timestamp AS INT64)) AS event_timestamp_formatted,
    p.sessionId,
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
    order_total,
    order_month,
    ip,
    session_number,
    ARRAY_AGG(source ORDER BY event_timestamp ASC LIMIT 1)[OFFSET(0)] AS session_source,
    MIN(event_timestamp_formatted) AS session_start
  FROM session_groups
  GROUP BY shopifyOrderId, order_total, order_month, ip, session_number
),

-- Step 7: Find first touch source for each order
first_touch_sources AS (
  SELECT
    shopifyOrderId,
    MIN(session_start) AS min_start_time
  FROM session_sources
  GROUP BY shopifyOrderId
),

first_touch AS (
  SELECT
    s.shopifyOrderId,
    s.session_source AS first_touch_source
  FROM session_sources s
  INNER JOIN first_touch_sources f 
    ON s.shopifyOrderId = f.shopifyOrderId 
    AND s.session_start = f.min_start_time
),

-- Step 8: Find last touch source for each order
last_touch_sources AS (
  SELECT
    shopifyOrderId,
    MAX(session_start) AS max_start_time
  FROM session_sources
  GROUP BY shopifyOrderId
),

last_touch AS (
  SELECT
    s.shopifyOrderId,
    s.session_source AS last_touch_source
  FROM session_sources s
  INNER JOIN last_touch_sources l 
    ON s.shopifyOrderId = l.shopifyOrderId 
    AND s.session_start = l.max_start_time
),

-- Step 9: Count sessions per order
session_counts AS (
  SELECT
    shopifyOrderId,
    COUNT(*) AS session_count
  FROM session_sources
  GROUP BY shopifyOrderId
),

-- Step 10: Create session-level detail with attribution weights
session_attribution_raw AS (
  SELECT
    s.shopifyOrderId,
    s.order_total,
    s.order_month,
    s.session_number,
    s.session_source,
    c.session_count,
    f.first_touch_source,
    l.last_touch_source,
    CASE
      WHEN c.session_count = 1 THEN 1.0  -- 100% to single source
      WHEN s.session_source = f.first_touch_source AND s.session_source = l.last_touch_source THEN 
        CASE 
          WHEN c.session_count = 1 THEN 1.0  -- It's both first and last because it's the only touchpoint
          ELSE 0.8  -- It gets both the first-touch (0.4) and last-touch (0.4) weights
        END
      WHEN s.session_source = f.first_touch_source THEN 0.4  -- 40% to first touch
      WHEN s.session_source = l.last_touch_source THEN 0.4  -- 40% to last touch
      ELSE 
        CASE
          WHEN c.session_count > 2 THEN 0.2 / (c.session_count - 2)  -- Distribute 20% evenly across middle touchpoints
          ELSE 0  -- No middle touchpoints in a 2-session journey
        END
    END AS attribution_weight
  FROM session_sources s
  JOIN session_counts c ON s.shopifyOrderId = c.shopifyOrderId
  JOIN first_touch f ON s.shopifyOrderId = f.shopifyOrderId
  JOIN last_touch l ON s.shopifyOrderId = l.shopifyOrderId
),

-- Step 11: Normalize weights to ensure they sum to exactly 1.0 per order
session_attribution AS (
  SELECT
    *,
    attribution_weight / NULLIF(SUM(attribution_weight) OVER (PARTITION BY shopifyOrderId), 0) AS normalized_weight
  FROM session_attribution_raw
)

SELECT
  'Total Revenue' AS metric,
  SUM(order_total) AS amount
FROM unique_orders

UNION ALL

SELECT
  'Attributed Revenue' AS metric,
  SUM(normalized_weight * order_total) AS amount
FROM session_attribution