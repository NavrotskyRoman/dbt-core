{% macro drop_deprecated_tables() %}
  {%- set items = var('deprecated_tables', []) -%}

  {%- if items | length == 0 -%}
    {{ log("drop_deprecated_tables: no deprecated_tables defined, nothing to drop", info=True) }}
  {%- else -%}
    {%- for fullname in items -%}
      {%- set parts = fullname.split('.') -%}

      {%- if parts | length != 2 -%}
        {{ log("drop_deprecated_tables: invalid value '" ~ fullname ~ "', expected 'schema.identifier'", info=True) }}
      {%- else -%}
        {%- set schema = parts[0] -%}
        {%- set identifier = parts[1] -%}

        {%- set relation = adapter.get_relation(
          database=target.database,
          schema=schema,
          identifier=identifier
        ) -%}

        {%- if relation is none -%}
          {{ log("drop_deprecated_tables: relation not found " ~ target.database ~ "." ~ schema ~ "." ~ identifier, info=True) }}
        {%- else -%}
          {{ log("drop_deprecated_tables: dropping " ~ relation, info=True) }}
          {%- do adapter.drop_relation(relation) -%}
        {%- endif -%}
      {%- endif -%}
    {%- endfor -%}
  {%- endif -%}
{% endmacro %}

{# В этом файле только drop_deprecated_tables(). Остальные макросы вынесены в свои файлы. #}
