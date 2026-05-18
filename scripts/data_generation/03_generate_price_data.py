import random
import pandas as pd
from pathlib import Path
from datetime import date, timedelta
import re

random.seed(42)

BASE_DIR = Path(__file__).resolve().parents[2]
raw_dir = BASE_DIR / "data" / "raw"

products = pd.read_csv(raw_dir / "products.csv")
branches = pd.read_csv(raw_dir / "branches.csv")

# -------------------------
# CLEAN PRICE FUNCTION (FINAL FIX)
# -------------------------
def clean_price(value):
    cleaned = re.sub(r"[^\d.]", "", str(value))
    return float(cleaned) if cleaned else 0.0

# -------------------------
# Helper: quarter dates
# -------------------------
def quarter_starts(start_year=2020, end_year=2025):
    dates = []
    for year in range(start_year, end_year + 1):
        for month in [1, 4, 7, 10]:
            dates.append(date(year, month, 1))
    return dates

# -------------------------
# 1. Product Price History
# -------------------------
price_history = []
price_history_id = 1
quarters = quarter_starts(2020, 2025)

for _, product in products.iterrows():
    product_id = product["ProductID"]
    sku = product["SKU"]
    base_price = clean_price(product["BasePrice"])

    current_price = base_price * random.uniform(0.82, 0.95)

    for i, start_date in enumerate(quarters):
        if i < len(quarters) - 1:
            end_date = quarters[i + 1] - timedelta(days=1)
        else:
            end_date = date(2025, 12, 31)

        if i > 0:
            current_price *= random.uniform(0.98, 1.04)

            if random.random() < 0.08:
                current_price *= random.uniform(1.04, 1.10)

        price_history.append([
            price_history_id,
            product_id,
            sku,
            start_date,
            end_date,
            round(current_price, 2),
            "All Branches"
        ])

        price_history_id += 1

price_history_df = pd.DataFrame(price_history, columns=[
    "PriceHistoryID",
    "ProductID",
    "SKU",
    "EffectiveFromDate",
    "EffectiveToDate",
    "UnitPrice",
    "PriceListBranch"
])

# -------------------------
# Helper: get price by date
# -------------------------
price_lookup = {}

for _, row in price_history_df.iterrows():
    product_id = row["ProductID"]
    price_lookup.setdefault(product_id, []).append({
        "from": row["EffectiveFromDate"],
        "to": row["EffectiveToDate"],
        "price": row["UnitPrice"]
    })

def get_price(product_id, price_date):
    for item in price_lookup[product_id]:
        if item["from"] <= price_date <= item["to"]:
            return item["price"]

    base_price = clean_price(
        products[products["ProductID"] == product_id]["BasePrice"].iloc[0]
    )
    return base_price
# -------------------------
# 2. Weekly Price Lists
# -------------------------
price_lists = []
price_list_items = []

price_list_id = 1
price_list_item_id = 1

current_date = date(2020, 1, 6)
end_date = date(2025, 12, 29)

while current_date <= end_date:
    for _, branch in branches.iterrows():
        price_lists.append([
            price_list_id,
            current_date,
            branch["BranchID"],
            branch["BranchName"],
            "Published"
        ])

        for _, product in products.iterrows():
            category = str(product["CategoryName"])

            if "Mosquito" in category or category == "Battery":
                exclusion_chance = 0.07
            else:
                exclusion_chance = 0.04

            if random.random() > exclusion_chance:
                price_list_items.append([
                    price_list_item_id,
                    price_list_id,
                    product["ProductID"],
                    product["SKU"],
                    get_price(product["ProductID"], current_date),
                    1
                ])
                price_list_item_id += 1

        price_list_id += 1

    current_date += timedelta(days=7)

price_lists_df = pd.DataFrame(price_lists, columns=[
    "PriceListID",
    "PriceListDate",
    "BranchID",
    "BranchName",
    "Status"
])

price_list_items_df = pd.DataFrame(price_list_items, columns=[
    "PriceListItemID",
    "PriceListID",
    "ProductID",
    "SKU",
    "UnitPrice",
    "IsIncluded"
])

# -------------------------
# 3. Diwali Schemes
# -------------------------
schemes = []
scheme_slabs = []

scheme_id = 1
scheme_slab_id = 1

for year in range(2020, 2026):
    start_date = date(year, 9, 15)
    end_date = date(year, 11, 15)

    schemes.append([
        scheme_id,
        f"Diwali Turnover Scheme {year}",
        "Diwali Turnover",
        start_date,
        end_date,
        1
    ])

    slabs = [
        ("No Benefit", 0, 499999, "None", 0),
        ("Silver Slab", 500000, 999999, "CashbackPercent", 1.5),
        ("Gold Slab", 1000000, 2499999, "CashbackPercent", 2.5),
        ("Platinum Slab", 2500000, 4999999, "GiftOrCashback", 3.5),
        ("Diamond Slab", 5000000, 999999999, "GiftOrCashback", 5.0),
    ]

    for slab in slabs:
        scheme_slabs.append([
            scheme_slab_id,
            scheme_id,
            slab[0],
            slab[1],
            slab[2],
            slab[3],
            slab[4]
        ])
        scheme_slab_id += 1

    scheme_id += 1

schemes_df = pd.DataFrame(schemes, columns=[
    "SchemeID",
    "SchemeName",
    "SchemeType",
    "StartDate",
    "EndDate",
    "IsActive"
])

scheme_slabs_df = pd.DataFrame(scheme_slabs, columns=[
    "SchemeSlabID",
    "SchemeID",
    "SlabName",
    "MinTurnover",
    "MaxTurnover",
    "BenefitType",
    "BenefitValue"
])

# -------------------------
# SAVE FILES
# -------------------------
price_history_df.to_csv(raw_dir / "product_price_history.csv", index=False)
price_lists_df.to_csv(raw_dir / "price_lists.csv", index=False)
price_list_items_df.to_csv(raw_dir / "price_list_items.csv", index=False)
schemes_df.to_csv(raw_dir / "schemes.csv", index=False)
scheme_slabs_df.to_csv(raw_dir / "scheme_slabs.csv", index=False)

print("✅ Price data generated successfully!")