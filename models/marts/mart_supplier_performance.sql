with lineitem_enriched as (
    select * from {{ ref('int_lineitem_enriched') }}
),

supplier_revenue as (
    select
        supplier_name,
        sum(extended_price * (1 - discount_percentage)) as total_revenue,
        count(line_item_key) as total_items_supplied
    from lineitem_enriched
    group by 1
)

select * from supplier_revenue
order by total_revenue desc
