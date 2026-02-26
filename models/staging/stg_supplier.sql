with
    source as (select * from {{ source("tpch-raw", "raw_supplier") }}),
    renamed as (
        select
            {{ dbt_utils.generate_surrogate_key("s_suppkey") }} as supplier_key,
            s_suppkey as supplier_id,
            s_name as supplier_name,
            s_address as supplier_address,
            s_nationkey as nation_key,
            s_phone as supplier_phone_number,
            s_acctbal as supplier_account_balance,
            s_comment as commentf

        from source
    )
select *
from renamed
