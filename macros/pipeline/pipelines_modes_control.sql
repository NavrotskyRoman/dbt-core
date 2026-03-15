{% macro pipeline_on_run_start() %}
  {# Управление обслуживанием external-таблиц перед dbt run / dbt build.
     См. vars.pipeline_mode и vars.external_tables в dbt_project.yml.
     DBT_PIPELINE_MODE в env переопределяет vars (например dev для локального compile без BQ). #}
  {% set mode = env_var('DBT_PIPELINE_MODE', var('pipeline_mode', 'full')) %}

  {% if mode in ['full', 'external_only'] %}
    {{ create_external_tables(var('external_tables', [])) }}
  {% elif mode == 'external_all' %}
    {{ dbt_external_tables.stage_external_sources() }}
  {% else %}
    {{ log('create_external_tables: skipped for pipeline_mode=' ~ mode, info=True) }}
  {% endif %}
{% endmacro %}


{% macro pipeline_on_run_end() %}
  {# Управление дропом устаревших моделей и датасетов после dbt run / dbt build.
     См. vars.pipeline_mode, vars.deprecated_tables и vars.drop_datasets.
     DBT_PIPELINE_MODE в env переопределяет vars. #}
  {% set mode = env_var('DBT_PIPELINE_MODE', var('pipeline_mode', 'full')) %}

  {% if mode not in ['no_drops', 'dev'] %}
    {{ drop_deprecated_tables() }}
    {{ drop_datasets() }}
  {% else %}
    {{ log('drop_deprecated_tables/drop_datasets: skipped for pipeline_mode=' ~ mode, info=True) }}
  {% endif %}
{% endmacro %}
