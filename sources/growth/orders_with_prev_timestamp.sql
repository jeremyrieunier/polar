with orders as (
    select
        shopifyOrderId as order_id,
        timestamp_millis(cast(timestamp as INT64)) AS order_timestamp,
        shopifyOrderProcessedAt AS order_datetime,
        shopifyOrderTotalPrice AS order_total,
        ip,
        format_date('%b %Y', date(shopifyOrderProcessedAt)) as order_month,
        row_number() over(partition by shopifyOrderId order by shopifyOrderProcessedAt) as row_num
    from growth.pixeldata
    where shopifyOrderId is not null
        and pagePath like '%/thank_you'
),

-- Step 2: Get all pageviews within 30 days before each order
pre_purchase_events AS (
  SELECT
    o.order_id AS shopifyOrderId,
    o.order_timestamp,
    o.ip,
    p.timestamp AS event_timestamp,
    TIMESTAMP_MILLIS(CAST(p.timestamp AS INT64)) AS event_timestamp_formatted,
    p.sessionId,
    p.pagePath,
    p.utmSource,
    p.pageReferrer,
    COALESCE(p.utmSource, 
      CASE 
        WHEN p.pageReferrer IS NULL OR p.pageReferrer = '' OR p.pageReferrer LIKE '%almondcow.co%' THEN 'direct' 
        ELSE REGEXP_EXTRACT(p.pageReferrer, 'http[s]?://([^/]*)') 
      END) AS source
  FROM orders o
  JOIN `polar-455513.growth.pixeldata` p
    ON o.ip = p.ip
    AND TIMESTAMP_MILLIS(CAST(p.timestamp AS INT64)) <= o.order_timestamp
    AND TIMESTAMP_MILLIS(CAST(p.timestamp AS INT64)) >= TIMESTAMP_SUB(o.order_timestamp, INTERVAL 30 DAY)
  WHERE o.row_num = 1
),
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
)

SELECT *
FROM session_groups