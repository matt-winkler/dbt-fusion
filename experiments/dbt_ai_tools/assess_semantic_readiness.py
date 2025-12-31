#!/usr/bin/env python3
"""
Semantic Layer Readiness Assessment for dbt Projects
Evaluates whether a dbt project is ready to build a semantic layer for LLM consumption.

Requirements:
    - Python 3.7+
    - PyYAML: pip install pyyaml
"""

import json
import sys
import yaml
from typing import Dict, List, Tuple, Any
from pathlib import Path
from dataclasses import dataclass, field
from collections import defaultdict


@dataclass
class AssessmentScore:
    """Container for assessment scores and findings."""
    score: float  # 0-100
    max_score: float
    findings: List[str] = field(default_factory=list)
    recommendations: List[str] = field(default_factory=list)
    
    @property
    def percentage(self) -> float:
        return (self.score / self.max_score * 100) if self.max_score > 0 else 0
    
    @property
    def grade(self) -> str:
        pct = self.percentage
        if pct >= 80:
            return "🟢 Ready"
        elif pct >= 50:
            return "🟡 Needs Prep"
        else:
            return "🔴 Not Ready"


class SemanticLayerReadinessAssessor:
    """Assesses dbt project readiness for semantic layer implementation."""
    
    def __init__(self, manifest_path: str, config_path: str = None):
        """
        Initialize with path to manifest.json and optional config file.
        
        Args:
            manifest_path: Path to dbt manifest.json
            config_path: Path to assessment config YAML (optional, defaults to assessment_config.yaml in same directory)
        """
        self.manifest_path = Path(manifest_path)
        
        # Load configuration
        if config_path is None:
            # Default to config file in same directory as script
            script_dir = Path(__file__).parent
            config_path = script_dir / 'assessment_config.yaml'
        
        self.config = self._load_config(config_path)
        
        # Load assessment patterns from config
        mart_config = self.config.get('mart_identification', {})
        self.MART_PREFIXES = mart_config.get('prefixes', [])
        self.MART_FOLDERS = mart_config.get('folders', [])
        self.MART_META_FIELDS = mart_config.get('meta_fields', [])
        self.MART_META_INDICATORS = mart_config.get('meta_indicators', [])
        
        fact_config = self.config.get('fact_identification', {})
        self.FACT_PREFIXES = fact_config.get('prefixes', [])
        self.FACT_FOLDERS = fact_config.get('folders', [])
        self.FACT_META_INDICATORS = fact_config.get('meta_indicators', [])
        
        self.GRAIN_KEYWORDS = self.config.get('grain_documentation', {}).get('keywords', [])
        
        temporal_config = self.config.get('temporal_columns', {})
        self.DATE_PATTERNS = temporal_config.get('patterns', [])
        self.TEMPORAL_META_FIELDS = temporal_config.get('model_meta_fields', [])
        
        measure_config = self.config.get('measure_identification', {})
        self.MEASURE_KEYWORDS = measure_config.get('keywords', [])
        self.MEASURE_META_FIELDS = measure_config.get('model_meta_fields', [])
        
        # Load manifest and index data
        self.manifest = self._load_manifest()
        self.models = self._get_models()
        self.sources = self._get_sources()
        self.relationship_tests = self._index_relationship_tests()
    
    def _load_config(self, config_path: Path) -> Dict:
        """Load assessment configuration from YAML file."""
        try:
            with open(config_path, 'r') as f:
                return yaml.safe_load(f)
        except FileNotFoundError:
            print(f"⚠️  Warning: Config file not found at {config_path}")
            print("    Using default configuration values.")
            # Return default config if file not found
            return {
                'mart_identification': {
                    'prefixes': ['fct_', 'dim_', 'fact_', 'mart_', 'rpt_', 'report_'],
                    'folders': ['marts', 'mart', 'core', 'presentation', 'reports', 'gold'],
                    'meta_fields': ['layer', 'type', 'model_type', 'mart_type'],
                    'meta_indicators': ['fct', 'dim', 'fact', 'dimension', 'mart', 'rpt', 'report', 'core', 'presentation']
                },
                'fact_identification': {
                    'prefixes': ['fct_', 'fact_'],
                    'folders': ['facts', 'fact'],
                    'meta_indicators': ['fct', 'fact', 'facts']
                },
                'grain_documentation': {
                    'keywords': ['one row per', 'grain', 'granularity', 'each row represents',
                                'row represents', 'unique by', 'keyed by']
                },
                'temporal_columns': {
                    'patterns': ['_date', '_at', '_time', '_ts', '_timestamp', 'date_', 'dt_'],
                    'model_meta_fields': ['temporal_field', 'time_field', 'date_field', 'event_time', 'event_date']
                },
                'measure_identification': {
                    'keywords': ['total', 'sum', 'count', 'amount', 'value', 'price', 'cost',
                               'revenue', 'quantity', 'qty', 'number', 'avg', 'average'],
                    'model_meta_fields': ['measures', 'measure_columns', 'metric_columns']
                }
            }
        except yaml.YAMLError as e:
            print(f"❌ Error: Invalid YAML in config file: {e}")
            sys.exit(1)
        
    def _load_manifest(self) -> Dict:
        """Load and parse manifest.json."""
        try:
            with open(self.manifest_path, 'r') as f:
                return json.load(f)
        except FileNotFoundError:
            print(f"❌ Error: Manifest file not found at {self.manifest_path}")
            sys.exit(1)
        except json.JSONDecodeError:
            print(f"❌ Error: Invalid JSON in manifest file")
            sys.exit(1)
    
    def _get_models(self) -> Dict[str, Any]:
        """Extract models from manifest."""
        return {
            key: value for key, value in self.manifest.get('nodes', {}).items()
            if value.get('resource_type') == 'model'
        }
    
    def _get_sources(self) -> Dict[str, Any]:
        """Extract sources from manifest."""
        return {
            key: value for key, value in self.manifest.get('sources', {}).items()
            if value.get('resource_type') == 'source'
        }
    
    def _index_relationship_tests(self) -> Dict[Tuple[str, str], Dict]:
        """
        Index all relationship tests by (model_unique_id, column_name).
        
        Returns a dict mapping (model_id, column_name) -> test_info
        """
        relationship_index = {}
        
        for node_id, node in self.manifest.get('nodes', {}).items():
            # Check if this is a test node
            if node.get('resource_type') != 'test':
                continue
            
            # Check if it's a relationships test
            test_metadata = node.get('test_metadata', {})
            if test_metadata.get('name') != 'relationships':
                continue
            
            # Extract the model and column being tested
            # The test is attached to a specific model via depends_on
            depends_on = node.get('depends_on', {}).get('nodes', [])
            
            # Get the column name from test metadata or kwargs
            column_name = test_metadata.get('kwargs', {}).get('column_name')
            if not column_name:
                continue
                        
            # Find the model this test is attached to (usually the first dependency that's a model)
            for dep in depends_on:
                if dep.startswith('model.'):
                    # Store relationship info indexed by (model_id, column_name)
                    key = (dep, column_name.lower())
                    relationship_index[key] = {
                        'test_id': node_id,
                        'to_model': test_metadata.get('kwargs', {}).get('to', ''),
                        'field': test_metadata.get('kwargs', {}).get('field', ''),
                    }
                    break
        
        return relationship_index
    
    def _is_mart_model(self, model: Dict) -> bool:
        """
        Determine if a model is a mart/final layer model.
        
        Checks config.meta for explicit layer/type designation first,
        then falls back to naming conventions.
        """
        # Primary check: Look for explicit layer/type in config.meta
        model_meta = model.get('config', {}).get('meta', {})
        if not model_meta:
            model_meta = {}
        
        # Check metadata fields for mart indicators
        for field in self.MART_META_FIELDS:
            if field in model_meta:
                field_value = str(model_meta[field]).lower()
                if any(indicator in field_value for indicator in self.MART_META_INDICATORS):
                    return True
        
        # Fallback: Check naming conventions
        name = model.get('name', '').lower()
        path = model.get('original_file_path', '').lower()
        
        # Check name prefixes
        if any(name.startswith(prefix) for prefix in self.MART_PREFIXES):
            return True
        
        # Check folder structure
        if any(folder in path for folder in self.MART_FOLDERS):
            return True
        
        return False
    
    def _is_fact_model(self, model: Dict) -> bool:
        """
        Determine if a model is specifically a fact table (subset of mart models).
        
        A fact model must first be a mart model, then additionally match
        fact-specific patterns. This is useful for:
        - Ensuring fact tables have temporal columns
        - Validating fact tables have measures defined
        - Analyzing fact vs dimension distributions
        
        Args:
            model: The model dictionary
            
        Returns:
            True if the model is a fact table
        """
        # First check: Must be a mart model
        if not self._is_mart_model(model):
            return False
        
        # Primary check: Look for fact-specific metadata in config.meta
        model_meta = model.get('config', {}).get('meta', {})
        if not model_meta:
            model_meta = {}
        
        # Check metadata fields for fact indicators
        for field in self.MART_META_FIELDS:
            if field in model_meta:
                field_value = str(model_meta[field]).lower()
                if any(indicator in field_value for indicator in self.FACT_META_INDICATORS):
                    return True
        
        # Fallback: Check naming conventions
        name = model.get('name', '').lower()
        path = model.get('original_file_path', '').lower()
        
        # Check name prefixes for fact patterns
        if any(name.startswith(prefix) for prefix in self.FACT_PREFIXES):
            return True
        
        # Check folder structure for fact-specific folders
        if any(folder in path for folder in self.FACT_FOLDERS):
            return True
        
        return False
    
    def _has_grain_documentation(self, model: Dict) -> bool:
        """
        Check if model has grain documentation.
        
        Checks for explicit grain fields in config.meta: 'grain' or 'granularity'
        Falls back to checking description for grain keywords.
        
        Args:
            model: The model dictionary
            
        Returns:
            True if grain is documented
        """
        # Primary check: Look for grain in config.meta
        model_meta = model.get('config', {}).get('meta', {})
        if not model_meta:
            model_meta = {}
        
        if any(field in model_meta for field in self.GRAIN_KEYWORDS):
            return True
        
        # Fallback: Check description for grain keywords
        description = model.get('description', '')
        if description:
            desc_lower = description.lower()
            if any(keyword in desc_lower for keyword in self.GRAIN_KEYWORDS):
                return True
        
        return False
    
    def _has_temporal_column(self, model: Dict) -> Tuple[bool, List[str]]:
        """
        Check if model has clear temporal columns.
        
        Checks for explicit temporal field designation in config.meta first
        (both model-level and column-level), then falls back to checking 
        column naming patterns.
        
        Args:
            model: The model dictionary
            
        Returns:
            Tuple of (has_temporal_column, list_of_temporal_column_names)
        """
        date_columns = []
        
        # Primary check: Look for temporal field metadata in model-level config.meta
        model_meta = model.get('config', {}).get('meta', {})
        if not model_meta:
            model_meta = {}
        
        # Check for explicit temporal field designation at model level
        for key in self.TEMPORAL_META_FIELDS:
            if key in model_meta:
                # If explicitly designated, add it to date_columns
                designated_field = model_meta[key]
                if designated_field:
                    date_columns.append(designated_field)
        
        # Secondary check: Look for column-level is_temporal_field metadata
        columns = model.get('columns', {})
        for col_name, col_info in columns.items():
            # Don't add duplicates if already found in model-level metadata
            if col_name in date_columns:
                continue
            
            # Check column-level config.meta for is_temporal_field
            col_meta = col_info.get('config', {}).get('meta', {})
            if not col_meta:
                col_meta = {}
            
            if col_meta.get('is_temporal_field', False):
                date_columns.append(col_name)
        
        # Fallback: Check column names for date patterns
        for col_name in columns.keys():
            # Don't add duplicates if already found in metadata
            if col_name in date_columns:
                continue
            col_lower = col_name.lower()
            if any(pattern in col_lower for pattern in self.DATE_PATTERNS):
                date_columns.append(col_name)
        
        return len(date_columns) > 0, date_columns
    
    def _is_likely_measure(self, model: Dict, col_name: str, col_info: Dict) -> bool:
        """
        Determine if a column is likely a measure.
        
        Checks metadata first (model-level list or column-level flag),
        then falls back to type and naming analysis.
        
        Args:
            model: The model dictionary
            col_name: The column name
            col_info: The column info dictionary
            
        Returns:
            True if the column is likely a measure
        """
        col_lower = col_name.lower()
        
        # Primary check: Look for measure list in model-level config.meta
        model_meta = model.get('config', {}).get('meta', {})
        if not model_meta:
            model_meta = {}
        
        # Check for explicit measure list at model level
        for key in self.MEASURE_META_FIELDS:
            if key in model_meta:
                return True
        
        # Secondary check: Look for is_measure flag in column-level config.meta
        col_meta = col_info.get('config', {}).get('meta', {})
        if not col_meta:
            col_meta = {}
        
        if col_meta.get('is_measure', False):
            return True
        
        # Fallback: Check type and naming patterns
        col_type = col_info.get('data_type', '')
        type_lower = (col_type or '').lower()
        
        # Numeric types with measure-like names
        if any(t in type_lower for t in ['int', 'float', 'numeric', 'decimal', 'double', 'number']):
            # Check if name suggests it's a measure
            if any(keyword in col_lower for keyword in self.MEASURE_KEYWORDS):
                return True
        
        return False
    
    def _is_foreign_key(self, model_id: str, col_name: str) -> bool:
        """
        Determine if a column is a foreign key.
        
        Checks if there's a dbt relationship test defined for this column
        
        Args:
            model_id: The unique_id of the model (e.g., 'model.project.model_name')
            col_name: The column name
            
        Returns:
            True if the column is a foreign key (has relationship test)
        """
        col_lower = col_name.lower()
        
        # Primary check: Does this column have a relationship test?
        if (model_id, col_lower) in self.relationship_tests:
            return True
        
        return False
    
    def _analyze_source_freshness(self) -> Dict[str, Any]:
        """
        Analyze source freshness configuration across all sources.
        
        Returns:
            Dictionary with freshness statistics and configuration info
        """
        if not self.sources:
            return {
                'total_sources': 0,
                'sources_with_freshness': 0,
                'freshness_ratio': 0,
                'configured_sources': []
            }
        
        total_sources = len(self.sources)
        sources_with_freshness = 0
        configured_sources = []
        
        for source_id, source in self.sources.items():
            # Check if freshness is configured
            freshness_config = source.get('freshness', {})
            loaded_at_field = source.get('loaded_at_field')
            
            # Freshness is configured if either warn_after or error_after is set
            # and there's a loaded_at_field to check against
            warn_after = freshness_config.get('warn_after')
            error_after = freshness_config.get('error_after')
            
            if loaded_at_field and (warn_after or error_after):
                sources_with_freshness += 1
                configured_sources.append({
                    'name': source.get('name'),
                    'source_name': source.get('source_name'),
                    'loaded_at_field': loaded_at_field,
                    'warn_after': warn_after,
                    'error_after': error_after,
                })
        
        return {
            'total_sources': total_sources,
            'sources_with_freshness': sources_with_freshness,
            'freshness_ratio': sources_with_freshness / total_sources if total_sources > 0 else 0,
            'configured_sources': configured_sources
        }
    
    def _analyze_ownership_metadata(self, models: Dict[str, Any]) -> Dict[str, Any]:
        """
        Analyze ownership metadata at model and column levels.
        
        Args:
            models: Dictionary of models to analyze
            
        Returns:
            Dictionary with ownership statistics
        """
        total_models = len(models)
        models_with_owner = 0
        total_columns = 0
        columns_with_owner = 0
        
        owner_keys = ['owner', 'owners', 'team', 'contact']  # Common owner field names
        
        for model_id, model in models.items():
            # Check model-level meta for owner
            model_meta = model.get('config', {}).get('meta', {})
            # Important: If meta is not found, set it to an empty dictionary
            if not model_meta:
                model_meta = {}
            if any(key in model_meta for key in owner_keys):
                models_with_owner += 1
            
            # Check column-level meta for owner
            columns = model.get('columns', {})
            for col_name, col_info in columns.items():
                total_columns += 1
                col_meta = col_info.get('config', {}).get('meta', {})
                if not col_meta:
                    col_meta = {}
                if any(key in col_meta for key in owner_keys):
                    columns_with_owner += 1
        
        return {
            'total_models': total_models,
            'models_with_owner': models_with_owner,
            'model_owner_ratio': models_with_owner / total_models if total_models > 0 else 0,
            'total_columns': total_columns,
            'columns_with_owner': columns_with_owner,
            'column_owner_ratio': columns_with_owner / total_columns if total_columns > 0 else 0,
        }
    
    def assess_column_documentation(self) -> AssessmentScore:
        """Assess column-level documentation quality (21 points)."""
        score = AssessmentScore(score=0, max_score=21)
        
        mart_models = {k: v for k, v in self.models.items() if self._is_mart_model(v)}
        
        if not mart_models:
            score.recommendations.append("No mart models to assess column documentation")
            return score
        
        total_columns = 0
        documented_columns = 0
        columns_with_units = 0
        business_friendly_names = 0
        
        for model in mart_models.values():
            columns = model.get('columns', {})
            total_columns += len(columns)
            
            for col_name, col_info in columns.items():
                description = col_info.get('description', '').strip()
                
                # Check if documented
                if description and len(description) > 10:
                    documented_columns += 1
                    
                    # Check for units (USD, $, cents, units, etc.)
                    desc_lower = description.lower()
                    if any(unit in desc_lower for unit in ['usd', '$', 'cents', 'dollars', 'units', 'count', 'percentage', '%']):
                        columns_with_units += 1
                
                # Check for business-friendly naming (not col_1, not single letters unless ID)
                if not col_name.startswith('col_') and len(col_name) > 2 and '_' in col_name:
                    business_friendly_names += 1
        
        if total_columns == 0:
            score.recommendations.append("No columns found in mart models")
            return score
        
        doc_ratio = documented_columns / total_columns
        unit_ratio = columns_with_units / total_columns
        naming_ratio = business_friendly_names / total_columns
        
        score.findings.append(f"Column documentation: {documented_columns}/{total_columns} ({doc_ratio*100:.0f}%)")
        score.findings.append(f"Columns with units: {columns_with_units}/{total_columns} ({unit_ratio*100:.0f}%)")
        score.findings.append(f"Business-friendly names: {business_friendly_names}/{total_columns} ({naming_ratio*100:.0f}%)")
        
        # Score: Documentation presence (11 points)
        if doc_ratio >= 0.8:
            score.score += 11
            score.findings.append("✓ Excellent column documentation coverage")
        elif doc_ratio >= 0.6:
            score.score += 7
            score.recommendations.append("Document more columns with business context")
        elif doc_ratio >= 0.3:
            score.score += 3
            score.recommendations.append("⚠️ Many columns lack documentation")
        else:
            score.recommendations.append("❌ Critical: Most columns are undocumented")
        
        # Score: Unit documentation (6 points)
        if unit_ratio >= 0.3:  # Expecting at least 30% of columns to have units (measures)
            score.score += 6
            score.findings.append("✓ Good unit documentation for measures")
        elif unit_ratio >= 0.15:
            score.score += 3
            score.recommendations.append("Add units (USD, quantity, etc.) to numeric column descriptions")
        else:
            score.recommendations.append("⚠️ Add units to measure columns (e.g., 'Total revenue in USD')")
        
        # Score: Naming conventions (4 points)
        if naming_ratio >= 0.8:
            score.score += 4
            score.findings.append("✓ Good column naming conventions")
        elif naming_ratio >= 0.5:
            score.score += 2
            score.recommendations.append("Improve column naming consistency")
        else:
            score.recommendations.append("⚠️ Use business-friendly column names (e.g., order_total not col_5)")
        
        return score
    
    def assess_relationship_documentation(self) -> AssessmentScore:
        """Assess relationship documentation (21 points)."""
        score = AssessmentScore(score=0, max_score=21)
        
        mart_models = {k: v for k, v in self.models.items() if self._is_mart_model(v)}
        
        if not mart_models:
            score.recommendations.append("No mart models to assess relationships")
            return score
        
        total_fks = 0
        clear_fk_naming = 0
        documented_joins = 0
        fks_with_tests = 0
        
        for model_id, model in mart_models.items():
            columns = model.get('columns', {})
            description = model.get('description', '').lower()
            
            # Check for join documentation in model description
            if 'join' in description or 'relationship' in description or 'foreign key' in description:
                documented_joins += 1
            
            for col_name, col_info in columns.items():
                if self._is_foreign_key(model_id, col_name):
                    total_fks += 1
                    
                    # Check if FK has a relationship test
                    if (model_id, col_name.lower()) in self.relationship_tests:
                        fks_with_tests += 1
                    
                    # Check if FK follows clear naming pattern
                    if col_name.endswith('_id') or col_name.endswith('_key'):
                        clear_fk_naming += 1
        
        score.findings.append(f"Foreign keys found: {total_fks}")
        if total_fks > 0:
            score.findings.append(f"FKs with relationship tests: {fks_with_tests}/{total_fks} ({fks_with_tests/total_fks*100:.0f}%)")
            score.findings.append(f"Clear FK naming: {clear_fk_naming}/{total_fks} ({clear_fk_naming/total_fks*100:.0f}%)")
        else:
            score.findings.append("No foreign keys detected")
        score.findings.append(f"Models with join documentation: {documented_joins}/{len(mart_models)}")
        
        # Score: FK documentation with tests and naming (12 points)
        if total_fks > 0:
            # Prioritize relationship tests (60% weight) over naming conventions (40% weight)
            test_ratio = fks_with_tests / total_fks
            naming_ratio = clear_fk_naming / total_fks
            
            # Weighted score: tests are more valuable than just naming
            combined_score = (test_ratio * 0.6 + naming_ratio * 0.4) * 12
            score.score += combined_score
            
            if test_ratio >= 0.8:
                score.findings.append("✓ Excellent relationship test coverage")
            elif test_ratio >= 0.5:
                score.findings.append("✓ Good relationship test coverage")
                score.recommendations.append("Add relationship tests to remaining foreign keys")
            elif test_ratio >= 0.2:
                score.recommendations.append("⚠️ Add relationship tests to validate foreign key constraints")
            else:
                score.recommendations.append("❌ Critical: Add relationship tests (e.g., relationships: {to: ref('dim_customers'), field: id})")
            
            if naming_ratio < 0.7 and test_ratio < 0.7:
                score.recommendations.append("⚠️ Use consistent FK naming (e.g., customer_id, product_key)")
        else:
            score.recommendations.append("⚠️ No foreign keys detected - ensure relationships are modeled")
        
        # Score: Relationship documentation (9 points)
        join_doc_ratio = documented_joins / len(mart_models) if mart_models else 0
        if join_doc_ratio >= 0.5:
            score.score += 9
            score.findings.append("✓ Good relationship documentation")
        elif join_doc_ratio >= 0.2:
            score.score += 4
            score.recommendations.append("Document join patterns in model descriptions")
        else:
            score.recommendations.append("❌ Add relationship documentation (e.g., 'Joins to dim_customers on customer_id')")
        
        return score
    
    def assess_temporal_consistency(self) -> AssessmentScore:
        """Assess temporal column consistency (32 points)."""
        score = AssessmentScore(score=0, max_score=32)
        
        fact_models = {k: v for k, v in self.models.items() if self._is_fact_model(v)}
        
        if not fact_models:
            score.recommendations.append("No fact models to assess")
            return score
        
        models_with_dates = 0
        date_columns_found = []
        
        for model_name, model in fact_models.items():
            has_date, date_cols = self._has_temporal_column(model)
            
            if has_date:
                models_with_dates += 1
                date_columns_found.extend(date_cols)
        
        temporal_ratio = models_with_dates / len(fact_models) if fact_models else 0
        
        score.findings.append(f"Mart models with date columns: {models_with_dates}/{len(fact_models)} ({temporal_ratio*100:.0f}%)")
        
        # Score: Temporal column coverage (26 points)
        if temporal_ratio >= 0.8:
            score.score += 26
            score.findings.append("✓ Excellent temporal column coverage")
        elif temporal_ratio >= 0.5:
            score.score += 16
            score.recommendations.append("Add date columns to more fact tables")
        elif temporal_ratio >= 0.2:
            score.score += 6
            score.recommendations.append("⚠️ Many fact tables lack date columns for time-based queries")
        else:
            score.recommendations.append("❌ Critical: Most fact tables lack clear date columns for time-based queries")
        
        # Score: Naming consistency (6 points)
        if date_columns_found:
            unique_patterns = set(date_columns_found)
            consistency_ratio = 1 - (len(unique_patterns) / len(date_columns_found))
            if consistency_ratio >= 0.7:  # Good consistency
                score.score += 6
                score.findings.append("✓ Consistent date column naming")
            elif consistency_ratio >= 0.4:
                score.score += 3
                score.recommendations.append("⚠️ Improve date column naming consistency")
            else:
                score.recommendations.append("⚠️ Standardize date column naming across models (e.g., always use *_date or *_at)")
        
        return score
    
    def assess_source_freshness(self) -> AssessmentScore:
        """Assess source freshness configuration (13 points)."""
        score = AssessmentScore(score=0, max_score=13)
        
        freshness_info = self._analyze_source_freshness()
        
        if freshness_info['total_sources'] == 0:
            score.findings.append("No sources found in project")
            return score
        
        total = freshness_info['total_sources']
        configured = freshness_info['sources_with_freshness']
        ratio = freshness_info['freshness_ratio']
        
        score.findings.append(f"Sources with freshness checks: {configured}/{total} ({ratio*100:.0f}%)")
        
        # Score based on freshness configuration coverage
        if ratio >= 0.8:
            score.score += 13
            score.findings.append("✓ Excellent source freshness coverage")
        elif ratio >= 0.5:
            score.score += 8
            score.findings.append("✓ Good source freshness coverage")
            score.recommendations.append("Add freshness checks to remaining sources")
        elif ratio >= 0.2:
            score.score += 2
            score.recommendations.append("⚠️ Configure freshness checks for more sources")
        else:
            if total > 0:
                score.recommendations.append("❌ Critical: Configure source freshness checks (warn_after, error_after)")
        
        # Show some examples of configured sources
        if freshness_info['configured_sources']:
            example_sources = freshness_info['configured_sources'][:3]
            examples = [f"{s['source_name']}.{s['name']}" for s in example_sources]
            if examples:
                score.findings.append(f"Example configured sources: {', '.join(examples)}")
        
        return score
    
    def assess_ownership_metadata(self) -> AssessmentScore:
        """Assess ownership metadata configuration (13 points)."""
        score = AssessmentScore(score=0, max_score=13)
        
        mart_models = {k: v for k, v in self.models.items() if self._is_mart_model(v)}
        
        if not mart_models:
            score.findings.append("No mart models to assess ownership")
            return score
        
        ownership_info = self._analyze_ownership_metadata(mart_models)
        
        model_total = ownership_info['total_models']
        model_with_owner = ownership_info['models_with_owner']
        model_ratio = ownership_info['model_owner_ratio']
        
        col_total = ownership_info['total_columns']
        col_with_owner = ownership_info['columns_with_owner']
        col_ratio = ownership_info['column_owner_ratio']
        
        score.findings.append(f"Mart models with owner metadata: {model_with_owner}/{model_total} ({model_ratio*100:.0f}%)")
        if col_total > 0:
            score.findings.append(f"Columns with owner metadata: {col_with_owner}/{col_total} ({col_ratio*100:.0f}%)")
        
        # Score based on model-level ownership (primary, 70% weight)
        model_points = 0
        if model_ratio >= 0.8:
            model_points = 9
            score.findings.append("✓ Excellent model ownership documentation")
        elif model_ratio >= 0.5:
            model_points = 6
            score.findings.append("✓ Good model ownership documentation")
            score.recommendations.append("Add owner metadata to remaining mart models")
        elif model_ratio >= 0.2:
            model_points = 3
            score.recommendations.append("⚠️ Add owner metadata to more models (e.g., meta: {owner: 'analytics-team'})")
        else:
            score.recommendations.append("❌ Critical: Add owner metadata to mart models for accountability")
        
        # Score based on column-level ownership (secondary, 30% weight)
        col_points = 0
        if col_total > 0:
            if col_ratio >= 0.3:  # Lower bar for column-level
                col_points = 4
                score.findings.append("✓ Some columns have ownership metadata")
            elif col_ratio >= 0.1:
                col_points = 1
                score.recommendations.append("Consider adding owner metadata to key columns")
        
        score.score = model_points + col_points
        
        return score
    
    def run_full_assessment(self) -> Dict[str, AssessmentScore]:
        """Run complete assessment across all dimensions."""
        return {
            'column_documentation': self.assess_column_documentation(),
            'relationship_documentation': self.assess_relationship_documentation(),
            'temporal_consistency': self.assess_temporal_consistency(),
            'source_freshness': self.assess_source_freshness(),
            'ownership_metadata': self.assess_ownership_metadata(),
        }
    
    def generate_report(self) -> str:
        """Generate a comprehensive readiness report."""
        results = self.run_full_assessment()
        
        # Calculate weighted total across all dimensions
        weights = {
            'column_documentation': 0.20,
            'relationship_documentation': 0.20,
            'temporal_consistency': 0.30,
            'source_freshness': 0.15,
            'ownership_metadata': 0.15,
        }
        
        total_score = sum(r.score for r in results.values())
        max_score = sum(r.max_score for r in results.values())
        percentage = (total_score / max_score * 100) if max_score > 0 else 0
        
        # Determine overall grade
        if percentage >= 80:
            overall_grade = "🟢 READY"
            readiness = "Your project is ready to build a semantic layer!"
        elif percentage >= 50:
            overall_grade = "🟡 NEEDS PREPARATION"
            readiness = "Address key gaps before building semantic layer."
        else:
            overall_grade = "🔴 NOT READY"
            readiness = "Significant work needed before semantic layer implementation."
        
        # Build report
        report = []
        report.append("=" * 80)
        report.append("🎯 SEMANTIC LAYER READINESS ASSESSMENT")
        report.append("=" * 80)
        report.append("")
        report.append(f"Overall Score: {total_score:.1f}/{max_score} ({percentage:.1f}%)")
        report.append(f"Overall Grade: {overall_grade}")
        report.append(f"Assessment: {readiness}")
        report.append("")
        report.append("=" * 80)
        report.append("")
        
        # Dimension details
        dimension_names = {
            'temporal_consistency': '1. Temporal Consistency (30%)',
            'column_documentation': '2. Column Documentation Quality (20%)',
            'relationship_documentation': '3. Relationship Documentation (20%)',
            'ownership_metadata': '4. Ownership Metadata (15%)',
            'source_freshness': '5. Source Freshness Configuration (15%)',
        }
        
        for key, result in results.items():
            report.append(f"{dimension_names[key]}")
            report.append(f"Score: {result.score:.1f}/{result.max_score} ({result.percentage:.1f}%) - {result.grade}")
            report.append("")
            
            if result.findings:
                report.append("Findings:")
                for finding in result.findings:
                    report.append(f"  • {finding}")
                report.append("")
            
            if result.recommendations:
                report.append("Recommendations:")
                for rec in result.recommendations:
                    report.append(f"  • {rec}")
                report.append("")
            
            report.append("-" * 80)
            report.append("")
        
        # Priority actions
        all_recs = []
        for result in results.values():
            all_recs.extend(result.recommendations)
        
        if all_recs:
            report.append("🎯 PRIORITY ACTIONS")
            report.append("=" * 80)
            critical_recs = [r for r in all_recs if r.startswith('❌')]
            warning_recs = [r for r in all_recs if r.startswith('⚠️')]
            other_recs = [r for r in all_recs if not r.startswith('❌') and not r.startswith('⚠️')]
            
            if critical_recs:
                report.append("\nCritical (Must Fix):")
                for rec in critical_recs:
                    report.append(f"  {rec}")
            
            if warning_recs:
                report.append("\nImportant (Should Fix):")
                for rec in warning_recs:
                    report.append(f"  {rec}")
            
            if other_recs:
                report.append("\nNice to Have:")
                for rec in other_recs:
                    report.append(f"  {rec}")
            
            report.append("")
        
        report.append("=" * 80)
        report.append("📊 NEXT STEPS")
        report.append("=" * 80)
        
        if percentage >= 80:
            report.append("\n✅ Your project is well-prepared for a semantic layer!")
            report.append("   Next: Start defining metrics in semantic models")
            report.append("   Focus: Create metrics that answer key business questions")
        elif percentage >= 50:
            report.append("\n⚠️  Address the recommendations above, then:")
            report.append("   1. Complete grain documentation for all marts")
            report.append("   2. Enhance column descriptions with business context")
            report.append("   3. Document relationships between models")
            report.append("   4. Start with a small pilot semantic layer")
        else:
            report.append("\n🔨 Foundational work needed:")
            report.append("   1. Build or refine your mart/presentation layer")
            report.append("   2. Document the grain of each mart model")
            report.append("   3. Add comprehensive column descriptions")
            report.append("   4. Establish clear naming conventions")
            report.append("   5. Re-run this assessment after improvements")
        
        report.append("")
        report.append("=" * 80)
        
        return "\n".join(report)


def main():
    """Main execution function."""
    if len(sys.argv) < 2:
        print("Usage: python assess_semantic_readiness.py <path_to_manifest.json> [config_file]")
        print("\nExamples:")
        print("  python assess_semantic_readiness.py target/manifest.json")
        print("  python assess_semantic_readiness.py target/manifest.json custom_config.yaml")
        sys.exit(1)
    
    manifest_path = sys.argv[1]
    config_path = sys.argv[2] if len(sys.argv) > 2 else None
    
    print("🔍 Loading dbt manifest...")
    assessor = SemanticLayerReadinessAssessor(manifest_path, config_path)
    
    print("📊 Running assessment...\n")
    report = assessor.generate_report()
    
    print(report)
    
    # Optionally save to file
    output_file = "semantic_layer_readiness_report.txt"
    with open(output_file, 'w') as f:
        f.write(report)
    
    print(f"\n💾 Report saved to: {output_file}")


if __name__ == "__main__":
    main()

