{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='part_id'
    )
}}

with
    source as (select * from {{ source("tpch-raw", "raw_part") }}),
    renamed as (
        select
            {{ dbt_utils.generate_surrogate_key(["p_partkey"]) }} as part_key,
            p_partkey as part_id,
            p_name as name,
            p_mfgr as manufacturer,
            p_brand as brand,
            p_type as type,
            p_size as size,
            p_container as container,
            p_retailprice as retail_price,
            p_comment as comment

        from source
    )

select * from renamed
