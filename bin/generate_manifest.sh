#!/bin/bash

# Determine the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Plugin root directory (parent of bin/)
PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"

# Paths
DATA_FILE="$PLUGIN_DIR/data/stratagems.txt"
OUTPUT_FILE="$PLUGIN_DIR/manifest.json"
HASH_FILE="$PLUGIN_DIR/data/.stratagems.md5"

# Check if manifest file exists
if [[ ! -f "$OUTPUT_FILE" ]]; then
    echo "Error: manifest file '$OUTPUT_FILE' not found." >&2
    exit 1
fi

# Function to calculate md5 hash of a file
get_hash() {
    md5sum "$1" | awk '{print $1}'
}

# Check if hash file exists and compare hashes
if [[ -f "$HASH_FILE" ]]; then
    OLD_HASH=$(cat "$HASH_FILE")
    NEW_HASH=$(get_hash "$DATA_FILE")
    if [[ "$OLD_HASH" == "$NEW_HASH" ]]; then
        echo "No changes detected. Manifest not updated."
        exit 0
    fi
fi

# Associative array for UUID uniqueness check
declare -A uuid_map

# Line counter for error messages
line_num=0

# Function to escape a string for JSON (replaces \, " and control characters)
json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"   # backslash
    s="${s//\"/\\\"}"   # double quote
    s="${s//$'\n'/\\n}" # newline
    s="${s//$'\r'/\\r}" # carriage return
    s="${s//$'\t'/\\t}" # tab
    printf '%s' "$s"
}

# Function to increment patch version (assumes format major.minor.patch)
increment_version() {
    local version="$1"
    local major minor patch
    IFS='.' read -r major minor patch <<< "$version"
    patch=$((10#$patch + 1))
    echo "$major.$minor.$patch"
}

# Build the Actions array content (without outer brackets)
actions_content=""
first=1

# Read data file line by line
while IFS='|' read -r display_category display_name icon_path; do
    ((line_num++))

    # Skip empty lines and comment lines (starting with #)
    [[ -z "$display_category" && -z "$display_name" && -z "$icon_path" ]] && continue
    [[ "$display_category" == \#* ]] && continue

    # Check mandatory fields
    if [[ -z "$display_category" || -z "$display_name" || -z "$icon_path" ]]; then
        echo "Error on line $line_num: all fields (display_category, display_name, icon_path) are mandatory." >&2
        echo "Line content: display_category='$display_category' display_name='$display_name' icon_path='$icon_path'" >&2
        exit 1
    fi

    # Extract filename from icon_path (basename)
    filename=$(basename "$icon_path")
    if [[ -z "$filename" ]]; then
        echo "Error on line $line_num: cannot extract filename from icon_path '$icon_path'." >&2
        exit 1
    fi

    # Generate UUID using filename
    uuid="com.user.helldivers2.${filename}.key"

    # Check for duplicate UUID
    if [[ -n "${uuid_map[$uuid]}" ]]; then
        echo "Error: duplicate UUID '$uuid' for strategem '$display_name'. Previously used for '${uuid_map[$uuid]}'." >&2
        exit 1
    fi
    uuid_map[$uuid]="$display_name"

    # Escape fields for JSON
    e_display_category=$(json_escape "$display_category")
    e_display_name=$(json_escape "$display_name")
    e_icon_path=$(json_escape "$icon_path")

    # Build Name field: [display_category] display_name
    name_field="[${e_display_category}] ${e_display_name}"

    # Build JSON object for the action
    action_obj=$(cat <<EOF
    {
      "UUID": "$uuid",
      "Name": "$name_field",
      "Tooltip": "$e_display_name",
      "Icon": "$e_icon_path",
      "States": [ { "Image": "$e_icon_path", "TitleMode": "NoChange" } ]
    }
EOF
)

    # Add comma if not the first element
    if [ $first -eq 1 ]; then
        first=0
    else
        actions_content+=","
    fi
    actions_content+="$action_obj"
done < "$DATA_FILE"

# Extract current version from manifest
CURRENT_VERSION=$(sed -n 's/.*"Version": *"\([^"]*\)".*/\1/p' "$OUTPUT_FILE" | head -n1)
if [[ -z "$CURRENT_VERSION" ]]; then
    echo "Error: could not parse version from existing manifest." >&2
    exit 1
fi

NEW_VERSION=$(increment_version "$CURRENT_VERSION")

# Create final manifest.json using heredoc
cat > "$OUTPUT_FILE" <<EOF
{
  "Name": "Helldivers 2",
  "Author": "TrSaur",
  "Description": "Helldivers 2 Stratagems",
  "Version": "$NEW_VERSION",
  "SDKVersion": 2,
  "CodePathLin": "bin/run.sh",
  "Icon": "images/assets/hd2",
  "Category": "Helldivers 2",
  "OS": [ { "Platform": "linux", "MinimumVersion": "1.0" } ],
  "Actions": [
$actions_content
  ]
}
EOF

# Update hash file
NEW_HASH=$(get_hash "$DATA_FILE")
echo "$NEW_HASH" > "$HASH_FILE"

echo "manifest.json successfully updated (version $NEW_VERSION) from $DATA_FILE"
