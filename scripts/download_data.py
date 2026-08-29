#!/usr/bin/env python3
# This file is used to download Brazilian E-Commerce Public Dataset by Olist from Kaggle into data/raw

import shutil
import sys
from pathlib import Path

import kagglehub

SLUG = "olistbr/brazilian-ecommerce"

WANTED = [
    "olist_customers_dataset.csv",
    "olist_sellers_dataset.csv",
    "olist_products_dataset.csv",
    "olist_order_items_dataset.csv",
    "olist_order_payments_dataset.csv",
    "olist_order_reviews_dataset.csv",
    "olist_orders_dataset.csv",
    "product_category_name_translation.csv",
]

DEST = Path(__file__).resolve().parent.parent / "data" / "raw"


def main():
    cache = Path(kagglehub.dataset_download(SLUG))
    DEST.mkdir(parents=True, exist_ok=True)

    missing = []
    for name in WANTED:
        src = cache / name
        if src.exists():
            shutil.copy(src, DEST / name)
        else:
            missing.append(name)

    if missing:
        print("Missing from download:", ", ".join(missing), file=sys.stderr)
        sys.exit(1)

    print(f"Copied {len(WANTED)} CSVs to {DEST}")


if __name__ == "__main__":
    main()
