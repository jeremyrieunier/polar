# Ecommerce Attribution
For the following exercices I first cleaned the csv file you provided using Python and converted it into a JSONL file. Thank you Sonnet 3.7. Then I uploaded the file into a GCP bucket before creating a dataset on BigQuery.

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
    group by store, order_month 
    order by store, strptime(order_month, '%b %Y')
)

SELECT *
FROM monthly_orders
```

```sql 
with order_events as (
    
))
    regexp_replace(shopifyShopURL, '^https?://|/$', '') AS store,
    shopifyOrderId AS order_id,
    shopifyOrderProcessedAt AS order_datetime,
    shopifyOrderTotalPrice AS order_total,
    FORMAT_DATE('%b %Y', DATE(shopifyOrderProcessedAt)) as order_month
from growth.pixeldata
where shopifyOrderId is not null
    and pagePath like '%/thank_you'
),

monthly_orders as (
    select
        store,
        order_month,
        count(distinct order_id) AS order_count,
        round(sum(order_total), 2) AS total_revenue,
        round(sum(order_total) / count(distinct order_id), 2) as avg_order_value
    from order_events
    group by store, order_month 
    order by store, strptime(order_month, '%b %Y')
)

select *
from monthly_orders
```

<BarChart 
    data={monthly_orders} 
    x=order_month 
    y=total_revenue
    y2=avg_order_value
    y2SeriesType=line
/>