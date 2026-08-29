# Olist E-Commerce Analytics

Analyzing ~100K orders from the public [Olist Brazilian e-commerce dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) (2016–2018). PostgreSQL + Power BI + written findings.

## Requirements

- PostgreSQL 17 (`brew install postgresql@17 && brew services start postgresql@17`)
- Python 3 with `kagglehub` (`pip install kagglehub`)
- A Kaggle API token at `~/.kaggle/kaggle.json` (Kaggle → Account → Create New Token)

## Setup

```bash
python3 scripts/download_data.py
creadb olist && psql olist -f sql/schema.sql
./scripts/load_data.sh
```

`load_data.sh` truncates all tables before loading, rerunning it is safe.

### Data

Raw CSVs aren't committed as `data/` is gitignored. Row counts after a clean load:

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

### Schema Notes

Column names and order match the raw CSVs exactly (including misspelling: lenght).

`load_data.sh` uses `\copy` without a column list, which matches by position, so **please do not reorder columns**.

`customers.customer_unique_id` is the **real_person**.

`customer_id` is **order-scoped**.

Repeat customers have multiple IDs. Use `customer_unique_id` for any cohort or repeat purchase analysis.

`order_reviews` has **no primary key** on purpose, the raw CSV contains duplicate `(review_id, order_id)` rows. Indexed on `order_id` instead.

`products.product_category_name` is NULL for 610 products. Category names are translated to English via `product_category_translation`, which does not cover every category.

## Repo Layout

```
sql/schema.sql          table definitions
scripts/download_data.py  Kaggle fetch
scripts/load_data.sh    CSV load
data/raw/               CSVs (gitignored)
dashboard/              Power BI .pbix (not yet built)
```
