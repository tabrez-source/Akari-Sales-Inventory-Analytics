import random
import pandas as pd
from pathlib import Path
from datetime import date, timedelta

random.seed(42)

BASE_DIR = Path(__file__).resolve().parents[2]
raw_dir = BASE_DIR / "data" / "raw"

products = pd.read_csv(raw_dir / "products.csv")
godowns = pd.read_csv(raw_dir / "godowns.csv")
dispatches = pd.read_csv(raw_dir / "dispatches.csv")
sales_items = pd.read_csv(raw_dir / "sales_order_items.csv")

# -------------------------
# STOCK INWARD (China Import)
# -------------------------
stock_inward = []
inward_id = 1

current_date = date(2020, 1, 15)

while current_date <= date(2025, 12, 31):
    for _, product in products.iterrows():
        category = str(product["CategoryName"])

        if "Mosquito" in category:
            qty = random.randint(2000, 8000)
        elif category == "Battery":
            qty = random.randint(3000, 12000)
        else:
            qty = random.randint(500, 4000)

        stock_inward.append([
            inward_id,
            product["ProductID"],
            product["SKU"],
            1,  # Bhiwandi main godown
            qty,
            current_date,
            "China Import"
        ])

        inward_id += 1

    current_date += timedelta(days=random.randint(60, 90))

# -------------------------
# STOCK OUTWARD (from sales)
# -------------------------
stock_outward = []

outward_id = 1

merged = sales_items.merge(dispatches, on="SalesOrderID", how="inner")

for _, row in merged.iterrows():
    stock_outward.append([
        outward_id,
        row["DispatchID"],
        row["SalesOrderID"],
        row["ProductID"],
        row["SKU"],
        row["GodownID"],
        row["Quantity"],
        row["DispatchDate"],
        "Sales Dispatch"
    ])
    outward_id += 1

# -------------------------
# INVENTORY SNAPSHOT
# -------------------------
inventory = {}

# Add inward
for row in stock_inward:
    key = (row[1], row[3])  # ProductID, GodownID
    inventory[key] = inventory.get(key, 0) + row[4]

# Subtract outward
for row in stock_outward:
    key = (row[3], row[5])
    inventory[key] = inventory.get(key, 0) - row[6]

inventory_snapshot = []
inv_id = 1

for (product_id, godown_id), qty in inventory.items():
    inventory_snapshot.append([
        inv_id,
        product_id,
        godown_id,
        max(qty, 0),
        "2025-12-31"
    ])
    inv_id += 1

# -------------------------
# SAVE FILES
# -------------------------
pd.DataFrame(stock_inward, columns=[
    "InwardID", "ProductID", "SKU", "GodownID",
    "Quantity", "InwardDate", "InwardType"
]).to_csv(raw_dir / "stock_inward.csv", index=False)

pd.DataFrame(stock_outward, columns=[
    "OutwardID", "DispatchID", "SalesOrderID",
    "ProductID", "SKU", "GodownID",
    "Quantity", "OutwardDate", "OutwardType"
]).to_csv(raw_dir / "stock_outward.csv", index=False)

pd.DataFrame(inventory_snapshot, columns=[
    "InventoryID", "ProductID", "GodownID",
    "CurrentStock", "SnapshotDate"
]).to_csv(raw_dir / "inventory_snapshot.csv", index=False)

print("✅ Inventory data generated successfully!")