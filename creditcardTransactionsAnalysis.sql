

--Exploring the dataset
select * from credit_card_transcations;
select min(transaction_date),max(transaction_date)from credit_card_transcations --Dataset Date Range b/w 2013-10-04 to 2015-05-26 
select distinct card_type from credit_card_transcations  --Silver ,Signatur,Gold,Platinum
select distinct city from credit_card_transcations --986 Total cities
select distinct exp_type from credit_card_transcations -- Entertainment,Food,Bills,Fuel,Travel,Grocery

--1- write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends 
WITH cte AS(
select sum(cast (amount as BIGINT))as total_amount from credit_card_transcations
),cte2 as(
select city,sum(amount)as spend,DENSE_RANK() over(order by sum(amount) desc) as rnk
from
credit_card_transcations
group by city
),cte3 as(
select * from cte2 where rnk <=5
)
select city,spend,round((1.0*spend/total_amount)*100,2)as percentage_contribution
from cte3,cte


--2- write a query to print highest spend month and amount spent in that month for each card type
select * from credit_card_transcations;
with cte as(
select year(transaction_date) as yr,MONTH(transaction_date) as mth,card_type ,sum(amount) as total_spend,DENSE_RANK()over(partition by card_type order by sum(amount) desc)  as rnk
from credit_card_transcations
group by year(transaction_date), MONTH(transaction_date),card_type

)
select yr,mth,card_type,total_spend from cte where rnk=1


--3- write a query to print the transaction details(all columns from the table) for each card type when
--it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)

select * from credit_card_transcations;

with cte as(
select *,sum(amount) over(partition by card_type order by transaction_date,transaction_id)as cummlative_sum
from
credit_card_transcations
),
cte2 as(
select * ,rank()over(partition by card_type order by cummlative_sum ) as rnk from cte where cummlative_sum>=1000000
)
select * from cte2 where rnk=1



--4- write a query to find city which had lowest percentage spend for gold card type

select * from credit_card_transcations;

with cte as(
select city,card_type,sum(amount)as amount
,sum(case when card_type='Gold' then amount end)as gold_amount
from credit_card_transcations
group by city,card_type
)
select top 1 city,1.0*sum(gold_amount)/sum(amount)*100 as gold_amount_perc
from cte
group by city
having sum(gold_amount) is not null
order by gold_amount_perc 


--5- write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)
select * from credit_card_transcations;

with cte as(
select city,exp_type,sum(amount) as expense_amount,
DENSE_RANK()over(partition by city order by sum(amount) desc) as rnk_desc,
DENSE_RANK()over(partition by city order by sum(amount) ) as rnk_asc
--,FIRST_VALUE(exp_type)over(partition by city order by sum(amount) desc)as highest_expense_type
--,LAST_VALUE(exp_type)over(partition by city order by sum(amount) )as lowest_expense_type
from credit_card_transcations
group by city,exp_type 
)
select city ,
max(case when rnk_asc=1 then exp_type end) lowest_expense_type,
min(case when rnk_desc=1 then exp_type end) highest_expense_type
from cte
group by city




--6- write a query to find percentage contribution of spends by females for each expense type

select exp_type,sum(case when gender='F' then amount end)*1.0/sum(amount) as female_perc_contribution
from 
credit_card_transcations
group by exp_type
order by female_perc_contribution desc


--7- which card and expense type combination saw highest month over month growth in Jan-2014

select * from credit_card_transcations;

with cte as(
select year(transaction_date) as yr,month(transaction_date)as mth,card_type,exp_type,
sum(amount)as total_amount,lag(sum(amount))over(partition by card_type,exp_type order by year(transaction_date) ,month(transaction_date)) as prev_spend
from credit_card_transcations
group by year(transaction_date),month(transaction_date),card_type,exp_type

)
select yr,mth, card_type,exp_type,round((total_amount - prev_spend)*1.0/prev_spend*100.0,2) as mom_growth
from cte
where prev_spend is not null and yr=2014 and mth=1
order by mom_growth desc



--8- during weekends which city has highest total spend to total no of transcations ratio 

select city,sum(amount)as total_spend, count(transaction_id) as no_of_transaction ,
sum(amount)*1.0/count(transaction_id) as ratio
from 
credit_card_transcations
where DATEPART(weekday,transaction_date) in (7,1)
group by city
order by ratio desc


--9- which city took least number of days to reach its 500th transaction after the first transaction in that city
select * from credit_card_transcations;

with cte as(
select city,transaction_date,
row_number()over(partition by city order by transaction_date) as rn
from credit_card_transcations

)
select top 3 city,min(transaction_date) as day1 ,max(transaction_date)as day_max
,DATEDIFF(day,min(transaction_date),max(transaction_date))as day_diff
from cte
where rn =1 or rn=500
group by city
having count(city)=2
order by day_diff 