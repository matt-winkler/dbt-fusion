

select case when eff_end_period_timestamp = timestamp('9999-12-31') then 'Y' else 'N' end as is_primary
       ,* 
from {{ref('snapshot_example_1_target')}}