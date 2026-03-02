with
    orders as (select * from {{ ref("int_orders_enriched") }}),

    lineitem as (select * from {{ ref("int_lineitem_enriched") }}),

    revenue_aggregation as (
        select
            o.region_name,
            o.nation_name,
            date_part('year', o.order_date) as order_year,
            sum(l.extended_price * (1 - l.discount_percentage)) as total_revenue
        from lineitem l
        inner join orders o on l.order_key = o.order_key
        group by 1, 2, 3
    )

select *
from revenue_aggregation
order by region_name, nation_name, order_year
