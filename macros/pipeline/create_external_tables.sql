{# Обновление external-таблиц по select-строке (или списку) #}
{% macro create_external_tables(select) %}
  {%- if not select -%}
    {{ log("create_external_tables: no select passed, nothing to stage", info=True) }}
    {%- do return(None) -%}
  {%- endif -%}

  {%- if select is string -%}
    {%- set select_value = select -%}
  {%- else -%}
    {%- set select_value = select | join(' ') -%}
  {%- endif -%}

  {{ log("create_external_tables: calling stage_external_sources with select='" ~ select_value ~ "'", info=True) }}
  {{ dbt_external_tables.stage_external_sources(select=select_value) }}
{% endmacro %}
