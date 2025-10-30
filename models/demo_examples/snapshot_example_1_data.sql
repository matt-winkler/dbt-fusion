with source_data as (
{% if var('time_period', '1') == '1' %}
select 123 as npin,	1 as upc_num,	345 as partner_identifier,	'Y' as is_primary,	timestamp('2025-10-14') as event_timestamp

{% elif var('time_period', '1') == '2' %}
select 123 as npin,	1 as upc_num,	345 as partner_identifier,	'N' as is_primary,	timestamp('2025-10-14') as event_timestamp union all
select 123 as npin,	1 as upc_num,	345 as partner_identifier,	'Y' as is_primary,	timestamp('2025-10-15') as event_timestamp 

{% else %}
select 123 as npin,	1 as upc_num,	345 as partner_identifier,	'N' as is_primary,	timestamp('2025-10-14') as event_timestamp union all
select 123 as npin,	1 as upc_num,	345 as partner_identifier,	'N' as is_primary,	timestamp('2025-10-15') as event_timestamp union all
select 123 as npin,	1 as upc_num,	345 as partner_identifier,	'Y' as is_primary,	timestamp('2025-10-16') as event_timestamp 
{% endif %}
)

select npin,
       upc_num,
       partner_identifier,
       event_timestamp,
       {{
        dbt_utils.generate_surrogate_key([
            'npin',
            'upc_num',
            'partner_identifier'
            ])
        }} as sk_id
from source_data