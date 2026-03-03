{{ config(materialized='incremental', schema='audit') }}

select
    null::varchar as run_id,
    null::varchar as model_name,
    null::int as total_rows_validated,
    null::int as failed_rows,
    null::float as failure_rate,
    null::float as avg_confidence,
    null::int as execution_time_ms,
    null::timestamp_ntz as created_at
where 1=0
