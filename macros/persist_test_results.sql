{% macro persist_test_results(results) %}
  -- depends_on: {{ ref('validation_logs') }}
  -- depends_on: {{ ref('validation_summaries') }}
  
  {%- set ai_tests = ['cortex_validation', 'cortex_revenue_dominance', 'cortex_key_duplication'] -%}
  
  {% for result in results if result.status == 'fail' %}
    {% if result.node.name.split('_')[0] in ai_tests %}
      
      {% set insert_query %}
        insert into {{ ref('validation_logs') }} (
            run_id,
            model_name,
            raw_ai_response,
            parsed_valid,
            confidence,
            reason,
            created_at
        )
        select 
            '{{ invocation_id }}' as run_id,
            '{{ result.node.attached_node }}' as model_name,
            ai_raw_response,
            false as parsed_valid,
            ml_confidence as confidence,
            failure_reason as reason,
            current_timestamp()
        from ({{ result.node.compiled_sql }})
      {% endset %}

      {% do run_query(insert_query) %}
      
    {% endif %}
  {% endfor %}

  {# Summary Logic #}
  {% if results | length > 0 %}
      {% set summary_query %}
        insert into {{ ref('validation_summaries') }} (
            run_id,
            model_name,
            total_rows_validated,
            failed_rows,
            execution_time_ms,
            created_at
        )
        values (
            '{{ invocation_id }}',
            'Global Test Run',
            {{ results | length }},
            {{ results | selectattr('status', 'equalto', 'fail') | list | length }},
            0, -- Placeholder for execution time
            current_timestamp()
        )
      {% endset %}
      {% do run_query(summary_query) %}
  {% endif %}

{% endmacro %}
