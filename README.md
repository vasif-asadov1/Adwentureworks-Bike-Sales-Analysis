# AdventureWorks DW - B2C Internet Sales Analysis

This project explores the Business-to-Customer (B2C) internet sales data within the AdventureWorksDW database. The goal is to extract actionable business insights regarding revenue trends, customer behavior, product profitability, and geographic performance. The analysis relies on advanced SQL techniques including Window Functions, CTEs, and dynamic data bucketing to create clean, aggregated datasets ready for visualization in BI tools like Tableau and Power BI.

*Note: Business-to-Business (B2B) Reseller sales are excluded from this specific analysis and will be evaluated in a separate project.*

**Tableau Dashboard:** You can observe the interactive Tableau dashboard using the following link: [AdventureWorksDW Sales Analysis Dashboard](https://public.tableau.com/app/profile/vasif.asadov2730/viz/AdventureWorksExecutiveDashboard_17723260919680/Dashboard2)

**Documentation:** SQL Queries, Explanations and Analysis is given in the following link: [SQL Queries Docs](https://vasif-asadov.gitbook.io/adventureworks-analysis)

**SQL Query Results:** You can observe the SQL Query results by following the given link: [SQL Query results](https://docs.google.com/spreadsheets/d/1q9_WyjrXjWc_S7sqvuiSEB62ZsJcYuLFSrcODvy3leQ/edit?gid=0#gid=0)



## Project Structure
The analysis is structured from initial environment setup through 6 core analytical and modeling sections:
0. Environment Setup & Data Preparation
1. Executive Macro-Performance & Revenue Trends
2. Customer Segmentation & Behavioral Profiling
3. Product Affinity & Profitability Analysis
4. Promotional ROI & Sales Drivers
5. Geographic Distribution & Fulfillment Efficiency
6. BI Data Modeling & View Creation

---

## Section 0: Environment Setup & Data Preparation

Before executing the B2C analysis, the database environment was configured and referential integrity was established to ensure accurate querying and seamless data modeling.

### Key Actions Performed:
* **Database Restoration:** Executed T-SQL server-level commands to restore the `AdventureWorksDW` database from a raw `.bak` backup file into the SQL Server environment.
* **Referential Integrity Enforcement:** The default database schema lacked strict relational mappings. `ALTER TABLE` commands were used to establish the Star/Snowflake schema architecture by adding standard `FOREIGN KEY` constraints.
* **Hierarchy Mapping:** * Connected Geographic dimensions (`DimGeography` to `DimSalesTerritory`).
  * Enforced the complete Product Hierarchy (`DimProduct` to `DimProductSubcategory` to `DimProductCategory`).
  * Resolved mapping for operational tables, bridging `FactInternetSalesReason` securely to both the sales fact table and the specific reason dimension table.

---

## Section 1: Executive Macro-Performance & Revenue Trends

This section focuses on the high-level financial health of the B2C channel, utilizing Common Table Expressions (CTEs) and Window Functions to calculate growth and running totals.

### Business Questions Answered:
**1. What is the overall Gross Profit and Gross Margin for the B2C channel, and how has it trended year over year?**
* **Logic:** Aggregated `FactInternetSales` by `CalendarYear` to calculate Total Revenue, Total Cost of Goods Sold (COGS), Gross Profit, and Gross Margin Percentage.

**2. What is the Year-over-Year (YoY) revenue growth rate for each month?**
* **Logic:** Utilized CTEs and the `LAG()` window function partitioned by month to compare current month revenue against the same month in the prior year. Filtered out incomplete years (2010, 2014) to ensure accurate trend analysis.

**3. What is the monthly seasonality of our sales, and which quarter drives the most revenue historically?**
* **Logic:** Grouped sales by Quarter and Month. Applied window functions to calculate total quarterly revenue and compare it against the previous quarter to determine Quarter-over-Quarter (QoQ) growth.

**4. How is the Average Order Value (AOV) trending alongside Total Order Volume?**
* **Logic:** Tracked monthly order volume using `COUNT(DISTINCT SalesOrderNumber)` and calculated the AOV to understand if revenue growth is driven by more orders or larger cart sizes.

**5. What is the Year-to-Date (YTD) cumulative revenue for the most recent fully completed year?**
* **Logic:** Filtered for the year 2013 and applied a running total window function (`SUM() OVER(ORDER BY day_number)`) to calculate daily cumulative revenue.

---

## Section 2: Customer Segmentation & Behavioral Profiling

This section analyzes the customer base to understand who is buying, how often they buy, and which demographic segments offer the highest Lifetime Value (LTV).

### Business Questions Answered:
**6. Which demographic segments (based on Income and Education) drive the highest overall revenue?**
* **Logic:** Calculated the median and standard deviation of customer incomes to dynamically define "Low", "Mid", and "High" budget segments. Grouped total revenue and order volume by these budget segments alongside education levels to identify the most lucrative customer profiles.

**7. Does the customer's commute distance and vehicle ownership impact their lifetime value?**
* **Logic:** Categorized customers by car ownership (0, 1, or >1) and grouped them by commute distance. Calculated total revenue and average revenue per customer within these buckets to assess the impact of logistics on purchasing behavior.

**8. Who are our "Whales" (Top 100 Most Valuable Customers), and what is their purchasing frequency?**
* **Logic:** Identified the Top 100 customers by total revenue. Calculated their purchasing frequency by dividing total orders by the number of distinct months they made a purchase to understand whale engagement levels.

**9. What is our generational spend distribution (Age Brackets)?**
* **Logic:** Dynamically calculated customer age at the time of purchase using the maximum `OrderDate` in the dataset to ensure historical accuracy. Segmented customers into 10-year age brackets and analyzed revenue distribution across age, gender, and marital status.

**10. What is our Customer Retention Rate (One-and-Done vs. Repeat Buyers)?**
* **Logic:** Counted distinct orders per customer to categorize them as "repeat-buyers" (>1 order) or "one-and-done" (1 order). Used window functions to calculate the percentage share of each group against the total customer base, establishing the baseline retention rate.

---

## Section 3: Product Affinity & Profitability Analysis

This section shifts the focus to the product catalog, evaluating which items, categories, and pricing tiers drive the most value for the B2C channel.

### Business Questions Answered:
**11. Which product categories and subcategories drive the highest profit margins, and which are a drag on profitability?**
* **Logic:** Joined sales data with the product hierarchy (Category > Subcategory > Product). Calculated Total Revenue, Total Cost, Gross Profit, and Gross Margin Percentage for each subcategory to identify the most and least profitable product lines.

**12. What is the disparity between our "High Volume" products and our "High Value" products?**
* **Logic:** Aggregated product sales by both total revenue (value) and total quantity sold (volume). Utilized dual `ROW_NUMBER()` window functions to rank products across both metrics, filtering for the Top 10 in either category to highlight items that sell frequently vs. items that generate the most cash.

**13. What is our basket size distribution, and how frequently do customers buy multiple items in a single transaction?**
* **Logic:** Calculated the number of items per individual `SalesOrderNumber` to determine basket sizes. Grouped the results to count the frequency of each basket size and calculated the percentage distribution across all orders.

**14. Are there any "Dead Weight" products in our active catalog that have negligible sales in the most recent year?**
* **Logic:** Filtered for currently active products in the catalog and joined them with sales data from the most recent full year (2013). Applied a `HAVING` clause to isolate underperforming products with less than $10,000 in annual revenue or fewer than 50 total units sold.

**15. How does product pricing tier affect consumer purchasing behavior?**
* **Logic:** Analyzed the list price distribution (min, max, average) to logically define "Entry-level", "Standard", and "Premium" pricing tiers. Grouped total units sold and total revenue by these tiers to determine which price points capture the largest share of the business.

---

## Section 4: Promotional ROI & Sales Drivers

This section investigates the underlying motivations behind customer purchases, tracking how psychological drivers and time influence Customer Lifetime Value (CLV).

### Business Questions Answered:
**16. What are the primary psychological drivers (Sales Reasons) behind our B2C purchases?**
* **Logic:** Resolved a many-to-many relationship between `FactInternetSales` and `FactInternetSalesReason` by joining on both Order Number and Line Number. Aggregated revenue and order volume by `SalesReasonName` to calculate the percentage of total sales driven by each specific motivation.

**17. What percentage of our total B2C volume is driven by promotional discounts versus standard pricing?**
* **Logic:** Queried the `DiscountAmount` within the fact table to determine promotional ROI. Discovered that B2C internet sales in this dataset do not utilize discounts, indicating 100% of volume is driven by standard pricing.

**18. What is our Customer Lifetime Value (CLV) distribution, and how long does it take for a customer to reach their maximum value?**
* **Logic:** Calculated customer tenure by finding the date difference between a customer's first and last purchase. Excluded one-time buyers to focus on retention, segmenting repeat customers into CLV tiers to identify the average tenure required to reach higher spending brackets.

**19. Do the primary sales drivers change depending on the Product Category?**
* **Logic:** Joined the product hierarchy with sales reason data. Grouped total orders by both category and sales reason, utilizing the `ROW_NUMBER()` window function to rank the reasons and isolate the #1 primary sales driver for each distinct product category.

---

## Section 5: Geographic Distribution & Fulfillment Efficiency

This section explores the global footprint of the B2C channel, evaluating regional revenue performance, operational delivery success, and localized market preferences.

### Business Questions Answered:
**20. Which countries and regions drive the most B2C revenue, and how does the Average Order Value (AOV) differ geographically?**
* **Logic:** Aggregated sales data by `SalesTerritoryCountry` and `SalesTerritoryRegion`. Counted distinct orders and customers to calculate regional Average Order Value (AOV), highlighting which global markets contain the highest-spending consumers.

**21. Are we meeting our operational Service Level Agreements (SLAs)? What is the average lead time between Order Date and Ship Date?**
* **Logic:** Calculated the lead time in days between order and ship dates. Utilized window functions to establish a dynamic regional average for shipping times, and applied a `CASE` statement with a +/- 5-day threshold to categorize monthly fulfillment performance as "early", "late", or "on-time".

**22. How heavily do freight and tax costs impact the final landed cost for the consumer across different countries?**
* **Logic:** Summed total tax and freight amounts by country and divided them by total regional revenue. This calculated the exact percentage impact of logistical and governmental costs on the consumer's final price in different global markets.

**23. Is there a regional bias for specific Product Categories?**
* **Logic:** Joined the product hierarchy to sales and territory data. Utilized a `SUM() OVER(PARTITION BY country)` window function to determine the percentage share of revenue each product category holds within individual countries, revealing localized product affinities.

---

## Section 6: BI Data Modeling & View Creation

To transition from ad-hoc SQL analysis to automated Business Intelligence reporting, the raw Star Schema was denormalized into specific, purpose-built SQL Views. These aggregated datasets are optimized for performance and directly feed the Tableau dashboards.

### Aggregated Datasets Created:
**1. Executive Summary Base (`orderline_level_agg`)**
* **Purpose:** Acts as the primary data source for high-level macro-performance and product dashboards.
* **Logic:** A fully denormalized view joining `FactInternetSales` with product, customer, calendar, and geographic dimensions. Pre-calculates exact line-item profit margins, applies dynamic historical age logic to customers, and flattens the schema to minimize processing latency in the BI layer.

**2. Customer 360 Profiling (`customer_360_profiling`)**
* **Purpose:** Feeds the Customer Segmentation dashboard with pre-calculated RFM (Recency, Frequency, Monetary) metrics.
* **Logic:** Aggregated strictly to the `CustomerKey` grain. Incorporates advanced behavioral calculations including `customer_tenure_days`, `days_since_last_order`, `active_months`, and pre-binned demographic attributes.

**3. Time Series Analytics (`daily_stats_agg`)**
* **Purpose:** Powers all historical trending, moving averages, and YoY growth visualizations.
* **Logic:** Aggregated to the daily calendar grain. Utilizes Common Table Expressions (CTEs) to isolate the exact date of every customer's *first* purchase, enabling accurate daily tracking of "New Customers Acquired" alongside standard daily revenue and volume metrics.

**4. Sales Driver Dimension (`v_sales_reasons`)**
* **Purpose:** Provides a clean mapping of psychological purchase drivers to individual transactions.
* **Logic:** Resolves the many-to-many relationship between sales and reasons into a lightweight dimension view, allowing the BI tool to filter revenue by specific promotional or psychological categories.
