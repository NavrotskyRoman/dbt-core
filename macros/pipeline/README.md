# dbt_core pipeline macros

Общие макросы для хуков пайплайна. Используются в `dbt_project.yml` проектов через `on-run-start` / `on-run-end`.

- **create_external_tables.sql** — `create_external_tables(select)`  
  Обёртка над `dbt_external_tables.stage_external_sources(select=...)`. Используется в `on-run-start` с `vars.external_tables`.

- **drop_deprecated_tables.sql** — `drop_deprecated_tables()`  
  Читает `vars.deprecated_tables` (список `"schema.identifier"`) и дропает эти relation'ы. Вызывается в `on-run-end`.

- **drop_datasets.sql** — `drop_datasets(dataset_name=None)`  
  С аргументом `dataset_name` (через `--args`) дропает один датасет; иначе читает `vars.drop_datasets` и дропает перечисленные.

- **pipelines_modes_control.sql** — `pipeline_on_run_start()`, `pipeline_on_run_end()`  
  Единственные макросы, которые указываются в `dbt_project.yml`. Внутри читают `vars.pipeline_mode`, `vars.external_tables`, `vars.deprecated_tables`, `vars.drop_datasets` и вызывают остальные макросы.

Подробнее: см. методологию в `.cursor/rules/dbt.md` в репозитории платформы и `vars` в `dbt_project.yml` каждого проекта.
