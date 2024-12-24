CREATE TABLE supplychain (
	Product_type varchar(20),	
	SKU	varchar(10),
	Price float,
	Availability int,	
	Number_of_products_sold	 int,
	Revenue_generated float,	
	Customer_demographics varchar(20),
	Stock_levels int,	
	Lead_times	int,
	Order_quantities int,	
	Shipping_times int,	
	Shipping_carriers varchar(20),
	Shipping_costs	float,
	Supplier_name	varchar(20),
	Location	varchar(20),
	Latitide	float,
	Longitude	float,
	Lead_time	int,
	Production_volumes	int,
	Manufacturing_lead_time	int,
	Manufacturing_costs	float,
	Inspection_results varchar(20),	
	Defect_rates float,	
	Transportation_modes varchar(10),	
	Routes	varchar(20),
	Costs float
	);

--- EDA

SELECT * FROM supplychain;

--- PROBLEM STATEMENTS
--1. What are the most frequently ordered products?
	SELECT product_type, COUNT(number_of_products_sold) AS total_product
	FROM supplychain
	GROUP BY 1
	ORDER BY 2 DESC;

--2. What is the total value of inventory on hand?
	SELECT DISTINCT (product_type), CEIL(SUM(stock_levels * price)) AS inventory_level
	FROM supplychain
	GROUP BY 1
	ORDER BY 2 DESC;

--3. Which supplier has the highest average delivery time?
	SELECT DISTINCT (supplier_name) , ROUND(AVG(lead_time),3) AS Avg_DT
	FROM supplychain
	GROUP BY 1
	ORDER BY 2 DESC
	LIMIT 1;

--4. What is the average cost per unit for each supplier?
	SELECT DISTINCT (supplier_name) , CEIL(AVG(manufacturing_costs)) AS Avg_Cost
	FROM supplychain
	GROUP BY 1
	ORDER BY 2 DESC;
	
--5. Which supplier has the highest defect rate?
-- Solving this in 3 different methods:
-- Simple Query
	SELECT DISTINCT (supplier_name) , CEIL(SUM(defect_rates)) AS total_defects
	FROM supplychain
	GROUP BY 1
	ORDER BY 2 DESC
	LIMIT 1;
	
-- As a CTE
	WITH Ranking AS(
		SELECT supplier_name, SUM(defect_rates) AS defects,
		RANK() OVER (ORDER BY SUM(defect_rates) DESC) AS Supplier_rank
		FROM supplychain
		GROUP BY 1
	)
	SELECT supplier_name, CEIL(defects) AS total_defect
	FROM Ranking 
	WHERE supplier_rank = 1 ;

-- As a subquery
	SELECT * FROM
		(SELECT supplier_name, CEIL(SUM(defect_rates)) AS total_defects,
		RANK() OVER (ORDER BY SUM(defect_rates) DESC) AS Supplier_rank
		FROM supplychain
		GROUP BY 1)AS Pop
	WHERE Supplier_rank= 1;
	
--6. What is the average shipping cost per order?	
	SELECT AVG(shipping_costs) AS avg_cost
	FROM supplychain;

--7. Which carrier has the highest on-time delivery rate?
	SELECT * FROM 
		(SELECT shipping_carriers, SUM(shipping_times) AS highest,
		ROW_NUMBER () OVER (ORDER BY SUM(shipping_times) DESC) AS best_carrier
		FROM supplychain
		GROUP BY 1) AS Tot
	WHERE best_carrier = 1;
	
--8. What is the total number of shipments by carrier? 
	SELECT shipping_carriers, COUNT(*)
	FROM supplychain
	GROUP BY 1;

--9. What is the total revenue generated?
	SELECT CEIL(SUM(revenue_generated)) AS total
	FROM supplychain;
	
--10. Which product category and customer generates the highest revenue?
	SELECT * FROM 
		(SELECT product_type, customer_demographics, CEIL(SUM(revenue_generated)) AS revenue,
		ROW_NUMBER() OVER(PARTITION BY customer_demographics ORDER BY SUM(revenue_generated) DESC)  AS ranking
		FROM supplychain
		GROUP BY 1, 2)
	WHERE ranking = 1;

--11. What is the average order value?
	SELECT ROUND(AVG(order_quantities), 3) 
	FROM supplychain; 
	
--12. Who are the top suppliers by revenue?
	--SELECT * FROM supplychain

	WITH Calculation AS 
	(
		SELECT supplier_name, SUM(revenue_generated) AS total_revenue,
		RANK() OVER (ORDER BY SUM(revenue_generated) DESC) AS ranking
		FROM supplychain
		GROUP BY 1
	)
	SELECT supplier_name, CEIL(total_revenue), ranking
	FROM Calculation
	LIMIT 3;
	
--13. What is the average order frequency per customer?
	SELECT customer_demographics, ROUND(AVG(order_quantities), 0) as order_freq
	FROM supplychain
	GROUP BY 1
	ORDER BY 1;
	
--14. Which location is most profitable?
	SELECT location, CEIL(SUM(revenue_generated)) AS most_profitable
	FROM supplychain
	GROUP BY 1
	ORDER BY 2 DESC;
	
--15. Who are the top 10 performing SKU by revenue and product sold?
	--SELECT * FROM supplychain
	
	SELECT sku, 
	       CEIL(SUM(revenue_generated)) AS total_revenue,
		   SUM(number_of_products_sold) AS total_products
	FROM supplychain
	GROUP BY 1
	ORDER BY 2 DESC, 3 DESC
	LIMIT 10;

	
--16. Which suppliers have the highest on-time delivery rates and the lowest defect rate

	WITH OnTime AS (
	    SELECT supplier_name, 
	    ROUND(AVG(lead_times),3) AS delivery_rate
	    FROM supplychain
	    GROUP BY 1
	),
	Defects AS (
	    SELECT supplier_name, 
		AVG(defect_rates) AS defects
	    FROM supplychain
	    GROUP BY 1
	)
	SELECT o.supplier_name, 
	       o.delivery_rate, 
	       d.defects
	FROM OnTime o
	JOIN Defects d ON o.supplier_name = d.supplier_name
	ORDER BY delivery_rate DESC, defects ASC;

--17. What is the most cost-effective transportation mode and route for each shipment?
SELECT * FROM supplychain;

	WITH CostEffective AS (
		SELECT 
			transportation_modes, 
			routes, 
			SUM(shipping_costs) AS costs,
			ROW_NUMBER() OVER (PARTITION BY routes ORDER BY SUM(shipping_costs) DESC) AS rank
		FROM supplychain
		GROUP BY 1,2
	)
	SELECT 
		transportation_modes, 
		routes, 
		costs 
	FROM 
		CostEffective
	WHERE 
		rank = 1;

--18. What are the lead times for all suppliers?

	SELECT supplier_name, SUM(lead_times)
	FROM supplychain
	GROUP BY 1
	ORDER BY 2 DESC;

--19. What transport mode has more populated customers?

	SELECT transportation_modes, COUNT(customer_demographics)
	FROM supplychain
	GROUP BY 1
	ORDER BY 2 DESC;

--20. What product type has the most defect rate?
	SELECT product_type, CEIL(SUM(defect_rates))
	FROM supplychain
	GROUP BY 1
	ORDER BY 2 DESC;

--21. What is the most cost-effective transportation mode and carrier for each shipment?
	SELECT 
		transportation_modes, 
		shipping_carriers, 
		SUM(shipping_costs) AS costs,
		ROW_NUMBER() OVER (PARTITION BY transportation_modes ORDER BY SUM(shipping_costs) DESC) AS rank
	FROM supplychain
	GROUP BY 1, 2
	