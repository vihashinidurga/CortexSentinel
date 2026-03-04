{% macro persist_test_results(results) %}
  -- depends_on: {{ ref('validation_logs') }}
  -- depends_on: {{ ref('validation_summaries') }}

  {% if execute %}
    {%- set ai_tests = ['cortex_validation', 'cortex_revenue_dominance', 'cortex_key_duplication'] -%}
    
    {% set log_inserts = [] %}
    {% for result in results if result.status == 'fail' %}
      {% set is_ai_test = false %}
      {% for prefix in ai_tests %}
        {% if result.node.name.startswith(prefix) %}
          {% set is_ai_test = true %}
        {% endif %}
      {% endfor %}

      {% if is_ai_test %}
        {% do log_inserts.append("
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

    {% set summary_insert = "" %}
    {% if results | length > 0 %}
        {% set summary_insert = "
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
          );
        " %}
    {% endif %}

    {% if log_inserts | length > 0 or summary_insert != "" %}
      {% set final_sql = "BEGIN; " ~ log_inserts | join('; ') ~ ('; ' if log_inserts | length > 0 else '') ~ summary_insert ~ " COMMIT;" %}
      {{ return(final_sql) }}
    {% endif %}

  {% endif %}
{% endmacro %}
