SELECT*FROM CUSTOMERS;
SELECT*FROM ORDERS;
SELECT*FROM RESTAURANTS;
SELECT*FROM DELIVERIES;
SELECT*FROM RIDERS;

select * from customers
where 
	customer_id is null
	or customer_name is null 
	or reg_date is null;

select * from orders
where 
	order_id is null
	or customer_id is null 
	or order_item is null
	or order_date is null
	or order_time is null 
	or order_status is null
	or total_amount is null;

select * from restaurants
where 
	restaurant_name is null
	or city is null 
	or opening_hours is null;

select count (*) from deliveries
where 
	delivery_status is null
	or delivery_time is null 
	or rider_id is null;


								---- Answer to key business questions 

-- Q1. Write a query to find the top 5 most frequently ordered dishes by the customer "Arjun Mehta" in the last 1 year.

Select
Customer_name,
Dishes,
total_orders
From
	(select
		c.customer_id,
		c.customer_name,
		o.order_item AS dishes,
		count (*) as total_orders,
		dense_rank () over(order by count(*) desc) as rank
	from orders as o 
	join customers as c
	on o.customer_id = c.customer_id
	where 
	extract (year from o.order_date) = '2023'
	and c.customer_name = 'Arjun Mehta'
	Group by 1, 2, 3 
	order by 1, 4 desc) as t1
where
rank <=5

--- Q2.Identify the time slots during which the most orders are placed, based on 2-hour intervals.

--Approach - 1
Select 
	case 
		 when extract (hour from order_time) between 0 and 1 then '00:00 to 02:00'
		 when extract (hour from order_time) between 2 and 3 then '02:00 to 04:00'
		 when extract (hour from order_time) between 4 and 5 then '04:00 to 06:00'		
		 when extract (hour from order_time) between 6 and 7 then '06:00 to 08:00'
		 when extract (hour from order_time) between 8 and 9 then '08:00 to 10:00'
		 when extract (hour from order_time) between 10 and 11 then '10:00 to 12:00'
		 when extract (hour from order_time) between 12 and 13 then '12:00 to 14:00'
		 when extract (hour from order_time) between 14 and 15 then '14:00 to 16:00'
		 when extract (hour from order_time) between 16 and 17 then '16:00 to 18:00'		
		 when extract (hour from order_time) between 18 and 19 then '18:00 to 20:00'
		 when extract (hour from order_time) between 20 and 21 then '20:00 to 22:00'
		 when extract (hour from order_time) between 22 and 23 then '22:00 to 00:00'
		 else 'undefined'
		 end as time_slots,
		 count(order_id) as total_orders
from orders
Group by time_slots 
Order by total_orders desc
limit 5;

--Approach - 2

Select 
 Floor(extract(hour from order_time)/2)*2 as start_time,
 Floor(extract(hour from order_time)/2)*2 + 2 as end_time,
 count(order_id) as total_orders
from orders 
Group by 1,2
Order by 3 desc
limit 5;

---- Q3. Find the average order value (AOV) per customer who has placed more than 750 orders.
select* from orders

Select 
Customer_name,
Number_of_orders,
Avg_Order_Value
From
	(Select 
	c.customer_name,
	o.customer_id,
	avg(total_amount) as Avg_Order_Value,
	count(c.customer_name) as Number_of_orders
	from customers c
	join orders o
	on c.customer_id = o.customer_id
	Group by 1,2
	Order by 3 desc) as t1
where 
Number_of_orders > 750;

-----Q4. List the customers who have spent more than 100K in total on food orders.
	
Select 
	c.customer_name,
	SUM(total_amount) as Total_Order_Value
	from customers c
	join orders o
	on c.customer_id = o.customer_id
	Group by 1 
	Having SUM(total_amount) > 100000
	order by 2 desc;

--- Q5. Write a query to find orders that were placed but not delivered.
---Approach-1
Select 
	r.restaurant_name,
	r.city,
	count(o.order_id) as orders_not_delivered
from Orders as O
left join restaurants as r 
on r.restaurant_id = o.restaurant_id
left join deliveries as d
on d.order_id = o.order_id
where d.delivery_id is null
Group by 1,2
Order by 3 desc;

--- Approach - 2
Select
	r.restaurant_name,
	r.city,
	count(o.order_id) as orders_not_delivered
from Orders as O
left join restaurants as r 
on r.restaurant_id = o.restaurant_id
where 
order_id not in (select order_id from deliveries)
Group by 1,2
Order by 3 desc;

-- Q6. Rank restaurants by their total revenue from the last year.
---Return: restaurant_name, total_revenue, and their rank within their city.

Select*
from
(Select 
	r.city, 
	r.restaurant_name,
	sum(o.total_amount) as revenue,
	rank() over(partition by r.city order by sum(o.total_amount) desc ) as rank
	from orders o
	join restaurants r 
	on r.restaurant_id = o.restaurant_id
	Group by 1,2)
where
rank = 1

----Q.7 Identify the most popular dish in each city based on the number of orders.

Select *
From 
	(Select 
	r.city, 
	o.order_item,
	count(o.order_id) as numberz_of_orders,
	rank() over (partition by r.city order by count(o.order_id)desc) as rank 
	from orders o
	join restaurants r
	on r.restaurant_id = o.restaurant_id
	group by 1,2)
where
rank = 1
or rank = 2;

--- Q8. Find customers who haven’t placed an order in 2024 but did in 2023.

Select
c.customer_name,
t.customer_id
from customers c
join
		(Select
		distinct customer_id
		from orders
		where 
		extract (year from order_date) = 2023
		and customer_id not in (
								Select
								distinct customer_id
								from orders
								where 
								extract (year from order_date) = 2024
								))as t
on c.customer_id = t.customer_ID


--- Q9. Calculate and compare the order cancellation rate for each restaurant between the current year and the previous year.

Select
b.restaurant_name,
a. cancellation_ratio_2023,
a. cancellation_ratio_2024
From (
	Select
	l.restaurant_id,
	l. cancellation_ratio_2023,
	c. cancellation_ratio_2024
	from (	
		Select 
		restaurant_id,
		Round((not_delivered :: numeric /total_orders :: numeric)*100,2) as cancellation_ratio_2023
		From(
			SELECT
				o. restaurant_id,
				count (o.order_id) as total_orders, 
				count (case when d.delivery_id is null then 1 end) as not_delivered
				from orders o
				left join deliveries d 
				on d.order_id = o.order_id
				where 
				extract (year from o.order_date) = '2023'
				Group by 1)
		Group by 1,2) as l
	join (
		Select 
		restaurant_id,
		Round((not_delivered :: numeric /total_orders :: numeric)*100,2) as cancellation_ratio_2024
		From(
			SELECT
				o. restaurant_id,
				count (o.order_id) as total_orders, 
				count (case when d.delivery_id is null then 1 end) as not_delivered
				from orders o
				left join deliveries d 
				on d.order_id = o.order_id
				where 
				extract (year from o.order_date) = '2024'
				Group by 1)
		Group by 1,2) as c
	on c.restaurant_id = l.restaurant_id
	Group by 1, 2, 3
) as a
join restaurants b 
on b.restaurant_id = a.restaurant_id
Group by 1,2,3
Order by 2 desc

---Q10. Determine each rider's average delivery time.
Select 
r.rider_name,
t. time_per_order
from riders r
Join 
	(select 
	d.rider_id,
	round(extract(epoch from (o.order_time - d.delivery_time + case when d.delivery_time < o.order_time then interval '1 day' else interval '0 day' end))/60, 2) as time_per_order
	from orders o 
	join deliveries d
	on o.order_id = d.order_id
	where d.delivery_status = 'Delivered'
	Order by 2 asc) as t
on r.rider_id = t.rider_id

--- Q11. Calculate each restaurant's growth ratio based on the total number of delivered orders since its joining.

	Select 
	r.restaurant_name,
	m.month,
	Round((m.this_month_orders :: numeric - m. last_month_orders :: numeric) / last_month_orders * 100, 2) as Gowth_rate
	From restaurants r
	Join
		(select
		o.restaurant_id,
		to_char(o.order_date, 'mm-yy') as month,
		count(o.order_id) as this_month_orders,
		lag(count(o.order_id),1) over (partition by o.restaurant_id order by to_char(o.order_date, 'mm-yy')  ) as last_month_orders
		from orders o
		join deliveries d
		on d.order_id = o.order_id 
		where 
		d.delivery_status = 'Delivered'
		Group by 1,2
		Order by 1,2) as m
	on r. restaurant_id = m.restaurant_id

--- Q12. Segment customers into 'Gold' or 'Silver' groups based on their total spending compared to the average order value (AOV).
---If a customer's total spending exceeds the AOV, label them as
---'Gold'; otherwise, label them as 'Silver'.
---Return: The total number of orders and total revenue for each segment.


Select 
Segment, 
sum (total_orders) as Order_count,
sum(total_spending) as Revenue
from
	(select
	customer_id,
	sum(total_amount) as total_spending,
	count(order_id) as total_orders,
	Case when (sum(total_amount)) > (select avg (total_amount) from orders) then 'Gold' else 'Silver' end as Segment 
	from orders
	where order_status = 'Completed'
	Group by 1)
Group by 1

-----Q13. Calculate each rider's total monthly earnings, assuming they earn 8% of the order amount.
Select 
r. rider_name,
e.month,
e.rider_earning
from riders r
Join 
	(Select
	d.rider_id,
	to_char(o.order_date, 'mm-yy') as month,
	Round(sum(o.total_amount :: numeric) * 0.08,2) as Rider_earning
	from orders o
	join deliveries d
	on d.order_id = o.order_id
	Group by 1,2
	order by 1, 2) as e
on r.rider_id = e.rider_id

---Q.14 Rider Ratings Analysis
---Find the number of 5-star, 4-star, and 3-star ratings each rider has.
--Riders receive ratings based on delivery time:
--● 5-star: Delivered in less than 15 minutes
--● 4-star: Delivered between 15 and 20 minutes
--● 3-star: Delivered after 20 minutes

Select 
r1.rider_id,
r.rider_name,
case when r1.duration<15 then '5-star' when r1.duration between 15 and 20 then '4-star' else '3-star' end as Rider_rating
From riders r
join 
	(Select
	o.order_id,
	d.rider_id,
	o.order_time,
	d.delivery_time,
	Round(Extract(epoch from (d.delivery_time -o.order_time + case when d.delivery_time<o.order_time then interval '1 day' else interval '0 day' end)) / 60,2) as duration
	from orders o
	join deliveries d
	on d.order_id = o.order_id
	where d.delivery_status = 'Delivered'
	group by 1,2,3,4) as r1
 on r.rider_id = r1.rider_id


---star count by rider
Select 
rider_id,
rider_name,
rider_rating,
Count(rider_rating)
from (
		Select 
	r1.rider_id,
	r.rider_name,
	case when r1.duration<15 then '5-star' when r1.duration between 15 and 20 then '4-star' else '3-star' end as Rider_rating
	From riders r
	join 
			(Select
			o.order_id,
			d.rider_id,
			o.order_time,
			d.delivery_time,
			Round(Extract(epoch from (d.delivery_time -o.order_time + case when d.delivery_time<o.order_time then interval '1 day' else interval '0 day' end)) / 60,2) as duration
			from orders o
			join deliveries d
			on d.order_id = o.order_id
			where d.delivery_status = 'Delivered'
			group by 1,2,3,4) as r1
 on r.rider_id = r1.rider_id
)
Group by 1,2,3
Order by 3 desc

---Q15. Analyze order frequency per day of the week and identify the peak day for each restaurant.
Select 
Restaurant_name,
Days as peak_day
From
	(Select
	r.restaurant_name,
	to_char(o.order_date, 'day') as Days,
	count(o.order_id) as order_frequency,
	Rank() over (partition by r.restaurant_name order by count(o.order_id)desc )
	from orders o
	join restaurants r
	on o.restaurant_id = r.restaurant_id
	group by 1,2
	Order by 1, 3 desc)
where rank = 1

-- Q16. Customer Lifetime Value (CLV)
----Calculate the total revenue generated by each customer over all their orders.
Select 
c.customer_name,
sum (o.total_amount) as CLV
From orders o
join customers c
on c.customer_id = o.customer_id
group by 1
order by 2 desc

---Q17. Identify sales trends by comparing each month's total sales to the previous month.
Select 
year,
month,
Round((current_month_sales ::numeric - last_month_sales :: numeric)/last_month_sales :: numeric *100,2) as Sales_trend
From
	(select
	Extract(year from order_date) as Year,
	extract (month from order_date) as Month,
	sum(total_amount) as last_month_sales,
	lag (sum(total_amount),1) over( partition by Extract(year from order_date) order by extract (month from order_date)) as current_month_sales
	from orders
	Group by 1,2)

---Q.18 Evaluate rider efficiency by determining average delivery times and identifying those with the lowest and highest averages.

Select 
t.rider_id,
r.rider_name,
Round(avg(t.riders_time),2) as Average_time_taken
From riders r
Join
	(Select
	d.rider_id,
	Round(Extract(Epoch from (d.delivery_time - o.order_time + case when d.delivery_time<o.order_time then interval '1 day' else interval '0 day' end))/60,2) as riders_time
	from orders o
	join deliveries d 
	on o.order_id = d.order_id
	where d.delivery_status = 'Delivered'
	Group by 1,2
	order by 2) as t
on r.rider_id = t.rider_id
Group by 1,2
Order by 3 asc

----Q19. Track the popularity of specific order items over time and identify seasonal demand spikes.

Select 
Seasons,
Order_item,
count(order_id) as number_of_orders
from (
	Select
	*,
	extract (month from order_date) as months,
	Case 
		when extract (month from order_date) between 6 and 9 then 'Summer' else 'winter' end as Seasons
	from orders)
Group by 1,2
Order by 2

----Q20. Rank each city based on the total revenue for the last year (2023).

 
select 
	r.city,
	sum (o.total_amount) as revenue,
	rank() over (order by sum (o.total_amount) desc ) as rank
from orders o
join restaurants r
on o.restaurant_id = r.restaurant_id
Group by 1
