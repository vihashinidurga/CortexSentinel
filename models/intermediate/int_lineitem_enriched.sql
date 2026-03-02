with
    lineitem as (select * from {{ ref("stg_lineitem") }}),

    part as (select * from {{ ref("stg_part") }}),

    supplier as (select * from {{ ref("stg_supplier") }}),

    enriched as (
        select
            l.line_item_key,
            l.order_key,
            l.part_key,
            l.supplier_key,
            l.line_number,
            l.quantity,
            l.extended_price,
            l.discount_percentage,
            l.tax_rate,
            l.status as item_status,
            p.name as part_name,
            p.manufacturer as part_manufacturer,
            s.name as supplier_name
        from lineitem l
        left join part p on l.part_key = p.part_id
        left join supplier s on l.supplier_key = s.supplier_id
    )

select *
from enriched
