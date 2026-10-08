-- change over time
-- analyses how a measure evolves over time. it helps track trends and identify seasonality in ur data
-- a high lvl overview insights that helps with strategic decision making
-- fact table usually targeted, ja q e ai onde tem os measures e dates

-- ex.: total sales by year
select order_date, sum(sales_amount) as [Total Sales]
from gold.fact_sales where order_date is not null group by order_date order by order_date; -- por dia

select year(order_date) as order_year, count(distinct customer_key) as total_customer, 
sum(quantity) as total_quantity, sum(sales_amount) as [Total Sales]
from gold.fact_sales where order_date is not null 
group by year(order_date) order by year(order_date); -- por ano

select month(order_date) as order_year, count(distinct customer_key) as total_customer, 
sum(quantity) as total_quantity, sum(sales_amount) as [Total Sales]
from gold.fact_sales where order_date is not null 
group by month(order_date) order by month(order_date); -- por mes, para seasonality of data

-- datetrunc: rounds a date or timestamp to a specific date part. para nao precisar ter duas colunas
-- quando quer dados por mes e ano
select datetrunc(year, order_date) as order_year, count(distinct customer_key) as total_customer, 
sum(quantity) as total_quantity, sum(sales_amount) as [Total Sales]
from gold.fact_sales where order_date is not null 
group by datetrunc(year, order_date) order by datetrunc(year, order_date);

-- cumulative analysis - aggregates the data progressively over time
-- helps to understand whether the business is growing or declining

-- ex.: get the total sales per month and the running total of sales over time
select order_date, [Total Sales], sum([Total Sales]) over (order by datetrunc(month, order_date))
as running_total_sales
from
( select datetrunc(month, order_date) as order_date, sum(sales_amount) as [Total Sales]
from gold.fact_sales where order_date is not null 
group by datetrunc(month, order_date))t;

-- para fazer o acumulador reiniciar quando mudar algo, so e usar partition by
select order_date, [Total Sales], sum([Total Sales]) over (partition by order_date order by order_date)
as running_total_sales
from
( select datetrunc(month, order_date) as order_date, sum(sales_amount) as [Total Sales]
from gold.fact_sales where order_date is not null 
group by datetrunc(month, order_date))t;

-- total value per year and the running total of sales over time
select order_date, [Total Sales], sum([Total Sales]) over (partition by order_date order by order_date)
as running_total_sales
from
( select datetrunc(year, order_date) as order_date, sum(sales_amount) as [Total Sales]
from gold.fact_sales where order_date is not null 
group by datetrunc(year, order_date))t;

-- quando usar aggregation normal e quando cumulative
-- normal agg - check the performance of each individual row. like how each year is performing
-- wf - quando quer ver progression e/ou como o business is going. like the progress of ur business
-- over the years

-- ex.: moving average price over the months
select order_date, [Total Sales], sum([Total Sales]) over (partition by order_date order by order_date)
as running_total_sales, avg([Average Price]) over (order by order_date) as moving_average_price
from
( select datetrunc(year, order_date) as order_date, sum(sales_amount) as [Total Sales],
avg(price) as [Average Price]
from gold.fact_sales where order_date is not null 
group by datetrunc(year, order_date))t;

-- performance analysis
-- compares the current value to the target value
-- helps measure success and compare performance

-- ex.: analyse the yearly performance of products by comparing each product's sales to both its average
-- sales performance and the previous year's sales
with yearly_product_sales as (
select year(s.order_date) as order_year, p.product_name, sum(s.sales_amount) 
as [Current Sales]
from gold.fact_sales s left join gold.dim_products p on s.product_key = p.product_key 
where s.order_date is not null group by year(s.order_date), p.product_name)

select order_year, product_name, [Current Sales], avg([Current Sales]) over (partition by product_name)
as [Average Sales], [Current Sales] - avg([Current Sales]) over (partition by product_name) as diff_avg_sales,
case when [Current Sales] - avg([Current Sales]) over (partition by product_name) > 0 then 'Above Average'
	when [Current Sales] - avg([Current Sales]) over (partition by product_name) < 0 then 'Below Average'
	else 'Average'
end as [Average Change],
-- year over year analysis
lag([Current Sales]) over (partition by product_name order by order_year) as [Previous Year],
[Current Sales] - lag([Current Sales]) over (partition by product_name order by order_year) as diff_years_sales,
case when [Current Sales] - lag([Current Sales]) over (partition by product_name order by order_year) > 0 then 'Increase'
	when [Current Sales] - lag([Current Sales]) over (partition by product_name order by order_year) < 0 then 'Decrease'
	else 'No Change'
end as [Previous Year Change]
from yearly_product_sales order by product_name, order_year;

-- part to whole
-- analyse how an individual part is performing compared to the overall, allowing us to understand
-- which category has the greatest impact on business
with category_sales as (
select category, sum(sales_amount) total_sales
from gold.fact_sales s left join gold.dim_products p on s.product_key = p.product_key
group by category)

select category, total_sales, sum(total_sales) over() as overall_sales, 
concat(round((cast(total_sales as float) /sum(total_sales) over() * 100), 2), '%') as [Percentage of Sales]
from category_sales order by [Percentage of Sales] desc;

-- data segmentation
-- group the data based on specific range. helps understand the correlation between 2 measures

-- ex.: segment products into cost ranges and count how many products fall into each segment
with product_segments as (
select product_key, product_name, product_cost,
case when product_cost < 100 then 'Below 100'
	when product_cost between 100 and 500 then '100-500'
	when product_cost between 500 and 1000 then '500-1000'
	else 'Above 1000'
end cost_range
from gold.dim_products)

select cost_range, count(product_key) as total_products
from product_segments group by cost_range order by total_products desc;

/* Group customers into 3 segments based on their spending behaviour:
	- VIP: Customers with at least 12 months of history and spending more than $5000
	- Regular: Customers with at least 12 months of history but spending $5000 or less
	- New: Customers with a lifespan less than 12 months.
And find the total number of customers by each group */
with customer_spending as (
select c.customer_key, sum(s.sales_amount) as total_spending, min(order_date) as first_order,
max(order_date) as last_order, datediff(month, min(order_date), max(order_date)) as lifespan
from gold.fact_sales as s left join gold.dim_customers c on s.customer_key = c.customer_key
group by c.customer_key)

select customer_segment, count(customer_key) as total_customers
from (
select customer_key,
case when lifespan >= 12 and total_spending > 5000 then 'VIP'
	when lifespan >= 12 and total_spending <= 5000 then 'Regular'
	else 'New'
end as customer_segment
from customer_spending)t
group by customer_segment;

-- business report
-- primeiro, faz se a cte base para retrieve core columns from tables
create view gold.report_customers as 
with base_query as (
select s.order_number, s.product_key, s.order_date, s.sales_amount, s.quantity, c.customer_key, 
c.customer_number, concat(c.first_name, ' ', c.last_name) as customer_name,
datediff(year, c.birthdate, getdate()) age
from gold.fact_sales as s left join gold.dim_customers as c on s.customer_key = c.customer_key
where order_date is not null),

-- intermediate cte onde faz todos aggregations no customer lvl
customer_aggregation as (select customer_key, customer_number, customer_name, age, count(distinct order_number) as total_orders, 
sum(sales_amount) as total_sales, sum(quantity) as total_quantity, 
count(distinct product_key) as total_products, max(order_date) as last_order_date, 
datediff(month, min(order_date), max(order_date)) as lifespan
from base_query group by customer_key, customer_number, customer_name, age)

select customer_key, customer_number, customer_name, age, 
case when age < 20 then 'Under 20'
	when age between 20 and 29 then '20-29'
	when age between 30 and 39 then '30-39'
	when age between 40 and 49 then '40-49'
	else 'Above 50'
end as age_group,
case when lifespan >= 12 and total_sales> 5000 then 'VIP'
	when lifespan >= 12 and total_sales<= 5000 then 'Regular'
	else 'New'
end as customer_segment, last_order_date, 
datediff(month, last_order_date, getdate()) as recency,
total_orders, total_sales, total_quantity, total_products, lifespan,
-- compute average order value
case when total_sales = 0 then 0
	else total_sales / total_orders
end as avg_order_value,
case when lifespan = 0 then total_sales
	else total_sales / lifespan
end as avg_monthly_spend
from customer_aggregation;