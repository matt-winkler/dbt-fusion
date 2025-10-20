{% macro is_model_expired() %}
    
    {% set model_config_meta = model.get('config').get('meta') %}
    {% set model_version = model.get('version') %}
    {% set model_latest_version = model.get('latest_version') %}

    {% if execute and model_version and model_version < model_latest_version %}

      {% if model_config_meta.get('deprecation_date') < modules.datetime.datetime.now().strftime('%Y-%m-%d') %}
        
        {% do exceptions.raise_compiler_error('model ' ~ model.name ~ '_v' ~ model_version ~ ' is expired') %}
      
      {% endif %}
       
    {% endif %}

{% endmacro %}