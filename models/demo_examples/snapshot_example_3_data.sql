with source_data as (
{% if var('time_period', '1') == '1' %}
select timestamp('2025-10-30 8:10:02') as event_time,	timestamp('2025-10-31 8:10:02') as as_of,   10046988 as rms_sku_num,	808 as store_num,	'REGULAR' as price_type,	38 as price_amount,	'USD' as currency union all
select timestamp('2025-10-30 8:10:02') as event_time,	timestamp('2025-11-03 11:00:00') as as_of,  10046988 as rms_sku_num,	808 as store_num,	'PROMOTION' as price_type,	28 as price_amount,	'USD' as currency union all
select timestamp('2025-10-30 8:10:02') as event_time,	timestamp('2025-12-04 9:30:00') as as_of,   10046988 as rms_sku_num,	808 as store_num,	'REGULAR' as price_type,	35 as price_amount,	'USD' as currency

{% elif var('time_period', '1') == '2' %}
select timestamp('2025-10-30 8:10:02') as event_time,	timestamp('2025-10-31 8:10:02') as as_of,   10046988 as rms_sku_num,	808 as store_num,	'REGULAR' as price_type,	38 as price_amount,	'USD' as currency union all
select timestamp('2025-10-30 8:10:02') as event_time,	timestamp('2025-11-03 11:00:00') as as_of,  10046988 as rms_sku_num,	808 as store_num,	'PROMOTION' as price_type,	28 as price_amount,	'USD' as currency union all
select timestamp('2025-10-30 8:10:02') as event_time,	timestamp('2025-12-04 9:30:00') as as_of,   10046988 as rms_sku_num,	808 as store_num,	'REGULAR' as price_type,	35 as price_amount,	'USD' as currency union all
select timestamp('2025-10-30 11:13:27') as event_time,	timestamp('2025-10-30 11:13:27') as as_of,   10046988 as rms_sku_num,	808 as store_num,	'REGULAR' as price_type,	35 as price_amount,	'USD' as currency union all
select timestamp('2025-10-30 11:13:27') as event_time,	timestamp('2025-11-15 11:20:00') as as_of,  10046988 as rms_sku_num,	808 as store_num,	'PROMOTION' as price_type,	27 as price_amount,	'USD' as currency union all
select timestamp('2025-10-30 11:13:27') as event_time,	timestamp('2025-12-10 9:30:00') as as_of,   10046988 as rms_sku_num,	808 as store_num,	'REGULAR' as price_type,	32 as price_amount,	'USD' as currency 

{% else %}
select timestamp('2025-10-30 8:10:02') as event_time,	timestamp('2025-10-31 8:10:02') as as_of,   10046988 as rms_sku_num,	808 as store_num,	'REGULAR' as price_type,	38 as price_amount,	'USD' as currency union all
select timestamp('2025-10-30 8:10:02') as event_time,	timestamp('2025-11-03 11:00:00') as as_of,  10046988 as rms_sku_num,	808 as store_num,	'PROMOTION' as price_type,	28 as price_amount,	'USD' as currency union all
select timestamp('2025-10-30 8:10:02') as event_time,	timestamp('2025-12-04 9:30:00') as as_of,   10046988 as rms_sku_num,	808 as store_num,	'REGULAR' as price_type,	35 as price_amount,	'USD' as currency union all
select timestamp('2025-10-30 11:13:27') as event_time,	timestamp('2025-10-30 11:13:27') as as_of,   10046988 as rms_sku_num,	808 as store_num,	'REGULAR' as price_type,	35 as price_amount,	'USD' as currency union all
select timestamp('2025-10-30 11:13:27') as event_time,	timestamp('2025-11-15 11:20:00') as as_of,  10046988 as rms_sku_num,	808 as store_num,	'PROMOTION' as price_type,	27 as price_amount,	'USD' as currency union all
select timestamp('2025-10-30 11:13:27') as event_time,	timestamp('2025-12-10 9:30:00') as as_of,   10046988 as rms_sku_num,	808 as store_num,	'REGULAR' as price_type,	32 as price_amount,	'USD' as currency union all
select timestamp('2025-10-30 20:10:02') as event_time,	timestamp('2025-10-30 20:10:02') as as_of,   10046988 as rms_sku_num,	808 as store_num,	'REGULAR' as price_type,	32 as price_amount,	'USD' as currency

{% endif %}
)

select  {{
         dbt_utils.generate_surrogate_key([
            'rms_sku_num',
            'store_num',
            'as_of'
            ])
        }} as sk_id, 
        {{
         dbt_utils.generate_surrogate_key([
            'rms_sku_num',
            'store_num'
            ])
        }} as business_key, 
        *
from source_data