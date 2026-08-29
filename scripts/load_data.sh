#!/bin/bash
# Load the 8 raw Olist CSVs into Postgres, parents before children.
set -euo pipefail

cd "$(dirname "$0")/.." # \copy paths are relative to psql's CWD
DB=olist

psql "$DB" -v ON_ERROR_STOP=1 <<'SQL'
TRUNCATE customers, sellers, products, product_category_translation,
         orders, order_items, order_payments, order_reviews CASCADE;

\copy customers FROM 'data/raw/olist_customers_dataset.csv' CSV HEADER
\copy sellers FROM 'data/raw/olist_sellers_dataset.csv' CSV HEADER
\copy products FROM 'data/raw/olist_products_dataset.csv' CSV HEADER
\copy product_category_translation FROM 'data/raw/product_category_name_translation.csv' CSV HEADER
\copy orders FROM 'data/raw/olist_orders_dataset.csv' CSV HEADER
\copy order_items FROM 'data/raw/olist_order_items_dataset.csv' CSV HEADER
\copy order_payments FROM 'data/raw/olist_order_payments_dataset.csv' CSV HEADER
\copy order_reviews FROM 'data/raw/olist_order_reviews_dataset.csv' CSV HEADER
SQL
