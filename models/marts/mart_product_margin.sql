with
    product_profitability as (select * from {{ ref("int_product_profitability") }}),

    category_margin as (
        select
            part_type as product_category,
            sum(net_revenue) as total_revenue,
            sum(total_cost) as total_cost,
            sum(margin) as total_margin,
            (sum(margin) / nullif(sum(net_revenue), 0)) * 100 as margin_percentage
        from product_profitability
        group by 1
    )

select *
from category_margin
order by total_margin desc
