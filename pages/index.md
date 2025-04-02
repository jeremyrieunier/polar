---
title: Welcome to Evidence
---

## Assessing Outbound Effectiveness
The growth team at Polar is responsible for lead generation, with the sales team handling conversion of these opportunities into customers. Thus, the goals of these outbound campaigns are:

1. Generate qualified pipeline opportunities for the sales team to work on
2. Engage ICP companies with relevant messaging

Given these goals, the ideal Top KPI for the outbound campaigns is Pipeline Value per Company Touched because:

1. It directly measures how efficiently outbound efforts generate pipeline value
2. It aligns with the growth team's primary goal of creating opportunities for the sales team
3. It accounts for both the quality and quantity of outreach

This metric is calculated as follows:
> PIPELINE_OPP_AMOUNT_FROM_OB_ALL_TIME / NB_COMPANIES_TOUCHED

### Supporting Metrics
While Pipeline Value per Company is the primary metric, I recommend tracking these supporting metrics to provide context:

**Pipeline Revenue Win Rate**: While the growth team does not own this metric, it measures how effectively the sales team converts pipeline opportunities into actual revenue. It highlights alignment between growth and sales teams and identifies which types of opportunities close at a higher rate.

This metric is calculated as follows:
> NEW_ARR_FROM_OB_ALL_TIME / PIPELINE_OPP_AMOUNT_FROM_OB_ALL_TIME

**ARR per Company Touched**: This metric shows the complete business impact of outbound efforts, capturing both pipeline generation efficiency and sales conversion effectiveness.

This metric is calculated as follows:
> NEW_ARR_FROM_OB_ALL_TIME / NB_COMPANIES_TOUCHED

**ICP Targeting Accuracy**: This metric measures how well campaigns focus on the ideal customer profile.

This metric is calculated as follows:
> (TOTAL_NB_POSITIVE_REPLIES_PER_CAMPAIGN / NB_COMPANIES_TOUCHED) × 100%



```sql categories
  select
      category
  from needful_things.orders
  group by category
```

<Dropdown data={categories} name=category value=category>
    <DropdownOption value="%" valueLabel="All Categories"/>
</Dropdown>

<Dropdown name=year>
    <DropdownOption value=% valueLabel="All Years"/>
    <DropdownOption value=2019/>
    <DropdownOption value=2020/>
    <DropdownOption value=2021/>
</Dropdown>

```sql orders_by_category
  select 
      date_trunc('month', order_datetime) as month,
      sum(sales) as sales_usd,
      category
  from needful_things.orders
  where category like '${inputs.category.value}'
  and date_part('year', order_datetime) like '${inputs.year.value}'
  group by all
  order by sales_usd desc
```

<BarChart
    data={orders_by_category}
    title="Sales by Month, {inputs.category.label}"
    x=month
    y=sales_usd
    series=category
/>

```sql hello
  select *
  from outbound.campaigns
```

```sql tenants
select *
from growth.tenants
limit 10
```

## What's Next?
- [Connect your data sources](settings)
- Edit/add markdown files in the `pages` folder
- Deploy your project with [Evidence Cloud](https://evidence.dev/cloud)

## Get Support
- Message us on [Slack](https://slack.evidence.dev/)
- Read the [Docs](https://docs.evidence.dev/)
- Open an issue on [Github](https://github.com/evidence-dev/evidence)
