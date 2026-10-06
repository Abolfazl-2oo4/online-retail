E-Commerce Data Analysis & Business Intelligence

An end-to-end e-commerce analytics project focused on transforming raw transactional data into actionable business insights using PostgreSQL, SQL, Python, Pandas, Matplotlib, and Power BI.

The project covers the complete analytical workflow:

Data Cleaning → SQL Analysis → Exploratory Data Analysis → Visualization → Business Intelligence Dashboard

Project Overview

The objective of this project is to analyze e-commerce transaction data and answer practical business questions related to:

Sales and revenue trends

Monthly growth

Product performance

Customer behavior

Order value and frequency

Product preferences

Country-level purchasing behavior

Purchase activity by time of day

Customer and product segmentation

The final analytical results are presented through an interactive Power BI dashboard.

Data Pipeline

Raw E-Commerce Data │ ▼ PostgreSQL │ ├── Data Cleaning ├── Data Validation └── SQL Analytics │ ▼ Python / Pandas │ ├── Statistical Analysis ├── Outlier Detection └── Exploratory Analysis │ ▼ Power BI │ ├── Data Modeling ├── DAX Measures ├── Interactive Filters ├── KPIs └── Business Dashboard 

Dataset

The dataset contains e-commerce transaction records with fields including:

ColumnDescriptionInvoiceNoInvoice / order identifierStockCodeProduct identifierDescriptionProduct descriptionQuantityNumber of units purchasedInvoiceDateTransaction date and timeUnitPriceUnit priceCustomerIDCustomer identifierCountryCustomer countryorder_stateTransaction statusmountTransaction amount 

1. Data Cleaning

Initial data cleaning was performed in PostgreSQL.

Invalid transaction values were removed:

DELETE FROM project WHERE "UnitPrice" < 0; DELETE FROM project WHERE "Quantity" < 0; 

Successful and canceled transactions were also separated during the analytical stage using order_state.

This cleaned dataset was then used as the basis for the following analysis stages.

2. PostgreSQL & SQL Analysis

PostgreSQL was used for the main analytical queries and business metrics.

Monthly Revenue & Growth

Monthly successful payments were calculated using DATE_TRUNC() and compared with the previous month using LAG().

This analysis provides:

Monthly revenue

Previous month's revenue

Month-over-month growth rate

Example SQL concepts:

DATE_TRUNC('month', "InvoiceDate") LAG(payment) OVER ( ORDER BY date ) 

Best-Selling Product by Month

Products were aggregated by month and ranked using ROW_NUMBER().

This identifies the product with the highest sales volume in each month.

ROW_NUMBER() OVER ( PARTITION BY "date" ORDER BY total_quantity DESC ) 

Order Analysis

Orders were analyzed according to their monetary value.

NTILE() was used to divide orders into five groups based on order value.

This provides a simple distribution of low-value to high-value orders.

Customer Analysis

Customer-level metrics include:

Total revenue

Number of orders

Total quantity purchased

Cancellation rate

Revenue-based segmentation

Order-frequency segmentation

Activity-based segmentation

Customers were divided into groups using NTILE().

Favorite Product per Customer

For each customer, products were ranked by total quantity purchased.

The highest-ranked product represents the customer's most purchased product.

This can be used as a basic customer preference indicator.

Favorite Month per Customer

Customer purchases were aggregated by month and ranked to identify the customer's most active purchasing month.

Product Analysis

Products were analyzed based on:

Total revenue

Sales volume

Number of orders

Revenue-based segmentation

Sales-based segmentation

Product Preference by Country

For each country, products were ranked according to total quantity sold.

This provides an overview of geographical product preferences.

3. Python & Pandas Analysis

Python was used for exploratory and statistical analysis.

Main libraries:

import pandas as pd import psycopg2 from sqlalchemy import create_engine import matplotlib.pyplot as plt

The PostgreSQL database was accessed through SQLAlchemy and Psycopg2.

df = pd.read_sql( 'SELECT * FROM project', engine ) 

Statistical Analysis

Price Variation

The coefficient of variation was calculated to measure price dispersion:

df['UnitPrice'].std() / df['UnitPrice'].mean() * 100 

Price Outlier Detection

The Interquartile Range (IQR) method was used to identify unusual prices.

Q1 = df['UnitPrice'].quantile(0.25) Q3 = df['UnitPrice'].quantile(0.75) IQR = Q3 - Q1 low = Q1 - 1.5 * IQR upper = Q3 + 1.5 * IQR 

Product × Month Analysis

A cross-tabulation was created to examine product sales across different months.

pd.crosstab( df["StockCode"], df["InvoiceDate"].dt.month, values=df["Quantity"], aggfunc="sum" ) 

4. Exploratory Data Visualization

Matplotlib was used to create exploratory visualizations including:

Products per Order

A histogram showing the distribution of the number of different products included in each order.

Orders by Hour

A time-based analysis showing order activity throughout the day.

Top Countries by Orders

A bar chart showing the countries with the highest number of orders.

Top Products by Revenue

A bar chart identifying the products generating the highest revenue.

These visualizations were primarily used for exploratory analysis before the final BI layer.

5. Power BI Dashboard

The final business intelligence layer of the project was implemented in Microsoft Power BI.

The Power BI report transforms the analytical data into an interactive dashboard for business-oriented analysis.

Power BI Components

The dashboard includes:

KPI Cards

Revenue analysis

Order analysis

Product analysis

Customer analysis

Order status filtering

Category analysis

Interactive slicers

DAX measures

Filter context analysis

DAX Measures

Business metrics were implemented using DAX measures rather than modifying the underlying database.

For example, total revenue is calculated as a measure and dynamically responds to the current filter context.

This allows the same metric to change automatically when users filter by:

Product

Category

Order status

Customer

Date

Other report dimensions

Interactive Analysis

Power BI allows users to interactively filter the dataset and immediately see the effect on the analytical metrics.

For example:

Order Status │ ▼ Slicer │ ▼ Filter Context │ ├── Revenue ├── Orders ├── Products └── Customers 

This makes the final dashboard more useful for business analysis than static Python visualizations.

Project Architecture

E-Commerce Dataset │ ▼ PostgreSQL │ ┌──────────┴──────────┐ │ │ Data Cleaning SQL Analysis │ │ └──────────┬──────────┘ ▼ Analytical Data │ ┌──────────┴──────────┐ │ │ Python / Pandas Power BI │ │ EDA / Statistics DAX / Dashboard │ │ └──────────┬──────────┘ ▼ Business Insights 

Technologies

TechnologyPurposePostgreSQLData storage and SQL analysisSQLData cleaning and analytical queriesPythonExploratory and statistical analysisPandasData manipulation and analysisMatplotlibExploratory visualizationPower BIBusiness intelligence and interactive dashboardDAXPower BI measures and analytical calculationsSQLAlchemyPostgreSQL connection from PythonPsycopg2PostgreSQL connectivityGit / GitHubVersion control 

Key Skills Demonstrated

SQL

Data cleaning

Aggregations

GROUP BY

CTEs

Window functions

LAG()

ROW_NUMBER()

NTILE()

Date analysis

Customer segmentation

Product ranking

Month-over-month analysis

Python / Pandas

Data loading from PostgreSQL

Data transformation

GroupBy analysis

Cross-tabulation

Statistical analysis

Outlier detection

Exploratory visualization

Power BI

Data modeling

DAX measures

Filter context

Slicers

KPI cards

Interactive dashboards

Business-oriented reporting

Project Structure

E-Commerce-Data-Analysis/ │ ├── sql/ │ └── analysis.sql │ ├── python/ │ └── analysis.py │ ├── powerbi/ │ └── ecommerce_dashboard.pbix │ ├── visualizations/ │ ├── products_per_order.png │ ├── orders_by_hour.png │ ├── top_countries.png │ └── top_products.png │ ├── README.md └── requirements.txt 

Business Questions

The project attempts to answer questions such as:

How is revenue changing over time?

Which products sell the most?

Which products generate the most revenue?

Which customers generate the highest revenue?

How frequently do customers place orders?

What is each customer's most purchased product?

Which months are customers most active?

Which countries generate the most orders?

At what time of day is order activity highest?

How are customers and products distributed across different segments?

Final Outcome

The project combines relational data analysis, statistical exploration, and business intelligence into a single analytical workflow.

The final Power BI dashboard provides an interactive layer on top of the cleaned and analyzed e-commerce data, allowing business metrics to be explored through filters and dynamic DAX measures.

Author

Abolfazl

E-Commerce Data Analysis & Business Intelligence Project
