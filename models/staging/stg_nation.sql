with
    source as (select * from {{ source("tpch-raw", "raw_nation") }}),
    renamed as (
        select
            {{ dbt_utils.generate_surrogate_key(["n_nationkey"]) }} as nation_key,
            n_nationkey as nation_id,
            n_name as name,
            n_regionkey as region_key,
            n_comment as comment
        from source
    )

select *
from renamed
