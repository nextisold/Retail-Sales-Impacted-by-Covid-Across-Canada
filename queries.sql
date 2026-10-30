select * from retail where province = 'Ontario'
order by month asc;


select month, sales, province, 'Before' as phase 
from retail where province = 'Ontario' and month < '2020-03'
order by month asc; 


select month, sales, province, 'During' as phase
from retail where province = 'Ontario' and month between '2020-03' and '2021-12'
order by month asc;


select month, sales, province, 'After' as phase 
from retail where province = 'Ontario' and month >= '2022-01'
order by month asc; 


Select *,
case when month < '2020-03' then 'Before'
     when month between '2020-03' and '2021-12' then 'During'
     else 'After' end as phase 
from retail 
where province = 'Ontario' 
order by month asc; 


select
case when 
     month < '2020-03' then 'Before'
     when month between '2020-03' and '2021-12' then 'During'
     else 'After' end as phase,
round(avg(sales)) as average_sales
from retail
where province = 'Ontario'
group by phase
order by month asc;


select province, 
    case when 
        month < '2020-03' then 'Before'
        when month between '2020-03' and '2021-12' then 'During'
        else 'After' end as phase, 
        round(avg(sales)) as average_sales
from retail 
group by province, phase 
order by province; 


select province, 
     round(avg(case when month < '2020-03' then sales end)) as before_pandemic, 
     round(avg(case when month between '2020-03' and '2021-12' then sales end)) as during_pandemic,
     round(avg(case when month > '2021-12' then sales end)) as after_pandemic
from retail
group by province 
order by province;

With phase_avgs as (
    select province, 
        round(avg(case when month < '2020-03' then sales end)) as before_pandemic, 
        round(avg(case when month between '2020-03' and '2021-12' then sales end)) as during_pandemic,
        round(avg(case when month > '2021-12' then sales end)) as after_pandemic
    from retail
    group by province
)  
select province, 
    round((during_pandemic - before_pandemic) * 100.0 / before_pandemic, 1) as during_pandemicpercentage,
    round((after_pandemic - before_pandemic) * 100.0 / before_pandemic, 1) as after_pandemicpercentage
from phase_avgs
order by after_pandemicpercentage desc;

with phase_avgs as ( 
    select product, 
        round(avg(case when month < '2020-03' then cpi_index end), 1) as before_pandemic_PI, 
        round(avg(case when month between '2020-03' and '2021-12' then cpi_index end), 1) as during_pandemic_PI,
        round(avg(case when month > '2021-12' then cpi_index end), 1) as after_pandemic_PI
    from cpi
    where product in ('Food', 'All-items')
    group by product
)
select product, 
    round((during_pandemic_PI - before_pandemic_PI) * 100.0 / before_pandemic_PI, 1) || '% Increase' as duringpandemicPI,
    round((after_pandemic_PI - before_pandemic_PI) * 100.0 / before_pandemic_PI, 1) || '% Increase' as afterpandemicPI
from phase_avgs 
order by afterpandemicPI desc; 


with phase_avgs as (
    select province,
        round(avg(case when month < '2020-03' then sales end)) as before_pandemic,
        round(avg(case when month > '2021-12' then sales end)) as after_pandemic
    from retail 
    where province <> 'Canada' 
    group by province
)
select province, 
    round((after_pandemic - before_pandemic) * 100.0 / before_pandemic, 1) as after_pandemic,
    rank() over (order by (after_pandemic - before_pandemic) * 100.0 / before_pandemic desc) as position
from phase_avgs 
order by position;


with phase_stats as (
    select province,
        avg(case when month < '2020-03' then sales end) as before_avg,
        min(case when month between '2020-03' and '2021-12' then sales end) as lowest_month
    from retail
    where province <> 'Canada'
    group by province
)
select province,
    round((lowest_month - before_avg) * 100.0 / before_avg, 1) as drop_pct
from phase_stats
order by drop_pct;


with joined as (
    select r.month, r.sales, c.cpi_index
    from retail r
    join cpi c on c.month = r.month
    where r.province = 'Canada' and c.product = 'All-items'
),
phase_avgs as (
    select
        avg(case when month < '2020-03' then sales end) as sales_before,
        avg(case when month > '2021-12' then sales end) as sales_after,
        avg(case when month < '2020-03' then cpi_index end) as cpi_before,
        avg(case when month > '2021-12' then cpi_index end) as cpi_after
    from joined
)
select
    round((sales_after - sales_before) * 100.0 / sales_before, 1) as sales_growth_pct,
    round((cpi_after - cpi_before) * 100.0 / cpi_before, 1) as price_growth_pct,
    round(((sales_after / sales_before) / (cpi_after / cpi_before) - 1) * 100, 1) as real_growth_pct
from phase_avgs;


with yoy as (
    select month, product,
           round((cpi_index / lag(cpi_index, 12) over (partition by product order by month) - 1) * 100, 1) as yoy_pct
    from cpi
    where product in ('Food', 'All-items')
)
select month,
       max(case when product = 'Food' then yoy_pct end) as food_yoy_pct,
       max(case when product = 'All-items' then yoy_pct end) as all_items_yoy_pct
from yoy
where yoy_pct is not null
group by month
order by month;

