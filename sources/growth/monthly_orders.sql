with orders as (
  select 
    regexp_replace(shopifyshopurl, '^https?://|/$', '') as store,
    shopifyorderid as order_id,
    date(shopifyorderprocessedat) as order_date,
    format_date('%b %y', date(shopifyorderprocessedat)) as order_month,
    shopifyordertotalprice as order_total,
    row_number() over(partition by shopifyorderid order by shopifyorderprocessedat) as row_num
  from growth.pixeldata
  where shopifyorderid is not null
    and pagepath like '%/thank_you'
),

monthly_orders as (
  select
    store,
    order_month,
    count(*) as order_count,
    round(sum(order_total), 2) as total_revenue,
    round(sum(order_total) / count(*), 2) as avg_order_value
  from orders
  where row_num = 1
  group by store, order_month
  order by store, parse_date('%b %y', order_month)
)

select * from monthly_orders