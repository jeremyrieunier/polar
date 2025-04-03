# Assessing Outbound Effectiveness
The growth team at Polar is responsible for lead generation, with the sales team handling conversion of these opportunities into customers. Thus, the goals of these outbound campaigns are:

1. Generate qualified pipeline opportunities for the sales team to work on
2. Engage ICP companies with relevant messaging

## Primary KPI Recommendation
Given these goals, the ideal Top KPI for the outbound campaigns is **Pipeline Value per Company Touched** because it:

- Directly measures how efficiently outbound efforts generate pipeline value
- Aligns with the growth team's primary goal of creating opportunities for the sales team and keeps it accountable
- Accounts for both the quality and quantity of outreach

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
This metric measures how well campaigns focus on the Ideal Customer Profile (ICP).

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
- Consider developing similar campaigns with high-quality messaging

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
To estimate the potential New ARR from scaling outbound to our entire TAM, I'll use a simplified approach applying the average deal size from previous outbound campaigns to different conversion rate scenarios.

```sql outbound_campaigns
select
  sum(NB_COMPANIES_TOUCHED) as companies_touched,
  sum(NEW_ARR_FROM_OB_ALL_TIME) as aar_value_created,
  sum(NB_CUSTOMERS_FROM_OB_ALL_TIME) as accounts_acquired,
  sum(NB_CUSTOMERS_FROM_OB_ALL_TIME) / sum(NB_COMPANIES_TOUCHED) as conversion_rate,
  sum(NEW_ARR_FROM_OB_ALL_TIME) / sum(NB_CUSTOMERS_FROM_OB_ALL_TIME) as average_deal_size
from outbound.campaigns
```
<DataTable data={outbound_campaigns}/>

### Key Caveats
- **Conversion rate based on overlapped data**: Calculated conversion rate (0.042%) is based on raw campaign data where some companies may have been counted multiple times across different campaigns.

- **Varying conversion by GMV tier**: Different GMV tiers likely have different propensities to convert, though our current data doesn't explicitly segment performance by customer size.

- **Blended approach**: I'm using overall conversion rates and applying our historical average deal size ($11,147) uniformly across all customer segments, which simplifies the analysis but may not reflect segment-specific differences.

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
## Current Growth Challenge
Polar currently generates $3M in ARR but aims to reach $10M by year-end. This requires an additional $7M in net new ARR. My analysis shows that even with optimistic projections, outbound strategies alone will only deliver between $847K-$1.84M in new ARR.

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
- Leverage client ecommerce data to create authoritative industry benchmarks and playbooks for each vertical (similar to [Chartmogul SaaS Benchmark Reports](https://chartmogul.com/reports/saas-benchmarks-report/), [EcommerceFuel Trends Report](https://www.ecommercefuel.com/ecommerce-trends/) or [CTC contents](https://commonthreadco.com/search?q=trend)).
- Develop compelling case studies highlighting specific pain points and measurable outcomes, using internal resources ([example I've done with a client of mine](https://drive.google.com/file/d/19JeAdIlXAQU0cbYteE0yTBGi92ceadUo/view?usp=sharing)) or specialized services like Testimonial Hero 
- Amplify content through owned channels (LinkedIn, Twitter) while securing placement in targeted industry publications and podcasts.
- Fight with Taylor Holiday on Twitter over marketing attribution.

## Paid Acquisition
- Use paid acquisition to build broader market awareness. Could be on LinkedIn, Youtube or Reddit communities.
- Test sponsored content in industry communities / newsletters like [EcommerceFuel](https://www.ecommercefuel.com/), [2PM](https://2pml.com/), and [draft.nu](https://draft.nu/membership/sponsor/).
- Test sponsoring influential industry podcasts including Honest Ecommerce, The Unofficial Shopify Podcast, and Ecommerce Conversations.

## Enhanced Outbound Approach 
- Scale highest-performing campaigns  with refined targeting
- Focus on improving personalization depth rather than simply increasing volume
- Integrate insights + case studies from inbound content to enhance message relevance and credibility

This balanced approach leverages each channel's strengths while building multiple growth engines that can help deliver the ambitious growth target.