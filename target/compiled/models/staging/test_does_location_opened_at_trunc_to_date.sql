WITH
              	MATT_W_ANALYTICS_DEV_dbt_mwinkler_raw_raw_stores as (SELECT   CAST(ID AS VARCHAR) AS ID,
  CAST(NAME AS VARCHAR) AS NAME,
  CAST(OPENED_AT AS TIMESTAMP_NTZ(9)) AS OPENED_AT,
  CAST(TAX_RATE AS FLOAT) AS TAX_RATE  FROM VALUES (1, 'Vice City', '2016-09-01T00:00:00', 0.2), (2, 'San Andreas', '2079-10-27T23:59:59.9999', 0.1) AS t(ID, NAME, OPENED_AT, TAX_RATE)),
  	MATT_W_ANALYTICS_DEV_dbt_mwinkler_stg_locations_expect as (SELECT   CAST(LOCATION_ID AS VARCHAR) AS LOCATION_ID,
  CAST(LOCATION_NAME AS VARCHAR) AS LOCATION_NAME,
  CAST(TAX_RATE AS FLOAT) AS TAX_RATE,
  CAST(OPENED_DATE AS DATE) AS OPENED_DATE  FROM VALUES (1, 'Vice City', 0.2, '2016-09-01'), (2, 'San Andreas', 0.1, '2079-10-27') AS t(LOCATION_ID, LOCATION_NAME, TAX_RATE, OPENED_DATE)),
  	MATT_W_ANALYTICS_DEV_dbt_mwinkler_stg_locations_actual as (with

source as (

    select * from MATT_W_ANALYTICS_DEV_dbt_mwinkler_raw_raw_stores

),

renamed as (

    select

        ----------  ids
        id as location_id,

        ---------- text
        name as location_name,

        ---------- numerics
        tax_rate,

        ---------- timestamps
        cast(opened_at as date) as opened_date

    from source

)

select * from renamed
)
            SELECT location_id, location_name, opened_date, tax_rate, 'actual' AS actual_or_expected FROM MATT_W_ANALYTICS_DEV_dbt_mwinkler_stg_locations_actual 
            UNION ALL 
            SELECT location_id, location_name, opened_date, tax_rate, 'expected' AS actual_or_expected FROM MATT_W_ANALYTICS_DEV_dbt_mwinkler_stg_locations_expect