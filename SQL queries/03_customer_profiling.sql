use AdventureWorksDW2025;
go


/*
**6. Which demographic segments (based on Income and Education) drive the highest overall revenue?** */

with median_cte as (
    select YearlyIncome,
           percentile_cont(0.5) within group (order by YearlyIncome) 
               over () as median_income
    from Customer
)
select 
    min(YearlyIncome) as min_income,
    avg(YearlyIncome) as avg_income,
    max(YearlyIncome) as max_income,
    stdev(YearlyIncome) as std_income,
    max(median_income) as median_income
from median_cte;


-- MIN INCOME : 10,000
-- MAX INCOME : 170,000
-- AVG INCOME : 57,305
-- MEDIAN INCOME : 60,000
-- STD INCOME : 32,285

/* RULES IF-THEN:
- INCOME <= (MEDIAN - STD) -> LOW BUDGET
- INCOME BETWEEN (MEDIAN - STD) AND (MEDIAN + STD) -> MID BUDGET
- INCOME >= (MEDIAN + STD) -> HIGH BUDGET
*/


with customer_info as 
(
    select 
        c.CustomerKey as customer_key,
        c.YearlyIncome as yearly_income,
        c.education,
        sum(fis.SalesAmount) as revenue,
        count(distinct fis.SalesOrderNumber) as num_orders
    from Customer c
    left join FactInternetSales fis
        on c.CustomerKey = fis.CustomerKey
    group by
        c.CustomerKey,
        c.YearlyIncome,
        c.education
),

customer_stats as (
    select 
        cast(avg(YearlyIncome) as float) as avg_income,
        cast(STDEV(YearlyIncome) as float) as std_income
    from Customer
)

select
    case 
        when yearly_income <= (avg_income - 0.7 * std_income) 
            then 'low_budget customer'
        when yearly_income >= (avg_income + 0.8 * std_income) 
            then 'high_budget customer'
        else 'mid-budget customer'
    end as customer_budget_segmentation, 

    education, 
    count(distinct customer_key) as num_customers,
    cast(sum(revenue) as float) as total_revenue, 
    cast(sum(num_orders) as float) as total_orders
from customer_info 
cross join customer_stats
group by
    case 
        when yearly_income <= (avg_income - 0.7 * std_income) 
            then 'low_budget customer'
        when yearly_income >= (avg_income + 0.8 * std_income) 
            then 'high_budget customer'
        else 'mid-budget customer'
    end,
    education
order by 
    total_revenue desc;
go
    

/*
**7. Does the customer's commute distance and vehicle ownership impact their lifetime value?** */

select distinct CommuteDistance from Customer;

with customer_info as (
    select
        cus.CustomerKey,
        cus.CommuteDistance as commute_distance,
        cus.NumberCarsOwned as num_cars,
        coalesce(sum(fis.SalesAmount),0) as revenue, 
        coalesce(count(distinct fis.SalesOrderNumber),0) as num_orders
    from Customer cus
    left join FactInternetSales fis
        on fis.CustomerKey = cus.CustomerKey
    group by 
        cus.CustomerKey,
        cus.CommuteDistance,
        cus.NumberCarsOwned
)
select
    case  
        when num_cars = 1 then '1 car'
        when num_cars > 1 then '>1 car'
        else 'no car'
    end as 'car_ownership',
    commute_distance,
    count(distinct customerkey) as num_customers,
    cast(sum(revenue) as decimal(20,3)) as total_revenue,
    sum(num_orders) as total_orders,
    cast(sum(revenue) / nullif(count(distinct customerkey),0) as decimal(10,3)) 
        as avg_revenue_per_customer
from customer_info
group by 
    case  
        when num_cars = 1 then '1 car'
        when num_cars > 1 then '>1 car'
        else 'no car'
    end,
    commute_distance
order by
    total_revenue desc,
    car_ownership
go


/*
**8. Who are our "Whales" (Top 100 Most Valuable Customers), and what is their purchasing frequency?** */

select top 100

    cus.CustomerKey,
    cus.FirstName,
    cus.LastName,
    sum(fis.salesamount) as revenue, 
    count(distinct fis.salesordernumber) as num_orders,
    count(distinct cast(format(fis.orderdate, 'yyyy-MM') as varchar(20)) ) as 'num_months_purchased',
    cast(count(distinct fis.salesordernumber) * 1.0 / 
        nullif(count(distinct format(fis.orderdate, 'yyyy-MM')),0) as decimal(10,3))
        as avg_orders_per_month

from Customer cus
    left join FactInternetSales fis 
        on fis.customerkey = cus.customerkey
group by 
    cus.CustomerKey,
    cus.FirstName,
    cus.LastName
order by 
    revenue desc;
go 


/*
**9. What is our generational spend distribution (Age Brackets)?** */

select min(DATEDIFF(year, BirthDate, getdate())) as min_date,
    max(DATEDIFF(year, BirthDate, getdate())) as max_date
from Customer;

-- MINIMUM CUSTOMER AGE IS 40 
-- MAXIMUM CUSTOMER AGE IS 110 
-- THIS IS HISTORICAL DATA, SO WE CAN NOT TODAY'S DATE AS REFERENCE DATE. 
-- INSTEAD CHOOSE THE MAX DATE IN THE DATASET (ORDERDATE)


with get_max_date as (
    select
        max(OrderDate) as reference_day
    from FactInternetSales
),

customer_info as (
    select
        cus.CustomerKey,
        -- we should find age using datediff() function
        DATEDIFF(year, cus.BirthDate, reference_day) as customer_age,
        cus.Gender as customer_gender,
        cus.MaritalStatus as customer_marital_status,
        sum(fis.SalesAmount) as customer_revenue,
        count(distinct fis.SalesOrderNumber) as customer_total_orders,
        sum(fis.OrderQuantity) as customer_total_products
    from Customer cus
    left join FactInternetSales fis
        on cus.CustomerKey = fis.CustomerKey
    cross  join get_max_date
    group by 
        cus.CustomerKey,
        DATEDIFF(year, cus.BirthDate, reference_day),
        cus.Gender,
        cus.MaritalStatus
)
select
    -- segment the customers into ages
    case  
        when customer_age < 25 then '<25'
        when Customer_age between 25 and 35  then '25-35'
        when customer_age between 36 and 45 then '36-45'
        when customer_age between 46 and 55 then '46-55'
        when customer_age between 56 and 65 then '56-65'
        else '66+'
    end as age_group,

    case 
        when customer_gender = 'F' then 'Female'
        when customer_gender = 'M' then 'Male'
        else 'Other'
    end as gender,
    case    
        when customer_marital_status = 'S' then 'Single' 
        when customer_marital_status = 'M' then 'Married'
        else 'Other'
    end as marital_status,
    count(distinct CustomerKey) as num_customers,
    coalesce(sum(customer_revenue),0) as total_revenue,
    coalesce(sum(customer_total_orders),0) as total_orders,
    coalesce(sum(customer_total_products),0) as total_products
from customer_info
group by 
    case  
        when customer_age < 25 then '<25'
        when Customer_age between 25 and 35  then '25-35'
        when customer_age between 36 and 45 then '36-45'
        when customer_age between 46 and 55 then '46-55'
        when customer_age between 56 and 65 then '56-65'
        else '66+'
    end,

    case 
        when customer_gender = 'F' then 'Female'
        when customer_gender = 'M' then 'Male'
        else 'Other'
    end,

    customer_marital_status,
    case    
        when customer_marital_status = 'S' then 'Single' 
        when customer_marital_status = 'M' then 'Married'
        else 'Other'
    end
order by
    total_revenue desc;
go 



/*
**10. What is our Customer Retention Rate (One-and-Done vs. Repeat Buyers)?**
*/

-- IDENTIFY CUSTOMERS WHO MADE 1 ORDER AND MULTIPLE ORDERS
-- RETENTION RATE - PERCENTAGE OF EACH

with customer_info as 
(
    select
        cus.CustomerKey,
        coalesce(count(distinct fis.SalesOrderNumber),0) as num_orders,
        sum(fis.SalesAmount) as revenue
    from customer cus
    left join FactInternetSales fis 
        on fis.CustomerKey = cus.CustomerKey
    group by cus.CustomerKey

),

retention_groups as (
    select
        case 
            when num_orders > 1 then 'repeat-buyers' 
            when num_orders = 1 then 'one-and-done'
            else 'no order'
        end as retention_group,

        count(distinct CustomerKey) as num_customers ,
        sum(revenue) as total_revenue
    from customer_info
    group by 
        case 
            when num_orders > 1 then 'repeat-buyers' 
            when num_orders = 1 then 'one-and-done'
            else 'no order'
        end
)

select
    retention_group,
    num_customers,
    total_revenue,
    cast(num_customers * 1.0 / nullif(sum(num_customers) over (),0) as decimal(10,3)) 
        as retention_rate_pct
from retention_groups
order by
    total_revenue desc;
go
        





