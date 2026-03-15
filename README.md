# dbt-core

Пакет общих макросов для dbt-проектов платформы. Не запускается отдельно — подключается как зависимость в других проектах через `packages.yml` (git).

## Содержимое

- **macros/pipeline/** — хуки пайплайна: external tables, drop deprecated tables, drop datasets, режимы `pipeline_mode`.
- **macros/common/** — общие макросы (например `generate_schema_name`).

## Подключение в проекте

В корне dbt-проекта (lp_crm, payments_nt и т.д.) в `packages.yml`:

```yaml
packages:
  - git: "https://github.com/YOUR_ORG/dbt-core.git"
    revision: main  # или тег, например v0.1.0
  # остальные пакеты (dbt_external_tables и т.д.)
```

После добавления зависимости:

```bash
dbt deps
```

В `dbt_project.yml` проекта оставьте вызовы макросов из пакета:

```yaml
on-run-start:
  - "{{ pipeline_on_run_start() }}"
on-run-end:
  - "{{ pipeline_on_run_end() }}"
```

И задайте `vars`: `pipeline_mode`, `external_tables`, `deprecated_tables`, `drop_datasets` по необходимости (см. методологию в `.cursor/rules/dbt.md`).

## Требования

- Проекты, использующие `create_external_tables` / `pipeline_on_run_start`, должны также подключать пакет **dbt-labs/dbt_external_tables** в своём `packages.yml`.

## Версионирование

При выносе в отдельный репозиторий рекомендуется тегировать релизы (например `v0.1.0`) и в `packages.yml` указывать `revision: v0.1.0` для стабильных сборок.

## License

License: MIT. See [LICENSE](LICENSE).
