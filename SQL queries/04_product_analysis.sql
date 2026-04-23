use AdventureWorksDW2025;
go


/*
**11. Which product categories and subcategories drive the highest profit margins, 
and which are drag on profitability?**
*/

-- DEFINE THE TERMS FIRST: 
-- SALESAMOUNT -> REVENUE
-- COST -> TOTAL COST
-- GROSS PROFIT -> REVENUE - TOTAL COST
-- GROSS PROFIT MARGIN -> (REVENUE - TOTAL COST) / REVENUE 
with product_stats as(
	select
		sub.ProductSubcategoryName as product_subcategory, 
		cat.ProductCategoryName as product_category,
		cast(sum(fis.salesamount) as decimal(20,3)) as total_revenue,
		cast(sum(fis.totalproductcost) as decimal(20,3)) as total_cost
	from Products p
	left join FactInternetSales fis
		on fis.ProductKey = p.ProductKey
	inner join ProductSubcategory sub
		on p.ProductSubcategoryKey = sub.ProductSubcategoryKey
	inner join ProductCategory cat
		on sub.ProductCategoryKey = cat.ProductCategoryKey
	group by
		sub.ProductSubcategoryName, 
		cat.ProductCategoryName
)
select
	product_category,
	product_subcategory,
	coalesce(total_revenue,0) as total_revenue,
	coalesce(total_cost,0) as total_cost,
	coalesce(total_revenue - total_cost,0) as total_profit,
	coalesce(cast(100.0 * (total_revenue - total_cost) / 
		nullif(total_revenue,0) as decimal(10,3)),0) as profit_margin
from product_stats
order by 
	profit_margin desc;
go





/*
**12. What is the disparity between our "High Volume" products and our "High Value" products?**
*/

-- STRATEGY: FOR EACH PRODUCT FIND TOTAL REVENUE AND TOTAL QUANTITY SOLD
-- RANK BY REVENUE AND QUANTITY
-- RETRIEVE ONLY TOP 10 REVENUE

with product_agg as(
	select
		p.ProductKey,
		p.ProductName,
		sum(salesamount) as product_revenue, 
		sum(OrderQuantity) as product_quantity 

	from FactInternetSales fis
	join products p
		on p.ProductKey = fis.ProductKey
	group by 
		p.ProductKey,
		p.ProductName
),
rank_products as (
	select
		ProductName,
		product_revenue,
		product_quantity,
		row_number() over (order by product_revenue desc) as product_value_rank,
		row_number() over (order by product_quantity desc) as product_volume_rank
	from product_agg
)
select
	ProductName,
	product_revenue,
	product_quantity,
	product_value_rank,
	product_volume_rank
from rank_products
where product_value_rank <= 10 or product_volume_rank <= 10
order by product_value_rank asc, product_volume_rank;
go


/*
**13. What is our basket size distribution, and how frequently do customers buy 
multiple items in a single transaction?**
*/

with bucket_size_calc as(
	select
		-- first determine bucket size
		SalesOrderNumber, 
		sum(OrderQuantity) as num_items
	from FactInternetSales
	group by SalesOrderNumber
)
select 
	num_items as bucket_size, 
	count(SalesOrderNumber) as num_orders,
	cast(100.0 * count(SalesOrderNumber) / sum(count(SalesOrderNumber)) over()
		as decimal(6,3)) as order_pct
from bucket_size_calc
group by 
	num_items 
order by num_orders ;
go


/*
**14. Are there any "Dead Weight" products in our active catalog that have negligible sales 
in the most recent year?**
*/

select
	p.ProductKey,
	p.ProductName,
	coalesce(sum(fis.SalesAmount),0) as revenue,
	coalesce(sum(fis.OrderQuantity),0) as quantity
from Products p
left join FactInternetSales fis
	on fis.ProductKey = p.ProductKey
	and year(fis.OrderDate) = 2013
where p.Status = 'Current'
group by
	p.ProductKey,
	p.ProductName
having 
	coalesce(sum(fis.SalesAmount),0) < 10000
	or 
	coalesce(sum(fis.OrderQuantity),0) < 50
order by 
	coalesce(sum(fis.SalesAmount),0) desc;
go 



/*
**15. How does product pricing tier affect consumer purchasing behavior?**
*/

select
	min(ListPrice) as min_price,
	avg(ListPrice) as avg_price,
	max(ListPrice) as max_price,
	STDEV(ListPrice) as std
from products;

-- min price : 2.28
-- avg price : 747.6617
-- max price : 3578.27

with product_stats as (
	select
		p.ProductKey,
		p.ListPrice,
		sum(fis.SalesAmount) as revenue,
		sum(fis.OrderQuantity) as quantity
	from Products p 
	left join FactInternetSales fis
		on fis.ProductKey = p.ProductKey
	group by 
		p.ProductKey,
		p.ListPrice
)

select
	case 
		when ListPrice <= 100 then 'Entry-level'
		when ListPrice > 1000 then 'Premium'
		else 'Standard'
	end as 'Price-Tiers',
	
	sum(revenue) as total_revenue,
	sum(quantity) as total_units_sold,
	cast(100.0 * sum(revenue) / nullif(sum(sum(revenue)) over (),0) 
		as decimal(10,3))as revenue_pct
from product_stats
group by 
	case 
		when ListPrice <= 100 then 'Entry-level'
		when ListPrice > 1000 then 'Premium'
		else 'Standard'
	end
order by
	revenue_pct desc;
go










