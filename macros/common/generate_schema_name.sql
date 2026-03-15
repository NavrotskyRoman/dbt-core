{% macro generate_schema_name(schema_name, node) -%}
    {{ schema_name or target.schema }}
{%- endmacro %}
