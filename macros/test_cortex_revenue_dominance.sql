{% test cortex_revenue_dominance(model, customer_column, revenue_column, threshold_percent=50, model_choice='snowflake-arctic', column_name=none) %}

with totals as (
    select 
        sum({{ revenue_column }}) as total_revenue
    from {{ model }}
),

customer_revenue as (
    select
        {{ customer_column }} as customer,
        sum({{ revenue_column }}) as revenue,
        (revenue / nullif((select total_revenue from totals), 0)) * 100 as pct_share
    from {{ model }}
    group by 1
),

top_clusters as (
    select 
        object_agg(customer, revenue) as revenue_profile,
        max(pct_share) as max_share
    from customer_revenue
    where pct_share > 5 -- only focus on significant customers for prompt brevity
),

inference as (
    select
        *,
        snowflake.cortex.complete(
            '{{ model_choice }}',
            concat(
                'Analyze this customer revenue profile for dominance. A single customer represents ', 
                round(max_share, 2), 
                '% of total revenue. Profile data (JSON): ', 
                cast(revenue_profile as text),
                '. Does this distribution suggest a high-risk dominance or data anomaly? ',
                'Return JSON: {"valid": boolean, "reason": "string", "confidence": float}.'
            )
        ) as ai_raw_response
    from top_clusters
    where max_share > {{ threshold_percent }}
),

parsed as (
    select
        *,
        try_parse_json(ai_raw_response) as ai_json
    from inference
)

select 
    revenue_profile as ai_input,
    ai_raw_response,
    cast(get(ai_json, 'reason') as text) as failure_reason,
    cast(get(ai_json, 'confidence') as float) as ml_confidence
from parsed
where (cast(get(ai_json, 'valid') as boolean) = false) 
   or (ai_json is null)

{% endtest %}
