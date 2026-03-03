{{ config(materialized='incremental', schema='audit') }}

-- This model initializes the schema for validation logging.
-- In a real production scenario, this could be populated via a post-hook or a dedicated mart
-- that aggregates the results of AI validation tests if they were persisted.

select
    null::varchar as run_id,
    null::varchar as model_name,
    null::variant as raw_ai_response,
    null::boolean as parsed_valid,
    null::float as confidence,
    null::varchar as reason,
    null::timestamp_ntz as created_at
where 1=0
