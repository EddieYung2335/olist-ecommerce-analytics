# Olist E-Commerce Analytics

A PostgreSQL + dashboard project on ~100K real Brazilian e-commerce orders (2016-2018). Six SQL queries turn raw transactions into stakeholder recommendations, backed by a live dashboard.

**[Open the live dashboard →](https://datastudio.google.com/s/mLeRatBbWHE)**

## What's here

`sql/` holds six standalone queries, one per business question, each readable top to bottom with no shared views. The dashboard connects live to a Neon-hosted Postgres instance, so it's not a static export or a CSV snapshot. [`findings.md`](findings.md) takes each query's result and spells out a recommendation in plain language.

## Business questions

1. Which product categories are declining quarter over quarter?
2. Which states drive the most revenue but have the worst delivery performance?
3. What's the real repeat-purchase rate, by cohort?
4. How concentrated is revenue among sellers?
5. Where does high revenue collide with low review scores?
6. Are there seasonal spikes worth planning around?

Full answers with numbers: [`findings.md`](findings.md).

## A data trap worth knowing about

Olist assigns a fresh `customer_id` to every order, even for the same shopper. The actual person is `customer_unique_id`. Join on `customer_id` for a retention or repeat-purchase question and the result is quietly wrong; it looks like data but it isn't the thing you're measuring. Every query here joins on `customer_unique_id` instead. See `sql/checks_findings.md` for the check that caught this (99,441 distinct `customer_id`, only 96,096 distinct people).

## Setup

Requirements:

- PostgreSQL 17 (`brew install postgresql@17 && brew services start postgresql@17`)
- Python 3 with `kagglehub` (`pip install kagglehub`)
- A Kaggle API token at `~/.kaggle/kaggle.json` (Kaggle → Account → Create New Token)

```bash
python3 scripts/download_data.py
createdb olist && psql olist -f sql/schema.sql
./scripts/load_data.sh
```

`load_data.sh` truncates all tables before loading, so rerunning it is safe.

Run the data quality checks:

```bash
psql olist -f sql/checks.sql
```

Run one business question, or all six:

```bash
psql olist -f sql/q1_category_decline.sql
for f in sql/q*.sql; do echo "=== $f ==="; psql olist -f "$f"; done
```

### Data

Raw CSVs aren't committed; `data/` is gitignored. Row counts after a clean load:

| table | rows |
|---|---|
| customers | 99,441 |
| orders | 99,441 |
| order_items | 112,650 |
| order_payments | 103,886 |
| order_reviews | 99,224 |
| products | 32,951 |
| sellers | 3,095 |
| product_category_translation | 71 |

### Schema notes

- Column names and order match the raw CSVs exactly, including the misspelling `lenght`.
- `load_data.sh` uses `\copy` without a column list, so it matches by position. Don't reorder columns.
- `customers.customer_unique_id` is the real person; `customer_id` is order-scoped. Use `customer_unique_id` for any cohort or repeat-purchase analysis.
- `order_reviews` has no primary key on purpose. The raw CSV contains duplicate `(review_id, order_id)` rows. It's indexed on `order_id` instead.
- `products.product_category_name` is NULL for 610 products. Category names are translated to English via `product_category_translation`, which doesn't cover every category.

## Repo layout

```
sql/schema.sql            table definitions
sql/q*.sql                six business questions, one file each
sql/checks.sql            data quality checks
findings.md                query results translated into recommendations
scripts/download_data.py  Kaggle fetch
scripts/load_data.sh      CSV load
data/raw/                 CSVs (gitignored)
```
