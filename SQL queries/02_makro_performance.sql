use AdventureWorksDW2025;
go


-- SHOW TABLES AND COLUMNS IN THE DATABASE

select
	table_name, 
	COLUMN_NAME, 
	DATA_TYPE
from INFORMATION_SCHEMA.COLUMNS;
go


/*
1. What is the overall Gross Profit and Gross Margin for the B2C channel, 
and how has it trended year over year? 


GROSS PROFIT = REVENUE - COST_OF_GOODS_SOLD
GROSS MARGIN = (REVENUE - COST_OF_GOOD_SOLD) / REVENUE = GROSS PROFIT / REVENUE
*/

select
	c.CalendarYear as [year],
	round(sum(fis.SalesAmount),2) as total_revenue,
	round(sum(fis.TotalProductCost),2) as total_cost,
	round(sum(fis.SalesAmount) - sum(fis.TotalProductCost),2) as gross_profit,
	cast(100.0 * (sum(fis.salesamount) - sum(fis.TotalProductCost)) /
		nullif(sum(fis.SalesAmount), 0) as decimal(5,2)) as gross_margin_pct
from FactInternetSales fis
left join Calendar c
	on c.DateKey = fis.OrderDateKey
where c.CalendarYear not in (2010,2014)
group by c.CalendarYear
order by [year] asc;


/* 
2. What is the Year-over-Year (YoY) revenue growth rate for each month? 
*/

with calculations as (
select
	c.CalendarYear as [year], 
	c.MonthNumberOfYear as month_number,
	c.MonthName as month_name,
	round(sum(fis.SalesAmount),2) as curr_total_revenue,
	lag(sum(fis.SalesAmount), 1) over (partition by c.MonthNumberOfYear 
		order by c.CalendarYear asc) as prev_total_revenue
from FactInternetSales fis 
join Calendar c 
	on c.DateKey = fis.OrderDateKey
	and c.CalendarYear not in (2010,2014)
group by 
	c.CalendarYear, 
	c.MonthNumberOfYear,
	c.MonthName
)

select
	[year], 
	month_number, 
	round(curr_total_revenue,2), 
	round(prev_total_revenue,2), 
	cast(100.0 * (curr_total_revenue - prev_total_revenue) / 
		nullif(prev_total_revenue, 0) as decimal(7,2)) as revenue_growth_pct
from calculations cal
order by [year], month_number;
go


/* 3. What is the monthly seasonality of our sales, and which quarter 
 drives the most revenue historically? */

with revenue_calculations as (
	select
		c.CalendarQuarter as [Quarter], 
		c.MonthNumberOfYear as month_number,
		c.MonthName as [Month],
		coalesce(sum(fis.SalesAmount),0) as revenue
	from FactInternetSales fis
	join Calendar c 
		on c.DateKey = fis.OrderDateKey
		and c.CalendarYear not in (2010, 2014)
	group by 
		c.CalendarQuarter, 
		c.MonthNumberOfYear,
		c.MonthName
),
curr_quarter_revenue_calc as (
	select
		[Quarter], 
		month_number,
		[Month], 
		revenue as monthly_revenue, 
		sum(revenue) over (partition by [Quarter]) as curr_quarter_revenue
	from revenue_calculations
),
growth_calc as (
	select
			[Quarter], 
			month_number,
			[Month], 
			monthly_revenue, 
			curr_quarter_revenue,
			lag(curr_quarter_revenue,3) over (order by [Quarter], month_number) as prev_quarter_revenue
	from curr_quarter_revenue_calc 
)

select 
	*,
	cast ((curr_quarter_revenue - prev_quarter_revenue) / nullif(prev_quarter_revenue,0) as decimal(10,2))
		as Q_revenue_growth_pct
from growth_calc
order by 
	[Quarter], 
	month_number;
go



/*
**4. How is the Average Order Value (AOV) trending alongside Total Order Volume?**
*/

select
	c.CalendarYear calendar_year, 
	c.MonthNumberOfYear as month_number,
	count(distinct fis.SalesOrderNumber) as num_distinct_orders, 
	sum(fis.OrderQuantity) as num_items, 
	cast(sum(fis.SalesAmount) / nullif(count (distinct fis.SalesOrderNumber),0) as float)
		as avg_order_value
from FactInternetSales fis
join Calendar c
	on c.DateKey = fis.OrderDateKey
	and c.CalendarYear not in (2010, 2014)
group by 
	c.CalendarYear,
	c.MonthNumberOfYear
order by 
	calendar_year,
	month_number;
go
	



/*
**5. What is the Year-to-Date (YTD) cumulative revenue for the most recent fully completed year?**
*/
d
with revenue_calculation as (
	select
		c.CalendarYear as calendar_year,
		c.MonthNumberOfYear as month_number,
		c.DayNumberOfYear as day_number,
		count(distinct fis.SalesOrderNumber) as num_orders,
		coalesce(sum(fis.salesamount), 0) as daily_revenue
	from FactInternetSales fis 
	right join Calendar c 
		on c.DateKey = fis.OrderDateKey
	where c.CalendarYear = 2013
	group by 
		c.CalendarYear,
		c.MonthNumberOfYear,
		c.DayNumberOfYear		
)

select
	*,
	sum(daily_revenue) over (order by day_number) as cumulative_revenue
from revenue_calculation r
order by 
	calendar_year,
	month_number,
	day_number
go







