# Olist E-Commerce Analytics — Design Spec

Date: 2026-08-27
Status: Approved

## Purpose

Portfolio project for Data Analyst job applications (Australia market). Goal:
prove the ability to take a business question, translate it into SQL, and
produce a stakeholder-actionable recommendation — not just "I can write SQL"
or "I can make charts."

Decision context: candidate is also considering Data Science roles. Decision
made during brainstorming: **this project stays a pure Data Analyst project**
(SQL + BI + written business recommendations). A separate future project
should carry the Data Science signal (proper ML: train/test split, model
comparison, evaluation metrics) — reusing this same Olist dataset is fine,
but as a distinct project/repo, not bolted onto this one. Rationale: one
project done well beats one project doing two things shallowly; DS hiring
managers screen for stats/ML rigor that a BI dashboard doesn't demonstrate,
and folding in a shallow model here would dilute the clean DA narrative this
project is built to prove.

## Candidate context

- SQL: solid (comfortable with joins, aggregation already)
- Dashboard tools (Power BI/Tableau): new
- Target market: Australia → Power BI chosen (shows up more in AU
  corporate/enterprise listings than Tableau)
- Time budget: 1 week, a few hours per night

## Dataset

**Olist Brazilian E-Commerce** (public, Kaggle). ~100K orders, 2016–2018.
Genuinely relational — forces multi-table joins rather than single-flat-CSV
filtering. Tables used: customers, orders, order_items, order_payments,
order_reviews, products, sellers, geolocation, product_category_name_translation.

**Known data trap (deliberate design point, becomes a README callout):**
`customer_id` in the orders table is **order-scoped** — a returning customer
gets a new `customer_id` on every order. True customer identity lives in
`customer_unique_id`. Any repeat-purchase / retention analysis must join on
`customer_unique_id`, not `customer_id`, or the result is silently wrong.
Catching and documenting this is itself part of the "real messiness" proof
point the project is meant to demonstrate.

Other expected messiness to document during load: nulls in delivery dates
(undelivered/cancelled orders), missing reviews, category name
translation gaps, possible duplicate/near-duplicate geolocation rows.

## Business questions (drive everything downstream)

1. Which product categories are declining quarter-over-quarter in revenue?
2. Which states drive the most revenue but have the worst delivery
   performance (actual vs. estimated delivery date)?
3. What's the real repeat-purchase rate by customer cohort (using
   `customer_unique_id`)?
4. How concentrated is revenue among sellers — what % of sellers drive 80%
   of revenue?
5. Where's the mismatch between high revenue and low review scores — which
   categories look good on sales but are quietly damaging brand trust?
6. Are there seasonal spikes worth flagging (e.g. Brazil's Black Friday
   equivalent in November) — is the business prepared for them?

## SQL layer

- Engine: **PostgreSQL** (local). Chosen over BigQuery/SQLite as the most
  commonly listed SQL engine in AU data analyst job ads, free, full window
  function support, clean native Power BI connector.
- `schema.sql` — DDL, reproducible load from raw Olist CSVs (no
  pre-cleaned starting point).
- One `.sql` file per business question (`q1_...sql` through `q6_...sql`),
  each with a comment header stating the business question before the query.
- Technique coverage across the 6 files (not a checklist — each technique
  serves a real question):
  - CTEs: all 6
  - Window functions: Q1 (LAG for QoQ), Q3 (first-order cohort), Q4
    (RANK/cumulative %), Q6 (month-over-month)
  - Multi-table joins: all 6
  - Subquery: Q4
  - GROUP BY/HAVING: Q2, Q5

## Dashboard (Power BI, 2 pages, connects live to Postgres)

**Page 1 — Overview:**
- KPI row: Total Revenue, Total Orders, Repeat Purchase Rate, Avg Delivery
  Delay
- Monthly revenue trend line
- Revenue by category (bar)
- Region/state slicer (cross-filters both pages)

**Page 2 — Deep dive:**
- Seller revenue concentration (Pareto / cumulative % chart)
- Delivery performance by state (map or bar)
- Review score vs. revenue (scatter or table)
- Category QoQ table with conditional formatting flagging declines

Both pages fit one screen — no scrolling. Power BI connects live to the
Postgres database (not a CSV export), so visuals stay correct if underlying
data changes, and it's a stronger resume claim ("connected BI tool directly
to a SQL database").

Publish target: **Power BI Service** (free tier), shared/view link for the
README — not screenshots-only, so the dashboard is clickable/interactive
for a reviewer.

## Written recommendations (`findings.md`)

One entry per business question (not one project-wide paragraph), 3-4
sentences each, following: **finding → likely cause → recommended action**.

Example shape: "Category X revenue down 12% QoQ while review scores hold
steady, ruling out a quality problem — points to pricing or competitive
pressure, not demand collapse. Recommend a promo test on category X next
quarter before cutting inventory allocation."

Numbers in findings.md must come from the actual queries run against the
real data — no placeholder/fabricated figures in the final version.

## Repo structure

```
olist-ecommerce-analytics/
├── README.md
├── sql/
│   ├── schema.sql
│   ├── q1_category_decline.sql
│   ├── q2_region_delivery.sql
│   ├── q3_repeat_purchase_cohort.sql
│   ├── q4_seller_concentration.sql
│   ├── q5_revenue_vs_reviews.sql
│   └── q6_seasonality.sql
├── findings.md
├── dashboard/
│   └── olist_dashboard.pbix
└── data/                  (gitignored — raw CSVs not committed; README
                             links the Kaggle source instead)
```

**README contents:** 1-paragraph problem framing → 6 business questions →
SQL techniques used (described in context, not as a skills list) →
dashboard screenshot + Power BI Service published link → link to
findings.md → resume bullet.

**Draft resume bullet** (fill in the real category/number once queries run
— do not fabricate ahead of time):
> "Analyzed 100K+ Brazilian e-commerce transactions using PostgreSQL (CTEs,
> window functions, multi-table joins) and built an interactive Power BI
> dashboard; identified [category]'s [X]% QoQ revenue decline and seller
> revenue concentration, recommending targeted pricing action."

## Timeline (1 week, a few hours/night)

- **Night 1–2:** Postgres setup, load Olist CSVs, `schema.sql`, sanity
  checks (row counts, nulls, the `customer_id` vs `customer_unique_id`
  trap) — document what's dirty as it's found.
- **Night 3–4:** Write and verify all 6 SQL queries against real loaded data.
- **Night 5–6:** Build Power BI dashboard, connect live to Postgres.
- **Night 7:** `findings.md`, `README.md`, publish to Power BI Service,
  finalize resume bullet with real numbers.

## Out of scope

- Any ML/predictive modeling (churn, CLV, forecasting) — deliberately
  deferred to a separate future DS-focused project.
- Tableau — Power BI only, per AU market fit decision.
- Additional dashboard pages beyond 2 — one-screen constraint is deliberate.
