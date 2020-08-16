
-- Q1: What is the average number of films rented per day, and the average days between rentals for the top 5 renting customers?
WITH
t1 AS (
SELECT customer_id,
	COUNT(*) AS num_of_films_rented,
	DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS customer_rank
FROM rental
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5
),

t2 AS (
SELECT t1.customer_rank,
       t1.customer_id,
       CONCAT(first_name,' ',last_name) AS full_name,
       DATE_TRUNC('day',rental_date) AS day,
       COUNT(*) AS num_of_films_rented_per_day,
       CAST(DATE_TRUNC('day',rental_date) AS DATE) - CAST(LAG(DATE_TRUNC('day',rental_date)) OVER (PARTITION BY t1.customer_id ORDER BY DATE_TRUNC('day',rental_date)) AS DATE) AS days_between_rentals
FROM t1
JOIN rental r
ON t1.customer_id = r.customer_id
JOIN customer c
ON t1.customer_id = c.customer_id
GROUP BY 1,2,3,4
)

SELECT customer_rank,
       full_name,
       ROUND(AVG(num_of_films_rented_per_day)) AS avg_films_rented_per_day,
       ROUND(AVG(days_between_rentals)) AS avg_days_between_rentals
FROM t2
GROUP BY 1,2
ORDER BY 1


-- Q2: What is the most rented film category in (India, China, United States, Japan and Brazil) and how many times they were rented?
WITH
t1 AS (
SELECT co.country,
       ca.name AS category_name,
       COUNT(*) AS num_of_rentals
FROM customer cu
JOIN address ad
ON ad.address_id = cu.address_id
JOIN city ci
ON ci.city_id = ad.city_id
JOIN country co
ON co.country_id = ci.country_id
JOIN rental re
ON cu.customer_id = re.customer_id
JOIN inventory i
ON i.inventory_id = re.inventory_id
JOIN film_category fc
ON fc.film_id = i.film_id
JOIN category ca
ON ca.category_id = fc.category_id
GROUP BY 1,2
),

t2 AS (
Select country,
       MAX(num_of_rentals) AS max_num_of_rentals
FROM t1
WHERE country IN ('India','China','United States','Japan','Brazil')
GROUP BY 1
)

Select t2.country,
       t1.category_name,
       t1.num_of_rentals
FROM t1
JOIN t2
ON t1.country = t2.country
AND t1.num_of_rentals = t2.max_num_of_rentals
ORDER BY 3 DESC


-- Q3: What is the most and least profitable films in store 1, And how many times they were rented?
WITH
t1 AS (
SELECT title,
       SUM(amount) AS total_earnings,
       COUNT(*) AS num_of_rentals
FROM film f
JOIN inventory i
ON f.film_id = i.film_id
JOIN rental r
ON i.inventory_id = r.inventory_id
JOIN payment p
ON r.rental_id = p.rental_id
WHERE i.store_id = 1
GROUP BY 1
),

t2 AS (
SELECT MAX(total_earnings) AS max,
       MIN(total_earnings) AS min
FROM t1
)

SELECT title,
       total_earnings,
       num_of_rentals
FROM t1
JOIN t2
ON t1.total_earnings=t2.max
OR t1.total_earnings=t2.min


-- Q4: What is the most and least preferred film length by customers?
SELECT CASE
       WHEN length < 60 THEN 'less than 1 hour'
       WHEN length BETWEEN 60 AND 120 THEN '1 - 2 hours'
       WHEN length BETWEEN 121 AND 180 THEN '2 - 3 hours'
       ELSE 'more than 3 hours'
       END AS film_length,
       COUNT(*) AS num_of_rentals
FROM film f
JOIN inventory i
ON f.film_id = i.film_id
JOIN rental r
ON i.inventory_id = r.rental_id
GROUP BY 1
ORDER BY 2 DESC
