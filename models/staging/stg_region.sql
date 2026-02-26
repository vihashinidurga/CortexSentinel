with
    source as (select * from {{ source("tpch-raw", "raw_region") }}),
    renamed as (
        select
            {{ dbt_utils.generate_surrogate_key(["r_regionkey"]) }} as region_key,
            r_regionkey as region_id,
            r_name as name,
            r_comment as comment
        from source
    )
select *
from renamed
