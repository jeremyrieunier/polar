-- Step 1: identify all orders with their ip addresses (with deduplication)
with order_events as (
  select
    shopifyorderid,
    timestamp_millis(cast(timestamp as int64)) as order_timestamp,
    date(shopifyorderprocessedat) as order_datetime,
    shopifyordertotalprice as order_total,
    ip,
    row_number() over(partition by shopifyorderid order by timestamp) as row_num
  from growth.pixeldata
  where 
    shopifyorderid is not null
    and pagepath like '%/thank_you'
    and date(shopifyorderprocessedat) >= '2023-01-01'  -- only include orders from january 1, 2023
),

-- Filter to include only unique orders
unique_orders as (
  select
    shopifyorderid,
    order_timestamp,
    order_datetime,
    order_total,
    ip
  from order_events
  where row_num = 1
),

-- Step 2: get all pageviews within 30 days before each order
pre_purchase_events as (
  select
    o.shopifyorderid,
    o.order_timestamp,
    o.order_datetime,
    o.order_total,
    o.ip,
    p.timestamp as event_timestamp,
    timestamp_millis(cast(p.timestamp as int64)) as event_timestamp_formatted,
    p.pagepath,
    p.utmsource,
    p.pagereferrer,
    coalesce(p.utmsource, 
      case 
        when p.pagereferrer is null or p.pagereferrer = '' or p.pagereferrer like '%almondcow.co%' then 'direct'
        else regexp_extract(regexp_extract(p.pagereferrer, 'http[s]?://([^/]*)'), '([^.]+\\.[^.]+)$') 
      end) as source
  from unique_orders o
  join `polar-455513.growth.pixeldata` p
    on o.ip = p.ip
    and timestamp_millis(cast(p.timestamp as int64)) <= o.order_timestamp
    and timestamp_millis(cast(p.timestamp as int64)) >= timestamp_sub(o.order_timestamp, interval 30 day)
),

-- Step 3: add previous timestamp to calculate gaps for session grouping
with_prev_timestamp as (
  select
    *,
    lag(event_timestamp_formatted) over(partition by shopifyorderid, ip order by event_timestamp) as prev_timestamp
  from pre_purchase_events
),

-- Step 4: mark session boundaries where gap > 30 minutes
session_boundaries as (
  select
    *,
    case 
      when prev_timestamp is null or 
           timestamp_diff(event_timestamp_formatted, prev_timestamp, second) > 1800 
      then 1 
      else 0 
    end as is_new_session
  from with_prev_timestamp
),

-- Step 5: create session groups by cumulative sum of boundaries
session_groups as (
  select
    *,
    sum(is_new_session) over(partition by shopifyorderid, ip order by event_timestamp) as session_number
  from session_boundaries
),

-- Step 6: get first interaction of each session to determine source
session_sources as (
  select
    shopifyorderid,
    ip,
    session_number,
    array_agg(source order by event_timestamp asc limit 1)[offset(0)] as session_source,
    min(event_timestamp_formatted) as session_start,
    max(event_timestamp_formatted) as session_end,
    count(*) as interactions_in_session
  from session_groups
  group by shopifyorderid, ip, session_number
),

-- Step 7: count sessions per order
session_counts_per_order as (
  select
    shopifyorderid,
    count(*) as session_count,
    string_agg(session_source, ' > ' order by session_start) as source_path
  from session_sources
  group by shopifyorderid
),

-- Step 8: create distribution of session counts
session_distribution as (
  select
    case 
      when session_count >= 5 then '5+'
      else cast(session_count as string)
    end as session_count_group,
    count(*) as order_count,
    round(count(*) / sum(count(*)) over(), 2) as percentage
  from session_counts_per_order
  group by session_count_group
)

-- Final results: distribution of session counts
select * from session_distribution
order by 
  case 
    when session_count_group = '5+' then 5
    else cast(session_count_group as int64)
  end
