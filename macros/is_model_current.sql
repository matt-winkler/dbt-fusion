{% macro is_model_current() %}
   
    {% set meta_config = this.get('config').get('meta') %}
    {% do log(meta_config, info=true) %}

    {% if model.get('version') and model.get('version') == model.get('latest_version') %}
        {{return(true)}}
    
    {# why does this not work? #}
    {% elif meta_config.get('deprecation_date') 
       and meta_config.get('deprecation_date') < '2025-08-01' %}

        {{return(false)}}
        
    {% else %}
    
        {{return(true)}}
    
    {% endif %}

{% endmacro %}