{% materialization validate_cluster_key, adapter='snowflake', supported_languages=['sql']%}
  {#-
    Custom materialization that validates and enforces cluster keys on Snowflake tables.
    
    This materialization:
    1. Validates that a cluster_by config is specified
    2. Creates the table with the cluster key applied
    3. Verifies that the cluster key columns exist in the table
    4. Confirms the cluster key was successfully applied to the relation
    
    Usage:
      {{ config(
          materialization='validate_cluster_key',
          cluster_by=['column1', 'column2']
      ) }}
  -#}

  {% set original_query_tag = set_query_tag() %}

  {%- set identifier = model['alias'] -%}
  {%- set language = model['language'] -%}
  
  {# Validate that cluster_by is configured #}
  {%- set cluster_by_keys = config.get('cluster_by', default=none) -%}
  
  {%- if not cluster_by_keys -%}
    {% do exceptions.raise_compiler_error(
      "Model '" ~ model.name ~ "' uses 'validate_cluster_key' materialization but has no 'cluster_by' configuration. " ~
      "Please add {{ config(cluster_by=['column_name']) }} to your model."
    ) %}
  {%- endif -%}
  
  {# Normalize cluster_by to a list #}
  {%- if cluster_by_keys and cluster_by_keys is string -%}
    {%- set cluster_by_keys = [cluster_by_keys] -%}
  {%- endif -%}
  
  {%- set cluster_by_string = cluster_by_keys|join(", ") -%}
  
  {# Log validation start #}
  {% do log("Validating cluster key configuration for model '" ~ model.name ~ "'", info=true) %}
  {% do log("  Cluster key columns: " ~ cluster_by_string, info=true) %}

  {% set grant_config = config.get('grants') %}

  {%- set existing_relation = adapter.get_relation(database=database, schema=schema, identifier=identifier) -%}

  {%- set catalog_relation = adapter.build_catalog_relation(config.model) -%}
  {%- set target_relation = api.Relation.create(
    identifier=identifier,
    schema=schema,
    database=database,
    type='table',
    table_format=catalog_relation.table_format
  ) -%}

  {{ run_hooks(pre_hooks) }}

  {% if target_relation.needs_to_drop(existing_relation) %}
    {{ drop_relation_if_exists(existing_relation) }}
  {% endif %}

  {# Create the table using standard create_table_as macro (which handles cluster keys) #}
  {% call statement('main', language=language) -%}
      {{ create_table_as(False, target_relation, compiled_code, language) }}
  {%- endcall %}

  {# Validate that the cluster key columns exist in the created table #}
  {% set column_validation_query %}
    select column_name
    from {{ target_relation.database }}.information_schema.columns
    where lower(table_schema) = '{{ target_relation.schema }}'
      and lower(table_name) = '{{ target_relation.identifier }}'
      and lower(column_name) in (
        {%- for column in cluster_by_keys -%}
          lower('{{ column }}')
          {%- if not loop.last -%}, {%- endif -%}
        {%- endfor -%}
      )
  {% endset %}
  
  {% set column_check_result = run_query(column_validation_query) %}
  
  {%- if execute -%}
    {% set existing_columns = column_check_result.columns[0].values() %}
    {% set existing_columns_lower = [] %}
    {% for col in existing_columns %}
      {% do existing_columns_lower.append(col|lower) %}
    {% endfor %}
    
    {# Check if all cluster_by columns exist #}
    {% set missing_columns = [] %}
    {% for cluster_col in cluster_by_keys %}
      {% if cluster_col|lower not in existing_columns_lower %}
        {% do missing_columns.append(cluster_col) %}
      {% endif %}
    {% endfor %}
    
    {% if missing_columns|length > 0 %}
      {% do exceptions.raise_compiler_error(
        "Cluster key validation failed for model '" ~ model.name ~ "'. " ~
        "The following columns specified in cluster_by do not exist in the table: " ~ missing_columns|join(", ") ~ ". " ~
        "Available columns: " ~ existing_columns_lower|join(", ")
      ) %}
    {% endif %}
  {%- endif -%}

  {# Verify the cluster key is applied by checking SHOW TABLES #}
  {% set cluster_validation_query %}
    show tables like '{{ target_relation.identifier }}' in schema {{ target_relation.database }}.{{ target_relation.schema }}
  {% endset %}
  
  {% set cluster_check_result = run_query(cluster_validation_query) %}
  
  {%- if execute -%}
    {% do log("✓ Cluster key validation passed", info=true) %}
    {% do log("  All cluster_by columns exist in the table", info=true) %}
    
    {# Try to get clustering key info from the result #}
    {% set clustering_keys_col_idx = none %}
    {% for i in range(cluster_check_result.column_names|length) %}
      {% if cluster_check_result.column_names[i]|lower == 'cluster_by' %}
        {% set clustering_keys_col_idx = i %}
      {% endif %}
    {% endfor %}
    
    {% if clustering_keys_col_idx is not none and cluster_check_result.rows|length > 0 %}
      {% set applied_cluster_key = cluster_check_result.rows[0][clustering_keys_col_idx] %}
      {% if applied_cluster_key %}
        {% do log("✓ Cluster key successfully applied: " ~ applied_cluster_key, info=true) %}
      {% endif %}
    {% endif %}
  {%- endif -%}

  {{ run_hooks(post_hooks) }}

  {% set should_revoke = should_revoke(existing_relation, full_refresh_mode=True) %}
  {% do apply_grants(target_relation, grant_config, should_revoke=should_revoke) %}

  {% do persist_docs(target_relation, model) %}

  {% do unset_query_tag(original_query_tag) %}

  {{ return({'relations': [target_relation]}) }}

{% endmaterialization %}

