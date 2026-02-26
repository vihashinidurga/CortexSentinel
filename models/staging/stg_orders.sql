with
    source as (select * from {{ source("tpch-raw", "raw_orders") }}),
    renamed as (
        select
            {{ dbt_utils.generate_surrogate_key(["o_orderkey"]) }} as order_id,
            o_custkey as customer_key,
            o_orderstatus as order_status,
            o_totalprice as total_price,
            o_orderdate as order_date,
            o_orderpriority as order_priority,
            o_clerk as clerk,
            o_shippriority as ship_priority,
            o_comment as comment

        from source
    )

select *
from renamed
