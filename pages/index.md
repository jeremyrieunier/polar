---
title: 👋 Hello Polar 🐻‍❄️
---

# Executive Summary
## Outbound Campaign Performance Analysis
<LinkButton url='/outbound'>
📈 Link to the analysis
</LinkButton>

### Key Metrics & Top Performers
Based on my analysis of Polar's outbound campaigns, I recommend Pipeline Value per Company Touched as the Top KPI. This metric directly measures outbound efficiency in generating qualified pipeline opportunities for the sales team.

```sql matrix
select
  CAMPAIGN_GROUP as campaign,
  NB_COMPANIES_TOUCHED as companies_touched,
  PIPELINE_OPP_AMOUNT_FROM_OB_ALL_TIME as pipeline_value_created,
  PIPELINE_OPP_AMOUNT_FROM_OB_ALL_TIME / NB_COMPANIES_TOUCHED as pipeline_value_per_company
from outbound.campaigns
order by companies_touched desc
```

<BubbleChart
  data={matrix}
  x=companies_touched
  y=pipeline_value_per_company
  series=campaign
  size=pipeline_value_created
  yFmt=usd
  yMin=0
  chartAreaHeight=350
  xLabelWrap=true
>
  <ReferenceLine
    x=7500
    label="Average Companies Touched"
  />
  <ReferenceLine
    y=8.70
    label="Average Pipeline Value"
  />
  <ReferenceArea 
    xMin=15000 
    xMax=20000 
    yMin=3
    yMax=12 
    label="Optimization Needed" 
    color="warning"
    border={true}
    labelPosition="center"
  />

  <ReferenceArea 
    xMin=7000 
    xMax=13000 
    yMin=12 
    yMax=27 
    label="Best Overall Performers" 
    color="positive"
    border={true}
    labelPosition="center"
  />

  <ReferenceArea 
    xMin=1000 
    xMax=6000 
    yMin=22
    yMax=30
    label="Growth Potential" 
    color="info"
    border={true}
    labelPosition="center"
  />

  <ReferenceArea 
    xMin=0 
    xMax=5000 
    yMin=0
    yMax=15
    label="Reconsider"
    color="negative"
    border={true}
    labelPosition="center"
  />
</BubbleChart>


Using this metric, our top performers are:
- GPT V3 - CAPI: $23.27 per company with 9,032 companies touched
- Klaviyo Flows Enrich: $14.72 per company with 10,821 companies touched

### Outbound Opportunity Sizing
Scaling outbound efforts to the entire TAM of 127,000 Shopify merchants could generate:

- Conservative scenario: $589K in new ARR (14.0% of sales capacity)
- Moderate scenario: $870K in new ARR (20.7% of sales capacity)
- Optimistic scenario: $1.15M in new ARR (27.4% of sales capacity)

This analysis reveals a significant gap between the $7M ARR growth target and what outbound alone can realistically deliver, even in the most optimistic scenario.

### Multi-Channel Acquisition Strategy Recommendations
To bridge this gap, I recommend a balanced approach across 3 key channels:

**1. Inbound Foundation**
- Leverage client ecommerce data to create authoritative industry benchmarks
- Develop compelling case studies highlighting specific pain points and outcomes
- Amplify content through owned channels and industry publications

**2. Enhanced Outbound**
- Scale highest-performing campaigns with refined targeting
- Focus on personalization quality rather than just volume
- Integrate insights from inbound content to improve message relevance

**3. Targeted Paid Acquisition**
- Build broader market awareness through LinkedIn, YouTube, and Reddit
- Test sponsored content in industry newsletters (EcommerceFuel, 2PM, draft.nu)
- Sponsor influential industry podcasts

## Sales + Attribution Analysis for Almond Cow
<LinkButton url='/attribution'>
📊 Link to the analysis
</LinkButton>

### Order Analysis

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

Analysis of Almond Cow's orders data revealed:

- Strong seasonal pattern with peak revenue during Nov-Dec 2022 BFCM + holiday season
- Significant drop in January 2023 showing typical post-holiday slump
- AOV highest during Nov-Dec ($251) and gradually recovered through Spring 2023

### Attribution Model Selection
I implemented a U-shaped attribution model based on the finding that nearly 50% of customers interact with the brand across multiple sessions before purchasing:


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


This model:
- Gives 40% credit to the first touchpoint (discovery)
- Gives 40% credit to the last touchpoint (conversion)
- Distributes remaining 20% across middle touchpoints

### Channel Performance

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
    chartAreaHeight=350
/>
The attribution analysis revealed:

- Direct traffic: Dominant channel accounting for 56% of attributed revenue ($2.19M)
- Google organic: Second largest at 10% ($410K)
- Google paid: Third at 8% ($308K)
- Attentive (SMS): Fourth at 5% ($188K)

The high proportion of direct traffic suggests potential UTM tagging inconsistencies across marketing campaigns, presenting an opportunity for improved tracking implementation.

I've made this app using [Evidence.dev](https://evidence.dev/). Code is on [GitHub](https://github.com/jeremyrieunier/polar). And this is mon [Linkedin profile](https://www.linkedin.com/in/jeremyrieunier/).