#!/usr/bin/env bash
# create-spec.sh
# Purpose: Generate comprehensive APP-001 spec from discovery JSON
# Usage: ./create-spec.sh "<discovery-json>"

set -euo pipefail

# Constants
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SPEC_DRIVE_DIR="${SPEC_DRIVE_DIR:-.spec-drive}"
SPECS_DIR="$SPEC_DRIVE_DIR/specs"
SPEC_ID="APP-001"
SPEC_FILE="$SPECS_DIR/$SPEC_ID.yaml"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ==============================================================================
# Validate Input
# ==============================================================================

if [[ $# -ne 1 ]]; then
  echo -e "${RED}❌ ERROR: Discovery JSON argument required${NC}" >&2
  echo "Usage: $0 '<discovery-json>'" >&2
  exit 1
fi

DISCOVERY_JSON="$1"

# Validate JSON
if ! echo "$DISCOVERY_JSON" | python3 -m json.tool >/dev/null 2>&1; then
  echo -e "${RED}❌ ERROR: Invalid JSON provided${NC}" >&2
  exit 1
fi

# Create temp file for JSON
TEMP_JSON=$(mktemp)
trap "rm -f $TEMP_JSON" EXIT
echo "$DISCOVERY_JSON" > "$TEMP_JSON"

# ==============================================================================
# Extract Data from Discovery JSON
# ==============================================================================

echo -e "${BLUE}Extracting discovery data...${NC}"

# Project data
PROJECT_NAME=$(python3 -c "import sys, json; print(json.load(open('$TEMP_JSON'))['project']['name'])")
PROJECT_VISION=$(python3 -c "import sys, json; print(json.load(open('$TEMP_JSON'))['project']['vision'])")
PROBLEM_STATEMENT=$(python3 -c "import sys, json; print(json.load(open('$TEMP_JSON'))['project'].get('problem_statement', ''))" || echo "")
INSPIRATION=$(python3 -c "import sys, json; print(json.load(open('$TEMP_JSON'))['project'].get('inspiration', ''))" || echo "")

# Metadata
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
INTERVIEW_DATE=$(python3 -c "import sys, json; print(json.load(open('$TEMP_JSON'))['metadata'].get('interview_date', '$TIMESTAMP'))" || echo "$TIMESTAMP")
COMPLETENESS=$(python3 -c "import sys, json; print(json.load(open('$TEMP_JSON'))['metadata'].get('completeness', 'complete'))" || echo "complete")

echo -e "${GREEN}✓${NC} Extracted project data"

# ==============================================================================
# Create Comprehensive YAML Spec
# ==============================================================================

echo -e "${BLUE}Generating comprehensive spec...${NC}"

# Create temp YAML file
TEMP_YAML=$(mktemp)
trap "rm -f $TEMP_JSON $TEMP_YAML" EXIT

# Build YAML using yq from scratch
# Start with metadata
yq eval -n ".id = \"$SPEC_ID\" | \
  .title = \"$PROJECT_NAME Project\" | \
  .type = \"project\" | \
  .status = \"discovery\" | \
  .created = \"$TIMESTAMP\" | \
  .updated = \"$TIMESTAMP\" | \
  .version = \"0.1.0\"" > "$TEMP_YAML"

# Add project section
yq eval -i ".project.name = \"$PROJECT_NAME\" | \
  .project.vision = \"$PROJECT_VISION\"" "$TEMP_YAML"

if [[ -n "$PROBLEM_STATEMENT" ]]; then
  yq eval -i ".project.problem_statement = \"$PROBLEM_STATEMENT\"" "$TEMP_YAML"
fi

if [[ -n "$INSPIRATION" ]]; then
  yq eval -i ".project.inspiration = \"$INSPIRATION\"" "$TEMP_YAML"
fi

# Add success metrics
METRICS_COUNT=$(python3 -c "import sys, json; print(len(json.load(open('$TEMP_JSON'))['project'].get('success_metrics', [])))")
for ((i=0; i<METRICS_COUNT; i++)); do
  METRIC=$(python3 -c "import sys, json; print(json.load(open('$TEMP_JSON'))['project']['success_metrics'][$i])")
  yq eval -i ".project.success_metrics[$i] = \"$METRIC\"" "$TEMP_YAML"
done

# Add users
USERS_COUNT=$(python3 -c "import sys, json; print(len(json.load(open('$TEMP_JSON')).get('users', [])))")
echo -e "${BLUE}Processing $USERS_COUNT user types...${NC}"

for ((i=0; i<USERS_COUNT; i++)); do
  # Extract user data using Python (escape for bash)
  python3 << EOF > /tmp/user_${i}.sh
import json
user = json.load(open('$TEMP_JSON'))['users'][$i]
# Escape for bash: remove newlines, escape single quotes
def bash_escape(s):
    if not s:
        return ""
    # Replace ACTUAL newline characters (not the string "\\n")
    s = s.replace('\n', ' ').replace('\r', ' ')
    # Replace single quotes for bash: ' becomes '\''
    s = s.replace("'", "'\\''")
    return s
print(f"USER_TYPE='{bash_escape(user.get('type', ''))}'")
print(f"USER_ROLE='{bash_escape(user.get('role_context', ''))}'")
print(f"USER_TECH_LEVEL='{bash_escape(user.get('technical_level', ''))}'")
print(f"USER_INTERACTION='{bash_escape(user.get('interaction_patterns', ''))}'")
EOF

  source /tmp/user_${i}.sh

  yq eval -i ".users[$i].type = \"$USER_TYPE\" | \
    .users[$i].role_context = \"$USER_ROLE\" | \
    .users[$i].technical_level = \"$USER_TECH_LEVEL\" | \
    .users[$i].interaction_patterns = \"$USER_INTERACTION\"" "$TEMP_YAML"

  # Add arrays (goals, pain_points, needs, current_alternatives)
  for field in goals pain_points needs current_alternatives; do
    FIELD_COUNT=$(python3 -c "import sys, json; print(len(json.load(open('$TEMP_JSON'))['users'][$i].get('$field', [])))")
    for ((j=0; j<FIELD_COUNT; j++)); do
      VALUE=$(python3 -c "import sys, json; print(json.load(open('$TEMP_JSON'))['users'][$i]['$field'][$j])")
      yq eval -i ".users[$i].$field[$j] = \"$VALUE\"" "$TEMP_YAML"
    done
  done

  rm -f /tmp/user_${i}.sh
done

echo -e "${GREEN}✓${NC} Added $USERS_COUNT user types"

# Add features
FEATURES_COUNT=$(python3 -c "import sys, json; print(len(json.load(open('$TEMP_JSON')).get('features', [])))")
echo -e "${BLUE}Processing $FEATURES_COUNT features...${NC}"

for ((i=0; i<FEATURES_COUNT; i++)); do
  # Extract feature data (escape for bash)
  python3 << EOF > /tmp/feature_${i}.sh
import json
feature = json.load(open('$TEMP_JSON'))['features'][$i]
# Escape for bash: remove newlines, escape single quotes
def bash_escape(s):
    if not s:
        return ""
    s = s.replace('\n', ' ').replace('\r', ' ')
    s = s.replace("'", "'\\''")
    return s
print(f"FEAT_TITLE='{bash_escape(feature.get('title', ''))}'")
print(f"FEAT_DESC='{bash_escape(feature.get('description', ''))}'")
print(f"FEAT_VALUE='{bash_escape(feature.get('user_value', ''))}'")
print(f"FEAT_FLOW='{bash_escape(feature.get('user_flow', ''))}'")
print(f"FEAT_PRIORITY='{bash_escape(feature.get('priority', 'medium'))}'")
print(f"FEAT_COMPLEXITY='{bash_escape(feature.get('complexity', 'moderate'))}'")
print(f"FEAT_MVP='{bash_escape(feature.get('mvp_scope', ''))}'")
EOF

  source /tmp/feature_${i}.sh

  yq eval -i ".features[$i].title = \"$FEAT_TITLE\" | \
    .features[$i].description = \"$FEAT_DESC\" | \
    .features[$i].user_value = \"$FEAT_VALUE\" | \
    .features[$i].user_flow = \"$FEAT_FLOW\" | \
    .features[$i].priority = \"$FEAT_PRIORITY\" | \
    .features[$i].complexity = \"$FEAT_COMPLEXITY\" | \
    .features[$i].mvp_scope = \"$FEAT_MVP\"" "$TEMP_YAML"

  # Add arrays (dependencies, risks, edge_cases, future_enhancements)
  for field in dependencies risks edge_cases future_enhancements; do
    FIELD_COUNT=$(python3 -c "import sys, json; print(len(json.load(open('$TEMP_JSON'))['features'][$i].get('$field', [])))")
    for ((j=0; j<FIELD_COUNT; j++)); do
      VALUE=$(python3 -c "import sys, json; print(json.load(open('$TEMP_JSON'))['features'][$i]['$field'][$j])")
      yq eval -i ".features[$i].$field[$j] = \"$VALUE\"" "$TEMP_YAML"
    done
  done

  rm -f /tmp/feature_${i}.sh
done

echo -e "${GREEN}✓${NC} Added $FEATURES_COUNT features"

# Add technical section
echo -e "${BLUE}Adding technical context...${NC}"

# Stack
python3 << 'EOF' > /tmp/tech_stack.sh
import json
tech = json.load(open('$TEMP_JSON'))['technical']
stack = tech.get('stack', {})
# Escape for bash: remove newlines, escape single quotes
def bash_escape(s):
    if not s:
        return ""
    s = s.replace('\n', ' ').replace('\r', ' ')
    s = s.replace("'", "'\\''")
    return s
print(f"TECH_LANG='{bash_escape(stack.get('language', ''))}'")
print(f"TECH_LANG_WHY='{bash_escape(stack.get('language_rationale', ''))}'")
print(f"TECH_FRAMEWORK='{bash_escape(stack.get('framework', ''))}'")
print(f"TECH_FRAMEWORK_WHY='{bash_escape(stack.get('framework_rationale', ''))}'")
print(f"TECH_DB='{bash_escape(stack.get('database', ''))}'")
print(f"TECH_DB_WHY='{bash_escape(stack.get('database_rationale', ''))}'")
print(f"TECH_HOSTING='{bash_escape(stack.get('hosting', ''))}'")
print(f"TECH_HOSTING_WHY='{bash_escape(stack.get('hosting_rationale', ''))}'")
EOF
sed -i "s/\$TEMP_JSON/$TEMP_JSON/g" /tmp/tech_stack.sh
source /tmp/tech_stack.sh

yq eval -i ".technical.stack.language = \"$TECH_LANG\" | \
  .technical.stack.language_rationale = \"$TECH_LANG_WHY\" | \
  .technical.stack.framework = \"$TECH_FRAMEWORK\" | \
  .technical.stack.framework_rationale = \"$TECH_FRAMEWORK_WHY\" | \
  .technical.stack.database = \"$TECH_DB\" | \
  .technical.stack.database_rationale = \"$TECH_DB_WHY\" | \
  .technical.stack.hosting = \"$TECH_HOSTING\" | \
  .technical.stack.hosting_rationale = \"$TECH_HOSTING_WHY\"" "$TEMP_YAML"

# Other tools
TOOLS_COUNT=$(python3 -c "import sys, json; print(len(json.load(open('$TEMP_JSON'))['technical']['stack'].get('other_tools', [])))")
for ((i=0; i<TOOLS_COUNT; i++)); do
  TOOL=$(python3 -c "import sys, json; print(json.load(open('$TEMP_JSON'))['technical']['stack']['other_tools'][$i])")
  yq eval -i ".technical.stack.other_tools[$i] = \"$TOOL\"" "$TEMP_YAML"
done

# Architecture
python3 << 'EOF' > /tmp/tech_arch.sh
import json
tech = json.load(open('$TEMP_JSON'))['technical']
arch = tech.get('architecture', {})
def bash_escape(s):
    if not s:
        return ""
    s = s.replace('\n', ' ').replace('\r', ' ')
    s = s.replace("'", "'\\''")
    return s
print(f"ARCH_STYLE='{bash_escape(arch.get('style', ''))}'")
EOF
sed -i "s/\$TEMP_JSON/$TEMP_JSON/g" /tmp/tech_arch.sh
source /tmp/tech_arch.sh

yq eval -i ".technical.architecture.style = \"$ARCH_STYLE\"" "$TEMP_YAML"

# Architectural constraints
CONSTRAINTS_COUNT=$(python3 -c "import sys, json; print(len(json.load(open('$TEMP_JSON'))['technical']['architecture'].get('architectural_constraints', [])))")
for ((i=0; i<CONSTRAINTS_COUNT; i++)); do
  CONSTRAINT=$(python3 -c "import sys, json; print(json.load(open('$TEMP_JSON'))['technical']['architecture']['architectural_constraints'][$i])")
  yq eval -i ".technical.architecture.architectural_constraints[$i] = \"$CONSTRAINT\"" "$TEMP_YAML"
done

# Compliance requirements
COMPLIANCE_COUNT=$(python3 -c "import sys, json; print(len(json.load(open('$TEMP_JSON'))['technical']['architecture'].get('compliance_requirements', [])))")
for ((i=0; i<COMPLIANCE_COUNT; i++)); do
  COMPLIANCE=$(python3 -c "import sys, json; print(json.load(open('$TEMP_JSON'))['technical']['architecture']['compliance_requirements'][$i])")
  yq eval -i ".technical.architecture.compliance_requirements[$i] = \"$COMPLIANCE\"" "$TEMP_YAML"
done

# Data
python3 << 'EOF' > /tmp/tech_data.sh
import json
tech = json.load(open('$TEMP_JSON'))['technical']
data = tech.get('data', {})
# Escape for bash: remove newlines, escape single quotes
def bash_escape(s):
    if not s:
        return ""
    s = s.replace('\n', ' ').replace('\r', ' ')
    s = s.replace("'", "'\\''")
    return s
print(f"DATA_SCALE='{bash_escape(data.get('scale_expectations', ''))}'")
print(f"DATA_SENSITIVE='{str(data.get('sensitive_data', False)).lower()}'")
print(f"DATA_BACKUP='{bash_escape(data.get('backup_requirements', ''))}'")
EOF
sed -i "s/\$TEMP_JSON/$TEMP_JSON/g" /tmp/tech_data.sh
source /tmp/tech_data.sh

yq eval -i ".technical.data.scale_expectations = \"$DATA_SCALE\" | \
  .technical.data.sensitive_data = $DATA_SENSITIVE | \
  .technical.data.backup_requirements = \"$DATA_BACKUP\"" "$TEMP_YAML"

# Storage needs
STORAGE_COUNT=$(python3 -c "import sys, json; print(len(json.load(open('$TEMP_JSON'))['technical']['data'].get('storage_needs', [])))")
for ((i=0; i<STORAGE_COUNT; i++)); do
  STORAGE=$(python3 -c "import sys, json; print(json.load(open('$TEMP_JSON'))['technical']['data']['storage_needs'][$i])")
  yq eval -i ".technical.data.storage_needs[$i] = \"$STORAGE\"" "$TEMP_YAML"
done

# Sensitive data types
SENSITIVE_COUNT=$(python3 -c "import sys, json; print(len(json.load(open('$TEMP_JSON'))['technical']['data'].get('sensitive_data_types', [])))")
for ((i=0; i<SENSITIVE_COUNT; i++)); do
  SENSITIVE=$(python3 -c "import sys, json; print(json.load(open('$TEMP_JSON'))['technical']['data']['sensitive_data_types'][$i])")
  yq eval -i ".technical.data.sensitive_data_types[$i] = \"$SENSITIVE\"" "$TEMP_YAML"
done

# Auth
python3 << 'EOF' > /tmp/tech_auth.sh
import json
tech = json.load(open('$TEMP_JSON'))['technical']
auth = tech.get('auth', {})
# Escape for bash: remove newlines, escape single quotes
def bash_escape(s):
    if not s:
        return ""
    s = s.replace('\n', ' ').replace('\r', ' ')
    s = s.replace("'", "'\\''")
    return s
print(f"AUTH_APPROACH='{bash_escape(auth.get('approach', ''))}'")
print(f"AUTH_RBAC='{str(auth.get('role_based_access', False)).lower()}'")
EOF
sed -i "s/\$TEMP_JSON/$TEMP_JSON/g" /tmp/tech_auth.sh
source /tmp/tech_auth.sh

yq eval -i ".technical.auth.approach = \"$AUTH_APPROACH\" | \
  .technical.auth.role_based_access = $AUTH_RBAC" "$TEMP_YAML"

# Auth methods
METHODS_COUNT=$(python3 -c "import sys, json; print(len(json.load(open('$TEMP_JSON'))['technical']['auth'].get('methods', [])))")
for ((i=0; i<METHODS_COUNT; i++)); do
  METHOD=$(python3 -c "import sys, json; print(json.load(open('$TEMP_JSON'))['technical']['auth']['methods'][$i])")
  yq eval -i ".technical.auth.methods[$i] = \"$METHOD\"" "$TEMP_YAML"
done

# Roles
ROLES_COUNT=$(python3 -c "import sys, json; print(len(json.load(open('$TEMP_JSON'))['technical']['auth'].get('roles', [])))")
for ((i=0; i<ROLES_COUNT; i++)); do
  ROLE=$(python3 -c "import sys, json; print(json.load(open('$TEMP_JSON'))['technical']['auth']['roles'][$i])")
  yq eval -i ".technical.auth.roles[$i] = \"$ROLE\"" "$TEMP_YAML"
done

# Integrations
INTEGRATIONS_COUNT=$(python3 -c "import sys, json; print(len(json.load(open('$TEMP_JSON'))['technical'].get('integrations', [])))")
for ((i=0; i<INTEGRATIONS_COUNT; i++)); do
  python3 << EOF > /tmp/integration_${i}.sh
import json
integration = json.load(open('$TEMP_JSON'))['technical']['integrations'][$i]
# Escape for bash: remove newlines, escape single quotes
def bash_escape(s):
    if not s:
        return ""
    s = s.replace('\n', ' ').replace('\r', ' ')
    s = s.replace("'", "'\\''")
    return s
print(f"INT_SYSTEM='{bash_escape(integration.get('system', ''))}'")
print(f"INT_PURPOSE='{bash_escape(integration.get('purpose', ''))}'")
print(f"INT_DATA='{bash_escape(integration.get('data_exchanged', ''))}'")
print(f"INT_FREQ='{bash_escape(integration.get('frequency', ''))}'")
print(f"INT_API='{str(integration.get('api_available', False)).lower()}'")
print(f"INT_NOTES='{bash_escape(integration.get('notes', ''))}'")
EOF

  source /tmp/integration_${i}.sh

  yq eval -i ".technical.integrations[$i].system = \"$INT_SYSTEM\" | \
    .technical.integrations[$i].purpose = \"$INT_PURPOSE\" | \
    .technical.integrations[$i].data_exchanged = \"$INT_DATA\" | \
    .technical.integrations[$i].frequency = \"$INT_FREQ\" | \
    .technical.integrations[$i].api_available = $INT_API | \
    .technical.integrations[$i].notes = \"$INT_NOTES\"" "$TEMP_YAML"

  rm -f /tmp/integration_${i}.sh
done

# Infrastructure
python3 << 'EOF' > /tmp/tech_infra.sh
import json
tech = json.load(open('$TEMP_JSON'))['technical']
infra = tech.get('infrastructure', {})
# Escape for bash: remove newlines, escape single quotes
def bash_escape(s):
    if not s:
        return ""
    s = s.replace('\n', ' ').replace('\r', ' ')
    s = s.replace("'", "'\\''")
    return s
print(f"INFRA_PLATFORM='{bash_escape(infra.get('hosting_platform', ''))}'")
print(f"INFRA_CICD='{bash_escape(infra.get('cicd_preference', ''))}'")
print(f"INFRA_PERF='{bash_escape(infra.get('performance_requirements', ''))}'")
EOF
sed -i "s/\$TEMP_JSON/$TEMP_JSON/g" /tmp/tech_infra.sh
source /tmp/tech_infra.sh

yq eval -i ".technical.infrastructure.hosting_platform = \"$INFRA_PLATFORM\" | \
  .technical.infrastructure.cicd_preference = \"$INFRA_CICD\" | \
  .technical.infrastructure.performance_requirements = \"$INFRA_PERF\"" "$TEMP_YAML"

# Monitoring needs
MONITORING_COUNT=$(python3 -c "import sys, json; print(len(json.load(open('$TEMP_JSON'))['technical']['infrastructure'].get('monitoring_needs', [])))")
for ((i=0; i<MONITORING_COUNT; i++)); do
  MONITORING=$(python3 -c "import sys, json; print(json.load(open('$TEMP_JSON'))['technical']['infrastructure']['monitoring_needs'][$i])")
  yq eval -i ".technical.infrastructure.monitoring_needs[$i] = \"$MONITORING\"" "$TEMP_YAML"
done

rm -f /tmp/tech_*.sh

echo -e "${GREEN}✓${NC} Added technical context"

# Add constraints
echo -e "${BLUE}Adding constraints...${NC}"

python3 << 'EOF' > /tmp/constraints.sh
import json
constraints = json.load(open('$TEMP_JSON')).get('constraints', {})
timeline = constraints.get('timeline', {})
team = constraints.get('team', {})
budget = constraints.get('budget', {})
# Escape for bash: remove newlines, escape single quotes
def bash_escape(s):
    if not s:
        return ""
    s = s.replace('\n', ' ').replace('\r', ' ')
    s = s.replace("'", "'\\''")
    return s

print(f"TIMELINE_DATE='{bash_escape(timeline.get('target_date', ''))}'")
print(f"TIMELINE_HARD='{str(timeline.get('hard_deadline', False)).lower()}'")
print(f"TEAM_SIZE='{team.get('size', 0)}'")
EOF
sed -i "s/\$TEMP_JSON/$TEMP_JSON/g" /tmp/constraints.sh
source /tmp/constraints.sh

yq eval -i ".constraints.timeline.target_date = \"$TIMELINE_DATE\" | \
  .constraints.timeline.hard_deadline = $TIMELINE_HARD | \
  .constraints.team.size = $TEAM_SIZE" "$TEMP_YAML"

# Timeline drivers
DRIVERS_COUNT=$(python3 -c "import sys, json; print(len(json.load(open('$TEMP_JSON'))['constraints']['timeline'].get('drivers', [])))")
for ((i=0; i<DRIVERS_COUNT; i++)); do
  DRIVER=$(python3 -c "import sys, json; print(json.load(open('$TEMP_JSON'))['constraints']['timeline']['drivers'][$i])")
  yq eval -i ".constraints.timeline.drivers[$i] = \"$DRIVER\"" "$TEMP_YAML"
done

# Milestones
MILESTONES_COUNT=$(python3 -c "import sys, json; print(len(json.load(open('$TEMP_JSON'))['constraints']['timeline'].get('milestones', [])))")
for ((i=0; i<MILESTONES_COUNT; i++)); do
  MILESTONE=$(python3 -c "import sys, json; print(json.load(open('$TEMP_JSON'))['constraints']['timeline']['milestones'][$i])")
  yq eval -i ".constraints.timeline.milestones[$i] = \"$MILESTONE\"" "$TEMP_YAML"
done

# Team roles
TEAM_ROLES_COUNT=$(python3 -c "import sys, json; print(len(json.load(open('$TEMP_JSON'))['constraints']['team'].get('roles', [])))")
for ((i=0; i<TEAM_ROLES_COUNT; i++)); do
  ROLE=$(python3 -c "import sys, json; print(json.load(open('$TEMP_JSON'))['constraints']['team']['roles'][$i])")
  yq eval -i ".constraints.team.roles[$i] = \"$ROLE\"" "$TEMP_YAML"
done

# Skill gaps
GAPS_COUNT=$(python3 -c "import sys, json; print(len(json.load(open('$TEMP_JSON'))['constraints']['team'].get('skill_gaps', [])))")
for ((i=0; i<GAPS_COUNT; i++)); do
  GAP=$(python3 -c "import sys, json; print(json.load(open('$TEMP_JSON'))['constraints']['team']['skill_gaps'][$i])")
  yq eval -i ".constraints.team.skill_gaps[$i] = \"$GAP\"" "$TEMP_YAML"
done

# Budget constraints
BUDGET_CONSTRAINTS_COUNT=$(python3 -c "import sys, json; print(len(json.load(open('$TEMP_JSON'))['constraints']['budget'].get('constraints', [])))")
for ((i=0; i<BUDGET_CONSTRAINTS_COUNT; i++)); do
  CONSTRAINT=$(python3 -c "import sys, json; print(json.load(open('$TEMP_JSON'))['constraints']['budget']['constraints'][$i])")
  yq eval -i ".constraints.budget.constraints[$i] = \"$CONSTRAINT\"" "$TEMP_YAML"
done

python3 << 'EOF' > /tmp/budget.sh
import json
constraints = json.load(open('$TEMP_JSON')).get('constraints', {})
budget = constraints.get('budget', {})
# Escape for bash: remove newlines, escape single quotes
def bash_escape(s):
    if not s:
        return ""
    s = s.replace('\n', ' ').replace('\r', ' ')
    s = s.replace("'", "'\\''")
    return s
print(f"BUDGET_INFRA='{bash_escape(budget.get('infrastructure_budget', ''))}'")
print(f"BUDGET_SERVICE='{bash_escape(budget.get('service_budget', ''))}'")
EOF
sed -i "s/\$TEMP_JSON/$TEMP_JSON/g" /tmp/budget.sh
source /tmp/budget.sh

yq eval -i ".constraints.budget.infrastructure_budget = \"$BUDGET_INFRA\" | \
  .constraints.budget.service_budget = \"$BUDGET_SERVICE\"" "$TEMP_YAML"

rm -f /tmp/constraints.sh /tmp/budget.sh

echo -e "${GREEN}✓${NC} Added constraints"

# Add risks
RISKS_COUNT=$(python3 -c "import sys, json; print(len(json.load(open('$TEMP_JSON')).get('risks', [])))")
echo -e "${BLUE}Processing $RISKS_COUNT risks...${NC}"

for ((i=0; i<RISKS_COUNT; i++)); do
  python3 << EOF > /tmp/risk_${i}.sh
import json
risk = json.load(open('$TEMP_JSON'))['risks'][$i]
# Escape for bash: remove newlines, escape single quotes
def bash_escape(s):
    if not s:
        return ""
    s = s.replace('\n', ' ').replace('\r', ' ')
    s = s.replace("'", "'\\''")
    return s
print(f"RISK_TYPE='{bash_escape(risk.get('type', ''))}'")
print(f"RISK_DESC='{bash_escape(risk.get('description', ''))}'")
print(f"RISK_LIKELIHOOD='{bash_escape(risk.get('likelihood', ''))}'")
print(f"RISK_IMPACT='{bash_escape(risk.get('impact', ''))}'")
print(f"RISK_MITIGATION='{bash_escape(risk.get('mitigation', ''))}'")
EOF

  source /tmp/risk_${i}.sh

  yq eval -i ".risks[$i].type = \"$RISK_TYPE\" | \
    .risks[$i].description = \"$RISK_DESC\" | \
    .risks[$i].likelihood = \"$RISK_LIKELIHOOD\" | \
    .risks[$i].impact = \"$RISK_IMPACT\" | \
    .risks[$i].mitigation = \"$RISK_MITIGATION\"" "$TEMP_YAML"

  rm -f /tmp/risk_${i}.sh
done

echo -e "${GREEN}✓${NC} Added $RISKS_COUNT risks"

# Add success criteria
echo -e "${BLUE}Adding success criteria...${NC}"

python3 << 'EOF' > /tmp/success.sh
import json
success = json.load(open('$TEMP_JSON')).get('success', {})
# Escape for bash: remove newlines, escape single quotes
def bash_escape(s):
    if not s:
        return ""
    s = s.replace('\n', ' ').replace('\r', ' ')
    s = s.replace("'", "'\\''")
    return s
print(f"SUCCESS_DOD='{bash_escape(success.get('definition_of_done', ''))}'")
EOF
sed -i "s/\$TEMP_JSON/$TEMP_JSON/g" /tmp/success.sh
source /tmp/success.sh

yq eval -i ".success.definition_of_done = \"$SUCCESS_DOD\"" "$TEMP_YAML"

# MVP scope
MVP_COUNT=$(python3 -c "import sys, json; print(len(json.load(open('$TEMP_JSON'))['success'].get('mvp_scope', [])))")
for ((i=0; i<MVP_COUNT; i++)); do
  MVP=$(python3 -c "import sys, json; print(json.load(open('$TEMP_JSON'))['success']['mvp_scope'][$i])")
  yq eval -i ".success.mvp_scope[$i] = \"$MVP\"" "$TEMP_YAML"
done

# Must have features
MUST_HAVE_COUNT=$(python3 -c "import sys, json; print(len(json.load(open('$TEMP_JSON'))['success'].get('must_have_features', [])))")
for ((i=0; i<MUST_HAVE_COUNT; i++)); do
  FEATURE=$(python3 -c "import sys, json; print(json.load(open('$TEMP_JSON'))['success']['must_have_features'][$i])")
  yq eval -i ".success.must_have_features[$i] = \"$FEATURE\"" "$TEMP_YAML"
done

# Metrics
METRICS_COUNT=$(python3 -c "import sys, json; print(len(json.load(open('$TEMP_JSON'))['success'].get('metrics', [])))")
for ((i=0; i<METRICS_COUNT; i++)); do
  METRIC=$(python3 -c "import sys, json; print(json.load(open('$TEMP_JSON'))['success']['metrics'][$i])")
  yq eval -i ".success.metrics[$i] = \"$METRIC\"" "$TEMP_YAML"
done

# Future vision
python3 << 'EOF' > /tmp/vision.sh
import json
success = json.load(open('$TEMP_JSON')).get('success', {})
vision = success.get('future_vision', {})
# Escape for bash: remove newlines, escape single quotes
def bash_escape(s):
    if not s:
        return ""
    s = s.replace('\n', ' ').replace('\r', ' ')
    s = s.replace("'", "'\\''")
    return s
EOF
sed -i "s/\$TEMP_JSON/$TEMP_JSON/g" /tmp/vision.sh
source /tmp/vision.sh

# Long term goals
GOALS_COUNT=$(python3 -c "import sys, json; print(len(json.load(open('$TEMP_JSON'))['success']['future_vision'].get('long_term_goals', [])))")
for ((i=0; i<GOALS_COUNT; i++)); do
  GOAL=$(python3 -c "import sys, json; print(json.load(open('$TEMP_JSON'))['success']['future_vision']['long_term_goals'][$i])")
  yq eval -i ".success.future_vision.long_term_goals[$i] = \"$GOAL\"" "$TEMP_YAML"
done

# Future phases
PHASES_COUNT=$(python3 -c "import sys, json; print(len(json.load(open('$TEMP_JSON'))['success']['future_vision'].get('future_phases', [])))")
for ((i=0; i<PHASES_COUNT; i++)); do
  PHASE=$(python3 -c "import sys, json; print(json.load(open('$TEMP_JSON'))['success']['future_vision']['future_phases'][$i])")
  yq eval -i ".success.future_vision.future_phases[$i] = \"$PHASE\"" "$TEMP_YAML"
done

# Blue sky features
BLUE_SKY_COUNT=$(python3 -c "import sys, json; print(len(json.load(open('$TEMP_JSON'))['success']['future_vision'].get('blue_sky_features', [])))")
for ((i=0; i<BLUE_SKY_COUNT; i++)); do
  FEATURE=$(python3 -c "import sys, json; print(json.load(open('$TEMP_JSON'))['success']['future_vision']['blue_sky_features'][$i])")
  yq eval -i ".success.future_vision.blue_sky_features[$i] = \"$FEATURE\"" "$TEMP_YAML"
done

rm -f /tmp/success.sh /tmp/vision.sh

echo -e "${GREEN}✓${NC} Added success criteria"

# Add open questions
QUESTIONS_COUNT=$(python3 -c "import sys, json; print(len(json.load(open('$TEMP_JSON')).get('open_questions', [])))")
echo -e "${BLUE}Processing $QUESTIONS_COUNT open questions...${NC}"

for ((i=0; i<QUESTIONS_COUNT; i++)); do
  python3 << EOF > /tmp/question_${i}.sh
import json
question = json.load(open('$TEMP_JSON'))['open_questions'][$i]
# Escape for bash: remove newlines, escape single quotes
def bash_escape(s):
    if not s:
        return ""
    s = s.replace('\n', ' ').replace('\r', ' ')
    s = s.replace("'", "'\\''")
    return s
print(f"Q_QUESTION='{bash_escape(question.get('question', ''))}'")
print(f"Q_CONTEXT='{bash_escape(question.get('context', ''))}'")
print(f"Q_PRIORITY='{bash_escape(question.get('priority', ''))}'")
EOF

  source /tmp/question_${i}.sh

  yq eval -i ".open_questions[$i].question = \"$Q_QUESTION\" | \
    .open_questions[$i].context = \"$Q_CONTEXT\" | \
    .open_questions[$i].priority = \"$Q_PRIORITY\"" "$TEMP_YAML"

  rm -f /tmp/question_${i}.sh
done

echo -e "${GREEN}✓${NC} Added $QUESTIONS_COUNT open questions"

# Add metadata
yq eval -i ".metadata.interview_date = \"$INTERVIEW_DATE\" | \
  .metadata.completeness = \"$COMPLETENESS\" | \
  .metadata.generated_by = \"spec-drive app-new workflow\"" "$TEMP_YAML"

echo -e "${GREEN}✓${NC} Comprehensive spec generated"

# ==============================================================================
# Write to Final Location
# ==============================================================================

# Ensure specs directory exists
mkdir -p "$SPECS_DIR"

# Atomic write
mv "$TEMP_YAML" "$SPEC_FILE" || {
  echo -e "${RED}❌ ERROR: Cannot write spec file: $SPEC_FILE${NC}" >&2
  exit 1
}

echo -e "${GREEN}✅ Created comprehensive spec: $SPEC_FILE${NC}"
exit 0
