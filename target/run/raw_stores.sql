
    
    
    
    create table MATT_W_ANALYTICS_DEV.dbt_mwinkler_raw.raw_stores (ID text,NAME text,OPENED_AT timestamp without time zone,TAX_RATE integer)
  ;
    -- dbt seed --
    
            insert into MATT_W_ANALYTICS_DEV.dbt_mwinkler_raw.raw_stores (ID, NAME, OPENED_AT, TAX_RATE) values
            (%s,%s,%s,%s),(%s,%s,%s,%s),(%s,%s,%s,%s),(%s,%s,%s,%s),(%s,%s,%s,%s),(%s,%s,%s,%s)
        

;
  