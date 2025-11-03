
select * 
from {{ref('snapshot_example_2_target')}}  
where (
    dbt_valid_to = timestamp('9999-12-31 23:59:59') or 
    (end_time > deploy_start_time)
)