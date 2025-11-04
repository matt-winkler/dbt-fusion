{% macro snapshot_example_2__remove_invalid_records(target_table, delete_column_name, delete_column_value)  %}
  
  delete from {{target_table}} where {{delete_column_name}} = {{delete_column_value}};

{% endmacro %}

{% macro snapshot_example_2__update_end_time(target_table, eff_end_column_name, eff_start_column_name, partition_key)  %}

  UPDATE
   {{target_table}} AS t
  SET
    {{eff_end_column_name}} = sub.new_value
  FROM
    (
        WITH
            cte_data AS (
                SELECT
                    dbt_scd_id,
                    coalesce(
                        {{eff_end_column_name}}, 
                        lead({{eff_start_column_name}}, 1) over (partition by {{partition_key}} order by dbt_updated_at)
                    ) as new_value
                    
                FROM
                    {{target_table}}
            )
        SELECT
            dbt_scd_id,
            new_value
        FROM
            cte_data
    ) AS sub
  WHERE
    t.dbt_scd_id = sub.dbt_scd_id
    and t.{{eff_end_column_name}} is null; 

{% endmacro %}


{% macro snapshot_example_3__update_end_time(target_table, eff_end_column_name, eff_start_column_name, join_key, partition_key)  %}

  UPDATE
   {{target_table}} AS t
  SET
    {{eff_end_column_name}} = sub.new_value
  FROM
    (
        WITH
            cte_data AS (
                SELECT
                    {{join_key}},
                    lead({{eff_start_column_name}}, 1) over (partition by {{partition_key}} order by {{eff_start_column_name}}) as new_value
                    
                FROM
                    {{target_table}}
            )
        SELECT
            {{join_key}},
            new_value
        FROM
            cte_data
    ) AS sub
  WHERE
    t.{{join_key}} = sub.{{join_key}} 

{% endmacro %}