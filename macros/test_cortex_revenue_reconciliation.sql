{% test cortex_revenue_reconciliation(model, other_model, revenue_expression, other_revenue_expression, threshold_variance=0.01, model_choice='snowflake-arctic', column_name=none) %}

with model_1 as (
    select 
        cast(coalesce(sum(cast({{ revenue_expression }} as float)), 0) as float) as total_revenue
    from {{ model }}
),

model_2 as (
    select 
        cast(coalesce(sum(cast({{ other_revenue_expression }} as float)), 0) as float) as total_revenue
    from {{ other_model }}
),

comparison as (
    select
        total_revenue as m1_revenue,
        (select total_revenue from model_2) as m2_revenue,
        abs(m1_revenue - m2_revenue) as variance,
        (variance / nullif(m1_revenue, 0)) * 100 as variance_pct
    from model_1
),

inference as (
    select
        *,
        snowflake.cortex.complete(
            '{{ model_choice }}',
            concat(
                'Reconcile revenue between two models. ',
                'Model 1 (Target): ', coalesce(round(m1_revenue, 2)::string, '0'), '. ',
                'Model 2 (Source): ', coalesce(round(m2_revenue, 2)::string, '0'), '. ',
                'Variance: ', coalesce(round(variance, 2)::string, '0'), ' (', coalesce(round(variance_pct, 2)::string, '0'), '%). ',
                'Does this variance suggest a data leak, calculation error, or is it within acceptable limits? ',
                'Return JSON object: {"valid": boolean, "reason": "string", "confidence": float}.'
            )
        ) as ai_raw_response
    from comparison
),

parsed as (
    select
        *,
        try_parse_json(ai_raw_response) as ai_json
    from inference
)

select 
     object_construct('m1_revenue', m1_revenue, 'm2_revenue', m2_revenue, 'variance_pct', variance_pct) as ai_input,
     ai_raw_response,
     cast(get(ai_json, 'reason') as text) as failure_reason,
     cast(get(ai_json, 'confidence') as float) as ml_confidence
from parsed
where (cast(get(ai_json, 'valid') as boolean) = false and variance_pct > {{ threshold_variance * 100 }})
   or (ai_json is null)

{% endtest %}
