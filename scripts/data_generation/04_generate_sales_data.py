import random
import pandas as pd
from pathlib import Path
from datetime import date, timedelta

random.seed(42)

BASE_DIR = Path(__file__).resolve().parents[2]
raw_dir = BASE_DIR / "data" / "raw"

products = pd.read_csv(raw_dir / "products.csv")
distributors = pd.read_csv(raw_dir / "distributors.csv")
sales_heads = pd.read_csv(raw_dir / "sales_heads.csv")
godowns = pd.read_csv(raw_dir / "godowns.csv")
price_history = pd.read_csv(raw_dir / "product_price_history.csv")
schemes = pd.read_csv(raw_dir / "schemes.csv")

START_DATE = date(2020, 1, 1)
END_DATE = date(2025, 12, 31)

# Safer large size: realistic but controllable
MIN_ORDERS_PER_DAY = 80
MAX_ORDERS_PER_DAY = 150

def get_price(product_id, order_date):
    rows = price_history[
        (price_history["ProductID"] == product_id) &
        (pd.to_datetime(price_history["EffectiveFromDate"]).dt.date <= order_date) &
        (pd.to_datetime(price_history["EffectiveToDate"]).dt.date >= order_date)
    ]
    return float(rows["UnitPrice"].iloc[0])

def is_diwali_period(d):
    return date(d.year, 9, 15) <= d <= date(d.year, 11, 15)

def get_scheme_id(d):
    rows = schemes[
        (pd.to_datetime(schemes["StartDate"]).dt.date <= d) &
        (pd.to_datetime(schemes["EndDate"]).dt.date >= d)
    ]
    return int(rows["SchemeID"].iloc[0]) if len(rows) > 0 else ""

def choose_product(order_date):
    weights = []
    for _, p in products.iterrows():
        category = str(p["CategoryName"])
        weight = 1

        if "Mosquito" in category:
            weight = 5
            if order_date.month in [3, 4, 5, 6, 7]:
                weight *= 2

        elif category == "Battery":
            weight = 4

        elif "Torch" in category:
            weight = 3

        elif category == "Emergency Light":
            weight = 2

        if is_diwali_period(order_date):
            weight *= 2

        weights.append(weight)

    return products.sample(1, weights=weights).iloc[0]

def choose_quantity(category):
    if "Mosquito" in category:
        return random.choice([12, 24, 36, 48, 60, 72, 120, 180, 240])
    elif category == "Battery":
        return random.choice([50, 100, 150, 200, 300, 500])
    elif "Torch" in category:
        return random.choice([12, 24, 36, 48, 60, 96, 120])
    else:
        return random.choice([6, 12, 24, 36, 48, 60])

# Distributor weights: Top + Regular distributors get more orders
dist_weights = []
for _, d in distributors.iterrows():
    tier = d["ActivityTier"]
    if tier == "Top":
        dist_weights.append(8)
    elif tier == "Regular":
        dist_weights.append(4)
    elif tier == "Occasional":
        dist_weights.append(1.5)
    else:
        dist_weights.append(0.3)

sales_orders = []
sales_order_items = []
dispatches = []

sales_order_id = 1
sales_order_item_id = 1
dispatch_id = 1

current_date = START_DATE

while current_date <= END_DATE:
    daily_orders = random.randint(MIN_ORDERS_PER_DAY, MAX_ORDERS_PER_DAY)

    if current_date.weekday() == 6:
        daily_orders = int(daily_orders * 0.40)

    if is_diwali_period(current_date):
        daily_orders = int(daily_orders * 2)

    if current_date.year == 2020 and current_date.month in [4, 5]:
        daily_orders = int(daily_orders * 0.55)

    for _ in range(daily_orders):
        distributor = distributors.sample(1, weights=dist_weights).iloc[0]
        distributor_region_branch = int(distributor["RegionBranchID"])

        # 35% cross-region sales
        if random.random() < 0.35:
            possible_branches = [1, 2, 3, 4]
            possible_branches.remove(distributor_region_branch)
            sales_branch_id = random.choice(possible_branches)
        else:
            sales_branch_id = distributor_region_branch

        sales_head = sales_heads[sales_heads["HomeBranchID"] == sales_branch_id].iloc[0]

        # Fulfillment godown: mostly same branch, sometimes Mumbai main
        same_branch_godowns = godowns[godowns["BranchID"] == sales_branch_id]
        if random.random() < 0.75:
            godown = same_branch_godowns.sample(1).iloc[0]
        else:
            godown = godowns[godowns["GodownID"] == 1].iloc[0]

        order_status = random.choices(
            ["Completed", "Partially Fulfilled", "Cancelled"],
            weights=[93, 5, 2],
            k=1
        )[0]

        scheme_id = get_scheme_id(current_date)

        sales_orders.append([
            sales_order_id,
            f"SO-{current_date.year}-{sales_order_id:06d}",
            current_date,
            int(distributor["DistributorID"]),
            sales_branch_id,
            int(sales_head["SalesHeadID"]),
            int(godown["GodownID"]),
            scheme_id,
            order_status,
            1 if sales_branch_id != distributor_region_branch else 0,
            "Tally"
        ])

        item_count = random.choices([1, 2, 3, 4, 5], weights=[18, 34, 28, 14, 6], k=1)[0]
        order_items_for_dispatch = []

        used_products = set()

        for _ in range(item_count):
            product = choose_product(current_date)

            while int(product["ProductID"]) in used_products:
                product = choose_product(current_date)

            used_products.add(int(product["ProductID"]))

            category = str(product["CategoryName"])
            quantity = choose_quantity(category)
            unit_price = get_price(int(product["ProductID"]), current_date)
            discount_percent = random.choices(
                [0, 1, 2, 3, 5, 7.5, 10],
                weights=[45, 12, 14, 12, 10, 5, 2],
                k=1
            )[0]

            line_total = round(quantity * unit_price * (1 - discount_percent / 100), 2)

            is_preorder = 0
            expected_stock_arrival_date = ""

            if (category == "Battery" or "Mosquito" in category) and random.random() < 0.035:
                is_preorder = 1
                expected_stock_arrival_date = current_date + timedelta(days=random.randint(7, 45))

            item_row = [
                sales_order_item_id,
                sales_order_id,
                int(product["ProductID"]),
                product["SKU"],
                quantity,
                unit_price,
                discount_percent,
                line_total,
                is_preorder,
                expected_stock_arrival_date
            ]

            sales_order_items.append(item_row)
            order_items_for_dispatch.append(item_row)
            sales_order_item_id += 1

        if order_status != "Cancelled":
            dispatch_date = current_date if random.random() < 0.85 else current_date + timedelta(days=1)

            dispatches.append([
                dispatch_id,
                sales_order_id,
                int(godown["GodownID"]),
                random.choice(["VRL Logistics", "TCI Express", "Gati Transport", "Local Tempo", "Om Logistics"]),
                f"LR{dispatch_date.strftime('%y%m%d')}{dispatch_id:07d}",
                f"BT{dispatch_date.strftime('%y%m%d')}{dispatch_id:07d}",
                dispatch_date,
                "Dispatched" if order_status == "Completed" else "Partial",
                random.choice(["Sent", "Confirmed", "Pending"])
            ])

            dispatch_id += 1

        sales_order_id += 1

    print(f"Generated sales for {current_date}")
    current_date += timedelta(days=1)

sales_orders_df = pd.DataFrame(sales_orders, columns=[
    "SalesOrderID",
    "OrderNumber",
    "OrderDate",
    "DistributorID",
    "SalesBranchID",
    "SalesHeadID",
    "FulfillmentGodownID",
    "SchemeID",
    "OrderStatus",
    "IsCrossRegionSale",
    "CreatedSource"
])

sales_order_items_df = pd.DataFrame(sales_order_items, columns=[
    "SalesOrderItemID",
    "SalesOrderID",
    "ProductID",
    "SKU",
    "Quantity",
    "UnitPrice",
    "DiscountPercent",
    "LineTotal",
    "IsPreOrder",
    "ExpectedStockArrivalDate"
])

dispatches_df = pd.DataFrame(dispatches, columns=[
    "DispatchID",
    "SalesOrderID",
    "GodownID",
    "TransportName",
    "LRNumber",
    "BiltyNumber",
    "DispatchDate",
    "DispatchStatus",
    "ReceivedConfirmationStatus"
])

sales_orders_df.to_csv(raw_dir / "sales_orders.csv", index=False)
sales_order_items_df.to_csv(raw_dir / "sales_order_items.csv", index=False)
dispatches_df.to_csv(raw_dir / "dispatches.csv", index=False)

print("✅ Sales data generated successfully!")
print(f"Sales Orders: {len(sales_orders_df)}")
print(f"Sales Order Items: {len(sales_order_items_df)}")
print(f"Dispatches: {len(dispatches_df)}")