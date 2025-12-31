# dbt AI Tools

A collection of tools to assess and enhance dbt projects for AI/LLM consumption.

## Tools

### 🎯 Semantic Layer Readiness Assessment

**Script:** `assess_semantic_readiness.py`

Evaluates whether your dbt project is ready to build a semantic layer that will be consumed by LLMs. The assessment covers five key dimensions with emphasis on temporal data, freshness, and ownership:

1. **Temporal Consistency (30%)** - % of fact models with clear, consistent temporal columns
2. **Column Documentation (20%)** - % of columns with meaningful descriptions
3. **Relationship Documentation (20%)** - % of mart models with at least one relationship test
4. **Ownership Metadata (15%)** - % of mart models with owner metadata defined
5. **Source Freshness Configuration (15%)** - % of sources with freshness checks configured

#### Key Features

- **Temporal-First Design**: 30% weight on temporal consistency - critical for time-based LLM queries
- **Structured Metadata**: Checks `config.meta` for explicit field designations at model and column levels
  - Mart layer: `layer`, `type`, or `model_type` (model-level)
  - Temporal fields: `temporal_field`, `time_field`, `date_field`, `event_time`, `event_date` (model-level) or `is_temporal_field` (column-level)
  - Measures: `measures`, `measure_columns`, `metric_columns` (model-level list) or `is_measure` (column-level)
  - Grain: `grain` or `granularity` (model-level)
  - Ownership: `owner`, `owners`, `team`, `contact` (model-level only)
- **Smart Relationship Detection**: Uses dbt `relationships` tests to identify validated foreign keys
- **Data Governance Focus**: 30% combined weight on freshness and ownership for production-ready AI systems
- **Source Freshness Analysis**: Evaluates whether sources have `warn_after` and `error_after` thresholds configured
- **Backward Compatible**: Falls back to naming conventions and descriptions if metadata not present
- **Actionable Recommendations**: Suggests specific dbt tests and configurations to add for better data quality

#### Usage

```bash
# First, ensure your dbt project has a compiled manifest
cd /path/to/your/dbt/project
dbt compile  # or dbt run

# Run the assessment (uses default config)
uv run experiments/dbt_ai_tools/assess_semantic_readiness.py target/manifest.json

# Or with python directly
python experiments/dbt_ai_tools/assess_semantic_readiness.py target/manifest.json

# Run with custom config file
uv run experiments/dbt_ai_tools/assess_semantic_readiness.py target/manifest.json my_custom_config.yaml
```

#### Customizing Assessment Criteria

The tool uses `assessment_config.yaml` for pattern matching. You can customize it to match your project's conventions.

**Configuration Sections:**

1. **`mart_identification`** - How to identify mart/final layer models
   - `prefixes`: Model name prefixes (e.g., `fct_`, `dim_`)
   - `folders`: Folder names containing marts (e.g., `marts/`, `gold/`)
   - `meta_fields`: Config.meta fields to check (e.g., `layer`, `type`)
   - `meta_indicators`: Values indicating mart layer (e.g., `fact`, `dim`)

2. **`fact_identification`** - How to identify fact models (subset of marts)
   - `prefixes`: Fact-specific name prefixes (e.g., `fct_`, `fact_`)
   - `folders`: Folder names containing facts (e.g., `facts/`)
   - `meta_indicators`: Values indicating fact table (e.g., `fct`, `fact`)

3. **`grain_documentation`** - Keywords indicating grain is documented
   - `keywords`: Phrases like "one row per", "grain", etc.

4. **`temporal_columns`** - How to identify date/time columns
   - `patterns`: Column name patterns (e.g., `_date`, `_at`)
   - `model_meta_fields`: Model-level meta fields (e.g., `temporal_field`)

5. **`measure_identification`** - How to identify measure columns
   - `keywords`: Column name keywords (e.g., `total`, `revenue`)
   - `model_meta_fields`: Model-level meta fields (e.g., `measures`)

6. **`ownership_metadata`** - How to identify ownership information
   - `meta_fields`: Config.meta fields for ownership (e.g., `owner`, `team`)

**Example: Customize for your company**

Edit `assessment_config.yaml` or create your own:

```yaml
mart_identification:
  prefixes:
    - fct_
    - dim_
    - my_company_mart_    # Your custom prefix
  folders:
    - marts
    - data_products       # Your custom folder
  meta_fields:
    - layer
    - my_custom_layer_field  # Your custom meta field

measure_identification:
  keywords:
    - total
    - kpi_                # Your custom metric prefix
    - metric_
  model_meta_fields:
    - measures
    - kpis                # Your custom meta field

ownership_metadata:
  meta_fields:
    - owner
    - owner_email         # Your custom ownership field
    - responsible_team
```

Then run with your custom config:
```bash
python assess_semantic_readiness.py target/manifest.json my_config.yaml
```

#### Output

The tool generates:
- Overall readiness score (0-100%)
- Detailed breakdown by dimension
- Specific findings for your project
- Prioritized recommendations (Critical/Important/Nice-to-have)
- Next steps based on your score
- A saved report file: `semantic_layer_readiness_report.txt`

#### Example Output

```
🎯 SEMANTIC LAYER READINESS ASSESSMENT
================================================================================

Overall Score: 62.5/100 (62.5%)
Overall Grade: 🟡 NEEDS PREPARATION
Assessment: Address key gaps before building semantic layer.

1. Temporal Consistency (30%)
Score: 18.0/30 (60.0%) - 🟡 Needs Prep

Findings:
  • Mart models with date columns: 6/8 (75%)
  • Date column naming inconsistent across models

Recommendations:
  • ⚠️ Standardize date column naming across models (e.g., always use *_date or *_at)

2. Column Documentation Quality (20%)
Score: 14.0/20 (70.0%) - 🟡 Needs Prep

Findings:
  • Column documentation: 45/67 (67%)
  • ✓ Good unit documentation for measures

...

4. Ownership Metadata (13%)
Score: 0.0/13 (0.0%) - 🔴 Not Ready

5. Source Freshness Configuration (12%)
Score: 0.0/12 (0.0%) - 🔴 Not Ready
```

#### Scoring Guide

- **🟢 80-100%**: Ready to build semantic layer
- **🟡 50-79%**: Needs preparation work first
- **🔴 0-49%**: Significant foundational work needed

**Note:** All five dimensions are required for full readiness. The scoring emphasizes **temporal consistency** (30%), as time-based queries are the most common in LLM-powered analytics.

#### Why This Scoring Distribution?

The weights reflect what matters most for **LLM-powered analytics**. All dimensions use **ratio-based scoring** to measure coverage:

1. **Temporal Consistency (30%)** - THE MOST CRITICAL
   - Time-based questions dominate analytics: "last quarter", "YoY", "trends over time"
   - Fact tables MUST have consistent date columns and naming
   - **Metric**: % of fact models with temporal columns + naming consistency
   - Example: "Show revenue last 6 months" requires clear, consistent temporal columns

2. **Documentation & Relationships (40%: Columns 20% + Relationships 20%)**
   - **Column Documentation (20%)**: Business context and descriptions for LLM understanding
     - **Metric**: % of columns with meaningful documentation (>10 characters)
   - **Relationship Documentation (20%)**: Models with dbt relationship tests ensure data quality
     - **Metric**: % of mart models with at least one relationship test

3. **Data Governance (30%: Ownership 15% + Freshness 15%)**
   - **Ownership (15%)**: LLMs need to route questions to the right team
     - **Metric**: % of mart models with owner metadata
   - **Source Freshness (15%)**: LLMs need to know if data is current
     - **Metric**: % of sources with freshness checks configured

#### Configuring Metadata for AI Readiness

The tool looks for structured metadata in `config.meta` properties.

**Mart Layer Designation:**

Explicitly mark models as mart/presentation layer using metadata (preferred):

```yaml
models:
  - name: orders
    description: Order transactions
    config:
      meta:
        layer: mart          # or 'fct', 'dim', 'fact', 'presentation', 'core'
        type: fact           # or use 'type' instead of 'layer'
        grain: one row per order
        owner: analytics-team
```

Or use naming conventions (fallback):
- Name prefixes: `fct_`, `dim_`, `fact_`, `mart_`, `rpt_`, `report_`
- Folder paths: `marts/`, `core/`, `presentation/`, `gold/`

**Temporal Field Designation:**

Explicitly designate temporal/date fields in metadata (preferred):

**Model-level designation:**
```yaml
models:
  - name: fct_orders
    description: Order transactions
    config:
      meta:
        temporal_field: order_date  # Explicit temporal field at model level
        layer: fact
        grain: one row per order
        owner: analytics-team
```

Supported model-level keys: `temporal_field`, `time_field`, `date_field`, `event_time`, `event_date`

**Column-level temporal designation:**
```yaml
models:
  - name: fct_orders
    config:
      meta:
        layer: fact
    columns:
      - name: order_date
        description: Date the order was placed
        config:
          meta:
            is_temporal_field: true  # Mark column as temporal field
      - name: created_at
        description: Record creation timestamp
      - name: updated_at
        description: Record update timestamp
```

**Measure Designation:**

Explicitly designate measure/metric columns in metadata:

**Model-level measure list:**
```yaml
models:
  - name: fct_orders
    config:
      meta:
        measures: [order_total, tax_amount, item_count]  # List of measure columns
        # or: measure_columns: [order_total, tax_amount]
        # or: metric_columns: "order_total, tax_amount"  # comma-separated string also works
```

**Column-level measure flag:**
```yaml
columns:
  - name: order_total
    description: Total order amount in USD
    config:
      meta:
        is_measure: true  # Mark column as a measure
  - name: customer_id
    description: Foreign key to customers
```

Or use naming conventions (fallback):
- Column patterns: `*_date`, `*_at`, `*_time`, `*_ts`, `*_timestamp`, `date_*`, `dt_*`

**Grain Documentation:**

Document grain explicitly in metadata (preferred) or description:

```yaml
models:
  - name: fct_orders
    description: Order transactions
    config:
      meta:
        grain: one row per order  # Explicit grain documentation
        owner: analytics-team
```

Or include grain in the description:

```yaml
models:
  - name: fct_orders
    description: One row per order. Contains all order transactions.
```

**Ownership Metadata:**

The tool looks for ownership keys at the model level: `owner`, `owners`, `team`, `contact`.

```yaml
models:
  - name: fct_orders
    config:
      meta:
        owner: analytics-team
        team: data-platform
        grain: one row per order
    columns:
      - name: order_id
        description: Unique order identifier
```

This structured metadata helps LLMs understand grain, ownership, and data context!

#### Complete Example: AI-Ready Model

Here's a fully metadata-driven model configuration:

```yaml
models:
  - name: orders
    description: Core order transactions
    config:
      meta:
        layer: fact                    # Mart designation
        grain: one row per order       # Grain documentation
        temporal_field: order_date     # Primary temporal field
        measures: [order_total, tax_amount, item_count]  # Measure columns
        owner: analytics-team          # Ownership
        team: data-platform
    columns:
      - name: order_id
        description: Unique order identifier
      - name: order_date
        description: Date the order was placed
        config:
          meta:
            is_temporal_field: true
      - name: order_total
        description: Total order amount in USD
        config:
          meta:
            is_measure: true
      - name: customer_id
        description: Foreign key to customers
        tests:
          - relationships:
              to: ref('customers')
              field: customer_id
```

This model is **100% AI-ready** with explicit, machine-readable metadata!

#### Distinguishing Fact vs Dimension Models

The tool includes logic to identify fact models specifically (a subset of mart models):

**Via metadata (preferred):**
```yaml
models:
  - name: orders
    config:
      meta:
        layer: fact        # or type: fact, or model_type: fct
        
  - name: customers
    config:
      meta:
        layer: dimension   # Mart model but NOT a fact
```

**Via naming conventions (fallback):**
- Fact prefixes: `fct_`, `fact_`
- Fact folders: `facts/`, `fact/`

The `_is_fact_model()` method first checks if a model is a mart, then applies fact-specific patterns. This is useful for:
- Validating that fact tables have temporal columns (dimensions may not need them)
- Ensuring fact tables have measures defined
- Analyzing fact vs dimension model distributions

**Usage example:**
```python
assessor = SemanticLayerReadinessAssessor('target/manifest.json')

# Get all mart models
mart_models = {k: v for k, v in assessor.models.items() 
               if assessor._is_mart_model(v)}

# Get only fact models (subset of marts)
fact_models = {k: v for k, v in mart_models.items() 
               if assessor._is_fact_model(v)}

# Get dimension models (marts that aren't facts)
dim_models = {k: v for k, v in mart_models.items() 
              if not assessor._is_fact_model(v)}

print(f"Marts: {len(mart_models)}, Facts: {len(fact_models)}, Dimensions: {len(dim_models)}")
```

## Quick Start

```bash
# 1. Install uv (if needed)
curl -LsSf https://astral.sh/uv/install.sh | sh

# 2. Install dependencies
cd experiments/dbt_ai_tools
uv pip install -r requirements.txt

# 3. Run the assessment
cd /path/to/your/dbt/project
uv run /path/to/assess_semantic_readiness.py target/manifest.json
```

## Configuration File

The tool uses `assessment_config.yaml` to define patterns for:
- **Mart identification**: Which model names/folders indicate final layer models
- **Fact identification**: Which marts are specifically fact tables (subset)
- **Grain documentation**: Keywords that indicate grain is documented
- **Temporal columns**: Patterns to identify date/time columns
- **Measure identification**: Keywords that suggest a column is a measure

**Location**: By default, the script looks for `assessment_config.yaml` in the same directory as the script.

**Customization**: Copy and modify `assessment_config.yaml` to match your project's conventions, then pass it as an argument to the script.

## Requirements

- Python 3.7+
- dbt project with compiled manifest.json
- PyYAML (for loading configuration file)
- uv (for package management)

### Installation

**Using uv (recommended):**
```bash
# Install uv if you don't have it
curl -LsSf https://astral.sh/uv/install.sh | sh

# Install dependencies
uv pip install -r experiments/dbt_ai_tools/requirements.txt

# Or install PyYAML directly
uv pip install pyyaml
```

**Using pip:**
```bash
pip install -r experiments/dbt_ai_tools/requirements.txt
```

## Future Tools

Potential additions to this toolkit:
- AI-friendly documentation generator
- Semantic model scaffolding tool
- Metric suggestion engine based on existing models
- LLM prompt template generator for your semantic layer

