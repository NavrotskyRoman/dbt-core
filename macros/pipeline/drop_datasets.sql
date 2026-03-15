{% macro drop_datasets(dataset_name=None) %}
  {# 1. Собираем список датасетов: либо из аргумента, либо из vars.drop_datasets #}
  {% if dataset_name %}
    {# Вызов: dbt run-operation drop_datasets --args '{"dataset_name": "no_schema"}' #}
    {% set datasets = [dataset_name] %}
  {% else %}
    {# Вызов без args: dbt run-operation drop_datasets,
       список берём из vars.drop_datasets (строка или список) #}
    {% set cfg = var('drop_datasets', []) %}
    {% if cfg is string %}
      {% set datasets = [cfg] %}
    {% else %}
      {% set datasets = cfg %}
    {% endif %}
  {% endif %}

  {# 2. Пустой список — просто логируем и выходим #}
  {% if datasets | length == 0 %}
    {{ log("drop_datasets: no datasets specified (empty args and vars:drop_dataset)", info=True) }}
    {% do return(None) %}
  {% endif %}

  {# 3. Дропаем каждый датасет из списка #}
  {% for ds in datasets %}
    {% if not ds %}
      {{ log("drop_datasets: skip empty dataset name in list", info=True) }}
    {% else %}
      {{ log("drop_datasets: dropping dataset " ~ target.database ~ "." ~ ds, info=True) }}
      {% set schema_relation = adapter.Relation.create(
        database=target.database,
        schema=ds
      ) %}
      {% do adapter.drop_schema(schema_relation) %}
    {% endif %}
  {% endfor %}
{% endmacro %}
