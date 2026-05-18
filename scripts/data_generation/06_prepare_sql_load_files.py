import pandas as pd
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[2]
raw_dir = BASE_DIR / "data" / "raw"
load_dir = BASE_DIR / "data" / "sql_load"

load_dir.mkdir(parents=True, exist_ok=True)

files = [
    "price_list_items",
    "sales_orders",
    "sales_order_items",
    "dispatches",
    "schemes",
    "stock_outward"
]

for file in files:
    input_file = raw_dir / f"{file}.csv"
    output_file = load_dir / f"{file}.tsv"

    df = pd.read_csv(input_file, dtype=str)
    df = df.fillna("")
    df.to_csv(output_file, sep="\t", index=False, encoding="utf-8", lineterminator="\n")

    print(f"Created: {output_file}")

print("Done.")