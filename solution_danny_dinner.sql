/*What is the total amount each customer spent at the restaurant?*/
SELECT customer_id, sum(price) as total_amount from sales as sales_table left join menu as menu_table 
on sales_table.product_id = menu_table.product_id group by customer_id;

/*How many days has each customer visited the restaurant?*/
SELECT customer_id, COUNT(DISTINCT order_date) as Count	from sales
group by customer_id;

/*What was the first item from the menu purchased by each customer?*/
SELECT customer_id, product_name 
from (
	SELECT sales.customer_id, menu.product_name, sales.product_id, sales.order_date, 
	row_number() over(PARTITION BY customer_id order by order_date) as rn
	from sales join menu on sales.product_id = menu.product_id) as table1
where rn = 1;

/*What is the most purchased item on the menu and how many times was it purchased by all customers?*/
SELECT menu.product_name, count(sales.product_id) as count 
from sales join menu on sales.product_id = menu.product_id
GROUP BY 1
order by count desc
limit 1;

/*Which item was the most popular for each customer?*/
with cte as (
select  customer_id, product_name, count, max(count) over(partition by customer_id) as max_count 
from(
	select distinct sales.customer_id, sales.product_id, menu.product_name, count(sales.product_id) 
	over(partition by customer_id, sales.product_id order by customer_id) as count 
	from sales join menu on sales.product_id = menu.product_id
	order by customer_id, count desc) x)
select customer_id, product_name, count from cte where count = max_count;

/*Which item was purchased first by the customer after they became a member?*/
with cte as (SELECT sales.customer_id, product_id, order_date, 
row_number() over(partition by sales.customer_id order by order_date) as rn
from sales join members on sales.customer_id = members.customer_id
where order_date>= members.join_date)

select cte.customer_id, cte.product_id, product_name, order_date 
from cte join menu on cte.product_id=menu.product_id where rn = 1
order by customer_id;

/*Which item was purchased just before the customer became a member?*/
with cte as(
select sales.customer_id, product_id, order_date, join_date
from sales join members on sales.customer_id = members.customer_id
where order_date<join_date)
select cte.customer_id, cte.product_id, product_name, order_date,join_date
from cte
join menu m on cte.product_id=m.product_id
order by cte.customer_id;

/*What is the total items and amount spent for each member before they became a member?*/
select distinct sales.customer_id,
	count(sales.product_id) over(partition by sales.customer_id) as total_items,
	sum(price) over(partition by sales.customer_id) as total_amt
from sales
join members on sales.customer_id=members.customer_id
join menu on sales.product_id=menu.product_id
where order_date<join_date;

/*If each $1 spent equates to 10 points and sushi has a 2x points multiplier - 
how many points would each customer have*/
with cte as(
SELECT sales.customer_id, sales.product_id, product_name, price,
case when product_name = 'sushi' then price*20
     when product_name != 'sushi' then price*10
     end as points from sales
join menu on sales.product_id=menu.product_id)

select distinct customer_id, sum(points) over(partition by customer_id) as total_points
from cte;

/*In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - 
how many points do customer A and B have at the end of January*/
select distinct customer_id, sum(points) over(partition by customer_id) total_point
from(
select sales.customer_id as customer_id, order_date, price,
CASE when day(order_date) <=7 then price*20
     when day(order_date) > 7 then price*10
     end as points from sales
join members on sales.customer_id=members.customer_id
join menu on sales.product_id=menu.product_id
where order_date>= join_date and month(order_date)=1) x

