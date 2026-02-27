{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='customer_id'
    )
}}

with
    source as (select * from {{ source("tpch-raw", "raw_customer") }}),
    renamed as (
        select
            {{ dbt_utils.generate_surrogate_key(["c_custkey"]) }} as customer_key,
            c_custkey as customer_id,
            c_name as name,
            c_address as address,
            c_nationkey as nation_key,
            c_phone as phone_number,
            c_acctbal as account_balance,
            c_mktsegment as market_segment,
            c_comment as comment
        from source
    )
select *
from renamed
