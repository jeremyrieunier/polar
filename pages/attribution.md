# Ecommerce Attribution
For the following exercices I first cleaned the csv file you provided using Python and converted it into a JSONL file. Thank you Sonnet 3.7. Then I uploaded the file into a GCP bucket before creating a dataset in BigQuery.

## Number of orders per month per store

```sql monthly_orders
with order_events as (
    select *
    from growth.order_events
),

monthly_orders as (
    select
        store,
        order_month,
        count(distinct order_id) AS order_count,
        round(sum(order_total), 2) AS total_revenue,
        round(sum(order_total) / count(distinct order_id), 2) as avg_order_value
    from order_events
    where row_num = 1
    group by store, order_month 
    order by store, strptime(order_month, '%b %Y')
)

SELECT *
FROM monthly_orders
```

<BarChart 
    data={monthly_orders} 
    x=order_month 
    y=total_revenue
    yFmt=usd0k
    y2Fmt=usd
    y2=avg_order_value
    y2SeriesType=line
    sort=false
    seriesOrder=order_month
    chartAreaHeight=350
/>

### Key findings
- Strong seasonal pattern with peak revenue during Nov-Dec 2022 holiday season (BFCM + Christmas)
- Significant drop in Jan 2023 showing typical post-holiday slump
- AOV highest during Nov-Dec ($251) and dropped to ~$205 in Jan-Feb as customers were likely more price-sensitive
- Gradual recovery in both order volume and AOV through Spring 2023

<Details title="Query used to calculate the number of orders per month per store">

```sql
WITH orders AS (
  SELECT 
    REGEXP_REPLACE(shopifyShopURL, '^https?://|/$', '') AS store,
    shopifyOrderId AS order_id,
    DATE(shopifyOrderProcessedAt) AS order_date,
    FORMAT_DATE('%b %Y', DATE(shopifyOrderProcessedAt)) as order_month,
    shopifyOrderTotalPrice AS order_total,
    ROW_NUMBER() OVER(PARTITION BY shopifyOrderId ORDER BY shopifyOrderProcessedAt) AS row_num
  FROM `polar-455513.growth.pixeldata`
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

```

It also addresses several important data quality considerations:

1. Normalizes store URLs to ensure consistent grouping regardless of URL format
2. Filters for actual conversion events using the `thank_you` page path, avoiding duplicate counting from order status checks
3. Deduplicates multiple pixel events for the same order ID by using ROW_NUMBER() and selecting only the first occurrence
4. Takes the earliest order record when multiple events exist, ensuring consistent handling of duplicates
5. Calculates key metrics like order count, total revenue, and average order value

</Details>

## Attribution modelling
Before choosing an attribution model I want to know many touchpoints users have before conversion using a 30-day windows. I'm using this windows arbitraly since the main product of this store is Milk Maker with historical AOV of this store is between 200 - 250 USD. My guess is that it's not an impulse buy and customers might visit the store over a few days before placing an order.

First let's use the previous query we've used to find out all unique orders:

```sql
WITH orders AS (
  SELECT 
    shopifyOrderId AS order_id,
    TIMESTAMP_MILLIS(CAST(timestamp AS INT64)) AS order_timestamp,
    ip,
    ROW_NUMBER() OVER(PARTITION BY shopifyOrderId ORDER BY shopifyOrderProcessedAt) AS row_num
  FROM `polar-455513.growth.pixeldata`
  WHERE shopifyOrderId IS NOT NULL
    AND pagePath LIKE '%/thank_you'
)
```

Then let's add a CTE to get all pageviews within 30 days before each order:

```sql
pre_purchase_events AS (
  SELECT
    o.order_id AS shopifyOrderId,
    o.order_timestamp,
    o.ip,
    p.timestamp AS event_timestamp,
    TIMESTAMP_MILLIS(CAST(p.timestamp AS INT64)) AS event_timestamp_formatted,
    p.sessionId,
    COALESCE(p.utmSource, 
      CASE 
        WHEN p.pageReferrer IS NULL OR p.pageReferrer = '' THEN 'direct'
        ELSE REGEXP_EXTRACT(p.pageReferrer, 'http[s]?://([^/]*)') 
      END) AS source
  FROM orders o
  JOIN `polar-455513.growth.pixeldata` p
    ON o.ip = p.ip
    AND TIMESTAMP_MILLIS(CAST(p.timestamp AS INT64)) <= o.order_timestamp
    AND TIMESTAMP_MILLIS(CAST(p.timestamp AS INT64)) >= TIMESTAMP_SUB(o.order_timestamp, INTERVAL 30 DAY)
  WHERE o.row_num = 1
)
```

Then another CTE to add previous timstramp using a `LAG()` function to calculate gaps for session grouping:

```sql
with_prev_timestamp AS (
  SELECT
    *,
    LAG(event_timestamp_formatted) OVER(PARTITION BY shopifyOrderId, ip ORDER BY event_timestamp) AS prev_timestamp
  FROM pre_purchase_events
)
```

Then 2 more CTEs to mark session boundaries with a gap superior at 30 minutes then create session groups by cumulative sum of boundaries:

```sql
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

session_groups AS (
  SELECT
    *,
    SUM(is_new_session) OVER(PARTITION BY shopifyOrderId, ip ORDER BY event_timestamp) AS session_number
  FROM session_boundaries
)
```

Let's check that everything is working using the order id `4543812534424`:

```sql check
select
    ip,
    sessionId,
    pagePath,
    source,
    is_new_session,
    session_number
from growth.orders_with_prev_timestamp
where shopifyOrderId = '4543812534424'
```

We can see that this customers had 3 distinct sessions over 3 days before purchasing:

- Session 1: January 8th - Browsed the glass jug and milk machine products
- Session 2: January 9th - Looked at the milk machine again and almonds
- Session 3: January 11th - Started from Facebook, used a discount code, viewed multiple products, and finally purchased.

Now we could finish 