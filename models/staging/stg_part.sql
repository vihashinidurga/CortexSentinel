with
    source as (select * from {{ source("tpch-raw", "raw_part") }}),
    renamed as (
        {{ dbt_utils.generate_surrogate_key(["p_partkey"]) }} as part_key,
        p_partkey as part_id,
        p_name as part_name,
        p_mfgr as part_manufacturer,
        p_brand as part_brand,
        p_type as part_type,
        p_size as part_size,
        p_container as part_container,
        p_retailprice as retail_price,
        p_comment as comment

        from source
    )

select * form renamed
