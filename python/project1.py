import psycopg2
import pandas as pd
from sqlalchemy import create_engine
import matplotlib.pyplot as plt





connection = psycopg2.connect(
    host="localhost",
    port=5433,
    database="ecommerce_db",
    user="postgres",
    password="sql12345"
)

#print("Database connection successful!")

engine = create_engine(
    "postgresql+psycopg2://postgres:sql12345@localhost:5433/ecommerce_db"
)
query='select * from project'

df= pd.read_sql(query,engine)

cv_price = round(df['UnitPrice'].std()/df['UnitPrice'].mean()*100,3)

df['y_m']=df['InvoiceDate'].dt.to_period('M')
monthly_orders=df.groupby('y_m').nunique()
mom=monthly_orders.pct_change()*100
print(mom)
#outlyers of price:
q1=df['UnitPrice'].quantile(0.25)
q3=df['UnitPrice'].quantile(0.75)
iqr=q3-q1
low=q1-(1.5*iqr)
upp=q3+(1.5*iqr)
price_state=(df['UnitPrice']>upp)|(df['UnitPrice']<low)
darsad_outlyer_price = price_state.mean()*100


#month_product
df['InvoiceDate']=pd.to_datetime(df['InvoiceDate'])
crosstab=pd.crosstab(df["StockCode"],df['InvoiceDate'].dt.month,
values=df['Quantity'],aggfunc="sum")
print(crosstab) 

sales = df[
    (df["Quantity"] > 0) &
    (df["UnitPrice"] > 0) &
    (df["order_state"] == 0)
].copy()

items_per_order = (
    sales.groupby("InvoiceNo")["StockCode"]
    .nunique()
)

plt.figure(figsize=(10, 5))
plt.hist(items_per_order, bins=30)
plt.xlabel("Number of Different Products")
plt.ylabel("Number of Orders")
plt.title("Products per Order")
plt.tight_layout()
plt.show()


sales["Hour"] = sales["InvoiceDate"].dt.hour

hourly_orders = (
    sales.groupby("Hour")["InvoiceNo"]
    .nunique()
)

plt.figure(figsize=(10, 5))
plt.plot(hourly_orders.index, hourly_orders.values, marker="o")
plt.xlabel("Hour")
plt.ylabel("Number of Orders")
plt.title("Orders by Hour")
plt.xticks(range(0, 24))
plt.grid()
plt.tight_layout()
plt.show()


country_orders = (
    sales.groupby("Country")["InvoiceNo"]
    .nunique()
    .sort_values(ascending=False)
    .head(10)
)

plt.figure(figsize=(10, 6))
plt.barh(
    country_orders.index[::-1],
    country_orders.values[::-1]
)
plt.xlabel("Number of Orders")
plt.ylabel("Country")
plt.title("Top 10 Countries by Number of Orders")
plt.tight_layout()
plt.show()


top_revenue_products = (
    sales.groupby("Description")["mount"]
    .sum()
    .sort_values(ascending=False)
    .head(10)
)

plt.figure(figsize=(10, 6))
plt.barh(
    top_revenue_products.index[::-1],
    top_revenue_products.values[::-1]
)
plt.xlabel("Revenue")
plt.ylabel("Product")
plt.title("Top 10 Products by Revenue")
plt.tight_layout()
plt.show()

print(df)