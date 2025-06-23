{% macro is_model_current() %}

    {% if model.get('version') and model.get('version') == model.get('latest_version') %}

        {{return(true)}}
    
    {# why does this not work? #}
    {% elif model.get('config').get('meta').get('deprecation_date')
        and model.get('config').get('meta').get('deprecation_date') < '2025-08-01' %}
        
        {{return(false)}}
        
    {% else %}
    
        {{return(true)}}
    
    {% endif %}

{% endmacro %}