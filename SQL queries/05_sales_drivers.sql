use AdventureWorksDW2025;
go


/*
**16. What are the primary psychological drivers (Sales Reasons) behind our B2C purchases?**
*/

select count(distinct salesordernumber), count(salesordernumber) from FactInternetSalesReason;

-- 23012 distinct salesordernumber
-- 64515 overall salesordernumber
-- so between factinternetsales and factinternetsalesreason the relationship is 
-- one to many
-- on the other hand, relationship between factinternetsalesreason and salesreason
-- is many-to-one
-- joinin all tables in the same select statement will lead us to duplicate problems
-- due to many-to-many relationship.
-- therefore we should join frs and fis using both salesordernumber and salesorderlinenumber

with sales_reason_stats as(
select
	fsr.SalesReasonKey,
	sum(fis.SalesAmount) as total_revenue,
	count(distinct fsr.SalesOrderNumber) as total_orders,
	sum(fis.OrderQuantity) as total_units_sold
from FactInternetSalesReason fsr
join FactInternetSales fis 
	on fsr.SalesOrderNumber = fis.SalesOrderNumber
	and fsr.SalesOrderLineNumber = fis.SalesOrderLineNumber

group by
	fsr.SalesReasonKey
)

select
	sr.SalesReasonName,
	sr.SalesReasonReasonType,
	cast(total_revenue as decimal(20,3)) as total_revenue,
	total_orders,
	total_units_sold,
	cast(
		total_revenue *100.0 / nullif(sum(total_revenue) over(),0)
		as decimal(10,2)
	) as revenue_pct
from sales_reason_stats r
join SalesReason sr 
	on r.SalesReasonKey = sr.SalesReasonKey

order by
	revenue_pct desc;
go



/*
**17. What percentage of our total B2C volume is driven by promotional discounts versus standard pricing?**
*/
select count(*) from FactInternetSales fis
where DiscountAmount > 0;

-- IN THE INTERNETSALES DISCOUNT IS NOT APPLIED TO ANY ORDER.


/* 
18: What is our Customer Lifetime Value (CLV) distribution, 
and how long does it take for a customer to reach their maximum value?
*/

with customer_stats as (
	select
		fis.CustomerKey, 
		min(fis.OrderDate) as first_purchase_date,
		max(fis.OrderDate) as last_purchase_date,
		sum(fis.SalesAmount) as lifetime_value,
		cast( 1.0 * datediff(day, min(fis.OrderDate),max(fis.OrderDate)) as float)
			as customer_tenure
	from FactInternetSales  fis
	group by CustomerKey
)

select
	case  
		when lifetime_value <= 100 then '<=100'
		when lifetime_value between 101 and 500 then '101-500'
		when lifetime_value between 501 and 1000 then '501-1000'
		when lifetime_value between 1001 and 2500 then '1001-2500'
		when lifetime_value between 2501 and 5000 then '2501-5000'
		when lifetime_value between 5000 and 10000 then '5001-10000'
		else '>10000'
	end as clv_tier,
	count(distinct CustomerKey) as num_customers,
	cast(avg(lifetime_value) as decimal(10,3)) as avg_lifetime_value,
	cast(avg(customer_tenure) as int) as avg_customer_tenure
from customer_stats
where customer_tenure <> 0  -- we don't consider one-time buyers
group by
	case  
		when lifetime_value <= 100 then '<=100'
		when lifetime_value between 101 and 500 then '101-500'
		when lifetime_value between 501 and 1000 then '501-1000'
		when lifetime_value between 1001 and 2500 then '1001-2500'
		when lifetime_value between 2501 and 5000 then '2501-5000'
		when lifetime_value between 5000 and 10000 then '5001-10000'
		else '>10000'
	end 
order by 
	avg_lifetime_value desc;
go


















/*
**19. Do the primary sales drivers change depending on the Product Category?**
*/

with product_stats as (
	select
		fis.SalesOrderNumber,
		cat.ProductCategoryName as product_category,
		frs.SalesReasonKey,
		sr.SalesReasonName as sales_reason
	from Products pr
	join ProductSubcategory sub
		on sub.ProductSubcategoryKey = pr.ProductSubcategoryKey
	join ProductCategory cat
		on cat.ProductCategoryKey = sub.ProductCategoryKey
	left join FactInternetSales fis
		on fis.ProductKey = pr.ProductKey
	left join FactInternetSalesReason frs
		on frs.SalesOrderNumber = fis.SalesOrderNumber
		and frs.SalesOrderLineNumber = fis.SalesOrderLineNumber
	left join  SalesReason sr
		on sr.SalesReasonKey = frs.SalesReasonKey


),

sales_reasons as (
	select
		product_category,
		sales_reason,
		count(distinct SalesOrderNumber) as num_orders
	from product_stats
	group by 
		product_category,
		sales_reason
),

ranked_sales as(
	select
		product_category,
		sales_reason,
		num_orders,
		ROW_NUMBER() over (partition by product_category 
			order by num_orders desc) as ranked_orders
	from sales_reasons
)

select 
	product_category,
	sales_reason,
	num_orders 
from ranked_sales
where ranked_orders = 1;
go



















