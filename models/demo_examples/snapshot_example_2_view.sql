
with data as (
select *,
       coalesce(end_time, lead(deploy_start_time, 1) over (partition by sku_id, channel order by dbt_updated_at)) as revised_end_time
from {{ref('snapshot_example_2_target')}} 
)
select * 
from data 
where to_delete = 0 
and   (dbt_valid_to = timestamp('9999-12-31 23:59:59')
or    (revised_end_time > deploy_start_time))