with lineitem as (
    select * from {{ ref('stg_lineitem') }}
),

part as (
    select * from {{ ref('stg_part') }}
),

partsupp as (
    select * from {{ ref('stg_partsupp') }}
),

profitability as (
    select
        l.order_key,
        l.part_key,
        l.supplier_key,
        l.quantity,
        l.extended_price,
        l.discount_percentage,
        p.name as part_name,
        p.type as part_type,
        ps.supply_cost,
        (l.extended_price * (1 - l.discount_percentage)) as net_revenue,
        (ps.supply_cost * l.quantity) as total_cost,
        ((l.extended_price * (1 - l.discount_percentage)) - (ps.supply_cost * l.quantity)) as margin
    from lineitem l
    inner join part p on l.part_key = p.part_id
    inner join partsupp ps on l.part_key = ps.part_key and l.supplier_key = ps.supplier_key
)

select * from profitability
