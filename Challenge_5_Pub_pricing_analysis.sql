use pub_data;

/*1. How many pubs are located in each country??*/
SELECT
pubs.country AS Country,
COUNT(DISTINCT pub_id) AS No_of_Pubs
FROM pubs
GROUP BY
1;

/*2. What is the total sales amount for each pub, including the beverage price and quantity sold?*/
SELECT
p.pub_name AS Pub_Name,
SUM(s.quantity*b.price_per_unit) AS Total_Sales_Amount,
SUM(s.quantity) AS Quantity_Sold
FROM sales AS s
LEFT JOIN pubs AS p
	ON p.pub_id = s.pub_id
LEFT JOIN beverages AS b
	ON b.beverage_id = s.beverage_id
GROUP BY
p.pub_id
;

/*3. Which pub has the highest average rating?*/
SELECT
p.pub_name AS Pub_Name,
ROUND(AVG(r.rating),2) AS Avg_Rating
FROM ratings AS r
LEFT JOIN pubs AS p
	ON p.pub_id = r.pub_id
GROUP BY
	p.pub_id
ORDER BY
	Avg_Rating DESC
LIMIT 1
;

/*4. What are the top 5 beverages by sales quantity across all pubs?*/

SELECT
p.pub_name AS Pub_Name,
b.beverage_name AS Beverage_Name,
SUM(s.quantity) AS Sales_Quantity
FROM sales AS s
LEFT JOIN pubs AS p
	ON p.pub_id = s.pub_id
LEFT JOIN beverages AS b
	ON b.beverage_id = s.beverage_id
GROUP BY
1,2
ORDER BY Sales_Quantity DESC
LIMIT 5
;

/* 5. How many sales transactions occurred on each date? */
SELECT
DATE(s.transaction_date) AS Transaction_Date,
SUM(s.quantity*b.price_per_unit) AS Transaction_Amount
FROM sales AS s
LEFT JOIN beverages AS b
	ON b.beverage_id = s.beverage_id
GROUP BY
1;

/*6. Find the name of someone that had cocktails and which pub they had it in */

WITH Customer AS
(SELECT DISTINCT
	b.beverage_id,
    pub_id,
    b.category
	FROM beverages AS b
    INNER JOIN sales AS s
		ON s.beverage_id = b.beverage_id
	WHERE b.category = 'Cocktail')
    SELECT
    r.customer_name AS Customer_Name,
    -- p.pub_id AS ,
    p.pub_name,
    c.category
    FROM ratings AS r, pubs AS p, Customer AS c
    WHERE r.pub_id = p.pub_id
		AND c.pub_id = p.pub_id
;

-- Another Method--
SELECT
r.customer_name AS Customer_Name,
p.pub_name AS Pub_Name,
b.category AS Beverage_Catagory
FROM ratings AS r
INNER JOIN pubs AS p
	ON p.pub_id = r.pub_id
INNER JOIN sales AS s
	ON s.pub_id = p.pub_id
INNER JOIN beverages AS b
	ON b.beverage_id = s.beverage_id
WHERE b.category = 'Cocktail'
;

/* 7. What is the average price per unit for each category of beverages, excluding the category 'Spirit'?*/

SELECT
b.category AS Catagory_Beverages,
ROUND(AVG(b.price_per_unit),2) AS Avg_Price_Per_Unit
FROM beverages AS b
WHERE b.category <> 'Spirit'
GROUP BY
b.beverage_id
ORDER BY
Avg_Price_Per_Unit DESC
;

/* 8. Which pubs have a rating higher than the average rating of all pubs?*/
WITH CTE1 AS
(SELECT ratings.pub_id, 
ratings.rating AS Rating,
ROUND(AVG(ratings.rating) OVER(PARTITION BY ratings.pub_id),1) AS 'Avg_Rating'
FROM ratings
GROUP BY ratings.pub_id, ratings.rating)
SELECT  
CTE1.pub_id AS Pub_id,
pubs.pub_name AS Pub_Name,
CTE1.rating AS Rating,
CTE1.Avg_Rating
FROM CTE1
INNER JOIN pubs 
ON CTE1.pub_id = pubs.pub_id
WHERE rating > Avg_Rating
;

/*9. What is the running total of sales amount for each pub, ordered by the transaction date?*/
WITH CTE2 AS
(SELECT
s.transaction_date AS Transaction_Date,
s.pub_id AS Pub_Id,
s.sale_id AS Sale_Id,
p.pub_name AS Pub_Name,
(b.price_per_unit*s.quantity) AS Total_Sales_Amount
FROM sales AS s
	LEFT JOIN beverages AS b
		ON s.beverage_id = b.beverage_id
	LEFT JOIN pubs AS p
		ON s.pub_id = p.pub_id
GROUP BY
	1,2
ORDER BY 1)
SELECT
Transaction_Date,
Pub_Name,
Total_Sales_Amount,
SUM(CTE2.Total_Sales_Amount) OVER (ORDER BY Transaction_Date ASC ,Sale_Id ) AS 'Running Total'
FROM CTE2
;

/*10. For each country, what is the average price per unit of beverages in each category, 
and what is the overall average price per unit of beverages across all categories?*/

SELECT 
b.beverage_name AS Beverage_Name,
p.country AS Country, 
b.category AS Category,
ROUND(AVG(b.price_per_unit),2) AS Avg_Price,
ROUND(AVG(b.price_per_unit) OVER (PARTITION BY p.country),2) AS Overall_Avarage_Price_Per_Unit
FROM pubs AS p
	LEFT JOIN sales AS s
		ON s.pub_id = p.pub_id
	LEFT JOIN beverages AS b
		ON b.beverage_id = s.beverage_id
GROUP BY
	Country, Category, b.price_per_unit;
    
/* 11. For each pub, what is the percentage contribution of each category of beverages to the total sales amount, 
and what is the pub's overall sales amount?*/

WITH Total_Sales_By_Catagory AS
(SELECT
p.pub_id AS Pub_id,
p.pub_name AS Pub_Name,
b.category AS Catagory,
SUM(b.price_per_unit * s.quantity) AS Total_Sales_Amount
FROM pubs AS p
	LEFT JOIN sales AS s
		ON s.pub_id = p.pub_id
	LEFT JOIN beverages AS b
		ON b.beverage_id = s.beverage_id
GROUP BY 
Pub_id,Catagory
),
Total_Sales_Pub AS
(SELECT *, SUM(Total_Sales_Amount) OVER (PARTITION BY Pub_id) AS Total_Sales_By_Pub FROM Total_Sales_By_Catagory)
SELECT 
Pub_Name,
Catagory,
Total_Sales_Amount,
ROUND(((Total_Sales_Amount/Total_Sales_By_Pub)*100),2) AS Percentage_of_Contribution 
FROM Total_Sales_Pub;
