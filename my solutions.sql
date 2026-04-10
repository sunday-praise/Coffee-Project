select * from city;
select * from products;
select * from customers;
select * from sales;

---data analysis
---the am0unt of people that consume coffee


------ Total Revenue from Coffee Sales in the last quarter of 2023
SELECT
ci.city_name,
SUM(s. total) as total_revenue
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
WHERE
EXTRACT (YEAR FROM s. sale_date) = 2023
AND
EXTRACT(quarter FROM s. sale_date) = 4
GROUP BY 1
ORDER BY 2 DESC



----3. Sales Count for Each Product
select 
    p.product_name,
	count(s.sale_id) as total_sales_count
from products p
join sales s
 on s.product_id = p.product_id
group by 1
order by total_sales_count DESC

----4. Average Sales Amount per City
---- the city and it's total sales
---- the total number of customers in each city
select 
    ci.city_name,
	sum(s.total) as total_revenue,
	count(distinct c.customer_id) as total_customers,
	ROUND(sum(s.total)::numeric
	         /count(distinct c.customer_id)::numeric,2) as average_sales
from customers c
join city ci
   on ci.city_id = c.city_id
join sales s
 on s.customer_id = c.customer_id
group by 1
order by average_sales desc

----5. City Population and Coffee Consumers
--- a list of cities along with their populations and estimated coffee consumers.
WITH city_table as
(
SELECT
city_name,
ROUND((population * 0.25)/1000000, 2) as coffee_consumers
FROM city
),
customers_table
as
(
SELECT 
ci.city_name,
COUNT(DISTINCT c.customer_name) as unique_customers
FROM sales  s
JOIN customers  c
ON c.customer_id = s.customer_id
JOIN city  ci
ON ci.city_id = c.city_id
GROUP BY 1
)
SELECT
customers_table.city_name,
city_table.coffee_consumers as coffee_consumer_in_million,
customers_table.unique_customers
FROM city_table 
JOIN customers_table 
  ON city_table.city_name = customers_table.city_name


-- Q6
-- Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?'
select *
from
(
SELECT p.product_name,
       ci.city_name,
	   count(s.sale_id) as total_orders,
	   dense_rank() over(partition by ci.city_name order by count(s.sale_id) desc) as rank
FROM sales as s
Join products as p
ON s.product_id = p.product_id
JOIN customers as c
ON c.customer_id = s.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
group by ci.city_name, p.product_name
---order by 1, 3
) as t1
where rank>=3

---7. Customer Segmentation by City
--- unique customers present in each city who have purchased coffee products
---select * from city;
---select * from products;
---select * from customers;
---select * from sales;

SELECT
ci.city_name,
COUNT(DISTINCT c.customer_id) as unique_customers
FROM city as ci
LEFT JOIN
customers as c
ON c.city_id = ci.city_id
JOIN sales as s
ON s.customer_id = c.customer_id
WHERE s.product_id BETWEEN 1 AND 14
GROUP BY 1

---Q.8
---Average Sale vs Rent
---each city and their average sale & rent per customer
WITH 
city_table
AS
(
	SELECT
		ci.city_name,
		SUM(s.total) as total_revenue,
		COUNT (DISTINCT s.customer_id) as total_customer,
		ROUND ( SUM(s.total) :: numeric/
		COUNT (DISTINCT s.customer_id) ::numeric
		,2) as avg_sale_pr_customer
		
	FROM sales as s
	JOIN customers as c
		ON s.customer_id = c.customer_id
	JOIN city as ci
		ON ci.city_id = c.city_id
	GROUP BY 1
	ORDER BY 2 DESC
),
city_rent
AS
	(SELECT
	city_name,
	estimated_rent
	FROM city
	)
	
SELECT
	cr.city_name,
	cr.estimated_rent,
	ct.total_customer,
	ct.avg_sale_pr_customer,
	round(
		cr.estimated_rent::numeric/ct.total_customer::numeric,2) 
		as average_rent_per_customer
FROM city_rent as cr
JOIN city_table as ct
	ON cr.city_name = ct.city_name

-- Monthly Sales Growth
-- Sales growth rate: the percentage growth (or decline) in sales over different time periods (monthly)
---by each city
with 
monthly_sales
as
(
	SELECT 
		ci.city_name,
		extract(month from s.sale_date) as month,
		extract(year from s.sale_date) as year,
		sum(s.total) as total_sales
	FROM sales as s
	JOIN customers as c
	ON c.customer_id = s.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	group by 1,2,3
	order by 1,3,2
),
growth_ratio
as
(
	select 
		city_name,
		month,
		year,
		total_sales as cr_month_sale,
		lag(total_sales, 1) over(partition by city_name order by year, month) as last_month_sale
	from monthly_sales
)	

select 
	city_name,
	month,
	year,
	cr_month_sale,
	last_month_sale,
	ROUND (
	(cr_month_sale-last_month_sale) :: numeric/last_month_sale :: numeric * 100
	, 2
	) as growth_ratio
from growth_ratio
where
	last_month_sale is not null



-- Q.10
-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer

WITH city_table
AS
(
SELECT
	ci.city_name,
	SUM(s.total) as total_revenue,
	COUNT (DISTINCT s.customer_id) as total_cx,
	ROUND ( SUM(s.total) :: numeric/
		COUNT (DISTINCT s.customer_id) :: numeric
	,2) as avg_sale_pr_cx
FROM sales as s
JOIN customers as c
	ON s.customer_id = c.customer_id
JOIN city as ci
	ON ci.city_id = c.city_id
GROUP BY 1
ORDER BY 2 DESC
),
city_rent
AS
(	
	SELECT
	city_name,
	estimated_rent,
	round((population * 0.25)/1000000,3) as estimated_coffee_consumer_in_millions
FROM city
)
 SELECT
	cr.city_name,
	cr.estimated_rent as total_rent,
	ct.total_cx,
	estimated_coffee_consumer_in_millions,
	ct.avg_sale_pr_cx,
	ROUND (
	cr.estimated_rent:: numeric/
	      ct.total_cx:: numeric
	, 2) as avg_rent_per_cx
FROM city_rent as cr
JOIN city_table as ct
ON cr.city_name = ct.city_name
ORDER BY 2 DESC

-- City Recomendations
---City 1: Pune
---1. Average rent per customer is very less,
---2. The city contains the highest total revenue,
---3. The average sale per customer is also high

---City 2. Delhi
---1. Highest estimated coffee consumer which is 7.7M
---2. The city contains the highest total customers which is 68
---3. The average rent per customer 330 (still under 500)

---City 3. Jaipur
---1. Highest customer number which is 69
---2. Average rent per customer is very less 156