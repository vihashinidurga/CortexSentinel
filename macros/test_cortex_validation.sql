{% test cortex_validation(model, column_name=none, columns=none, rules="", confidence_threshold=0.8, mode='hybrid', row_limit=1000, model_choice='mistral-7b') %}

{# 
    Cortex AI Data Validation Generic Test
    
    Parameters:
    - model: The model to test
    - column_name: Single column to validate (optional)
    - columns: List of columns to validate as an object (optional)
    - rules: Semantic rules for the AI to follow
    - confidence_threshold: Float (0-1) to determine failure
    - mode: 'sql_only' | 'hybrid' | 'ai_full' | 'sample' | 'incremental'
    - row_limit: Max rows to process to control costs
    - model_choice: Cortex LLM model to use (default: mistral-7b)
#}

with base as (
    select 
        *,
        {% if columns %}
            object_construct({{ columns | join(', ') }}) as ai_input
        {% else %}
            object_construct('{{ column_name }}', {{ column_name }}) as ai_input
        {% endif %}
    from {{ model }}
    {% if mode == 'sample' %}
        tablesample (10)
    {% endif %}
),

filtered as (
    -- In 'hybrid' mode, you would add SQL logic here to filter for 
    -- records that aren't obviously invalid via standard SQL.
    select * from base
    where 1=1
    {% if mode == 'incremental' and adapter.get_columns_in_relation(model) | map(attribute='name') | list | intersect(['validated_at', 'updated_at']) | length == 2 %}
        and (validated_at is null or validated_at < updated_at)
    {% endif %}
    limit {{ row_limit }}
),

inference as (
    select
        *,
        snowflake.cortex.complete(
            '{{ model_choice }}',
            concat(
                'Validate based on semantic rules: ', {{ dbt.string_literal(rules) }},
                '. Return ONLY a JSON object: {"valid": boolean, "confidence": float, "reason": "string"}. ',
                'Data: ', cast(ai_input as text)
            )
        ) as ai_raw_response
    from filtered
),

parsed as (
    select
        *,
        try_parse_json(ai_raw_response) as ai_json
    from inference
)

-- dbt test semantics: 0 rows = pass, >0 rows = fail
select 
    ai_input,
    ai_raw_response,
    cast(ai_json:reason as text) as failure_reason,
    cast(ai_json:confidence as float) as ml_confidence
from parsed
where (cast(ai_json:valid as boolean) = false)
   or (cast(ai_json:confidence as float) < {{ confidence_threshold }})
   or (ai_json is null) -- Handle malformed JSON or timeouts

{% endtest %}
