{% test cortex_revenue_reconciliation(model, other_model, revenue_expression, other_revenue_expression, threshold_variance=0.01, model_choice='snowflake-arctic', column_name=none) %}

with model_1 as (
    select 
        sum({{ revenue_expression }}) as total_revenue
    from {{ model }}
),

model_2 as (
    select 
        sum({{ other_revenue_expression }}) as total_revenue
    from {{ other_model }}
),

comparison as (
    select
        m1.total_revenue as m1_revenue,
        m2.total_revenue as m2_revenue,
        abs(m1.total_revenue - m2.total_revenue) as variance,
        (variance / nullif(m1.total_revenue, 0)) * 100 as variance_pct
    from model_1 m1
    cross join model_2 m2
),

inference as (
    select
        *,
        snowflake.cortex.complete(
            '{{ model_choice }}',
            concat(
                'Reconcile revenue between two models. ',
                'Model 1 (Target): ', round(m1_revenue, 2), '. ',
                'Model 2 (Source): ', round(m2_revenue, 2), '. ',
                'Variance: ', round(variance, 2), ' (', round(variance_pct, 2), '%). ',
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
