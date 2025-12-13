{# 
This model is used to validate the cluster key validation macro.
It creates a table with a cluster key and then validates that the cluster key is applied.
#}

{{ 
    config(
        materialized='validate_cluster_key',
        cluster_by=['id']
        ) 
}}

{# post_hook=["ALTER TABLE {{ this }}  CLUSTER BY (id);"] #}

select 1 as id