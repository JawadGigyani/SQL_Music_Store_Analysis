-- Question 1: Who is the senior most employee based on job title?
SELECT *
FROM employee
ORDER BY levels DESC
LIMIT 1


-- Qesution 2: Which countries have the most Invoices?
SELECT billing_country, COUNT(*) AS invoices
FROM invoice
GROUP BY billing_country
ORDER BY invoices DESC


-- Question 3: What are top 3 values of total invoice?
SELECT total
FROM invoice
ORDER BY total DESC
LIMIT 3


-- Question 4: Which city has the best customers? We would like to throw a promotional Music Festival
-- 			in the city we made the most money. Write a query that returns one city that has the
-- 			highest sum of invoice totals. Return both the city name & sum of all invoice totals.
SELECT billing_city, SUM(total) AS invoice_total
FROM invoice
GROUP BY billing_city
ORDER BY invoice_total DESC


-- Question 5: Who is the best customer? The customer who has spent the most money will be declared
-- 		the best customer. Write a query that returns the person who has spent the most money
SELECT 
	customer.customer_id,
	customer.first_name || ' ' || customer.last_name AS name, 
	SUM(invoice.total) AS total
FROM 
	customer
INNER JOIN
	invoice USING(customer_id)
GROUP BY 
	customer_id
ORDER BY 
	total DESC
LIMIT 1


-- Question 6:  Write query to return the email, first name, last name, & Genre of all Rock Music 
-- 		listeners. Return your list ordered alphabetically by email starting with A.
SELECT DISTINCT
    customer.email,
    customer.first_name,
    customer.last_name
FROM
    customer
INNER JOIN
    invoice USING (customer_id)
INNER JOIN
    invoice_line USING (invoice_id)
WHERE
    track_id IN (
        SELECT track_id
        FROM track
        INNER JOIN genre USING (genre_id)
        WHERE genre.name = 'Rock'
    )
ORDER BY
    customer.email;


-- Question 7: Let's invite the artists who have written the most rock music in our dataset. Write a 
-- 		query that returns the Artist name and total track count of the top 10 rock bands.
SELECT
    artist.artist_id,
    artist.name,
    COUNT(artist.artist_id) AS num_of_songs
FROM
    track
INNER JOIN
    album USING (album_id)
INNER JOIN
    artist USING (artist_id)
INNER JOIN
    genre USING (genre_id)
WHERE
    genre.name LIKE 'Rock'
GROUP BY
    artist.artist_id
ORDER BY
    num_of_songs DESC
LIMIT 10;


-- Question 8: Return all the track names that have a song length longer than the average song length. 
-- 		Return the Name and Milliseconds for each track. Order by the song length with the 
-- 		longest songs listed first
SELECT
    name,
    milliseconds
FROM
    track
WHERE
    milliseconds > (
        SELECT AVG(milliseconds) AS avg_track_length
        FROM track
    )
ORDER BY
    milliseconds DESC;


-- Question 9: Find how much amount spent by each customer on artists? Write a query to return
-- 		customer name, artist name and total spent.
WITH best_selling_artist AS (
    SELECT
        artist.artist_id AS artist_id,
        artist.name AS artist_name,
        SUM(invoice_line.unit_price * invoice_line.quantity) AS total_sales
    FROM
        invoice_line
    INNER JOIN
        track USING(track_id)
    INNER JOIN
        album USING(album_id)
    INNER JOIN
        artist USING(artist_id)
    GROUP BY
        1
    ORDER BY
        3 DESC
    LIMIT 1
)

SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    bsa.artist_name,
    SUM(il.unit_price * il.quantity) AS amount_spent
FROM
    invoice i
INNER JOIN
    customer c USING(customer_id)
INNER JOIN
    invoice_line il USING(invoice_id)
INNER JOIN
    track t USING(track_id)
INNER JOIN
    album alb USING(album_id)
INNER JOIN
    best_selling_artist bsa USING(artist_id)
GROUP BY
    1, 2, 3, 4
ORDER BY
    5 DESC;


-- Question 10: We want to find out the most popular music Genre for each country. We determine the 
-- 		most popular genre as the genre with the highest amount of purchases. Write a query 
-- 		that returns each country along with the top Genre. For countries where the maximum 
-- 		number of purchases is shared return all Genres.
WITH popular_genre AS (
    SELECT
        COUNT(invoice_line.quantity) AS purchases,
        customer.country,
        genre.name,
        genre.genre_id,
        ROW_NUMBER() OVER (PARTITION BY customer.country ORDER BY COUNT(invoice_line.quantity) DESC) AS RowNo
    FROM
        invoice_line
    INNER JOIN
        invoice USING (invoice_id)
    INNER JOIN
        customer USING (customer_id)
    INNER JOIN
        track USING (track_id)
    INNER JOIN
        genre USING (genre_id)
    GROUP BY
        2, 3, 4
    ORDER BY
        2 ASC, 1 DESC
)
SELECT *
FROM
    popular_genre
WHERE
    RowNo <= 1;

-- Method 2 --
WITH RECURSIVE sales_per_country AS (
    SELECT
        COUNT(*) AS purchases_per_genre,
        customer.country,
        genre.name,
        genre.genre_id
    FROM
        invoice_line
    INNER JOIN
        invoice USING (invoice_id)
    INNER JOIN
        customer USING (customer_id)
    INNER JOIN
        track USING (track_id)
    INNER JOIN
        genre USING (genre_id)
    GROUP BY
        2, 3, 4
    ORDER BY
        2
),
max_genre_per_country AS (
    SELECT
        MAX(purchases_per_genre) AS max_genre_number,
        country
    FROM
        sales_per_country
    GROUP BY
        2
    ORDER BY
        2
)

SELECT
    sales_per_country.*
FROM
    sales_per_country
INNER JOIN
    max_genre_per_country USING (country)
WHERE
    sales_per_country.purchases_per_genre = max_genre_per_country.max_genre_number;


-- Question 11: Write a query that determines the customer that has spent the most on music for each 
-- 		country. Write a query that returns the country along with the top customer and how
-- 		much they spent. For countries where the top amount spent is shared, provide all 
-- 		customers who spent this amount
WITH RECURSIVE customer_with_country AS (
    SELECT
        customer.customer_id,
        first_name,
        last_name,
        billing_country,
        SUM(total) AS total_spending
    FROM
        invoice
    INNER JOIN
        customer USING (customer_id)
    GROUP BY
        1, 2, 3, 4
    ORDER BY
        1, 5 DESC
),
country_max_spending AS (
    SELECT
        billing_country,
        MAX(total_spending) AS max_spending
    FROM
        customer_with_country
    GROUP BY
        billing_country
)

SELECT
    cc.billing_country,
    cc.total_spending,
    cc.first_name,
    cc.last_name
FROM
    customer_with_country cc
INNER JOIN
    country_max_spending ms USING (billing_country)
WHERE
    cc.total_spending = ms.max_spending
ORDER BY
    1;

-- Method 2 --
WITH customer_with_country AS (
    SELECT
        customer.customer_id,
        first_name,
        last_name,
        billing_country,
        SUM(total) AS total_spending,
        ROW_NUMBER() OVER (PARTITION BY billing_country ORDER BY SUM(total) DESC) AS RowNo
    FROM
        invoice
    INNER JOIN
        customer USING (customer_id)
    GROUP BY
        1, 2, 3, 4
    ORDER BY
        4 ASC, 5 DESC
)

SELECT *
FROM customer_with_country
WHERE RowNo <= 1;
