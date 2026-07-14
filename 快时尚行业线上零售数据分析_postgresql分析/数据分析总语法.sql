select *
from customers;
select *
from login_log;
select *
from orders;
select *
from orders_items;
select *
from products;
select *
from products_skus;
select *
from regioninfo;

--将时间戳转换为date保存在新列
alter table customers add column created_new date;
UPDATE customers SET created_new = to_timestamp(created_at)::date;

--地域分析
---各个省市的情况以及所占百分比
select 省份表.regionname as 省份,
       城市表.regionname as 城市,
      sum(total_price)as 消费金额,
      sum(total_price)/sum(sum(total_price)) over() as 消费金额占比
from orders left join regioninfo as 城市表
on city=城市表.regionid
left join regioninfo as 省份表
on 城市表.parentid=省份表.regionid
group by 省份表.regionname,城市表.regionname
order by 消费金额占比 desc;

----用户留存分析
SELECT 
    created_new,
    COUNT(DISTINCT customers.id) AS 新增用户数,
    SUM(CASE WHEN (login_date - created_new) = 1 THEN 1 ELSE 0 END) AS 次日留存数,
    SUM(CASE WHEN (login_date - created_new) = 3 THEN 1 ELSE 0 END) AS 三日留存数,
    SUM(CASE WHEN (login_date - created_new) = 1 THEN 1 ELSE 0 END) * 1.0 / COUNT(DISTINCT customers.id) AS 次日留存率,
    SUM(CASE WHEN (login_date - created_new) = 3 THEN 1 ELSE 0 END) * 1.0 / COUNT(DISTINCT customers.id) AS 三日留存率
FROM customers
LEFT JOIN login_log ON customers.id = login_log.customer_id
WHERE EXTRACT(YEAR FROM created_new) = 2018 
  AND EXTRACT(MONTH FROM created_new) = 3
GROUP BY created_new;



--用户复购分析
select 月份,
       sum(是否复购::int)as 复购用户数,
       count(是否复购::int)as 总用户数,
       avg(是否复购::int)as 复购率
from(select
EXTRACT(month FROM created_at) as 月份,
customer_id,
count(*) as 消费次数,
count(*)>1 as 是否复购
from orders
where EXTRACT(YEAR FROM created_at) = 2017
group by EXTRACT(month FROM created_at),customer_id)as t
group by 月份;

---连续行为天数
WITH t AS (
    SELECT DISTINCT customer_id, created_at
    FROM orders
    WHERE EXTRACT(YEAR FROM created_at) = 2018 AND EXTRACT(MONTH FROM created_at) = 3
),
ranked AS (
    SELECT 
        customer_id,
        created_at,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY created_at ASC) AS rn,
        created_at - (ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY created_at ASC))::int AS grp_date
    FROM t
),
grp_count AS (
    SELECT 
        customer_id,
        grp_date,
        COUNT(*) AS consecutive_days
    FROM ranked
    GROUP BY customer_id, grp_date
)
SELECT 
    customer_id,
    MAX(consecutive_days) AS max_consecutive_days
FROM grp_count
GROUP BY customer_id
HAVING MAX(consecutive_days) > 1  
ORDER BY customer_id;



