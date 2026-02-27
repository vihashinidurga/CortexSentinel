{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key=['part_key', 'supplier_key']
    )
}}

with
    source as (select * from {{ source("tpch-raw", "raw_partsupp") }}),
    renamed as (
        select
            {{ dbt_utils.generate_surrogate_key(["ps_partkey", "ps_suppkey"]) }}
            as part_supplier_key,
            ps_partkey as part_key,
            ps_suppkey as supplier_key,
            ps_availqty as available_quantity,
            ps_supplycost as supply_cost,
            ps_comment as comment
        from source
    )

select *
from renamed
