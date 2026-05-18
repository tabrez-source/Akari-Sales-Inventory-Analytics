import pandas as pd
from pathlib import Path

# Paths
BASE_DIR = Path(__file__).resolve().parents[2]
seed_file = BASE_DIR / "data" / "seed" / "product_master_seed.csv"
output_dir = BASE_DIR / "data" / "raw"

# Read seed file
df = pd.read_csv(seed_file)

# Clean data
df = df[df["Status"].str.lower() == "include"]
df = df.dropna(subset=["SKU", "Category", "ModelNumber"])

# Create Product Categories
categories = df["Category"].drop_duplicates().reset_index(drop=True)
categories_df = pd.DataFrame({
    "CategoryID": range(1, len(categories)+1),
    "CategoryName": categories
})

# Merge CategoryID into products
df = df.merge(categories_df, left_on="Category", right_on="CategoryName")

# Create Products table
products_df = pd.DataFrame({
    "ProductID": range(1, len(df)+1),
    "SKU": df["SKU"],
    "CategoryID": df["CategoryID"],
    "CategoryName": df["Category"],
    "ModelNumber": df["ModelNumber"],
    "Specification": df["Specification"],
    "PackageQty": df["PackageQty"],
    "BasePrice": df["BasePrice"],
    "PriceListDate": df["PriceListDate"],
    "PriceListBranch": df["PriceListBranch"],
    "IsActive": 1
})

# Save files
output_dir.mkdir(parents=True, exist_ok=True)

categories_df.to_csv(output_dir / "product_categories.csv", index=False)
products_df.to_csv(output_dir / "products.csv", index=False)

print("✅ Master data generated successfully!")