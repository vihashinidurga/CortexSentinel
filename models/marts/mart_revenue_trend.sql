with orders as (
    select * from {{ ref('int_orders_enriched') }}
),

lineitem as (
    select * from {{ ref('int_lineitem_enriched') }}
),

monthly_revenue as (
    select
        date_trunc('month', o.order_date) as order_month,
        sum(l.extended_price * (1 - l.discount_percentage)) as total_revenue
    from lineitem l
    inner join orders o on l.order_key = o.order_key
    group by 1
)

select * from monthly_revenue
order by order_month
