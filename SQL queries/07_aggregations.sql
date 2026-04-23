use AdventureWorksDW2025;
go


select * from FactInternetSales;
go

-- DATA WITH ORDER LINE  LEVEL FOR EXECUTIVE SUMMARY DASHBOARD.

create or alter view orderline_level_agg as 
with get_last_date as (
	select 
		max(orderdate) as reference_day
	from FactInternetSales
)
select
	fis.SalesOrderNumber as order_number,
	fis.SalesOrderLineNumber as order_line_number,

	-- product info
	fis.ProductKey as product_key,
	pr.ProductName as product_name,
	sub.ProductSubcategoryName as product_subcategory,
	cat.ProductCategoryName as product_category,
	pr.ListPrice as product_list_price,
	
	-- customer info
	cus.customerkey as customer_key,
	concat(cus.FirstName, ' ', cus.LastName) as customer_name,
	DATEDIFF(year, cus.BirthDate, gld.reference_day) as customer_age,
	cus.Gender as customer_gender,
	cus.MaritalStatus as customer_marital_status,
	cus.Education as customer_education,
	cus.Occupation as customer_occupation,
	cus.YearlyIncome as customer_income,

	-- regional sales info
	st.SalesTerritoryGroup as sales_territory_group,
	st.SalesTerritoryCountry as sales_country,
	st.SalesTerritoryRegion as sales_region,
	geo.StateProvinceName as sales_state,
	geo.City as sales_city,
	geo.PostalCode as sales_postal_code,
	geo.IpAddressLocator as sales_ip_address,

	-- financial data
	cast(fis.SalesAmount as decimal(20,3)) as revenue,
	cast(fis.TotalProductCost as decimal(20,3)) as cost,
	cast(fis.SalesAmount - fis.TotalProductCost as decimal(20,3)) as profit,
	cast(fis.TaxAmt as decimal(20,3)) as tax,
	cast(fis.Freight as decimal(20,3)) as freight,
	cast(fis.UnitPrice as decimal(20,4)) as unit_price,
	fis.OrderQuantity as quantity,
	cur.CurrencyName as currency, 

	-- time data
	fis.OrderDate as order_date,
	fis.ShipDate as ship_date,
	fis.DueDate as due_date

from FactInternetSales fis
left join Customer cus 
	on cus.CustomerKey = fis.CustomerKey
left join geography geo
    on geo.geographykey = cus.geographykey
left join SalesTerritory st
	on st.SalesTerritoryKey = fis.SalesTerritoryKey
left join Products pr
	on pr.ProductKey = fis.ProductKey
left join ProductSubcategory sub
	on sub.ProductSubcategoryKey = pr.ProductSubcategoryKey
left join ProductCategory cat
	on cat.ProductCategoryKey = sub.ProductCategoryKey
left join Currency cur
	on cur.CurrencyKey = fis.CurrencyKey
left join Calendar cal 
	on cal.DateKey = fis.OrderDateKey
cross join get_last_date gld;
go


select column_name from INFORMATION_SCHEMA.columns 
where TABLE_NAME = 'orderline_level_agg';


select table_name,column_name from INFORMATION_SCHEMA.columns;


select count(*) from orderline_level_agg;


select count(*) from FactInternetSales;
go


select * from orderline_level_agg order by order_number;
go


create or alter view v_sales_reasons as
select
	fsr.SalesOrderNumber as order_number,
	fsr.SalesOrderLineNumber as order_line_number,
	sr.SalesReasonName as sales_reason_name,
	sr.SalesReasonReasonType as sales_reason_type
from FactInternetSalesReason fsr
left join SalesReason sr
	on sr.SalesReasonKey = fsr.SalesReasonKey;
go


select * from v_sales_reasons;
go


-- DATA WITH CUSTOMER LEVEL FOR CUSTOMER PROFILING DASHBOARD
create or alter view customer_360_profiling as
with get_last_date as (
	select 
		max(orderdate) as reference_day
	from FactInternetSales
)

select
	fis.CustomerKey as customer_key,
	concat(cus.FirstName, ' ', cus.LastName) as full_name, 
	DATEDIFF(year, cus.BirthDate, gld.reference_day) as age,
	cus.Gender as gender,
	cus.MaritalStatus as marital_status,
	cus.TotalChildren as total_children,
	cus.NumberChildrenAtHome as num_children_at_home,
	cus.Education as education,
	cus.Occupation as occupation,
	case 
		when cus.NumberCarsOwned > 1 then '>= 2 cars'
		when cus.NumberCarsOwned = 1 then '1 car'
		else 'no car'
	end as car_ownership,
	cus.HouseOwnerFlag as houseowner_flag,
	cus.CommuteDistance as commute_distance,
	cus.YearlyIncome as yearly_income,

	-- geospatial
	geo.CountryRegionName as region,
	geo.StateProvinceName as state,
	geo.City as city,
	geo.PostalCode as postal_code,
	
	-- financial
	cast(coalesce(sum(fis.SalesAmount),0) as decimal(20,3)) as total_spent,
	cast(coalesce(sum(fis.taxamt),0) as decimal(20,3)) as total_tax,
	cast(coalesce(sum(fis.freight),0) as decimal(20,3)) as total_freight,
	coalesce(count(distinct fis.SalesOrderNumber),0) as num_orders,
	coalesce(count(fis.ProductKey),0) as num_products,
	

	-- date
	min(fis.OrderDate) as first_purchase_date,
	max(fis.OrderDate) as last_purchase_date,
	datediff(day, min(fis.OrderDate), max(fis.OrderDate)) as customer_tenure_days,
	datediff(day, max(fis.OrderDate), max(reference_day)) as days_since_last_order,
	count(distinct format(fis.OrderDate, 'yyyy-MM')) as active_months
from Customer cus
left join FactInternetSales fis
	on fis.CustomerKey = cus.CustomerKey
left join Geography geo
	on geo.GeographyKey = cus.GeographyKey
cross join get_last_date gld
group by
	fis.CustomerKey,
	concat(cus.FirstName, ' ', cus.LastName), 
	DATEDIFF(year, cus.BirthDate, gld.reference_day),
	cus.Gender,
	cus.MaritalStatus,
	cus.TotalChildren,
	cus.NumberChildrenAtHome,
	cus.Education,
	cus.Occupation ,
	case 
		when cus.NumberCarsOwned > 1 then '>= 2 cars'
		when cus.NumberCarsOwned = 1 then '1 car'
		else 'no car'
	end ,
	cus.HouseOwnerFlag,
	cus.CommuteDistance ,
	cus.YearlyIncome,
	geo.CountryRegionName,
	geo.StateProvinceName,
	geo.City,
	geo.PostalCode;
go

select count(distinct customerkey) from customer;

select count(distinct customer_key) from customer_360_profiling;
go

select * from customer_360_profiling;
go


-- DATA AGGREGATION FOR TIME SERIES ANALYSIS

create or alter view daily_stats_agg as 
with new_customers as(
	select
		CustomerKey,
		min(OrderDateKey) as first_purchase_date_key
	from FactInternetSales
	group by CustomerKey
),

num_new_customers as (
	select
		first_purchase_date_key,
		count(CustomerKey) as new_customers
	from new_customers
	group by first_purchase_date_key
)

select 
	cal.FullDateAlternateKey  as full_date, 
	cal.CalendarYear as calendar_year,
	cal.CalendarSemester as calendar_semester,
	cal.CalendarQuarter as calendar_quarter,
	cal.FiscalYear as fiscal_year,
	cal.FiscalSemester as fiscal_semester,
	cal.FiscalQuarter as fiscal_quarter,
	cal.MonthNumberOfYear as month_number,
	cal.MonthName as month_name,
	cal.WeekNumberOfYear as week_number,
	cal.DayNumberOfYear as day_number,




	-- financial
	cast(coalesce(sum(fis.SalesAmount),0) as decimal(20,3)) as sales_amount,
	cast(coalesce(sum(fis.TaxAmt),0) as decimal(20,3)) as tax_amount,
	cast(coalesce(sum(fis.Freight),0) as decimal(20,3)) as freight_amount,
	cast(coalesce(sum(fis.totalproductcost),0) as decimal(20,3)) as total_cost,
	cast(coalesce(sum(fis.salesamount) - sum(fis.totalproductcost),0) as decimal(20,3)) as total_profit,

	coalesce(count(distinct SalesOrderNumber),0) as total_orders,
	coalesce(sum(fis.OrderQuantity),0) as total_items,
	coalesce(count(fis.productkey),0) as total_products,

	coalesce(count(distinct CustomerKey),0) as total_customers,
	coalesce(max(nc.new_customers),0) as new_customers

from Calendar cal 
left join FactInternetSales fis
	on fis.OrderDateKey = cal.DateKey
left join num_new_customers nc 
	on nc.first_purchase_date_key = cal.DateKey
group by 
	cal.FullDateAlternateKey, 
	cal.CalendarYear,
	cal.CalendarSemester,
	cal.CalendarQuarter,
	cal.FiscalYear,
	cal.FiscalSemester,
	cal.FiscalQuarter,
	cal.MonthNumberOfYear,
	cal.MonthName,
	cal.WeekNumberOfYear,
	cal.DayNumberOfYear;
go

select * from daily_stats_agg order by full_date asc;











