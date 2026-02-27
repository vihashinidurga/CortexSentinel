with orders as (
    select * from {{ ref('stg_orders') }}
),

customers as (
    select * from {{ ref('stg_customers') }}
),

nations as (
    select * from {{ ref('stg_nation') }}
),

regions as (
    select * from {{ ref('stg_region') }}
),

enriched as (
    select
        o.order_key,
        o.order_id,
        o.order_date,
        o.status as order_status,
        c.customer_id,
        c.name as customer_name,
        n.name as nation_name,
        r.name as region_name
    from orders o
    left join customers c on o.customer_key = c.customer_id
    left join nations n on c.nation_key = n.nation_id
    left join regions r on n.region_key = r.region_id
)

select * from enriched
