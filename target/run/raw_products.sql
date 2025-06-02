
    
    
    
    create table MATT_W_ANALYTICS_DEV.dbt_mwinkler_raw.raw_products (SKU text,NAME text,TYPE text,PRICE integer,DESCRIPTION text)
  ;
    -- dbt seed --
    
            insert into MATT_W_ANALYTICS_DEV.dbt_mwinkler_raw.raw_products (SKU, NAME, TYPE, PRICE, DESCRIPTION) values
            (%s,%s,%s,%s,%s),(%s,%s,%s,%s,%s),(%s,%s,%s,%s,%s),(%s,%s,%s,%s,%s),(%s,%s,%s,%s,%s),(%s,%s,%s,%s,%s),(%s,%s,%s,%s,%s),(%s,%s,%s,%s,%s),(%s,%s,%s,%s,%s),(%s,%s,%s,%s,%s)
        

;
  