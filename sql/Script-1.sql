create DATABASE online_retail;

delete from project
where "UnitPrice"<0;

delete from project
where "Quantity" <0;

--time analyze :
	with secsussful_pay as(
	select * from project p 
	where p.order_state  = 0
	),
	monthly_payment as(select date_trunc('month',"InvoiceDate" )as date,
	sum(mount) as payment
	from secsussful_pay
	group by date),
	lag as(select date,payment, lag(payment) over(order by date) as lag
	from monthly_payment)
	select date,lag,payment ,((payment-lag)/lag)*100 mizan_roshd from lag;
--favurit product for month
	WITH product_sales AS (
    SELECT
    date_trunc('month',"InvoiceDate" )as date,
    "StockCode" ,
    SUM("Quantity") AS total_quantity
    FROM project p 
    WHERE p.order_state  = 0
    GROUP BY "date", "StockCode"
	),
	ranked AS (
    SELECT
    "date",
    "StockCode",
    total_quantity,
    ROW_NUMBER() OVER (
    PARTITION BY "date"
    ORDER BY total_quantity DESC
    ) AS rn
    FROM product_sales
	)
	SELECT
    "date",
    "StockCode",
    total_quantity
	FROM ranked
	WHERE rn = 1
	ORDER BY "date";
		
--orders analyze
	select sum(mount) as summ,count(p."InvoiceNo" ),ntile(5)
	over(order by sum(mount)) as ntil  from project p
	group by p."InvoiceNo" 
	order by ntil  desc;

--customers analyze :
	select p."CustomerID" , sum(mount) pool,count(p."InvoiceNo")
	order_item_count,sum(p."Quantity") activity
	,sum(order_state)/count(p."InvoiceNo")*100 canseled_payment 
	,ntile(3)over(order by sum(mount)) n_pool,
	ntile(3)over(order by count(p."InvoiceNo")) n_order,
	ntile(3)over(order by sum(p."Quantity")) n_poritem
	from project p 
	group by p."CustomerID";
--favurit product for customers
	WITH product_sales AS (
    SELECT
    "CustomerID",
    "StockCode",
    SUM("Quantity") AS total_quantity
    FROM project p 
    WHERE p.order_state  = 0
    GROUP BY "CustomerID", "StockCode"
	),
	ranked AS (
    SELECT
    "CustomerID",
    "StockCode",
    total_quantity,
    ROW_NUMBER() OVER (
    PARTITION BY "CustomerID"
    ORDER BY total_quantity DESC
    ) AS rn
    FROM product_sales
	)
	SELECT
    "CustomerID",
    "StockCode",
    total_quantity
	FROM ranked
	WHERE rn = 1
	ORDER BY "CustomerID";
--favurit month for customers
	WITH product_sales AS (
    SELECT
    "CustomerID",
    date_trunc('month',"InvoiceDate" )as date,
    SUM("Quantity") AS total_quantity
    FROM project p 
    WHERE p.order_state  = 0
    GROUP BY "CustomerID", "date"
	),
	ranked AS (
    SELECT
    "CustomerID",
    "date",
    total_quantity,
    ROW_NUMBER() OVER (
    PARTITION BY "CustomerID"
    ORDER BY total_quantity DESC
    ) AS rn
    FROM product_sales
	)
	SELECT
    "CustomerID",
    "date",
    total_quantity
	FROM ranked
	WHERE rn = 1
	ORDER BY "CustomerID";


--product analyze : 
	select p."StockCode" id , sum(mount) pool,sum(p."Quantity")*
	count(p."InvoiceNo") count_ordering
	,ntile(3)over(order by sum(mount)) n_pool,
	ntile(3)over(order by sum(p."Quantity")) n_order
	from project p 
	group by p."StockCode";
--favurit product for country
	WITH product_sales AS (
    SELECT
    "Country",
    "StockCode",
    SUM("Quantity") AS total_quantity
    FROM project p 
    WHERE p.order_state  = 0
    GROUP BY "Country", "StockCode"
	),
	ranked AS (
    SELECT
    "Country",
    "StockCode",
    total_quantity,
    ROW_NUMBER() OVER (
    PARTITION BY "Country"
    ORDER BY total_quantity DESC
    ) AS rn
    FROM product_sales
	)
	SELECT
    "Country",
    "StockCode",
    total_quantity
	FROM ranked
	WHERE rn = 1
	ORDER BY "Country";




select p."CustomerID"  from project p 

