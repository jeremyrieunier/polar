# Ecommerce Attribution
For the following exercises, I first cleaned the CSV file using Python and converted it into a JSONL file. (Thank you, Sonnet 3.7.) Then, I uploaded the file to a GCP bucket before creating a dataset in BigQuery.

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

<DataTable data={monthly_orders} totalRow=true >
  <Column id=store />
  <Column id=order_month />
  <Column id=order_count />
  <Column id=total_revenue fmt=usd0 />
  <Column id=avg_order_value totalAgg="average of $225.65" />
</DataTable>


### Key Findings
- Strong seasonal pattern with peak revenue during Nov-Dec 2022 holiday season (BFCM + Christmas)
- Significant drop in Jan 2023 showing typical post-holiday slump
- AOV highest during Nov-Dec ($251) and dropped to ~$205 in Jan-Feb as customers were likely more price-sensitive
- Gradual recovery in both order volume and AOV through Spring 2023

<Details title="SQL Query used to calculate the number of orders per month per store">

```sql
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

```

This query addresses several important data quality considerations:

1. Normalizes store URLs to ensure consistent grouping regardless of URL format
2. Filters for actual conversion events using the `thank_you` page path, avoiding duplicate counting from order status checks
3. Deduplicates multiple pixel events for the same order ID by using `ROW_NUMBER()` and selecting only the first occurrence
4. Takes the earliest order record when multiple events exist, ensuring consistent handling of duplicates
5. Calculates key metrics like order count, total revenue, and average order value

</Details>

## Attribution Modelling

Before choosing an attribution model, let's analyze how many touchpoints customers have within a 30-day window before purchasing.

My hypothesis is that with an AOV over $225, Almond Cow's customers visit the store multiple times before committing to purchase, as this represents a considered decision rather than an impulse buy.

After analyzing the data for orders placed from January 2023 onward (ensuring complete 30-day lookback data), the results confirmed my hypothesis:

```sql session_distribution
select *
from growth.session_distribution
```

```sql pie_data
select
  concat(session_count_group, ' session(s)') as name,
  order_count as value
from ${session_distribution}
```

#### Nearly 50% of all customers interact with the brand through multiple sessions
<ECharts config={
    {
        tooltip: {
            formatter: '{b} session(s): {c} ({d}%)'
        },
        series: [
        {
          type: 'pie',
          data: [...pie_data],
        }
      ]
      }
    }
/>


As we can see in the above chart, nearly half of all customers interact with the brand through multiple sessions before purchasing. This multi-touch behavior makes sense for a premium product like a milk maker, where customers likely research recipes, explore features, and consider their options across multiple visits.

<Details title="SQL Query used to find how many touchpoints customers have">

First, I wrote a CTE to get all order data, making sure to filter only for "thank you" pages and orders from January 2023 onwards. I'm using a 30-day lookback window, and the first events in the dataset were triggered around November 24th, so starting from January gives us complete lookback data for all orders.

I also used the `ROW_NUMBER()` function to handle potential duplicate order events by assigning a sequence number to each order record:


```sql
WITH order_events AS (
  SELECT
    shopifyOrderId,
    TIMESTAMP_MILLIS(CAST(timestamp AS INT64)) AS order_timestamp,
    DATE(shopifyOrderProcessedAt) AS order_datetime,
    shopifyOrderTotalPrice AS order_total,
    ip,
    ROW_NUMBER() OVER(PARTITION BY shopifyOrderId ORDER BY timestamp) AS row_num
  FROM `polar-455513.growth.pixeldata`
  WHERE 
    shopifyOrderId IS NOT NULL
    AND pagePath LIKE '%/thank_you'
    AND DATE(shopifyOrderProcessedAt) >= '2023-01-01'
),

unique_orders AS (
  SELECT
    shopifyOrderId,
    order_timestamp,
    order_datetime,
    order_total,
    ip
  FROM order_events
  WHERE row_num = 1
)
```

I then created a second CTE to keep only unique orders by filtering for `row_num = 1`, ensuring I count each order exactly once:

```sql
unique_orders AS (
  SELECT shopifyOrderId, order_timestamp, order_datetime, order_total, ip
  FROM order_events
  WHERE row_num = 1
)
```

Next, I joined the unique orders with all the pixel data to find every interaction that happened within 30 days before each purchase. I'm using the IP address to connect users to their events and adding logic to determine the traffic source:

```sql
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
```

This is where I implemented the session logic. I first used a `LAG()` function to find the previous timestamp for each event:

```sql
with_prev_timestamp AS (
  SELECT
    *,
    LAG(event_timestamp_formatted) OVER(PARTITION BY shopifyOrderId, ip ORDER BY event_timestamp) AS prev_timestamp
  FROM pre_purchase_events
),
```

Then I marked session boundaries when there's a gap of more than 30 minutes between events:

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
```

I then used a cumulative sum to assign a consistent session number to all events in the same session:
```sql
session_groups AS (
  SELECT
    *,
    SUM(is_new_session) OVER(PARTITION BY shopifyOrderId, ip ORDER BY event_timestamp) AS session_number
  FROM session_boundaries
),
```

For each session, I identifed the entry source (first touchpoint), session duration, and interaction count:
```sql
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
)
```

I then counted sessions per order and constructed the customer journey path:
```sql
session_counts_per_order AS (
  SELECT
    shopifyOrderId,
    COUNT(*) AS session_count,
    STRING_AGG(session_source, ' > ' ORDER BY session_start) AS source_path
  FROM session_sources
  GROUP BY shopifyOrderId
)
```

Finally, I created a distribution to see how many touchpoints customers typically have before purchasing:
```sql
session_distribution AS (
  SELECT
    CASE WHEN session_count >= 5 THEN '5+' ELSE CAST(session_count AS STRING) END AS session_count_group,
    COUNT(*) AS order_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage
  FROM session_counts_per_order
  GROUP BY session_count_group
)
```
</Details>

### Attribution Model Selection
Based on these findings, I've decided to implement a position-based (U-shaped) attribution model, which:
- Gives 40% credit to the first touchpoint (discovery)
- Gives 40% credit to the last touchpoint (conversion)
- Distributes the remaining 20% across middle touchpoints

This model properly recognizes both the critical discovery phase and the final conversion decision, while still acknowledging the nurturing effect of middle interactions. For single-session journeys, the source simply receives 100% of the credit.

```sql attribution
select *
from growth.u_model
limit 10
```

<BarChart 
    data={attribution} 
    x=source_group
    y=attributed_revenue
    yFmt=usd0k
    y2=percentage_total
    y2Fmt=pct
    y2SeriesType=line
/>

<DataTable  data={attribution} totalRow=true >
  <Column id=source_group />
  <Column id=attributed_revenue  fmt=usd0/>
  <Column id=percentage_total fmt=pct />
</DataTable>

