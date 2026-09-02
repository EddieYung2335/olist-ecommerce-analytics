# Findings & Recommendations

**Scope:** delivered orders only, revenue = `SUM(order_items.price)`. The last
delivered order was purchased 2018-08-29, so the final month and quarter are
partial. Anywhere a trailing period is involved, that is called out below —
several of these numbers look worse than reality if the truncation is ignored.

## Q1 - Category QoQ revenue decline

`musical_instruments` is the clearest warning sign. It grew for five straight quarters through Q2 2018, then dropped 66.1% in Q3 (54,310.30 to 18,391.27). Part of that is the truncated window — 2018-Q3 holds two months against three — but per month it is still 18,103 in Q2 against 9,196 in Q3, a 49% fall. Quality isn't the cause: 4.22 stars, above the 4.11 category mean (both from the `category_stats` CTE in `sql/q5_revenue_vs_reviews.sql`, before the below-average filter).

`computers` and `fixed_telephony` also show sharp declines, but they rebound hard the next quarter. That whiplash is noise, not a signal. `small_appliances_home_oven_and_coffee` is still ramping — too new to judge.

**Recommend:** Audit `musical_instruments` for pricing, promotion timing, and inventory gaps before cutting spend. Monitor the volatile decliners but don't act on them yet.

## Q2 - Region revenue vs delivery performance

SP generates the most revenue (5.1M), but it's also the shakiest delivery-wise.

| State | Revenue | Early by (days) |
|-------|---------|---|
| SP | 5,066,563 | 10.3 |
| RJ | 1,759,651 | 11.1 |
| MG | 1,552,482 | 12.4 |
| RS | 728,718 | 13.2 |
| PR | 666,064 | 12.5 |

SP has the thinnest margin for error. A carrier or fulfillment stumble in your biggest market compounds fast.

**Recommend:** Audit the carriers and fulfillment mix in SP before scaling marketing spend there.

## Q3 - Repeat-purchase rate by cohort

True repeat rate (joined on `customer_unique_id`, not `customer_id`): 3.0% overall. 2,801 repeat customers out of 93,358.

It's also declining, though not as steeply as the raw cohort table suggests — recent cohorts have had less time to come back, and the 0.6% on August 2018 is mostly that. Comparing only cohorts with at least six months of runway: January 2017 repeated at 7.3%, February 2018 at 3.8%. The rate roughly halved in a year. The platform is acquiring one-time buyers much faster than it's converting them into repeat buyers.

**Recommend:** Run a retention campaign targeting single-purchase customers, especially in the first 30 days after delivery when the relationship is warmest.

## Q4 - Seller revenue concentration

533 sellers (17.9% of the 2,970 with delivered revenue) generate the first 80% of revenue. Lose that group and four fifths of revenue goes with it.

**Recommend:** Assign account managers to the top sellers. Simultaneously, recruit new sellers in low-concentration categories to build redundancy.

## Q5 - Revenue vs review score mismatch

`watches_gifts` generates 1.17M in revenue — the highest of any category scoring below the 4.11 average — but scores 4.07. Only `health_beauty` sells more overall (1.23M), and it scores 4.19.

High revenue + below-average satisfaction = brand risk. A quality issue here touches thousands of customers.

**Recommend:** Audit `watches_gifts` for product accuracy, delivery damage, and seller-level quality gaps before increasing promotion.

## Q6 - Seasonality

November 2017 order volume jumped 62.8% (4,478 → 7,289 delivered orders), with revenue up 52% (648K → 988K). Brazil's Black Friday effect. December fell back to 726K. It's the only spike in the series — 2018 has no November to compare, since the data stops at August.

SP is the largest state by revenue (Q2) and has the tightest delivery buffer of the top five, so inventory and capacity planning for Black Friday is most critical there.

**Recommend:** Plan November inventory and delivery capacity now. Extra attention to SP fulfillment.
