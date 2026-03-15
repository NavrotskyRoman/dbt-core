# Правила ведения dbt

Слои: **raws → staging → intermediate → marts**. Один датасет/схема на слой. Конфиг `+schema` в `dbt_project.yml` по папкам.

**Датасеты в BigQuery**: **raws**, **intermediate**, **staging**, **seeds**, **snapshots**, **utils** — без приставок доменов (один датасет на слой). Поскольку все модели слоя попадают в один датасет, **во всех неймингах кроме marts обязательно добавляем домен** (см. формат ниже). **Marts** — датасеты с доменами: `marts_core`, `marts_finance` и т.д.; там домен в имени датасета, в имени модели можно без домена.

**Правило домена и сабдомена (для всех моделей кроме marts):**
- **Домен** — источник/продукт (напр. `lp_crm`). **Сабдомен** — область данных или тип выгрузки внутри домена (напр. `st_ord` = stats_orders, ещё могут быть orders, contacts и т.д.).
- В именах **домена дефис не используется** (только буквы, цифры, underscore).
- Если есть сабдомен — фиксируем его через `__`: **`<префикс>_<домен>__<сабдомен>__<остальное>`**. Без сабдомена: **`<префикс>_<домен>__<остальное>`**.
- **Только один уровень вложенности**: домен + опционально один сабдомен, не глубже.
- Парсинг: по первому `__` отделяем префикс_домен от остального; при наличии сабдомена следующий `__` отделяет сабдомен от остального.

## Префиксы моделей (нейминг)

Для **всех моделей кроме marts** — префикс по слою **и домен в имени** (формат как в staging):

| Префикс | Слой | Формат имени (домен обязателен; при сабдомене — `__сабдомен__` перед остальным) |
|---------|------|----------------------------------------------------------------------------------|
| `raw_`  | raws | `raw_<домен>__<таблица>` или `raw_<домен>__<сабдомен>__<таблица>` |
| `base_` | staging (точка входа) | `base_<домен>__<таблица>` или `base_<домен>__<сабдомен>__<таблица>` |
| `stg_`  | staging (шаги цепочки) | `stg_<домен>__<имя>` или `stg_<домен>__<сабдомен>__<имя>` |
| `seed_` | seeds | `seed_<домен>__<название>` или `seed_<домен>__<сабдомен>__<название>` |
| `int_`  | intermediate | `int_<домен>__<имя>` или `int_<домен>__<сабдомен>__<имя>` |
| `util_` | utils | `util_<домен или назначение>__<имя>` или с `__<сабдомен>__` при необходимости |
| `snap_` | snapshot | `snap_<source>__<table>` или `snap_<source>__<сабдомен>__<table>` (источник = домен) |

В **marts** — префиксы по типу модели данных (домен в датасете, в имени модели не дублируем):

| Префикс | Тип |
|---------|-----|
| `fct_`  | fact (таблица фактов: события, транзакции) |
| `dim_`  | dimension (таблица измерений: справочники) |

Примеры: `fct_products_orders`, `dim_country`, `dim_customer`.

## Папки (домен = устойчивая привязка)

Чтобы было устойчиво, **для какого домена** что предназначено — задаём папкой (и при необходимости именем).

- **raws/<домен или сабдомен>/** — только объявление источников (external, сырые таблицы) **по домену/сабдомену**. Внутри: файлы вида `_raws_<домен>__<сабдомен>.yml` (или `_raws_<домен>.yml`, если без сабдомена). Пример: `raws/stats_orders/_raws_lp_crm__stats_orders.yml`.
- **staging/<домен>/** — цепочка моделей от source до последнего шага перед marts. Внутри: `__staging_sources.yml` (если нужны source-ссылки для этого домена), модели.
- **intermediate/<домен>/** — джойны, сводки по домену.
- **marts/<домен>/** — готовые витрины (имена с префиксами `fct_` / `dim_`). Внутри: `__marts_sources.yml` (если нужны ref на другие слои в доке), модели.
- **seeds/<домен>/** — сиды по домену. Имя файла с доменом в нейминге: `seed_<домен>__<название>.csv` (напр. `seed_shopify__product_name_mapping.csv`). В BigQuery датасет один — `seeds`; домен в имени таблицы обязателен.
- **utils/<домен или назначение>/** — утилиты по домену/назначению. Имя модели: `util_<домен или назначение>__<имя>.sql` (напр. `util_stats_order_products__time_spine_daily.sql`). В BigQuery датасет один — `utils`; домен/назначение в имени таблицы обязателен.
- Файлы sources: **двойное `__` в начале** — правило для YAML с источниками: `__<слой>_sources.yml`. Так сразу видно, что это конфиг, а не модель; в листинге идут первыми.

## Именование моделей

- **Staging** (цепочка от source): точка входа — `base_<домен>__<таблица>.sql` или `base_<домен>__<сабдомен>__<таблица>.sql`; далее шаги — `stg_<домен>__<имя>.sql` или `stg_<домен>__<сабдомен>__<имя>.sql`. Домен без дефиса; сабдомен — один уровень, через `__`.
- **Intermediate**: `int_<домен>__<имя>.sql` или `int_<домен>__<сабдомен>__<имя>.sql` (напр. `int_lp_crm__st_ord__enriched.sql`).
- **Seeds**: `seed_<домен>__<название>.csv` или `seed_<домен>__<сабдомен>__<название>.csv` (напр. `seed_lp_crm__st_ord__product_name_mapping.csv`).
- **Utils**: `util_<домен или назначение>__<имя>.sql` или с `__<сабдомен>__` при необходимости (напр. `util_lp_crm__st_ord__time_spine_daily.sql`).
- **Snapshot**: `snap_<source>__<table>.sql` или `snap_<source>__<сабдомен>__<table>.sql` (источник = домен).
- **Marts**: префикс `fct_` или `dim_` + имя витрины без домена (домен в датасете): `fct_products_orders.sql`, `dim_country.sql`. Правило домена/сабдомена к marts не применяется.
- Везде (кроме marts): только `ref()` и `source()`, без хардкода схем. Теги в `config(tags=[...])`: слой, домен, сущность.

## Ступенчатые преобразования в staging

- Одна staging-модель = одно логическое преобразование (одна «ступень» пайплайна).
- Если появляется отдельная самодостаточная логика (нормализация справочников, маппинги, сложные фильтры, агрегаты),
  выносим её в отдельный stg-шаг с именем `stg_<домен>__<сабдомен>__<from>-<to>.sql` (или без сабдомена).
- Пример для домена `lp_crm`, сабдомен `st_ord` (stats_orders_products):
  - `base_lp_crm__st_ord__raw_lp_crm_soe_ext` — точка входа: приведение типов сырых данных от source.
  - `stg_lp_crm__st_ord__raw_so_ext-lts_uniq` — дедупликация и подготовка массивов продуктов.
  - `stg_lp_crm__st_ord__lts_uniq-prod_arr` — подготовка массивов.
  - `stg_lp_crm__st_ord__prod_arr-prod_orders` — разворот массивов в строки (`products_array` → строки товаров).
  - `stg_lp_crm__st_ord__prod_orders-name_norm` — нормализация `product_name` через seed-таблицу `product_name_mapping`.

## Пример структуры

```
dbt/
├── dbt_profiles/
│   ├── profiles.yml
│   └── credentials/
│       └── secret.json
│
└── dbt_project/
    ├── models/
    │   ├── raws/
    │   │   ├── shopify/
    │   │   │   └── _raws_shopify.yml                 # источники домена shopify
    │   │   └── stats_orders/
    │   │       └── _raws_lp_crm__stats_orders.yml    # источники домена lp_crm, сабдомен stats_orders
    │   ├── staging/
    │   │   ├── shopify/                    # домен без сабдомена
    │   │   │   ├── base_shopify__orders.sql
    │   │   │   └── stg_shopify__orders.sql
    │   │   ├── lp_crm/                     # домен с сабдоменом st_ord
    │   │   │   └── stats_orders_products/
    │   │   │       ├── base_lp_crm__st_ord__raw_lp_crm_soe_ext.sql
    │   │   │       └── stg_lp_crm__st_ord__raw_so_ext-typed.sql
    │   │   └── stripe/
    │   │       ├── base_stripe__payments.sql
    │   │       └── stg_stripe__payments.sql
    │   ├── intermediate/
    │   │   ├── orders/
    │   │   │   ├── int_orders__enriched.sql
    │   │   │   └── int_orders__customer_join.sql
    │   │   └── users/
    │   │       └── int_users__lifetime_value.sql
    │   └── marts/
    │       ├── core/
    │       │   ├── dim_users.sql
    │       │   ├── dim_products.sql
    │       │   └── fct_orders.sql
    │       ├── finance/
    │       │   └── fct_revenue.sql
    │       └── marketing/
    │           └── fct_campaign_performance.sql
    │   └── utils/
    │       ├── stats_order_products/
    │       │   └── util_lp_crm__st_ord__time_spine_daily.sql
    │       └── tech_tables/
    │           └── util_tech_tables__date_spine.sql
    │
    ├── snapshots/
    │   ├── finance/
    │   │   └── snap_stripe__payments.sql
    │   └── product/
    │       └── snap_app__users.sql
    │
    ├── seeds/
    │   ├── shopify/
    │   │   └── seed_shopify__product_name_mapping.csv
    │   └── stats_orders/
    │       └── seed_lp_crm__st_ord__product_name_mapping.csv
    │
    ├── macros/
    │   ├── utils/
    │   └── tests/
    │
    ├── tests/
    │   └── marts/
    │       └── <домен>/
    │           └── assert_*.sql
    │
    ├── analyses/
    ├── docs/
    │
    ├── dbt_project.yml
    └── packages.yml
```

(Sources в папке домена: `_raws_<домен>__<сабдомен>.yml` (или без сабдомена), `_staging_<домен>__<сабдомен>.yml`, `_marts_<домен>__<сабдомен>.yml`. Staging — base_ / stg_, при сабдомене — `__сабдомен__` в имени. Marts — dim_ / fct_ по домену, snapshots — `snap_<source>__<table>`. Домен и сабдомен без дефиса, один уровень вложенности.)

## Как это выглядит в BigQuery

Один слой dbt → один датасет. **Имена датасетов — без приставок доменов**: `raws`, `staging`, `intermediate`, `seeds`, `snapshots`, `utils`. Домен в общих датасетах задаётся **именем таблицы**: формат `<префикс>_<домен>__<остальное>` или при сабдомене `<префикс>_<домен>__<сабдомен>__<остальное>` (домен/сабдомен без дефиса). В `dbt_project.yml` задаём `+schema` соответственно.

**Raws:** external-таблицы слоя raws создаём и обновляем **через dbt** с пакетом `dbt_external_tables`.  
В YAML (`raws/<домен или сабдомен>/_raws_<домен>__<сабдомен>.yml`) объявляем `sources` с блоком `external:` (location в GCS, options, partitions, columns).  
Дальше есть два варианта:
- Явный запуск: `dbt run-operation stage_external_sources` (создаёт/пересоздаёт все external-таблицы по описаниям).
- Автоматический запуск в начале пайплайна: проектный макрос `pipeline_on_run_start()` из `macros/pipeline/pipeline_modes_control.sql`, который внутри вызывает `create_external_tables()` или `stage_external_sources()` в зависимости от `vars.pipeline_mode` / `vars.external_tables` (см. `dbt_project.yml`).  
Нейминг таблиц сырого слоя в BigQuery: **`raw_<домен>__<таблица>`** — по тому же принципу «домен в имени», чтобы в общем датасете было однозначно. Пример ниже.

```
<project_id>/
├── raws/                         # таблицы создаются/обновляются через dbt_external_tables (stage_external_sources)
│   ├── raw_shopify__orders       # пример имён: raw_<домен>__<таблица>
│   ├── raw_shopify__customers
│   └── raw_stripe__payments
├── staging/
│   ├── base_shopify__orders
│   ├── stg_shopify__orders
│   ├── base_lp_crm__st_ord__raw_lp_crm_soe_ext
│   ├── stg_lp_crm__st_ord__raw_so_ext-typed
│   ├── base_stripe__payments
│   └── stg_stripe__payments
├── intermediate/
│   ├── int_orders__enriched
│   ├── int_orders__customer_join
│   └── int_users__lifetime_value
├── marts_crm/                   # marts — с доменами обязательно
│   ├── dim_users
│   ├── dim_products
│   └── fct_orders
├── marts_finance/
│   └── fct_revenue
├── marts_marketing/
│   └── fct_campaign_performance
├── snapshots/
│   ├── snap_stripe__payments
│   └── snap_app__users
├── seeds/                        # домен в имени обязателен; при сабдомене — __сабдомен__
│   ├── seed_shopify__product_name_mapping
│   └── seed_lp_crm__st_ord__product_name_mapping
└── utils/                        # домен/назначение в имени обязателен
    ├── util_lp_crm__st_ord__time_spine_daily
    └── util_tech_tables__date_spine
```

Имена таблиц/вью = имена моделей dbt. Во всех слоях кроме marts в имени обязательно домен (без дефиса); при сабдомене — `__сабдомен__` перед остальным: `stg_shopify__orders`, `stg_lp_crm__st_ord__raw_so_ext-typed`, `seed_lp_crm__st_ord__product_name_mapping`. Marts: датасет с доменом (`marts_core`), имя таблицы без домена (`fct_orders`, `dim_users`).

## Slim CI (важная оптимизация)

В CI используем **state:modified+** и **defer**: собираются только изменённые модели, остальные подставляются из production.

**Как работает defer:** если модель не изменена, CI не строит её, а подставляет артефакт из prod (например `marts_crm.dim_customers` берётся из production).

**Зачем:** при 600 моделях и 4 изменённых CI строит только 4 модели, остальные — из prod. Сильно ускоряет пайплайн.

**Полный pipeline CI:**

1. `dbt deps`
2. `dbt seed`
3. `dbt build --select state:modified+ --defer --state prod_artifacts`
4. `dbt test`

(Артефакты prod должны быть доступны в `prod_artifacts` для сравнения state.)

## Остальное

- В начале модели — `config(materialized=..., tags=[...])`. Staging/intermediate — обычно `view`, marts — `table`/`view`.
- Источники в YAML внутри папки домена по слою: `_raws_<домен>__<сабдомен>.yml`, `_staging_<домен>__<сабдомен>.yml`, `_marts_<домен>__<сабдомен>.yml`. External — в raws с `external:` (через пакет `dbt_external_tables` и `stage_external_sources`).
- Staging/intermediate не зависят от marts; циклов нет. Перед коммитом: `dbt compile`, `dbt run`, при необходимости `dbt test`.

### Режимы обслуживания пайплайна (vars.pipeline_mode)

В `dbt_project.yml` проекта lp_crm заведена переменная `vars.pipeline_mode`, которая управляет тем, какие «сервисные» действия выполняются в `on-run-start` / `on-run-end`:

- `"full"` (дефолт):  
  - `on-run-start` вызывает `create_external_tables(var('external_tables', []))` → создаёт/обновляет external-таблицы, указанные в `vars.external_tables`.  
  - `on-run-end` вызывает `drop_deprecated_tables()` и `drop_datasets()` → удаляет устаревшие модели и датасеты.
- `"no_external"`:  
  - external-таблицы **не** пересоздаются;  
  - `drop_deprecated_tables()` и `drop_datasets()` выполняются.
- `"external_only"`:  
  - создаются/обновляются только указанные в `vars.external_tables` external-таблицы;  
  - дропы deprecated/датасетов выполняются как обычно.
- `"external_all"`:  
  - `on-run-start` вызывает `dbt_external_tables.stage_external_sources()` без select → создаёт/обновляет **все** external-таблицы, описанные в sources;  
  - `on-run-end` вызывает `drop_deprecated_tables()` и `drop_datasets()` как в `"full"`.
- `"no_drops"`:  
  - external-таблицы создаются/обновляются как в `"full"` (по `vars.external_tables`);  
  - `drop_deprecated_tables()` и `drop_datasets()` **не** вызываются.
- `"dev"`:  
  - external-таблицы **не** пересоздаются;  
  - `drop_deprecated_tables()` и `drop_datasets()` **не** вызываются (максимально безопасный режим для локальной разработки).

Режим можно переопределить на запуске через `--vars`, например:

```bash
dbt run --vars '{pipeline_mode: "no_external"}'
dbt run --vars '{pipeline_mode: "external_only", external_tables: ["raw_lp_crm.stats_orders_external"]}'
dbt run --vars '{pipeline_mode: "external_all"}'
dbt run --vars '{pipeline_mode: "no_drops"}'
dbt run --vars '{pipeline_mode: "dev"}'
```


---CICD

### Удаление переименованных / неиспользуемых моделей (макрос `drop_deprecated_tables`)

- **Принцип**: ничего не удаляем «по поиску по имени»; всегда есть **явный список** таблиц, которые можно дропать.  
  В `dbt_project.yml` проекта создаём переменную:
  ```yaml
  vars:
    deprecated_tables:
      - "schema.table_name"
      - "staging.base_lp_crm__stats_orders__external-typed"
      # ...
  ```
  Формат всегда `"<schema>.<identifier>"`, где `schema` — датасет в BigQuery (`staging`, `intermediate`, `utils`, `marts_*` и т.д.), `identifier` — имя модели dbt.

- **Макрос `drop_deprecated_tables`** (определён в `macros/pipeline/drop_deprecated_tables.sql`):
  - Читает `var('deprecated_tables', [])`.
  - Для каждой записи через `adapter.get_relation` находит relation в БД и дропает его через `adapter.drop_relation`.
  - Если relation не найден — только логирует, без ошибки.

- **Запуск в lp_crm**:
  - Автоматически после `dbt run` / `dbt build` через хук `on-run-end` в `dbt_project.yml`:
    ```yaml
    on-run-end:
      - "{{ drop_deprecated_tables() }}"
    ```
  - Либо вручную:
    ```bash
    dbt run-operation drop_deprecated_tables
    ```

- **Переименование модели**:
  1. Переименовали файл и/или модель в коде.
  2. Добавили **старое** имя таблицы в `vars.deprecated_tables` (в формате `schema.old_name`).
  3. Прогнали `dbt run` / `dbt build` (новая модель создастся под новым именем, старая будет удалена макросом).

- **Удаление по тегу (опционально)**:
  - Отдельный макрос может собирать список моделей по тегу (`tag:deprecated`, `tag:tmp` и т.п.), строить по ним `schema.identifier` и передавать в `drop_deprecated_tables`.  
  - Правило: в таких макросах всё равно должен быть **явный фильтр по проекту/домену** (по имени схемы/таблицы), чтобы не зацепить модели других проектов в общих датасетах.

### Удаление датасетов (schema) в BigQuery (макрос `drop_datasets`)

- Для разового удаления целого датасета (например, ошибочно созданного `no_schema`) используем макрос `drop_datasets` (определён в `macros/pipeline/drop_datasets.sql`):
  - В `dbt_project.yml`:
    ```yaml
    vars:
      drop_datasets:
        - "no_schema"
        # - "old_dataset"
    ```
  - Макрос `drop_datasets`:
    - Берёт список `var('drop_datasets', [])` или аргумент `dataset_name` из `--args`.
    - Для каждого имени создаёт relation через `adapter.Relation.create(database=target.database, schema=dataset_name)` и дропает его через `adapter.drop_schema`.
    - Работает только по явно указанным датасетам.

- **Запуск**:
  ```bash
  # Использовать список из vars.drop_datasets
  dbt run-operation drop_datasets

  # Разово удалить конкретный датасет без правки vars
  dbt run-operation drop_datasets --args '{"dataset_name": "no_schema"}'
  ```

- **Безопасность**:
  - Удаление датасетов обычно оставляем под ручной/осознанный запуск (через `run-operation`).
  - В проекте lp_crm для удобства также добавлен вызов `drop_datasets()` в `on-run-end`, но список `vars.drop_datasets` должен быть всегда явным и аккуратно поддерживаться.


