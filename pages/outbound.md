# Assessing Outbound Effectiveness
The growth team at Polar is responsible for lead generation, with the sales team handling conversion of these opportunities into customers. Thus, the goals of these outbound campaigns are:

1. Generate qualified pipeline opportunities for the sales team to work on
2. Engage ICP companies with relevant messaging

## Primary KPI Recommendation
Given these goals, the ideal Top KPI for the outbound campaigns is **Pipeline Value per Company Touched** because it:

- Directly measures how efficiently outbound efforts generate pipeline value
- Aligns with the growth team's primary goal of creating opportunities for the sales team and while keeping it accountable
- Accounts for both the quality and quantity of outreach

This metric is calculated as follows:
> Pipeline Value Created / Companies Touched

```sql pipeline_value_company
select
  CAMPAIGN_GROUP as campaign,
  PIPELINE_OPP_AMOUNT_FROM_OB_ALL_TIME as pipeline_value_created,
  NB_COMPANIES_TOUCHED as companies_touched,
  (PIPELINE_OPP_AMOUNT_FROM_OB_ALL_TIME / NB_COMPANIES_TOUCHED) as pipeline_value_per_company_touched
from outbound.campaigns
order by 2 desc
```

<DataTable data={pipeline_value_company} wrapTitles=true totalRow=true>
  <Column id=campaign />
  <Column id=pipeline_value_created fmt=usd />
  <Column id=companies_touched />
  <Column id=pipeline_value_per_company_touched fmt=usd contentType=bar totalAgg="average of $8.7"/>
</DataTable>

## Supporting Metrics
While Pipeline Value per Company Touched is the primary metric, I recommend tracking these supporting metrics to provide additional context:

### Pipeline Revenue Win Rate
While the growth team does not own this metric, it measures how effectively the sales team converts pipeline opportunities into actual revenue. It highlights alignment between growth and sales teams and identifies which types of opportunities close at a higher rate.

This metric is calculated as follows:
> ARR Value Created / Pipeline Value Created

```sql pipeline_win_rate
select
  CAMPAIGN_GROUP as campaign,
  PIPELINE_OPP_AMOUNT_FROM_OB_ALL_TIME as pipeline_value_created,
  NEW_ARR_FROM_OB_ALL_TIME as arr_value_created,
  NEW_ARR_FROM_OB_ALL_TIME / PIPELINE_OPP_AMOUNT_FROM_OB_ALL_TIME as pipeline_revenue_win_rate
from outbound.campaigns
order by 2 desc
```

<DataTable data={pipeline_win_rate} wrapTitles=true totalRow=true>
  <Column id=campaign />
  <Column id=pipeline_value_created fmt=usd0 />
  <Column id=arr_value_created fmt=usd0 />
  <Column id=pipeline_revenue_win_rate totalAgg="average of 53.30%" fmt=pct />
</DataTable>

### ARR Value per Company Touched
This metric shows the complete business impact of outbound efforts, capturing both pipeline generation efficiency and sales conversion effectiveness.

This metric is calculated as follows:
> ARR Value Created / Companies Touched

```sql arr_value_company
select
  CAMPAIGN_GROUP as campaign,
  NEW_ARR_FROM_OB_ALL_TIME as arr_value_created,
  NB_COMPANIES_TOUCHED as companies_touched,
  NEW_ARR_FROM_OB_ALL_TIME / NB_COMPANIES_TOUCHED as arr_per_company_touched
from outbound.campaigns
order by 2 desc
```

<DataTable data={arr_value_company} wrapTitles=true totalRow=true >
  <Column id=campaign />
  <Column id=arr_value_created fmt=usd0 />
  <Column id=companies_touched  />
  <Column id=arr_per_company_touched fmt=usd totalAgg="average of $4.64" />
</DataTable> 


### ICP Targeting Accuracy
This metric measures how well campaigns focus on the Ideal Customer Profile (ICP).

This metric is calculated as follows:
> (ICP Companies Touched / Companies Touched) × 100%

```sql icp_targeting
select
  CAMPAIGN_GROUP as campaign,
  NB_COMPANIES_TOUCHED as companies_touched,
  NB_COMPANIES_TOUCHED_ICP as icp_companies_touched,
  NB_COMPANIES_TOUCHED_ICP / NB_COMPANIES_TOUCHED as icp_targeting_accuracy
from outbound.campaigns
order by 2 desc
```

<DataTable data={icp_targeting} wrapTitles=true totalRow=true >
  <Column id=campaign />
  <Column id=companies_touched />
  <Column id=icp_companies_touched  />
  <Column id=icp_targeting_accuracy fmt=pct totalAgg="average of 49%" />
</DataTable> 


# Top Performing Campaigns
To properly evaluate campaign performance, we must consider both efficiency (Pipeline Value per Company Touched), scale (number of companies touched), and impact (total pipeline generated) using a matrix bubble chart:

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

## Best Overall Performers
These campaigns generate substantial pipeline with good efficiency, striking a balance between reach and performance.

```best
select
  CAMPAIGN_GROUP as campaign,
  NB_COMPANIES_TOUCHED as companies_touched,
  PIPELINE_OPP_AMOUNT_FROM_OB_ALL_TIME as pipeline_value_created,
  PIPELINE_OPP_AMOUNT_FROM_OB_ALL_TIME / NB_COMPANIES_TOUCHED as pipeline_value_per_company,
  NEW_ARR_FROM_OB_ALL_TIME as arr_value_created,
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
  NEW_ARR_FROM_OB_ALL_TIME as arr_value_created,
  NB_CUSTOMERS_FROM_OB_ALL_TIME as accounts_acquired,
  NEW_ARR_FROM_OB_ALL_TIME / NB_CUSTOMERS_FROM_OB_ALL_TIME as avg_deal_size
from outbound.campaigns
where campaign in ('Technology intent', 'Ask Polar Lite')
order by companies_touched desc
```
<DataTable data={growth}/>

Action Plan:
- Scale up these campaigns to reach more companies while monitoring efficiency metrics
- Preserve the targeting precision and messaging quality
- Consider developing similar campaigns with high-quality messaging

## Low Efficiency, High Scale (Optimization Needed)
These campaigns reach a significant number of companies but underperform in generating pipeline value per company touched.

```optimization
select
  CAMPAIGN_GROUP as campaign,
  NB_COMPANIES_TOUCHED as companies_touched,
  PIPELINE_OPP_AMOUNT_FROM_OB_ALL_TIME as pipeline_value_created,
  PIPELINE_OPP_AMOUNT_FROM_OB_ALL_TIME / NB_COMPANIES_TOUCHED as pipeline_value_per_company,
  NEW_ARR_FROM_OB_ALL_TIME as arr_value_created,
  NB_CUSTOMERS_FROM_OB_ALL_TIME as accounts_acquired,
  NEW_ARR_FROM_OB_ALL_TIME / NB_CUSTOMERS_FROM_OB_ALL_TIME as avg_deal_size
from outbound.campaigns
where campaign in ('GA4', 'Loom')
order by companies_touched desc
```
<DataTable data={optimization}/>

Action plan:
- Improve messaging or targeting to increase efficiency
- Develop segment-specific messaging based on industry and company size

## Low Efficiency, Low Scale (Reconsider)
These campaigns underperform on both critical dimensions, indicating fundamental issues.

```reconsider
select
  CAMPAIGN_GROUP as campaign,
  NB_COMPANIES_TOUCHED as companies_touched,
  PIPELINE_OPP_AMOUNT_FROM_OB_ALL_TIME as pipeline_value_created,
  PIPELINE_OPP_AMOUNT_FROM_OB_ALL_TIME / NB_COMPANIES_TOUCHED as pipeline_value_per_company,
  NEW_ARR_FROM_OB_ALL_TIME as arr_value_created,
  NB_CUSTOMERS_FROM_OB_ALL_TIME as accounts_acquired,
  NEW_ARR_FROM_OB_ALL_TIME / NB_CUSTOMERS_FROM_OB_ALL_TIME as avg_deal_size
from outbound.campaigns
where campaign in ('Fashion / Multiple Products', 'GPT V4 (GPT-4o)', 'Creative Studio', 'GPT V3 - French')
order by companies_touched desc
```
<DataTable data={reconsider}/>

Action plan:
- Identify specific failure points
- Test new messaging if the segment remains important
- Consider relocating resources to other campaigns

# Size the outbound opportunity
The TAM of Polar consists of 127,000 Shopify merchants with a GMV between $1M and $500M:

| GMV Category | Number of Merchants | % of Total |
| ------------ | --------- | ---------- |
| $1-5M | 84,881 | 66.8% |
| $5-10M | 36,377 | 28.6% | 
| $10-50M | 4,804 | 3.8% |
| $50-100M | 619 | 0.5% |
| $100-500M | 319 | 0.25% |

## Outbound Opportunity Sizing
To estimate the potential New ARR from scaling outbound to our entire TAM, I'll use an approach that aligns with the Top KPI I previously defined: Pipeline Value per Company Touched.

> Potential New ARR = (TAM × Pipeline Value per Company Touched) × Pipeline Revenue Win Rate

- TAM = 127,000 Shopify merchants with GMV between $1M and $500M
- Pipeline Value per Company Touched varies by scenario (based on campaign performance)
- Pipeline Revenue Win Rate = 53.3% (derived from historical data)

This ensures methodological consistency between how we measure campaign performance and how we forecast future opportunity

### Key Caveats
- **Data limited to historical performance**: This analysis assumes future campaigns will perform similarly to past ones, which may not account for market changes, or diminishing returns as we scale.

- **Varying conversion by GMV tier**:  Different GMV tiers likely have different propensities to convert, though our current data doesn't explicitly segment performance by customer size.

- **Pipeline-to-revenue conversion**: We use the historical Pipeline Revenue Win Rate (53.3%) to convert pipeline into ARR, which assumes the sales team will maintain similar close rates at scale.

- **Market saturation effects**: This analysis doesn't account for potential saturation effects from repeatedly targeting the same TAM with similar messaging.

## Opportunity Size Calculations
### Conservative Scenario
Using our average Pipeline Value per Company Touched ($8.70):

| TAM | Pipeline Value/Company | Pipeline Value | Pipeline Revenue Win Rate | Potential ARR |
| --- | ---------------------- | -------------- | ------------------------- | ------------- |
| 127,000 | $8.70 | $1,104,900 | 53.3% | $588,965 |

### Moderate Scenario
Using a midpoint value between average and top performers ($12.85):

| TAM | Pipeline Value/Company | Pipeline Value | Pipeline Revenue Win Rate | Potential ARR |
| --- | ---------------------- | -------------- | ------------------------- | ------------- |
| 127,000 | $12.85 | $1,631,950 | 53.3% | $869,881 |

### Optimistic Scenario
Using values from our best-performing campaigns ($17.00):

| TAM | Pipeline Value/Company | Pipeline Value | Pipeline Revenue Win Rate | Potential ARR |
| --- | ---------------------- | -------------- | ------------------------- | ------------- |
| 127,000 | $17.00 | $2,159,000| 53.3% | $1,150,798 |


## Accounting for Sales Capacity
Current sales capacity: 7 quota-carrying reps × $600K quota = $4.2M yearly capacity

All scenarios fall well within our current sales capacity:

- Conservative scenario: $588,965 (14.0% of capacity)
- Moderate scenario: $869,881 (20.7% of capacity)
- Optimistic scenario: $1,150,798 (27.4% of capacity)

This analysis suggests that scaling our outbound efforts to our entire TAM could generate between $589K and $1.15M in new ARR. This represents a significant achievable growth opportunity that can be handled by the current sales team capacity.

# Prioritizing Outbound as a Growth Lever
## Current Growth Challenge
Polar currently generates $3M in ARR but aims to reach $10M by year-end. This requires an additional $7M in net new ARR. My analysis shows that even with optimistic projections, outbound strategies alone will only deliver between $870K-$1.15M in new ARR.

This creates a clear need for a multi-channel approach to bridge the remaining gap.

## Strategic Channel Assessment

### Outbound Marketing: Precision with Limitations
**Advantages**
- Precision targeting of ICP companies
- Predictable unit economics with controlled scaling
- Direct engagement with decision-makers
- Proven success with campaigns like Technology Intent and Klaviyo Flows Enrich

**Key Challenges**
- With 127,000 total merchants and 15,000 monthly contacts, we risk exhausting our addressable ICP
- Increased volume may trigger email spam filters and harm domain reputation
- Maintaining quality at higher volumes becomes increasingly difficult beyond certain volumes
- Contact information accuracy diminishes over time, with a potential impact on email deliverability

### Inbound: Building Sustainable Growth Engines
- Particularly effective for reaching the mid-market (1-10M GMV) segment
- Establishes thought leadership and brand authority
- Generates content like case studies and benchmarks that enhances outbound campaigns and sales enablement

### Paid Acquisition: Accelerating Growth and Awareness
- Enables rapid testing and optimization cycles
- Builds broader market awareness
- Allows precise targeting parameters to reach specific ICPs
- Extends reach beyond existing Storeleads database

# Recommended Acquisition Channel Mix

## Inbound Foundation 
- Leverage client ecommerce data to create authoritative industry benchmarks and playbooks for each vertical (similar to [Chartmogul SaaS Benchmark Reports](https://chartmogul.com/reports/saas-benchmarks-report/), [Equals guide to SaaS Metrics](https://equals.com/guides/saas-metrics/), [EcommerceFuel Trends Report](https://www.ecommercefuel.com/ecommerce-trends/) or [CTC contents](https://commonthreadco.com/search?q=trend)).
- Develop compelling case studies highlighting specific pain points and measurable outcomes, using internal resources ([example I've done with a client of mine](https://drive.google.com/file/d/19JeAdIlXAQU0cbYteE0yTBGi92ceadUo/view?usp=sharing)) or specialized services like [Testimonial Hero](https://www.testimonialhero.com/).
- Amplify content through owned channels (LinkedIn, Twitter) while securing placement in targeted industry publications and podcasts.
- Channel our inner Anakin and fight with Taylor Holiday on Twitter over marketing attribution 😏

## Paid Acquisition
- Use paid acquisition to build broader market awareness. Could be on LinkedIn, Youtube or Reddit communities.
- Test sponsored content in industry communities / newsletters like [EcommerceFuel](https://www.ecommercefuel.com/), [2PM](https://2pml.com/), and [draft.nu](https://draft.nu/membership/sponsor/).
- Test sponsoring influential industry podcasts like [Honest Ecommerce](https://honestecommerce.co/), [The Unofficial Shopify Podcast](https://unofficialshopifypodcast.com/), and [Ecommerce Conversations](https://www.practicalecommerce.com/tag/podcasts).

## Enhanced Outbound Approach 
- Scale highest-performing campaigns  with refined targeting
- Focus on improving personalization depth rather than simply increasing volume
- Integrate insights + case studies from inbound content to enhance message relevance and credibility

This balanced approach leverages each channel's strengths while building multiple growth engines that can help deliver the ambitious growth target.