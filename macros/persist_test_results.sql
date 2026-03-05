{% macro persist_test_results(results) %}
  -- depends_on: {{ ref('validation_logs') }}
  -- depends_on: {{ ref('validation_summaries') }}

  {% if execute %}
    {%- set ai_tests = ['cortex_validation', 'cortex_revenue_dominance', 'cortex_key_duplication', 'cortex_revenue_reconciliation'] -%}
    
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
              {{ dbt.string_literal(invocation_id) }},
              {{ dbt.string_literal(result.node.attached_node) }},
              ai_raw_response,
              false,
              ml_confidence,
              failure_reason,
              current_timestamp()
          from (" ~ result.node.compiled_sql ~ ")
        ") %}
      {% endif %}
    {% endfor %}

    {% set total_tests = results | length %}
    {% set failed_tests = results | selectattr('status', 'equalto', 'fail') | list | length %}
    {% set failure_rate = (failed_tests / total_tests * 100) if total_tests > 0 else 0 %}
    {% set total_exec_time = results | map(attribute='execution_time') | sum | round(2) * 1000 %}

    {% set summary_insert = "" %}
    {% if total_tests > 0 %}
        {% set summary_insert = "
          insert into " ~ ref('validation_summaries') ~ " (
              run_id, model_name, total_rows_validated, failed_rows, failure_rate, avg_confidence, execution_time_ms, created_at
          )
          select 
              {{ dbt.string_literal(invocation_id) }},
              'Global Test Run',
              " ~ total_tests ~ ",
              " ~ failed_tests ~ ",
              " ~ failure_rate ~ ",
              (select avg(confidence) from " ~ ref('validation_logs') ~ " where run_id = {{ dbt.string_literal(invocation_id) }}),
              " ~ total_exec_time ~ ",
              current_timestamp()
          ;
        " %}
    {% endif %}

    {% if log_inserts | length > 0 or summary_insert != "" %}
      {% set final_sql = "BEGIN; " ~ log_inserts | join('; ') ~ ('; ' if log_inserts | length > 0 else '') ~ summary_insert ~ " COMMIT;" %}
      {{ return(final_sql) }}
    {% endif %}

  {% endif %}
{% endmacro %}
