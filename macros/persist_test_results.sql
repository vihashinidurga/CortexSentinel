{% macro persist_test_results(results) %}
  -- depends_on: {{ ref('validation_logs') }}
  -- depends_on: {{ ref('validation_summaries') }}

  {% if execute %}
    {%- set ai_tests = ['cortex_validation', 'cortex_revenue_dominance', 'cortex_key_duplication'] -%}
    
    {% set dml_queries = [] %}
    
    {% for result in results if result.status == 'fail' %}
      {% if result.node.name.split('_')[0] in ai_tests %}
        {% do dml_queries.append("
          insert into " ~ ref('validation_logs') ~ " (
              run_id, model_name, raw_ai_response, parsed_valid, confidence, reason, created_at
          )
          select 
              '" ~ invocation_id ~ "',
              '" ~ result.node.attached_node ~ "',
              ai_raw_response,
              false,
              ml_confidence,
              failure_reason,
              current_timestamp()
          from (" ~ result.node.compiled_sql ~ ")
        ") %}
      {% endif %}
    {% endfor %}

    {# Summary Logic #}
    {% if results | length > 0 %}
        {% do dml_queries.append("
          insert into " ~ ref('validation_summaries') ~ " (
              run_id, model_name, total_rows_validated, failed_rows, execution_time_ms, created_at
          )
          values (
              '" ~ invocation_id ~ "',
              'Global Test Run',
              " ~ (results | length) ~ ",
              " ~ (results | selectattr('status', 'equalto', 'fail') | list | length) ~ ",
              0,
              current_timestamp()
          )
        ") %}
    {% endif %}

    {% if dml_queries | length > 0 %}
      {% set final_sql = "BEGIN; " ~ dml_queries | join('; ') ~ "; COMMIT;" %}
      {% do run_query(final_sql) %}
    {% endif %}

  {% endif %}
{% endmacro %}
