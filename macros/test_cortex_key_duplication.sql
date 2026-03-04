{% test cortex_key_duplication(model, columns=none, column_name=none, model_choice='snowflake-arctic') %}

{%- set columns = columns if columns else [column_name] -%}

{%- set columns_csv = columns | join(', ') -%}

with duplicates as (
    select 
        {{ columns_csv }},
        count(*) as duplicate_count
    from {{ model }}
    group by {{ columns_csv }}
    having count(*) > 1
    limit 10 -- limit to save tokens/cost
),

conflicting_data as (
    select
        d.*,
        object_construct(m.*) as row_data
    from {{ model }} m
    join duplicates d on 
        {% for col in columns %}
            m.{{ col }} = d.{{ col }}
            {% if not loop.last %} and {% endif %}
        {% endfor %}
),

grouped_conflicts as (
    select
        {{ columns_csv }},
        array_agg(row_data) as conflicting_rows
    from conflicting_data
    group by {{ columns_csv }}
),

inference as (
    select
        *,
        snowflake.cortex.complete(
            '{{ model_choice }}',
            concat(
                'Investigate duplicate keys for columns ({{ columns_csv }}). ',
                'Conflicting row data: ', cast(conflicting_rows as text),
                '. Determine if this is a Merge Failure (all columns but timestamp match), ',
                'Hash Collision (keys match but data is totally different), or expected duplication. ',
                'Return JSON: {"valid": false, "duplication_type": "string", "reason": "string"}.'
            )
        ) as ai_raw_response
    from grouped_conflicts
),

parsed as (
    select
        *,
        try_parse_json(ai_raw_response) as ai_json
    from inference
)

select 
     {{ columns_csv }} as ai_input,
     ai_raw_response,
     cast(get(ai_json, 'reason') as text) as failure_reason,
     0.9 as ml_confidence -- Default high confidence for structural checks
from parsed
where (cast(get(ai_json, 'valid') as boolean) = false)
   or (ai_json is null)

{% endtest %}
