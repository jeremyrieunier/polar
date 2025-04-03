select
    regexp_replace(shopifyShopURL, '^https?://|/$', '') as store,
    shopifyOrderId as order_id,
    date(shopifyOrderProcessedAt) as order_date,
    format_date('%b %Y', date(shopifyOrderProcessedAt)) as order_month,
    shopifyOrderTotalPrice AS order_total,
    row_number() over(partition by shopifyOrderId order by shopifyOrderProcessedAt) as row_num
from growth.pixeldata
where shopifyOrderId is not null
    and pagePath like '%/thank_you'