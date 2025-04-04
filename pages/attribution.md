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

<DataTable data={monthly_orders}/>

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

My hypothesis is that with an AOV over $200, Almond Cow's customers visit the store multiple times before committing to purchase, as this represents a considered decision rather than an impulse buy.

After analyzing the data for orders placed from January 2023 onward (ensuring complete 30-day lookback data), the results confirmed my hypothesis:



```sql session_distribution
select *
from growth.session_distribution
```
<BarChart 
    data={session_distribution}
    title="Nearly 50% of all customers interact with the brand through multiple sessions"
    x=session_count_group
    xAxisTitle="Number of sessions"
    y=percentage
    series=session_count_group
    yFmt=pct
    yMax=1
    swapXY=true
/>

As we can see in the above chart, nearly half of all customers interact with the brand through multiple sessions before purchasing. This multi-touch behavior makes sense for a premium product like a milk maker, where customers likely research recipes, explore features, and consider their options across multiple visits.

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

<DataTable  data={attribution} >
  <Column id="source" wrap=true />
  <Column id="2023-01" fmt=usd0k />
  <Column id="2023-02" fmt=usd0k />
  <Column id="2023-03" fmt=usd0k />
  <Column id="2023-04" fmt=usd0k />
  <Column id="2023-05" fmt=usd0k />
  <Column id="2023-06" fmt=usd0k />
</DataTable>

