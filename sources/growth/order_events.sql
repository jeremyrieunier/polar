select
    regexp_replace(shopifyShopURL, '^https?://|/$', '') AS store,
    shopifyOrderId AS order_id,
    shopifyOrderProcessedAt AS order_datetime,
    shopifyOrderTotalPrice AS order_total,
    FORMAT_DATE('%b %Y', DATE(shopifyOrderProcessedAt)) as order_month
from growth.pixeldata
where shopifyOrderId is not null
    and pagePath like '%/thank_you'