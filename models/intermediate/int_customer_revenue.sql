with orders as (
    select * from {{ ref('int_orders_enriched') }}
),

lineitem as (
    select * from {{ ref('int_lineitem_enriched') }}
),

customer_revenue as (
    select
        o.customer_id,
        o.customer_name,
        sum(l.extended_price * (1 - l.discount_percentage)) as total_revenue
    from lineitem l
    inner join orders o on l.order_key = o.order_key
    group by 1, 2
)

select * from customer_revenue
