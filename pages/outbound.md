# Assessing Outbound Effectiveness
The growth team at Polar is responsible for lead generation, with the sales team handling conversion of these opportunities into customers. Thus, the goals of these outbound campaigns are:

1. Generate qualified pipeline opportunities for the sales team to work on
2. Engage ICP companies with relevant messaging

Given these goals, the ideal Top KPI for the outbound campaigns is **Pipeline Value per Company Touched** because:

1. It directly measures how efficiently outbound efforts generate pipeline value
2. It aligns with the growth team's primary goal of creating opportunities for the sales team
3. It accounts for both the quality and quantity of outreach

This metric is calculated as follows:
> PIPELINE_OPP_AMOUNT_FROM_OB_ALL_TIME / NB_COMPANIES_TOUCHED

## Supporting Metrics
While Pipeline Value per Company is the primary metric, I recommend tracking these supporting metrics to provide context:

**Pipeline Revenue Win Rate**: While the growth team does not own this metric, it measures how effectively the sales team converts pipeline opportunities into actual revenue. It highlights alignment between growth and sales teams and identifies which types of opportunities close at a higher rate.

This metric is calculated as follows:
> NEW_ARR_FROM_OB_ALL_TIME / PIPELINE_OPP_AMOUNT_FROM_OB_ALL_TIME

**ARR per Company Touched**: This metric shows the complete business impact of outbound efforts, capturing both pipeline generation efficiency and sales conversion effectiveness.

This metric is calculated as follows:
> NEW_ARR_FROM_OB_ALL_TIME / NB_COMPANIES_TOUCHED

**ICP Targeting Accuracy**: This metric measures how well campaigns focus on the ideal customer profile.

This metric is calculated as follows:
> (NB_COMPANIES_TOUCHED_ICP / NB_COMPANIES_TOUCHED) × 100%

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
To properly evaluate campaign performance, we must consider both efficiency (Pipeline Value per Company Touched), scale (number of companies touched), and impact (total pipeline generated) using a matrix approach:

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
chartAreaHeight=350
/>

## Best Overall Performers

### GPT V3 - CAPI and Klaviyo flows enrich

These campaigns generate substantial pipeline with good efficiency, striking a balance between reach and performance.

Action Plan:
- Conduct segmentation analysis to identify highest-performing subgroups
- Optimize messaging and improve efficiency
- Maintain current scale while working to push efficiency metrics above $25 per company

## High Efficiency, Low Scale (Growth Potential)
### Technology intent, Ask Polar Lite, Demo App Nurture
These campaigns show promising efficiency but need expansion

Action Plan:
- Scale up these campaigns to reach more companies while monitoring efficiency metrics
- Preserve the targeting precision and messaging quality
- Consider developing similar campaigns with high-quality messagin

## Low Efficiency, High Scale (Optimization Needed)
### GA4, Loom, BFCM
These campaigns reach a significant number of companies but underperform in generating pipeline value.

Action plan:
- Improve messaging or targeting to increase efficiency
- Develop segment-specific messaging based on industry and company size

## Low Efficiency, Low Scale (Reconsider)
### Fashion / Multiple Products
This campaign underperforms on both critical dimensions, indicating fundamental issues.

Action plan:
- Identify specific failure points
- Text new messaging if the segment remains important
- Consider relocating resources to other campaigns

