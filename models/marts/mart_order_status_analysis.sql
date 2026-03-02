with orders as (
    select * from {{ ref('stg_orders') }}
),

status_metrics as (
    select
        status,
        count(*) as total_orders,
        count(*) / sum(count(*)) over() * 100 as percentage_of_total
    from orders
    group by 1
),

cancellation_rate as (
    select
        (count(case when status = 'F' then 1 end) / count(*)) * 100 as cancellation_rate_percentage
    from orders
)

select 
    s.*,
    c.cancellation_rate_percentage
from status_metrics s
cross join cancellation_rate c
