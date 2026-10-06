create DATABASE online_shop;
CREATE TABLE categories (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE customers (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL UNIQUE
);

CREATE TABLE products (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    price NUMERIC(12,2) NOT NULL CHECK (price >= 0),
    stock INT NOT NULL CHECK (stock >= 0),
    description TEXT,
    cat_id INT NOT NULL,
    FOREIGN KEY (cat_id) REFERENCES categories(id)
);

CREATE TABLE orders (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id INT NOT NULL,
    order_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    status VARCHAR(20) NOT NULL DEFAULT 'pending',

    FOREIGN KEY (customer_id)
        REFERENCES customers(id),CHECK(
        status IN (
            'pending',
            'paid',
            'shipped',
            'delivered',
            'canceled'
        )
    )
);


CREATE TABLE order_item (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(12,2)
        NOT NULL CHECK (unit_price >= 0),
    FOREIGN KEY (order_id)
        REFERENCES orders(id),
    FOREIGN KEY (product_id)
        REFERENCES products(id)
);


drop table order_item 

CREATE TABLE payments (
    payment_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    order_id INT NOT NULL,

    amount NUMERIC(12,2)
        NOT NULL CHECK (amount >= 0),

    payment_method VARCHAR(20) NOT NULL,

    payment_status VARCHAR(20)
        NOT NULL DEFAULT 'pending',

    payment_date TIMESTAMP
        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (order_id)
        REFERENCES orders(id),

    CHECK (
        payment_method IN (
            'card',
            'online',
            'cash'
        )
    ),

    CHECK (
        payment_status IN (
            'successful',
            'failed',
            'pending'
        )
    )
);




INSERT INTO categories (name)
SELECT
    'Category_' || i
FROM generate_series(1, 20) AS s(i);

INSERT INTO customers (name, phone)
SELECT
    'Customer_' as i,
    '09' || LPAD(i::text, 9, '0')
FROM generate_series(1, 20000) AS s(i);

INSERT INTO products (
    name,
    price,
    stock,
    description,
    cat_id
)
SELECT
    'Product_' || i,
    ROUND(
        CASE
       WHEN random() < 0.01
                THEN 5000 + random() * 45000
           ELSE
                50 + random() * 2000
        END
    ::numeric, 2),
    case WHEN random() < 0.01
            THEN floor(2000 + random() * 8000)::int
        ELSE
            floor(random() * 500)::int
    END,
    'Synthetic product description ' as i,
    floor(random() * 20 + 1)::int FROM generate_series(1, 1000) AS s(i);

INSERT INTO orders (
    customer_id,
    order_date,
    status
)
SELECT
    floor(
        pow(random(), 2) * 19000 + 1
    )::int,
    timestamp '2025-01-01'
    +
    random() *
    (
        timestamp '2026-09-24'
        - timestamp '2025-01-01'
    ),
    CASE
        WHEN random() < 0.05 THEN 'pending'
        WHEN random() < 0.15 THEN 'paid'
        WHEN random() < 0.10 THEN 'shipped'
        WHEN random() < 0.65 THEN 'delivered'
        ELSE 'canceled'
    END
FROM generate_series(1, 100000);

INSERT INTO order_item (
    order_id,
    product_id,
    quantity,
    unit_price
)
SELECT
    x.order_id,
    x.product_id,
    x.quantity,
    p.price
FROM (
    SELECT
        floor(random() * 100000 + 1)::int AS order_id,
        floor(random() * 950 + 1)::int AS product_id,
        floor(random() * 5 + 1)::int AS quantity
    FROM generate_series(1, 300000)
) x
JOIN products p
    ON p.id = x.product_id;


INSERT INTO payments (
    order_id,
    amount,
    payment_method,
    payment_status,
    payment_date
)
SELECT
    o.id AS order_id,
    COALESCE(
        SUM(oi.quantity * oi.unit_price),
        0
    )::numeric(12,2) AS amount,
    CASE
        WHEN random() < 0.45 THEN 'card'
        WHEN random() < 0.85 THEN 'online'
        ELSE 'cash'
    END AS payment_method,
    CASE
        WHEN o.status = 'canceled'
            THEN 'failed'
        WHEN random() < 0.05
            THEN 'pending'
        WHEN random() < 0.05
            THEN 'failed'
        ELSE 'successful'
    END AS payment_status,
    o.order_date
        + random() * interval '5 days'
FROM orders o
LEFT JOIN order_item oi
    ON oi.order_id = o.id
GROUP BY
    o.id,
    o.order_date,
    o.status;
  


--products analyze :
    select p.id,sum(oi.quantity*oi.unit_price) as pool,
    sum(quantity) as quantity,p.stock
    from products p join order_item oi on product_id=p.id
    group by p.id
    order by quantity desc
    
create index if not exists idx_orders_item_order_id on order_item(order_id);
create index if not exists idx_orders_item_order_id on orders(customer_id);
--costomers analyze :
    with a as(select c.id , sum(oi.quantity) as quantity , sum(p.amount) as pool, count(o.id) 
    as repeat_order
    from customers c 
    left join orders o on o.customer_id = c.id 
    left join order_item oi on oi.order_id =o.id 
    left  join payments p on p.order_id =o.id 
    where p.payment_status ='successful'
    group by c.id)
    select *,ntile(5)over(order by quantity) as rank_activity
    from a;

    select
	customers.id,count(orders.id) as a, case when
	count(orders.id)>1 then 'repeat' when count(orders.id)=1 then 'one time' else 'null' end 
	from customers left join orders on customer_id =customers.id
	group by id
	order by a desc;
	WITH category_purchase AS (
    	SELECT
        customers.id AS customer_id,
        categories.id AS category_name,
        SUM(order_item.quantity * order_item.unit_price) AS total_purchase
    	FROM order_item
   		JOIN orders
        ON order_item.order_id = orders.id
    	JOIN customers
        ON orders.customer_id = customers.id
    	JOIN products
        ON order_item.product_id = products.id
    	JOIN categories
        ON products.cat_id = categories.id
    	GROUP BY
        customers.id,
        categories.id),rank as (select customer_id
        as id,category_name as cat
        ,row_number()over(partition by customer_id order by 
        total_purchase desc) as m from category_purchase
        )
        select id ,cat as fav_cat
        from rank
        where m=1;
    with a as (select customers.id ,orders.order_date as date
			,lag(orders.order_date) over(partition by
			customer_id order by orders.order_date ) as lag
			,orders.order_date-lag(orders.order_date) 
			over(partition by customer_id order by orders.order_date ) as modat
			from orders join customers on customer_id =customers.id),
			n as(select id,avg(modat) as avg from a
			group by id)
			select customers.id as id , avg , case when avg 
			is null then 'one_time' when avg<= interval '30 day' 
			then 'frequent' when avg<=interval '180 day' 
			then 'normal' else 'in_frequent' end as cases
			from n join customers on n.id=customers.id
   
create index if not exists idx_products_cat_id on products(cat_id)

--category analyze :
	select sum(order_item.quantity * order_item.unit_price )
	as forosh, sum(quantity) as quantity 
	,categories.name from order_item join
	products on order_item.product_id =products.id 
	join categories on products.cat_id =categories.id
	group by categories.name
	order by quantity  desc;
	with product_list as(
	select product_id ,sum(unit_price*quantity)
	 as price  from order_item
	group by product_id 
	),
	row_num as (select max(product_list.price) as best_p,row_number()over(partition by
	cat_id order by max(product_list.price)desc) as rank_product,product_id ,cat_id 
	 from product_list
	join products on products.id=product_id 
	group by products.cat_id ,product_id 
	order by best_p desc)
	select * from row_num 
	where rank_product =1;
 
--time analyze :
	with secsussful_pay as(
	select * from payments
	where payment_status ='successful'
	),
	monthly_payment as(select date_trunc('month',payment_date)as date,
	sum(amount) as payment
	from secsussful_pay
	group by date),
	lag as(select date,payment, lag(payment) over(order by date) as lag
	from monthly_payment)
	select date,lag,payment ,((payment-lag)/nullif(lag,0))*100 mizan_roshd from lag;

--payment analyze :
	WITH num AS (
	    SELECT
	        payment_status,
	        COUNT(*) AS payment_count
	    FROM payments
	    GROUP BY payment_status
	)
	SELECT
	    payment_status,
	    payment_count,
	    ROUND(
	        payment_count * 100.0 /
	        SUM(payment_count) OVER (),
	        2
	    ) AS percentage
	FROM num;
	with most_method as(
	select payment_method as ravesh,
	count(payment_id) as tedad  from payments 
	group by payment_method )
	select ravesh,tedad,tedad*100/sum(tedad) 
	over() as darsad_estefadeh from most_method; 
	with most_method_success as(
	select payment_method as ravesh, count(payment_id)
	as tedad  from payments
	where payment_status ='successful'
	group by payment_method )
	select ravesh,tedad,round(tedad*100/sum(tedad)over(),3)
	as darsad_movafaghiat from most_method_success ; 
	with b as(
	select payment_method as ravesh, count(payment_id) as tedad from payments 
	group by payment_method)
	,a as(
	select payment_method as ravesh, count(payment_id)as tedad from payments
	where payment_status ='successful'
	group by payment_method)
	select b.ravesh , b.tedad , a.tedad*100.0/b.tedad as
	success_rate from b left join a on a.ravesh = b.ravesh; 



--orders analyze :
WITH near_order AS (
    SELECT
        customer_id,
        id AS order_id,
        order_date,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY order_date DESC
        ) AS rn
    FROM orders
),
latest_order AS (
    SELECT
        customer_id,
        oi.order_id,
        order_date,
        SUM(oi.quantity * oi.unit_price) AS order_value
    FROM near_order
    JOIN order_item oi
        ON oi.order_id = near_order.order_id
    WHERE rn = 1
    GROUP BY
        customer_id,
        oi.order_id,
        order_date
)
SELECT
    customer_id,
    order_id,
    order_date,
    order_value,
    NTILE(5) OVER (
        ORDER BY order_value
    ) AS rank_order
FROM latest_order
ORDER BY rank_order DESC;
	


--segment analyze :
explain analyze WITH valid_orders AS (
    SELECT
        id AS order_id,
        customer_id,
        order_date
    FROM orders
    WHERE status IN ('paid', 'shipped', 'delivered')
),
rfm_base AS (
    SELECT
        vo.customer_id,
        MAX(vo.order_date) AS last_order_date,
        COUNT(DISTINCT vo.order_id) AS frequency,
        SUM(oi.quantity * oi.unit_price) AS monetary
    FROM valid_orders vo
    JOIN order_item oi
        ON oi.order_id = vo.order_id
    GROUP BY vo.customer_id
),
rfm AS (
    SELECT
        customer_id,
        last_order_date,
        DATE '2026-09-24' - last_order_date::date
            AS recency,
        frequency,
        monetary,
        NTILE(5) OVER (
            ORDER BY last_order_date DESC
        ) AS recency_score,
        NTILE(5) OVER (
            ORDER BY frequency
        ) AS frequency_score,
        NTILE(5) OVER (
            ORDER BY monetary
        ) AS monetary_score
    FROM rfm_base
),
customer_segment AS (
    SELECT
        *,
        CASE
            WHEN monetary_score >= 4
             AND frequency_score >= 4
             AND recency_score >= 4
                THEN 'high valuable and active'
            WHEN monetary_score >= 4
                THEN 'high valuable'
            WHEN frequency_score >= 4
             AND recency_score >= 4
                THEN 'active'
            ELSE 'unvaluable'
        END AS segment_state
    FROM rfm
)
SELECT
    segment_state,
    COUNT(*) AS customer_count,
    SUM(monetary) AS total_revenue,
    ROUND(AVG(monetary), 2) AS avg_customer_value,
    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS percentage_of_customers,
    ROUND(
        SUM(monetary) * 100.0 /
        SUM(SUM(monetary)) OVER (),
        2
    ) AS percentage_of_revenue
FROM customer_segment
GROUP BY segment_state
ORDER BY total_revenue DESC;









-- prrrroooooooooooooooooggggggggggeeeeeeeeeeeeeee
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

