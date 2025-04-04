WITH orders AS (
  SELECT 
    REGEXP_REPLACE(shopifyShopURL, '^https?://|/$', '') AS store,
    shopifyOrderId AS order_id,
    DATE(shopifyOrderProcessedAt) AS order_date,
    FORMAT_DATE('%b %Y', DATE(shopifyOrderProcessedAt)) as order_month,
    shopifyOrderTotalPrice AS order_total,
    ROW_NUMBER() OVER(PARTITION BY shopifyOrderId ORDER BY shopifyOrderProcessedAt) AS row_num
  FROM growth.pixeldata
  WHERE shopifyOrderId IS NOT NULL
    AND pagePath LIKE '%/thank_you'
),

monthly_orders AS (
  SELECT
    store,
    order_month,
    COUNT(*) AS order_count,
    ROUND(SUM(order_total), 2) AS total_revenue,
    ROUND(SUM(order_total) / COUNT(*), 2) AS avg_order_value
  FROM orders
  WHERE row_num = 1
  GROUP BY store, order_month
  ORDER BY store, PARSE_DATE('%b %Y', order_month)
)

SELECT * FROM monthly_orders