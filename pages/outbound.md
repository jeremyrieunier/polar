# Assessing Outbound Effectiveness
The growth team at Polar is responsible for lead generation, with the sales team handling conversion of these opportunities into customers. Thus, the goals of these outbound campaigns are:

1. Generate qualified pipeline opportunities for the sales team to work on
2. Engage ICP companies with relevant messaging

Given these goals, the ideal Top KPI for the outbound campaigns is:

## Pipeline Value per Company Touched

This metric:

1. Directly measures how efficiently outbound efforts generate pipeline value
2. Aligns with the growth team's primary goal of creating opportunities for the sales team and keep it accountable
3. Accounts for both the quality and quantity of outreach

This metric is calculated as follows:
> Pipeline Value Created / Companies Touched

## Supporting Metrics
While Pipeline Value per Company Touched is the primary metric, I recommend tracking these supporting metrics to provide context:

### Pipeline Revenue Win Rate
While the growth team does not own this metric, it measures how effectively the sales team converts pipeline opportunities into actual revenue. It highlights alignment between growth and sales teams and identifies which types of opportunities close at a higher rate.

This metric is calculated as follows:
> ARR Value Created / Pipeline Value Created

### ARR Value per Company Touched
This metric shows the complete business impact of outbound efforts, capturing both pipeline generation efficiency and sales conversion effectiveness.

This metric is calculated as follows:
> ARR Value Created / Companies Touched

### ICP Targeting Accuracy
This metric measures how well campaigns focus on the Ideal Customer Profile (ICP)

This metric is calculated as follows:
> (ICP Companies Touched / Companies Touched) × 100%

```sql campaigns
select
  CAMPAIGN_GROUP as campaign,
  PIPELINE_OPP_AMOUNT_FROM_OB_ALL_TIME as pipeline_value_created,
  NEW_ARR_FROM_OB_ALL_TIME as aar_value_created,
  NB_COMPANIES_TOUCHED as companies_touched,
  PIPELINE_OPP_AMOUNT_FROM_OB_ALL_TIME / NB_COMPANIES_TOUCHED as pipeline_value_per_company,
  NEW_ARR_FROM_OB_ALL_TIME / NB_COMPANIES_TOUCHED as aar_per_company,
  (NB_COMPANIES_TOUCHED_ICP / NB_COMPANIES_TOUCHED) as icp_targeting_accuracy
from outbound.campaigns
order by pipeline_value_created desc
```
<DataTable data={campaigns} />

# Top Performing Campaigns
To properly evaluate campaign performance, we must consider both efficiency (Pipeline Value per Company Touched), scale (number of companies touched), and impact (total pipeline generated) using a matrix bubble chart:

```sql matrix
select
  CAMPAIGN_GROUP as campaign,
  NB_COMPANIES_TOUCHED as companies_touched,
  PIPELINE_OPP_AMOUNT_FROM_OB_ALL_TIME as pipeline_value_created,
  PIPELINE_OPP_AMOUNT_FROM_OB_ALL_TIME / NB_COMPANIES_TOUCHED as pipeline_value_per_company
from outbound.campaigns
```

<BubbleChart
  data={matrix}
  x=companies_touched
  y=pipeline_value_per_company
  series=campaign
  size=pipeline_value_created
  yMin=0
  xMin=0
  yFmt=usd
  chartAreaHeight=350
>
  <ReferenceArea 
    xMin=15000 
    xMax=20000 
    yMin=0 
    yMax=15 
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
    xMin=0 
    xMax=6000 
    yMin=10
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
    yMax=5
    label="Reconsider"
    color="negative"
    border={true}
    labelPosition="center"
  />
</BubbleChart>

## Best Overall Performers
These campaigns generate substantial pipeline with good efficiency, striking a balance between reach and performance.

```best
select
  CAMPAIGN_GROUP as campaign,
  NB_COMPANIES_TOUCHED as companies_touched,
  PIPELINE_OPP_AMOUNT_FROM_OB_ALL_TIME as pipeline_value_created,
  PIPELINE_OPP_AMOUNT_FROM_OB_ALL_TIME / NB_COMPANIES_TOUCHED as pipeline_value_per_company,
  NEW_ARR_FROM_OB_ALL_TIME as aar_value_created,
  NB_CUSTOMERS_FROM_OB_ALL_TIME as accounts_acquired,
  NEW_ARR_FROM_OB_ALL_TIME / NB_CUSTOMERS_FROM_OB_ALL_TIME as avg_deal_size
from outbound.campaigns
where campaign in ('GPT V3 - CAPI', 'Klaviyo flows enrich')
order by companies_touched desc
```
<DataTable data={best}/>

Action Plan:
- Conduct segmentation analysis to identify highest-performing subgroups
- Optimize messaging and improve efficiency
- Maintain current scale while working to push efficiency metrics above $25 per company

## High Efficiency, Low Scale (Growth Potential)
These campaigns show promising efficiency but need expansion.

```growth
select
  CAMPAIGN_GROUP as campaign,
  NB_COMPANIES_TOUCHED as companies_touched,
  PIPELINE_OPP_AMOUNT_FROM_OB_ALL_TIME as pipeline_value_created,
  PIPELINE_OPP_AMOUNT_FROM_OB_ALL_TIME / NB_COMPANIES_TOUCHED as pipeline_value_per_company,
  NEW_ARR_FROM_OB_ALL_TIME as aar_value_created,
  NB_CUSTOMERS_FROM_OB_ALL_TIME as accounts_acquired,
  NEW_ARR_FROM_OB_ALL_TIME / NB_CUSTOMERS_FROM_OB_ALL_TIME as avg_deal_size
from outbound.campaigns
where campaign in ('Technology intent', 'Ask Polar Lite', 'Demo App Nurture', 'GPT V3 - French', 'Creative Studio', 'GPT V4 (GPT-4o)')
order by companies_touched desc
```
<DataTable data={growth}/>

Action Plan:
- Scale up these campaigns to reach more companies while monitoring efficiency metrics
- Preserve the targeting precision and messaging quality
- Consider developing similar campaigns with high-quality messagin

## Low Efficiency, High Scale (Optimization Needed)
These campaigns reach a significant number of companies but underperform in generating pipeline value per company touched.

```optimization
select
  CAMPAIGN_GROUP as campaign,
  NB_COMPANIES_TOUCHED as companies_touched,
  PIPELINE_OPP_AMOUNT_FROM_OB_ALL_TIME as pipeline_value_created,
  PIPELINE_OPP_AMOUNT_FROM_OB_ALL_TIME / NB_COMPANIES_TOUCHED as pipeline_value_per_company,
  NEW_ARR_FROM_OB_ALL_TIME as aar_value_created,
  NB_CUSTOMERS_FROM_OB_ALL_TIME as accounts_acquired,
  NEW_ARR_FROM_OB_ALL_TIME / NB_CUSTOMERS_FROM_OB_ALL_TIME as avg_deal_size
from outbound.campaigns
where campaign in ('GA4', 'Loom', 'Other', 'GPT V3 - CEO')
order by companies_touched desc
```
<DataTable data={optimization}/>

Action plan:
- Improve messaging or targeting to increase efficiency
- Develop segment-specific messaging based on industry and company size

## Low Efficiency, Low Scale (Reconsider)
This campaign underperforms on both critical dimensions, indicating fundamental issues.

```reconsider
select
  CAMPAIGN_GROUP as campaign,
  NB_COMPANIES_TOUCHED as companies_touched,
  PIPELINE_OPP_AMOUNT_FROM_OB_ALL_TIME as pipeline_value_created,
  PIPELINE_OPP_AMOUNT_FROM_OB_ALL_TIME / NB_COMPANIES_TOUCHED as pipeline_value_per_company,
  NEW_ARR_FROM_OB_ALL_TIME as aar_value_created,
  NB_CUSTOMERS_FROM_OB_ALL_TIME as accounts_acquired,
  NEW_ARR_FROM_OB_ALL_TIME / NB_CUSTOMERS_FROM_OB_ALL_TIME as avg_deal_size
from outbound.campaigns
where campaign in ('Fashion / Multiple Products')
order by companies_touched desc
```
<DataTable data={reconsider}/>

Action plan:
- Identify specific failure points
- Text new messaging if the segment remains important
- Consider relocating resources to other campaigns

# Size the outbound opportunity
The Total Addressable Market (TAM) of Polar consists of 127,000 Shopify merchants with GMV between $1M and $500M:

| GMV Category | Number of Merchants | % of Total |
| ------------ | --------- | ---------- |
| $1-5M | 84,881 | 66.8% |
| $5-10M | 36,377 | 28.6% | 
| $10-50M | 4,804 | 3.8% |
| $50-100M | 619 | 0.5% |
| $100-500M | 319 | 0.25% |

## Outbound Opportunity Sizing
To estimate the potential New ARR from scaling outbound to our entire TAM, I'll use a simplified approach applying our historical ACV to different conversion rate scenarios.

### Key Caveats
**Conversion rate based on overlapped data**: Our calculated conversion rate (0.042%) is based on raw campaign data where some companies may have been counted multiple times across different campaigns,

**Varying conversion by GMV tier**: Different GMV tiers likely have different propensities to convert, though our current data doesn't explicitly segment performance by customer size.

**Blended approach**: We're using overall conversion rates and applying our historical average ACV ($11,147) uniformly across all customer segments, which simplifies the analysis but may not reflect segment-specific differences.

## Opportunity Size Calculations
### Conservative Scenario
Using our overall observed conversion rate (0.042%):

| TAM | Conversion Rate | New Customers | Historical ACV | Potential ARR |
| --- | --------------- | ------------- | -------------- | ------------- |
| 127,000 | 0.042% | 53 | $11,147 | $591,000 |

### Moderate Scenario
Using a slightly improved conversion rate (0.06%):

| TAM | Conversion Rate | New Customers | Historical ACV | Potential ARR |
| --- | --------------- | ------------- | -------------- | ------------- |
| 127,000 | 0.06% | 76 | $11,147 | $847,000 |

### Optimistic Scenario
Using the conversion rate from our best-performing campaigns (0.13%): 

| TAM | Conversion Rate | New Customers | Historical ACV | Potential ARR |
| --- | --------------- | ------------- | -------------- | ------------- |
| 127,000 | 0.13% | 165 | $11,147 | $1,839,000 |

## Accounting for Sales Capacity
Current sales capacity: 7 quota-carrying reps × $600K quota = $4.2M yearly capacity

All scenarios fall well within our current sales capacity:

- Conservative scenario: $591,000 (14.1% of capacity)
- Moderate scenario: $847,000 (20.2% of capacity)
- Optimistic scenario: $1,839,000 (43.8% of capacity)

This analysis suggests that scaling our outbound efforts to our entire TAM could generate between $591K and $1.84M in new ARR. This represents a significant achievable growth opportunity that can be handled by the current sales team capacity.

# Prioritizing Outbound as a Growth Lever
Current ARR is $3M with a goal to achieve $10M by end of year, meaning Polar needs an additional $7M ARR to achieve its objective.

With a relatistic outbound potential of 847K-$1.84M ARR based on past performance, outbound alone will not achieve the $7M ARR growth target.

Let's compare Outbound VS Inbound VS Paid Ads.

## Outbound strengths
- Highly target approach to ICP
- Controlled scaling with prectidable unit economics
- Direct access to decision makers
- Showing promising results with campaigns like Technology Intent and Klaviyo Flows Enrich

## Outbound limitations
- TAM fatigue: 127,000 merchants and reaching 15,000/month, market saturation becomes a concern with a risk of diminusing return as we exhaust ICP
- Email deliverability issue: increasing volume could trigger spam filters, - especially with low engagement metrics that risks damaging domain reputation
- Personalization limits: scaling personalized outreach becomes challenging beyond certain volumes
- Data quality issues: Contact information could becomes outdated, with a potential impact on email deliverability
