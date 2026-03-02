use AdventureWorksDW2025;
go


/*
**20. Which countries and regions drive the most B2C revenue, 
and how does the Average Order Value (AOV) differ geographically?**
*/

select
	st.SalesTerritoryCountry as country,
	st.SalesTerritoryRegion as region,
	coalesce(sum(fis.SalesAmount),0) as total_revenue,
	coalesce(count(distinct fis.SalesOrderNumber),0) as total_orders,
	coalesce(count(distinct fis.CustomerKey),0) as total_customers, 
	cast(
		sum(fis.SalesAmount) / nullif(count(distinct fis.SalesOrderNumber),0) 
		as decimal(20,3)
	) as avg_order_value
from FactInternetSales fis
left join SalesTerritory st
	on st.SalesTerritoryKey = fis.SalesTerritoryKey
group by
	st.SalesTerritoryCountry,
	st.SalesTerritoryRegion
order by
	total_revenue desc;
go
	

/*
**21. Are we meeting our operational Service Level Agreements (SLAs)? 
What is the average lead time between Order Date and Ship Date?**
*/

with shipping_days as (
	select
		fis.SalesOrderNumber,
		fis.OrderDateKey,
		st.SalesTerritoryRegion as region,
		min(datediff(day, fis.OrderDate, fis.ShipDate)) as days_to_ship
	from FactInternetSales fis 
	left join SalesTerritory st
		on st.SalesTerritoryKey = fis.SalesTerritoryKey
	group by
		fis.SalesOrderNumber,
		fis.OrderDateKey,
		st.SalesTerritoryRegion
)

select
	c.MonthNumberOfYear as month_number,
	c.MonthName as month_name,
	sd.region,
	coalesce(cast(avg(sd.days_to_ship) as int), 0) as avg_days_to_ship,
	case 
		when avg(sd.days_to_ship) > 5 + avg(avg(sd.days_to_ship)) over (partition by sd.region) 
			then 'late delivery'
		when avg(sd.days_to_ship) < avg(avg(sd.days_to_ship)) over (partition by sd.region) - 5 
			then 'early delivery'
		else 'on-time delivery'
	end as delivery_performance
from Calendar c
left join shipping_days sd
	on sd.OrderDateKey = c.DateKey
group by 
	c.MonthNumberOfYear ,
	c.MonthName ,
	sd.region
order by
	month_number;
go




/*
**22. How heavily do freight and tax costs impact the final landed cost for the 
consumer across different countries?**
*/

with country_stats as (
	select
		fis.salesordernumber,
		st.SalesTerritoryCountry as country,
		sum(fis.SalesAmount) as revenue,
		sum(fis.TaxAmt) as tax,
		sum(fis.Freight) as freight
	from FactInternetSales fis 
	join SalesTerritory st
		on st.SalesTerritoryKey = fis.SalesTerritoryKey
	group by 
		fis.salesordernumber,
		st.SalesTerritoryCountry
)
select
	country,
	cast(sum(revenue) as decimal (20,3)) as total_revenue,
	cast(sum(tax) as decimal (20,3)) as total_tax,
	cast(sum(freight) as decimal (20,3)) as total_freight,
	cast(
		sum(tax) * 1.0 / nullif(sum(revenue),0) as decimal (10,3)
	) as tax_pct,
	cast(
		sum(freight) * 1.0 / nullif(sum(revenue),0) as decimal (10,3)
	) as freight_pct,
	cast(
		(sum(tax) + sum(freight)) * 1.0 / nullif(sum(revenue),0) as decimal (10,3)
	) as tax_freight_pct
from country_stats
group by
	country 
order by
	total_revenue desc;
go


/*
**23. Is there a regional bias for specific Product Categories?**
*/

with product_info as(
	select
		pr.ProductKey,
		cat.ProductCategoryName as product_category,
		st.SalesTerritoryCountry as country,
		sum(fis.SalesAmount) as revenue
	from Products pr
	join ProductSubcategory sub
		on sub.ProductSubcategoryKey = pr.ProductSubcategoryKey
	join ProductCategory cat 
		on cat.ProductCategoryKey = sub.ProductCategoryKey
	join FactInternetSales fis
		on fis.ProductKey = pr.ProductKey
	join SalesTerritory st
		on st.SalesTerritoryKey = fis.SalesTerritoryKey
group by
	pr.ProductKey,
	cat.ProductCategoryName,
	st.SalesTerritoryCountry
)

select
		country,
		product_category,
		sum(revenue) as total_revenue,
		cast(
			sum(revenue) * 100.0 / nullif((sum(sum(revenue)) over(partition by country)),0)
			as decimal(10,3)
		) as revenue_pct
	from product_info
	group by
		country,
		product_category
	order by 
		country,
		revenue_pct desc;
go



























