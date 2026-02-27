{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='supplier_id'
    )
}}

with
    source as (select * from {{ source("tpch-raw", "raw_supplier") }}),
    renamed as (
        select
            {{ dbt_utils.generate_surrogate_key(["s_suppkey"]) }} as supplier_key,
            s_suppkey as supplier_id,
            s_name as name,
            s_address as address,
            s_nationkey as nation_key,
            s_phone as phone_number,
            s_acctbal as account_balance,
            s_comment as comment

        from source
    )
select *
from renamed
