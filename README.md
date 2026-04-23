# 🚲 AdventureWorks DW - B2C Internet Sales Analysis

[![Tableau](https://img.shields.io/badge/Tableau-e97627?style=for-the-badge&logo=Tableau&logoColor=white)](#)
[![SQL Server](https://img.shields.io/badge/SQL_Server-CC292B?style=for-the-badge&logo=microsoft-sql-server&logoColor=white)](#)
[![Quarto](https://img.shields.io/badge/Quarto-4670D8?style=for-the-badge&logo=quarto&logoColor=white)](#)

## 📌 Project Overview
This project explores the Business-to-Customer (B2C) internet sales data within the **AdventureWorksDW** database. The primary goal is to extract actionable business insights regarding revenue trends, customer behavior, product profitability, and geographic performance. 

The analysis relies on advanced SQL techniques—including Window Functions, CTEs, and dynamic data bucketing—to create clean, aggregated datasets ready for visualization in BI tools like Tableau and Power BI.

>*Note: Business-to-Business (B2B) Reseller sales are excluded from this specific analysis and will be evaluated in a separate project.*

---

## 🔗 Quick Links
- 📊 **Tableau Dashboard:** [Explore the Interactive Dashboard Here](https://public.tableau.com/app/profile/vasif.asadov2730/viz/AdventureWorksExecutiveDashboard_17723260919680/Dashboard2)
- 📖 **Documentation & Analysis:** [SQL Queries, Explanations and Analysis](https://vasif-asadov1.github.io/Adwentureworks-Bike-Sales-Analysis/)

---

## 🏗️ Project Structure
The analysis is structured from initial environment setup through 6 core analytical and modeling sections.

### Section 0: Environment Setup & Data Preparation
Before executing the B2C analysis, the database environment was configured and referential integrity was established to ensure accurate querying and seamless data modeling.

* **Database Restoration:** Executed T-SQL server-level commands to restore the `AdventureWorksDW` database from a raw `.bak` backup file into the SQL Server environment.
* **Referential Integrity Enforcement:** The default database schema lacked strict relational mappings. `ALTER TABLE` commands were used to establish the Star/Snowflake schema architecture by adding standard `FOREIGN KEY` constraints.
* **Hierarchy Mapping:** * Connected Geographic dimensions (`DimGeography` to `DimSalesTerritory`).
  * Enforced the complete Product Hierarchy (`DimProduct` to `DimProductSubcategory` to `DimProductCategory`).
  * Resolved mapping for operational tables, bridging `FactInternetSalesReason` securely to both the sales fact table and the specific reason dimension table.

### Section 1: Executive Macro-Performance & Revenue Trends
Focuses on the high-level financial health of the B2C channel, utilizing CTEs and Window Functions to calculate growth and running totals.

* **Gross Profit & Margin:** Aggregated `FactInternetSales` by `CalendarYear` to calculate Total Revenue, COGS, Gross Profit, and Gross Margin Percentage.
* **YoY Revenue Growth:** Utilized CTEs and the `LAG()` window function partitioned by month to compare current month revenue against the prior year (excluding incomplete years like 2010, 2014).
* **Seasonality & QoQ Growth:** Grouped sales by Quarter/Month and applied window functions to calculate total quarterly revenue and Quarter-over-Quarter growth.
* **Average Order Value (AOV):** Tracked monthly order volume (`COUNT(DISTINCT SalesOrderNumber)`) and calculated AOV to determine if growth is volume-driven or cart-size-driven.
* **YTD Cumulative Revenue:** Filtered for 2013 and applied a running total window function (`SUM() OVER(ORDER BY day_number)`) for daily cumulative revenue.

### Section 2: Customer Segmentation & Behavioral Profiling
Analyzes the customer base to understand demographics, purchase frequency, and Lifetime Value (LTV).

* **Demographic Value:** Calculated median/standard deviation of incomes to define "Low", "Mid", and "High" budget segments. Grouped by education to identify lucrative profiles.
* **Logistics & Value:** Categorized customers by car ownership and commute distance to assess the impact of logistics on purchasing behavior.
* **"Whales" (Top 100):** Identified the Top 100 customers by total revenue and calculated purchasing frequency (total orders / distinct active months).
* **Generational Spend:** Dynamically calculated customer age using the maximum `OrderDate`. Segmented into 10-year brackets analyzing revenue across age, gender, and marital status.
* **Customer Retention:** Counted distinct orders to categorize as "repeat-buyers" (>1) or "one-and-done" (1). Used window functions to calculate the percentage share of the baseline retention rate.

### Section 3: Product Affinity & Profitability Analysis
Evaluates which items, categories, and pricing tiers drive the most value for the B2C channel.

* **Category Profitability:** Joined sales with the product hierarchy. Calculated Revenue, Cost, Profit, and Margin for each subcategory.
* **Volume vs. Value:** Utilized dual `ROW_NUMBER()` functions to rank products by both revenue (value) and quantity (volume), filtering Top 10s to highlight frequent sellers vs. cash generators.
* **Basket Size Distribution:** Calculated items per `SalesOrderNumber` and grouped the frequency to find percentage distributions across all orders.
* **"Dead Weight" Products:** Filtered active products joined with 2013 sales. Applied a `HAVING` clause to isolate products with `<$10k` annual revenue or `<50` units sold.
* **Pricing Tiers:** Analyzed list prices to define "Entry", "Standard", and "Premium" tiers, grouping units sold and revenue to find the sweet spot for consumer purchasing.

### Section 4: Promotional ROI & Sales Drivers
Investigates psychological drivers and time influence on Customer Lifetime Value (CLV).

* **Psychological Drivers:** Resolved the many-to-many relationship between Sales and Reasons. Aggregated revenue/volume by `SalesReasonName` to find percentage motivations.
* **Promotional ROI:** Queried `DiscountAmount`; discovered B2C internet sales in this dataset do not utilize discounts (100% standard pricing volume).
* **CLV & Tenure:** Calculated tenure (date difference between first/last purchase). Segmented repeat customers into CLV tiers to identify time required to reach higher spending brackets.
* **Drivers by Category:** Utilized `ROW_NUMBER()` to rank and isolate the #1 primary sales driver for each distinct product category.

### Section 5: Geographic Distribution & Fulfillment Efficiency
Explores the global footprint, regional performance, and delivery success.

* **Regional Revenue & AOV:** Aggregated sales by Country and Region to calculate regional AOV and highlight high-spending global markets.
* **Fulfillment SLAs:** Calculated Order-to-Ship lead time. Used dynamic regional averages and `CASE` statements (+/- 5 days) to categorize fulfillment as "early", "late", or "on-time".
* **Landed Costs:** Summed tax and freight by country, divided by regional revenue to calculate the exact percentage impact on the consumer's final price.
* **Regional Product Bias:** Used `SUM() OVER(PARTITION BY country)` to determine the percentage share of revenue each category holds within specific countries.

### Section 6: BI Data Modeling & View Creation
Transitioning from ad-hoc SQL to automated BI reporting by denormalizing the Star Schema into optimized SQL Views.

1. **`orderline_level_agg` (Executive Summary Base):** Fully denormalized view joining facts with dimensions. Pre-calculates exact line-item margins and flattens schema for zero-latency BI processing.
2. **`customer_360_profiling` (Customer 360 Profiling):** Aggregated to the `CustomerKey` grain. Incorporates RFM metrics, tenure, active months, and pre-binned demographics.
3. **`daily_stats_agg` (Time Series Analytics):** Aggregated to the daily grain. Uses CTEs to isolate "New Customers Acquired" alongside daily revenue/volume for YoY and moving averages.
4. **`v_sales_reasons` (Sales Driver Dimension):** Resolves the many-to-many relationship into a lightweight dimension view for filtering revenue by promotional/psychological categories.

---
*Created by [Vasif Asadov](https://github.com/vasif-asadov1)*
