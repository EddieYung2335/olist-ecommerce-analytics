# Olist E-Commerce Analytics Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Data Analyst portfolio project on the Olist e-commerce dataset that proves business-question → SQL → stakeholder-recommendation translation, packaged as a PostgreSQL query set + a 2-page Power BI dashboard + written findings.

**Architecture:** Raw Olist CSVs load into a normalized PostgreSQL schema. Six standalone `.sql` files each answer one business question, demonstrating CTEs, window functions, multi-table joins, subqueries, and GROUP BY/HAVING. Power BI connects live to Postgres (not CSV) for the dashboard. `findings.md` translates each query's output into a stakeholder recommendation.

**Tech Stack:** PostgreSQL (local), Power BI Desktop + Power BI Service (free tier), psql CLI.

**Spec:** `docs/superpowers/specs/2026-08-27-olist-ecommerce-analytics-design.md`

## Global Constraints

- Engine: PostgreSQL (local) — not BigQuery, not SQLite.
- Dashboard tool: Power BI only — not Tableau (AU market fit decision).
- Dashboard: exactly 2 pages, each fits one screen — no scrolling, no third page.
- Power BI connects **live** to Postgres — not a CSV import.
- Publish target: Power BI Service (free tier) with a shared/view link.
- Repeat-purchase / customer-identity analysis MUST join on `customer_unique_id`, never the order-scoped `customer_id` — this is the dataset's known trap (see spec).
- Numbers written into `findings.md` and the README resume bullet must come from actual query output against loaded data — never fabricated ahead of time.
- Out of scope: no ML/predictive modeling in this repo (deferred to a separate future project per spec decision).
- Geolocation table is out of scope — none of the 6 business questions need lat/lng, state codes on `customers`/`sellers` are sufficient (YAGNI trim from the full Olist dataset).

---

## Task 1: Project scaffolding, schema, and data load

**Files:**
- Create: `schema.sql`
- Create: `scripts/load_data.sh`
- Create: `.gitignore`
- Create: `data/raw/` (directory, gitignored contents)

**Interfaces:**
- Consumes: nothing (first task)
- Produces: Postgres database `olist` with tables `customers`, `orders`, `sellers`, `products`, `order_items`, `order_payments`, `order_reviews`, `product_category_translation`, fully loaded — all later SQL tasks query these tables directly by name.

- [ ] **Step 1: Create the database and schema file**

```sql
-- schema.sql
CREATE TABLE customers (
    customer_id VARCHAR(32) PRIMARY KEY,
    customer_unique_id VARCHAR(32) NOT NULL,
    customer_zip_code_prefix VARCHAR(10),
    customer_city VARCHAR(100),
    customer_state VARCHAR(2)
);

CREATE TABLE sellers (
    seller_id VARCHAR(32) PRIMARY KEY,
    seller_zip_code_prefix VARCHAR(10),
    seller_city VARCHAR(100),
    seller_state VARCHAR(2)
);

CREATE TABLE products (
    product_id VARCHAR(32) PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_name_lenght INT,
    product_description_lenght INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
);

CREATE TABLE product_category_translation (
    product_category_name VARCHAR(100) PRIMARY KEY,
    product_category_name_english VARCHAR(100)
);

CREATE TABLE orders (
    order_id VARCHAR(32) PRIMARY KEY,
    customer_id VARCHAR(32) REFERENCES customers(customer_id),
    order_status VARCHAR(20),
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP
);

CREATE TABLE order_items (
    order_id VARCHAR(32) REFERENCES orders(order_id),
    order_item_id INT,
    product_id VARCHAR(32) REFERENCES products(product_id),
    seller_id VARCHAR(32) REFERENCES sellers(seller_id),
    shipping_limit_date TIMESTAMP,
    price NUMERIC(10,2),
    freight_value NUMERIC(10,2),
    PRIMARY KEY (order_id, order_item_id)
);

CREATE TABLE order_payments (
    order_id VARCHAR(32) REFERENCES orders(order_id),
    payment_sequential INT,
    payment_type VARCHAR(20),
    payment_installments INT,
    payment_value NUMERIC(10,2),
    PRIMARY KEY (order_id, payment_sequential)
);

-- No PK here: the raw Olist review CSV has known duplicate
-- (review_id, order_id) rows. An index is enough for our joins.
CREATE TABLE order_reviews (
    review_id VARCHAR(32),
    order_id VARCHAR(32) REFERENCES orders(order_id),
    review_score INT,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP
);
CREATE INDEX idx_order_reviews_order_id ON order_reviews(order_id);
```

Run: `createdb olist && psql olist -f schema.sql`
Expected: 8 `CREATE TABLE` confirmations, no errors.

- [ ] **Step 2: Download the raw CSVs manually**

Go to the Olist dataset on Kaggle ("Brazilian E-Commerce Public Dataset by Olist"), download, and extract all CSVs into `data/raw/`. Expected files:
`olist_customers_dataset.csv`, `olist_orders_dataset.csv`, `olist_sellers_dataset.csv`, `olist_products_dataset.csv`, `olist_order_items_dataset.csv`, `olist_order_payments_dataset.csv`, `olist_order_reviews_dataset.csv`, `product_category_name_translation.csv`.

Run: `ls data/raw/`
Expected: all 8 filenames listed above.

- [ ] **Step 3: Write the load script**

```bash
#!/bin/bash
# scripts/load_data.sh
set -e
DB=olist

psql "$DB" <<SQL
\copy customers FROM 'data/raw/olist_customers_dataset.csv' CSV HEADER
\copy sellers FROM 'data/raw/olist_sellers_dataset.csv' CSV HEADER
\copy products FROM 'data/raw/olist_products_dataset.csv' CSV HEADER
\copy product_category_translation FROM 'data/raw/product_category_name_translation.csv' CSV HEADER
\copy orders FROM 'data/raw/olist_orders_dataset.csv' CSV HEADER
\copy order_items FROM 'data/raw/olist_order_items_dataset.csv' CSV HEADER
\copy order_payments FROM 'data/raw/olist_order_payments_dataset.csv' CSV HEADER
\copy order_reviews FROM 'data/raw/olist_order_reviews_dataset.csv' CSV HEADER
SQL
```

Run: `chmod +x scripts/load_data.sh && ./scripts/load_data.sh`
Expected: 8 `COPY <n>` lines, no constraint-violation errors. If `orders` or `order_items` COPY fails on a foreign key, it means load order was wrong — parent tables (`customers`, `sellers`, `products`) must load before children (`orders`, `order_items`); the script above already orders them correctly.

- [ ] **Step 4: Verify row counts**

Run:
```bash
psql olist -c "SELECT 'customers', count(*) FROM customers
UNION ALL SELECT 'orders', count(*) FROM orders
UNION ALL SELECT 'order_items', count(*) FROM order_items
UNION ALL SELECT 'order_payments', count(*) FROM order_payments
UNION ALL SELECT 'order_reviews', count(*) FROM order_reviews
UNION ALL SELECT 'products', count(*) FROM products
UNION ALL SELECT 'sellers', count(*) FROM sellers;"
```
Expected: `orders` ~99,441 rows, `customers` ~99,441 rows, `order_items` ~112,650 rows (approximate — exact counts depend on the Kaggle snapshot downloaded; all should be non-zero and in the same order of magnitude).

- [ ] **Step 5: Write `.gitignore` and commit**

```
data/raw/
*.pbix.bak
```

(`.pbix` itself is committed later in Task 9/10 — it's a small binary and is the deliverable, not a build artifact.)

```bash
git add schema.sql scripts/load_data.sh .gitignore
git commit -m "Add Postgres schema and data load script for Olist dataset"
```

---

## Task 2: Data quality sanity checks

**Files:**
- Create: `sql/checks.sql`
- Create: `sql/checks_findings.md`

**Interfaces:**
- Consumes: loaded tables from Task 1.
- Produces: `sql/checks_findings.md` documenting the dataset's real messiness — referenced from the README's "known data issues" section (Task 12).

- [ ] **Step 1: Write the checks query file**

```sql
-- sql/checks.sql

-- 1. The core trap: customer_id is order-scoped, customer_unique_id is the real person.
SELECT
    COUNT(DISTINCT customer_id) AS distinct_customer_ids,
    COUNT(DISTINCT customer_unique_id) AS distinct_real_customers
FROM customers;
-- distinct_real_customers < distinct_customer_ids proves repeat customers exist
-- and that customer_id alone would undercount every repeat purchaser as new.

-- 2. Delivered orders missing a delivery date (shouldn't happen, but Olist has some).
SELECT COUNT(*) AS delivered_but_no_delivery_date
FROM orders
WHERE order_status = 'delivered' AND order_delivered_customer_date IS NULL;

-- 3. Products with a category name that has no English translation.
SELECT DISTINCT p.product_category_name
FROM products p
LEFT JOIN product_category_translation t
    ON t.product_category_name = p.product_category_name
WHERE t.product_category_name_english IS NULL
    AND p.product_category_name IS NOT NULL;

-- 4. Duplicate rows in order_reviews (known Olist data issue).
SELECT review_id, order_id, COUNT(*)
FROM order_reviews
GROUP BY review_id, order_id
HAVING COUNT(*) > 1;

-- 5. Products with a NULL category entirely.
SELECT COUNT(*) AS products_missing_category
FROM products
WHERE product_category_name IS NULL;
```

Run: `psql olist -f sql/checks.sql`
Expected: all 5 queries return without error. Query 1's two counts should differ (fewer unique customers than customer_ids). Queries 2-5 return the actual dirty-row counts — record whatever numbers come back, don't expect zero.

- [ ] **Step 2: Record findings from the actual output**

Write `sql/checks_findings.md` with the real numbers from Step 1's output, e.g.:

```markdown
# Data Quality Findings

- Distinct customer_id: <actual number> vs distinct customer_unique_id: <actual number>
  → confirms customer_id is order-scoped; all cohort/repeat-purchase analysis
    must use customer_unique_id.
- <actual number> delivered orders have a NULL delivery date.
- <actual number> product categories have no English translation — these are
  displayed under their original Portuguese name in all downstream queries.
- <actual number> duplicate (review_id, order_id) pairs found in order_reviews —
  this is why order_reviews has no primary key constraint in schema.sql.
- <actual number> products have a NULL category name.
```

- [ ] **Step 3: Commit**

```bash
git add sql/checks.sql sql/checks_findings.md
git commit -m "Add data quality sanity checks and document known Olist data issues"
```

---

## Task 3: Q1 — Category QoQ revenue decline

**Files:**
- Create: `sql/q1_category_decline.sql`

**Interfaces:**
- Consumes: `orders`, `order_items`, `products`, `product_category_translation` (Task 1).
- Produces: result columns `(category, quarter, revenue, prev_quarter_revenue, pct_change)` — consumed by the dashboard's category QoQ table (Task 10) and `findings.md` Q1 entry (Task 11).

- [ ] **Step 1: Write the query**

```sql
-- sql/q1_category_decline.sql
-- Business question: Which product categories are declining
-- quarter-over-quarter in revenue?

WITH category_rev AS (
    SELECT
        COALESCE(t.product_category_name_english, p.product_category_name) AS category,
        DATE_TRUNC('quarter', o.order_purchase_timestamp) AS quarter,
        SUM(oi.price) AS revenue
    FROM order_items oi
    JOIN orders o ON o.order_id = oi.order_id
    JOIN products p ON p.product_id = oi.product_id
    LEFT JOIN product_category_translation t
        ON t.product_category_name = p.product_category_name
    WHERE o.order_status = 'delivered'
    GROUP BY 1, 2
),
qoq AS (
    SELECT
        category,
        quarter,
        revenue,
        LAG(revenue) OVER (PARTITION BY category ORDER BY quarter) AS prev_quarter_revenue
    FROM category_rev
)
SELECT
    category,
    quarter,
    revenue,
    prev_quarter_revenue,
    ROUND(100.0 * (revenue - prev_quarter_revenue) / NULLIF(prev_quarter_revenue, 0), 1) AS pct_change
FROM qoq
WHERE prev_quarter_revenue IS NOT NULL
ORDER BY category, quarter;
```

- [ ] **Step 2: Run and verify**

Run: `psql olist -f sql/q1_category_decline.sql`
Expected: rows with non-null `category`, `quarter` values between 2016-2017-01-01 and 2018-01-01, `pct_change` values (both positive and negative present — if every row is positive, the LAG direction or WHERE filter is wrong).

- [ ] **Step 3: Commit**

```bash
git add sql/q1_category_decline.sql
git commit -m "Add Q1 query: category QoQ revenue decline"
```

---

## Task 4: Q2 — Region revenue vs. delivery performance

**Files:**
- Create: `sql/q2_region_delivery.sql`

**Interfaces:**
- Consumes: `orders`, `customers`, `order_items` (Task 1).
- Produces: result columns `(customer_state, total_revenue, total_orders, avg_delivery_delay_days)` — consumed by the dashboard's delivery-by-state chart (Task 10) and `findings.md` Q2 entry (Task 11).

- [ ] **Step 1: Write the query**

```sql
-- sql/q2_region_delivery.sql
-- Business question: Which states drive the most revenue but have
-- the worst delivery performance?

WITH order_delivery AS (
    SELECT
        o.order_id,
        c.customer_state,
        oi.price,
        EXTRACT(DAY FROM (o.order_delivered_customer_date - o.order_estimated_delivery_date)) AS delivery_delay_days
    FROM orders o
    JOIN customers c ON c.customer_id = o.customer_id
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
)
SELECT
    customer_state,
    SUM(price) AS total_revenue,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(AVG(delivery_delay_days), 1) AS avg_delivery_delay_days
FROM order_delivery
GROUP BY customer_state
HAVING SUM(price) > 0
ORDER BY total_revenue DESC;
```

(Positive `avg_delivery_delay_days` means delivered later than estimated; negative means early.)

- [ ] **Step 2: Run and verify**

Run: `psql olist -f sql/q2_region_delivery.sql`
Expected: one row per Brazilian state (2-letter codes like SP, RJ, MG), `total_revenue` descending, `avg_delivery_delay_days` mostly negative (Olist tends to deliver early) with a few states positive.

- [ ] **Step 3: Commit**

```bash
git add sql/q2_region_delivery.sql
git commit -m "Add Q2 query: region revenue vs delivery performance"
```

---

## Task 5: Q3 — Repeat-purchase rate by cohort

**Files:**
- Create: `sql/q3_repeat_purchase_cohort.sql`

**Interfaces:**
- Consumes: `orders`, `customers` (Task 1) — MUST join on `customer_unique_id` per Global Constraints.
- Produces: result columns `(cohort_month, cohort_size, repeat_customers, repeat_rate_pct)` — consumed by the dashboard's Repeat Purchase Rate KPI (Task 9) and `findings.md` Q3 entry (Task 11).

- [ ] **Step 1: Write the query**

```sql
-- sql/q3_repeat_purchase_cohort.sql
-- Business question: What's the real repeat-purchase rate by customer
-- cohort? Uses customer_unique_id, not the order-scoped customer_id
-- (see sql/checks_findings.md for why this matters).

WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        o.order_id,
        o.order_purchase_timestamp,
        MIN(o.order_purchase_timestamp) OVER (PARTITION BY c.customer_unique_id) AS first_purchase_date
    FROM orders o
    JOIN customers c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
),
cohort AS (
    SELECT
        customer_unique_id,
        DATE_TRUNC('month', first_purchase_date) AS cohort_month,
        COUNT(DISTINCT order_id) AS total_orders
    FROM customer_orders
    GROUP BY 1, 2
)
SELECT
    cohort_month,
    COUNT(*) AS cohort_size,
    SUM(CASE WHEN total_orders > 1 THEN 1 ELSE 0 END) AS repeat_customers,
    ROUND(100.0 * SUM(CASE WHEN total_orders > 1 THEN 1 ELSE 0 END) / COUNT(*), 1) AS repeat_rate_pct
FROM cohort
GROUP BY cohort_month
ORDER BY cohort_month;
```

- [ ] **Step 2: Run and verify**

Run: `psql olist -f sql/q3_repeat_purchase_cohort.sql`
Expected: one row per month from 2016-09 through 2018-08ish, `repeat_rate_pct` values — Olist's true repeat rate is known to be low (single digits). If any row shows >50%, the join is still using `customer_id` instead of `customer_unique_id` — check the join condition.

- [ ] **Step 3: Commit**

```bash
git add sql/q3_repeat_purchase_cohort.sql
git commit -m "Add Q3 query: repeat-purchase rate by cohort (customer_unique_id)"
```

---

## Task 6: Q4 — Seller revenue concentration

**Files:**
- Create: `sql/q4_seller_concentration.sql`

**Interfaces:**
- Consumes: `order_items`, `orders` (Task 1).
- Produces: result columns `(seller_id, revenue, revenue_rank, cumulative_pct_of_revenue)` — consumed by the dashboard's Pareto chart (Task 10) and `findings.md` Q4 entry (Task 11).

- [ ] **Step 1: Write the query**

```sql
-- sql/q4_seller_concentration.sql
-- Business question: How concentrated is revenue among sellers —
-- what % of sellers drive 80% of revenue?

WITH seller_rev AS (
    SELECT oi.seller_id, SUM(oi.price) AS revenue
    FROM order_items oi
    JOIN orders o ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY oi.seller_id
),
ranked AS (
    SELECT
        seller_id,
        revenue,
        RANK() OVER (ORDER BY revenue DESC) AS revenue_rank,
        SUM(revenue) OVER (ORDER BY revenue DESC) AS running_total
    FROM seller_rev
)
SELECT
    seller_id,
    revenue,
    revenue_rank,
    ROUND(100.0 * running_total / (SELECT SUM(revenue) FROM seller_rev), 1) AS cumulative_pct_of_revenue
FROM ranked
ORDER BY revenue_rank;
```

- [ ] **Step 2: Run and verify**

Run: `psql olist -f sql/q4_seller_concentration.sql`
Expected: rows ordered by `revenue_rank` ascending, `cumulative_pct_of_revenue` monotonically increasing toward 100.0 on the last row. Find the row where it first crosses 80 — that row's `revenue_rank` divided by total seller count (from `sql/checks.sql`-style `SELECT COUNT(*) FROM seller_rev`) is the "% of sellers driving 80% of revenue" figure for `findings.md`.

- [ ] **Step 3: Commit**

```bash
git add sql/q4_seller_concentration.sql
git commit -m "Add Q4 query: seller revenue concentration"
```

---

## Task 7: Q5 — Revenue vs. review score mismatch

**Files:**
- Create: `sql/q5_revenue_vs_reviews.sql`

**Interfaces:**
- Consumes: `order_items`, `orders`, `products`, `product_category_translation`, `order_reviews` (Task 1).
- Produces: result columns `(category, revenue, avg_review_score)` — consumed by `findings.md` Q5 entry (Task 11) and the dashboard's review-vs-revenue table (Task 10).

- [ ] **Step 1: Write the query**

```sql
-- sql/q5_revenue_vs_reviews.sql
-- Business question: Where's the mismatch between high revenue and
-- low review scores — which categories look good on sales but are
-- quietly damaging brand trust?

WITH category_stats AS (
    SELECT
        COALESCE(t.product_category_name_english, p.product_category_name) AS category,
        SUM(oi.price) AS revenue,
        AVG(r.review_score) AS avg_review_score
    FROM order_items oi
    JOIN orders o ON o.order_id = oi.order_id
    JOIN products p ON p.product_id = oi.product_id
    LEFT JOIN product_category_translation t
        ON t.product_category_name = p.product_category_name
    LEFT JOIN order_reviews r ON r.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY 1
    HAVING SUM(oi.price) > 10000  -- drop tiny categories, they're noise
)
SELECT
    category,
    revenue,
    ROUND(avg_review_score, 2) AS avg_review_score
FROM category_stats
WHERE avg_review_score < (SELECT AVG(avg_review_score) FROM category_stats)
ORDER BY revenue DESC;
```

- [ ] **Step 2: Run and verify**

Run: `psql olist -f sql/q5_revenue_vs_reviews.sql`
Expected: a non-empty list of categories (fewer than the full category count), all with `avg_review_score` below the overall average and `revenue` above the $10,000 floor. If empty, the $10,000 threshold may be too high for the loaded dataset — lower it and re-run.

- [ ] **Step 3: Commit**

```bash
git add sql/q5_revenue_vs_reviews.sql
git commit -m "Add Q5 query: revenue vs review score mismatch"
```

---

## Task 8: Q6 — Seasonality

**Files:**
- Create: `sql/q6_seasonality.sql`

**Interfaces:**
- Consumes: `orders`, `order_items` (Task 1).
- Produces: result columns `(month, total_orders, revenue, prev_month_orders, mom_pct_change)` — consumed by the dashboard's monthly revenue trend line (Task 9) and `findings.md` Q6 entry (Task 11).

- [ ] **Step 1: Write the query**

```sql
-- sql/q6_seasonality.sql
-- Business question: Are there seasonal spikes worth flagging
-- (e.g. Brazil's November Black Friday equivalent)?

WITH monthly_orders AS (
    SELECT
        DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(oi.price) AS revenue
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY 1
)
SELECT
    month,
    total_orders,
    revenue,
    LAG(total_orders) OVER (ORDER BY month) AS prev_month_orders,
    ROUND(
        100.0 * (total_orders - LAG(total_orders) OVER (ORDER BY month))
        / NULLIF(LAG(total_orders) OVER (ORDER BY month), 0), 1
    ) AS mom_pct_change
FROM monthly_orders
ORDER BY month;
```

- [ ] **Step 2: Run and verify**

Run: `psql olist -f sql/q6_seasonality.sql`
Expected: one row per month, November months showing a positive `mom_pct_change` spike relative to surrounding months (Brazil's "Black Friday" — confirm this pattern shows up; if November looks flat, check that `order_status = 'delivered'` isn't excluding a batch of November orders that were cancelled disproportionately, which would itself be a findings.md-worthy note rather than a bug).

- [ ] **Step 3: Commit**

```bash
git add sql/q6_seasonality.sql
git commit -m "Add Q6 query: seasonality / month-over-month trend"
```

---

## Task 9: Power BI dashboard — Page 1 (Overview)

**Files:**
- Create: `dashboard/olist_dashboard.pbix`

**Interfaces:**
- Consumes: live Postgres connection to the `olist` database (Task 1); reuses the logic from `sql/q3_repeat_purchase_cohort.sql` and `sql/q6_seasonality.sql` as Power Query / DAX measures (Power BI can't run arbitrary CTEs at the visual level, so the query logic is re-expressed as DAX — same result, same tables).
- Produces: `dashboard/olist_dashboard.pbix` file, opened and extended by Task 10.

- [ ] **Step 1: Connect Power BI to Postgres**

In Power BI Desktop: Get Data → PostgreSQL database → host `localhost`, database `olist`. Import (not DirectQuery, to keep this simple) all 8 tables from Task 1.

Run: after load, check the Fields pane lists all 8 tables.
Expected: `customers`, `orders`, `sellers`, `products`, `order_items`, `order_payments`, `order_reviews`, `product_category_translation` all present with row counts matching Task 1 Step 4.

- [ ] **Step 2: Build the KPI row**

Add 4 Card visuals with these DAX measures:

```dax
Total Revenue = SUM(order_items[price])
Total Orders = DISTINCTCOUNT(orders[order_id])
Avg Delivery Delay Days =
    AVERAGEX(
        FILTER(orders, orders[order_status] = "delivered" && NOT(ISBLANK(orders[order_delivered_customer_date]))),
        DATEDIFF(orders[order_estimated_delivery_date], orders[order_delivered_customer_date], DAY)
    )
Repeat Purchase Rate =
    VAR CustomerOrderCounts =
        SUMMARIZE(
            RELATEDTABLE(orders),
            customers[customer_unique_id],
            "OrderCount", DISTINCTCOUNT(orders[order_id])
        )
    VAR RepeatCustomers = COUNTROWS(FILTER(CustomerOrderCounts, [OrderCount] > 1))
    VAR TotalCustomers = COUNTROWS(CustomerOrderCounts)
    RETURN DIVIDE(RepeatCustomers, TotalCustomers)
```

Verify each Card's displayed value against the corresponding SQL query's output (`Total Revenue` vs. the grand total from `sql/q4_seller_concentration.sql`'s `SUM(revenue)`; `Repeat Purchase Rate` vs. the overall rate implied by `sql/q3_repeat_purchase_cohort.sql`'s totals) — they must match within rounding.

- [ ] **Step 3: Build the trend line and category bar**

Add a Line Chart: X-axis `orders[order_purchase_timestamp]` (set to Month granularity), Y-axis `Total Revenue` measure. Add a Bar Chart: axis `product_category_translation[product_category_name_english]` (relate `products` → `order_items` → this table via existing keys), value `Total Revenue`.

Run: visually confirm the line chart's November spikes match `sql/q6_seasonality.sql` output, and the top category bar matches the highest-revenue category from `sql/q1_category_decline.sql`.

- [ ] **Step 4: Add the region slicer and save**

Add a Slicer visual bound to `customers[customer_state]`. Confirm it cross-filters the KPI cards and charts on this page when a state is selected.

Save as `dashboard/olist_dashboard.pbix`.

- [ ] **Step 5: Commit**

```bash
git add dashboard/olist_dashboard.pbix
git commit -m "Add Power BI dashboard Page 1: Overview (KPIs, trend, category, slicer)"
```

---

## Task 10: Power BI dashboard — Page 2 (Deep dive)

**Files:**
- Modify: `dashboard/olist_dashboard.pbix`

**Interfaces:**
- Consumes: same live Postgres tables as Task 9, plus `sql/q4_seller_concentration.sql` and `sql/q2_region_delivery.sql` logic re-expressed as DAX.
- Produces: finished 2-page `.pbix`, consumed by Task 12 (README screenshot + publish).

- [ ] **Step 1: Add a second page named "Deep Dive"**

- [ ] **Step 2: Build the seller concentration (Pareto) chart**

Add measure:
```dax
Cumulative Seller Revenue % =
    VAR CurrentSellerRevenue = [Total Revenue]
    VAR SellersRankedHigherOrEqual =
        FILTER(
            ALL(order_items[seller_id]),
            CALCULATE([Total Revenue]) >= CurrentSellerRevenue
        )
    RETURN DIVIDE(CALCULATE([Total Revenue], SellersRankedHigherOrEqual), CALCULATE([Total Revenue], ALL(order_items[seller_id])))
```
Add a Line Chart: X-axis sellers ranked by revenue, Y-axis `Cumulative Seller Revenue %`.

Verify: the curve's shape matches `sql/q4_seller_concentration.sql` output — same point where it crosses 80%.

- [ ] **Step 3: Build delivery-by-state and review-vs-revenue visuals**

Add a Bar Chart or Filled Map: `customers[customer_state]` vs. `Avg Delivery Delay Days` measure (from Task 9). Add a Table visual: category, `Total Revenue`, average `order_reviews[review_score]` — matching the columns from `sql/q5_revenue_vs_reviews.sql`.

- [ ] **Step 4: Build the category QoQ table with conditional formatting**

Add a Table visual: category, quarter, revenue, and a `QoQ % Change` measure derived the same way as `sql/q1_category_decline.sql` (DAX equivalent using `CALCULATE` + `DATEADD` for the prior quarter). Apply conditional formatting (red background) to `QoQ % Change` where value < 0.

Verify: both pages together fit on-screen with no visual overlapping and no scrollbar in Power BI's normal view.

- [ ] **Step 5: Commit**

```bash
git add dashboard/olist_dashboard.pbix
git commit -m "Add Power BI dashboard Page 2: Deep Dive (seller concentration, delivery, reviews, QoQ)"
```

---

## Task 11: Written findings

**Files:**
- Create: `findings.md`

**Interfaces:**
- Consumes: actual output from all 6 `sql/q*.sql` files (Tasks 3-8) — real numbers only, per Global Constraints.
- Produces: `findings.md`, linked from `README.md` (Task 12).

- [ ] **Step 1: Re-run all 6 queries and record the actual output numbers**

Run: `for f in sql/q*.sql; do echo "=== $f ==="; psql olist -f "$f"; done > /tmp/query_output.txt`

Read `/tmp/query_output.txt` and extract the specific figures needed below (largest QoQ decline, worst-delivery high-revenue state, actual repeat rate %, actual seller concentration %, actual mismatched category, actual November spike %).

- [ ] **Step 2: Write `findings.md`**

```markdown
# Findings & Recommendations

## Q1 — Category QoQ revenue decline
[Category] declined [X]% quarter-over-quarter in [quarter], the steepest
drop of any category above the noise floor. [State whether review scores
for that category also declined, using Q5 data, to rule in/out a quality
cause.] Recommend [pricing review / promo test / inventory hold] before
[cutting spend / reordering stock].

## Q2 — Region revenue vs delivery performance
[State] generates [$X] in revenue — [rank] highest — but averages [Y] days
[late/early] against estimate, the worst of the top-5 revenue states.
Recommend auditing the carrier/fulfillment partner serving [state] before
scaling further marketing spend there.

## Q3 — Repeat-purchase rate by cohort
Using the corrected `customer_unique_id` join, true repeat-purchase rate is
[X]%, [trending up/down/flat] across cohorts from [start] to [end]. This is
[higher/lower] than the naive customer_id-based figure would suggest.
Recommend [a retention campaign targeting single-purchase customers /
investigating the low-cohort-size months for a marketing gap].

## Q4 — Seller revenue concentration
[X]% of sellers generate 80% of total revenue. This concentration means
[losing the top N sellers would materially hurt the marketplace / the
long tail is healthy diversification]. Recommend [an account-management
program for top sellers / diversifying seller acquisition in categories
dominated by few sellers].

## Q5 — Revenue vs review score mismatch
[Category] generates $[X] in revenue but averages only [Y] stars, below
the platform average of [Z]. This is a brand-risk category — high volume,
quiet dissatisfaction. Recommend a quality/complaint audit on [category]
before further promoting it.

## Q6 — Seasonality
Order volume spikes [X]% in November relative to the surrounding months,
consistent with Brazil's Black Friday period. Recommend confirming
inventory and delivery-capacity planning is scaled for November ahead of
the next cycle, given Q2's delivery-delay findings already show strain in
[state].
```

Fill every `[bracket]` with the real value from Step 1's output — no bracket may remain in the committed file.

- [ ] **Step 3: Commit**

```bash
git add findings.md
git commit -m "Add written findings and recommendations for all 6 business questions"
```

---

## Task 12: README, publish, and resume bullet

**Files:**
- Create: `README.md`
- Create: `assets/dashboard_screenshot.png`

**Interfaces:**
- Consumes: `findings.md` (Task 11), `dashboard/olist_dashboard.pbix` (Tasks 9-10), all `sql/q*.sql` files (Tasks 3-8), `sql/checks_findings.md` (Task 2).
- Produces: final `README.md` — the artifact a hiring manager actually opens first.

- [ ] **Step 1: Publish to Power BI Service**

In Power BI Desktop: File → Publish → publish to a new workspace (e.g. "Olist Analytics"). In app.powerbi.com, open the published report, use Share → "Publish to web" or a view-only link (whichever the free tier account allows), and copy the link.

- [ ] **Step 2: Take the dashboard screenshot**

Screenshot both pages (or the Overview page if only one fits cleanly) and save to `assets/dashboard_screenshot.png`.

- [ ] **Step 3: Write `README.md`**

```markdown
# Olist E-Commerce Analytics

Analysis of 100K+ Brazilian e-commerce transactions (Olist, 2016-2018)
translating stakeholder business questions into SQL evidence and an
actionable dashboard.

## Business questions
1. Which product categories are declining quarter-over-quarter?
2. Which states drive the most revenue but have the worst delivery
   performance?
3. What's the real repeat-purchase rate by customer cohort?
4. How concentrated is revenue among sellers?
5. Where's the mismatch between high revenue and low review scores?
6. Are there seasonal spikes worth flagging?

## A data trap worth knowing about
Olist's `customer_id` is order-scoped — a returning customer gets a new
`customer_id` on every order. The real person is `customer_unique_id`.
Every repeat-purchase query in this project joins on the latter; see
`sql/checks_findings.md` for the check that surfaced this.

## SQL
Six standalone queries in `sql/`, one per business question above, using
CTEs, window functions (`LAG`, `RANK`, running totals), multi-table joins,
a scalar subquery, and `GROUP BY`/`HAVING`. Schema and load script in
`schema.sql` / `scripts/load_data.sh`.

## Dashboard
Power BI, 2 pages (Overview + Deep Dive), connected live to PostgreSQL.
[Live link to Power BI Service report]

![Dashboard screenshot](assets/dashboard_screenshot.png)

## Findings & recommendations
See [`findings.md`](findings.md) for the full write-up per question.

## Resume bullet
> Analyzed 100K+ Brazilian e-commerce transactions using PostgreSQL (CTEs,
> window functions, multi-table joins) and built an interactive Power BI
> dashboard; identified [category]'s [X]% QoQ revenue decline and seller
> revenue concentration, recommending targeted pricing action.
```

Fill in the Power BI Service link and the resume bullet's brackets using the real published link and Task 11's actual figures.

- [ ] **Step 4: Commit**

```bash
git add README.md assets/dashboard_screenshot.png
git commit -m "Add README with business questions, dashboard, findings, and resume bullet"
```
