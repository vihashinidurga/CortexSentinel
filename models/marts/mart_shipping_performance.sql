with lineitem as (
    select * from {{ ref('stg_lineitem') }}
),

orders_enriched as (
    select * from {{ ref('int_orders_enriched') }}
),

shipping_performance as (
    select
        o.region_name,
        avg(l.receipt_date - l.ship_date) as avg_shipping_delay_days
    from lineitem l
    inner join orders_enriched o on l.order_key = o.order_key
    where l.receipt_date is not null and l.ship_date is not null
    group by 1
)

select * from shipping_performance
order by avg_shipping_delay_days desc
