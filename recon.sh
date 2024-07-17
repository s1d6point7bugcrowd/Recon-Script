#!/bin/bash

# Define colors for output using RGB
ORANGE='\033[38;2;255;165;0m'
NC='\033[0m' # No Color
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'

# Define speech parameters
SPEECH_RATE=140
VOICE="en+f3" # English female voice

# Function for voice announcements
function announce_message() {
    local message=$1
    if [ "$ENABLE_VOICE" == "y" ]; then
        espeak -s $SPEECH_RATE -v $VOICE "$message"
    fi
}

# Display banner with lolcat
echo -e "${BLUE}coded by: s1d6p01nt7${NC}" | lolcat

# Prompt to enable voice announcements
echo -e "${ORANGE}Do you want to enable voice announcements? (y/n)${NC}"
read ENABLE_VOICE

# Welcome message
announce_message "Voice notifications activated."

# Pause to display the banner and clear the screen
sleep 2
clear

# Prompt to decide data storage
announce_message "Do you want to store the data permanently? Enter yes or no."
echo -e "${ORANGE}Do you want to store the data permanently? (y/n)${NC}"
read STORE_PERMANENTLY

# Set data directory based on user input
if [ "$STORE_PERMANENTLY" == "n" ]; then
    DATA_DIR="/tmp"
else
    DATA_DIR="./data"
    mkdir -p $DATA_DIR
fi

# Prompt to use proxychains
announce_message "Do you want to use proxychains? Enter yes or no."
echo -e "${ORANGE}Do you want to use proxychains? (y/n)${NC}"
read USE_PROXYCHAINS

# Set proxychains command based on user input
if [ "$USE_PROXYCHAINS" == "y" ]; then
    PROXYCHAINS_CMD="proxychains"
else
    PROXYCHAINS_CMD=""
fi

# Prompt to scan a domain or a single URL
announce_message "Do you want to scan a domain or a single URL? Enter one for domain or two for URL."
echo -e "${ORANGE}Do you want to scan a domain (1) or a single URL (2)?${NC}"
read SCAN_TYPE

# Validate SCAN_TYPE input
if [[ "$SCAN_TYPE" != "1" && "$SCAN_TYPE" != "2" ]]; then
    echo -e "${RED}Invalid option selected.${NC}"
    exit 1
fi

# Prompt for out-of-scope patterns
announce_message "Enter comma-separated out-of-scope patterns."
echo -e "${ORANGE}Enter comma-separated out-of-scope patterns (e.g., *.example.com, example.example.com):${NC}"
read OOS_INPUT

# Handle empty OOS patterns
if [ -z "$OOS_INPUT" ]; then
    OOS_PATTERNS=()
else
    OOS_PATTERNS=(${OOS_INPUT//,/ })
fi

# Debug: Display out-of-scope patterns
echo -e "${CYAN}Debug: OOS_PATTERNS='${OOS_PATTERNS[*]}'${NC}"

# Prompt for bug bounty program name
announce_message "Enter the bug bounty program name."
echo -e "${ORANGE}Enter the bug bounty program name:${NC}"
read PROGRAM_NAME
CUSTOM_HEADER="X-Bug-Bounty: researcher@$PROGRAM_NAME"

# Prompt for Nuclei template paths
announce_message "Enter the Nuclei template paths (comma-separated)."
echo -e "${ORANGE}Enter the Nuclei template paths (comma-separated):${NC}"
read TEMPLATE_PATHS

# Handle Nuclei template paths
if [ -z "$TEMPLATE_PATHS" ]; then
    echo -e "${CYAN}No Nuclei template paths provided. Using default Nuclei command.${NC}"
    TEMPLATE_PATHS_ARRAY=()
else
    TEMPLATE_PATHS_ARRAY=(${TEMPLATE_PATHS//,/ })
fi

# Prompt for Nuclei template tags
announce_message "Enter the Nuclei template tags (comma-separated)."
echo -e "${ORANGE}Enter the Nuclei template tags (comma-separated):${NC}"
read TEMPLATE_TAGS

# Handle Nuclei template tags
if [ -z "$TEMPLATE_TAGS" ]; then
    echo -e "${CYAN}No Nuclei template tags provided. Using default Nuclei command.${NC}"
    TEMPLATE_TAGS_ARRAY=()
else
    TEMPLATE_TAGS_ARRAY=(${TEMPLATE_TAGS//,/ })
fi

# Function to announce vulnerability severity
function announce_vulnerability() {
    local severity=$1
    case $severity in
        "medium")
            echo -e "${GREEN}Announcing: Medium severity vulnerability detected${NC}"
            ;;
        "high")
            echo -e "${RED}Announcing: High severity vulnerability detected${NC}"
            ;;
        "critical")
            echo -e "${RED}Announcing: Critical severity vulnerability detected${NC}"
            ;;
        *)
            echo -e "${CYAN}Announcing: $severity severity vulnerability detected${NC}"
            ;;
    esac
    announce_message "$severity severity vulnerability detected"
}

# Check if espeak is installed
if ! command -v espeak &> /dev/null; then
    echo -e "${RED}espeak command not found. Please install espeak to enable voice announcements.${NC}"
    exit 1
fi

# Function to run Nuclei
function run_nuclei() {
    local target_file=$1
    local nuclei_cmd="nuclei -rl 5 -ss template-spray -H \"$CUSTOM_HEADER\""

    if [ ${#TEMPLATE_PATHS_ARRAY[@]} -ne 0 ]; then
        for template_path in "${TEMPLATE_PATHS_ARRAY[@]}"; do
            nuclei_cmd+=" -t $template_path"
        done
    fi

    if [ ${#TEMPLATE_TAGS_ARRAY[@]} -ne 0 ]; then
        nuclei_cmd+=" -tags ${TEMPLATE_TAGS_ARRAY[*]}"
    fi

    echo -e "${ORANGE}Running nuclei command: $nuclei_cmd on targets in $target_file...${NC}"
    eval "$PROXYCHAINS_CMD cat $target_file | $nuclei_cmd" | tee -a "${DATA_DIR}/nuclei-output.txt" | while read -r line; do
        echo "$line"
        if echo "$line" | grep -iq 'medium'; then
            announce_vulnerability "medium"
        elif echo "$line" | grep -iq 'high'; then
            announce_vulnerability "high"
        elif echo "$line" | grep -iq 'critical'; then
            announce_vulnerability "critical"
        fi
    done
}

# Function to filter out-of-scope patterns
function filter_oos() {
    local input_file=$1
    local output_file=$2
    > "$output_file"
    while read -r line; do
        local in_scope=true
        for oos in "${OOS_PATTERNS[@]}"; do
            if [[ "$line" == *"$oos"* ]]; then
                in_scope=false
                echo -e "${CYAN}OOS: $line${NC}"
                break
            fi
        done
        if $in_scope; then
            echo "$line" >> "$output_file"
        fi
    done < "$input_file"
}

# Function to find new subdomains discovered by dnsx
function find_new_subdomains() {
    local original_file=$1
    local new_file=$2
    local output_file=$3

    # Use comm to find new subdomains in dnsx results
    comm -13 <(sort "$original_file") <(sort "$new_file") > "$output_file"

    if [ -s "$output_file" ]; then
        echo -e "${ORANGE}New subdomains discovered:${NC}"
        cat "$output_file"
    else
        echo -e "${CYAN}No new subdomains discovered by dnsx.${NC}"
    fi
}

# Main logic for domain or URL scan
if [[ "$SCAN_TYPE" -eq 1 ]]; then
    announce_message "Enter the target domain."
    echo -e "${ORANGE}Enter the target domain:${NC}"
    read TARGET

    announce_message "Running subfinder..."
    echo -e "${ORANGE}Running subfinder...${NC}"
    $PROXYCHAINS_CMD subfinder -d $TARGET -silent -all | anew ${DATA_DIR}/${TARGET}-subs.txt

    announce_message "Filtering out-of-scope patterns from subfinder results..."
    echo -e "${ORANGE}Subfinder completed. Filtering OOS patterns...${NC}"
    filter_oos "${DATA_DIR}/${TARGET}-subs.txt" "${DATA_DIR}/${TARGET}-filtered-subs.txt"
    echo -e "${ORANGE}Filtered subdomains:${NC}"
    cat ${DATA_DIR}/${TARGET}-filtered-subs.txt

    announce_message "Running dnsx on filtered subdomains with resolver list to expand results..."
    echo -e "${ORANGE}OOS filtering completed. Running dnsx...${NC}"
    $PROXYCHAINS_CMD dnsx -rl 5 -resp -silent -r /home/kali/resolvers/resolvers-community.txt < ${DATA_DIR}/${TARGET}-filtered-subs.txt | anew ${DATA_DIR}/${TARGET}-dnsx-results.txt

    # Combine results from dnsx to further discover subdomains
    anew ${DATA_DIR}/${TARGET}-dnsx-results.txt < ${DATA_DIR}/${TARGET}-filtered-subs.txt > ${DATA_DIR}/${TARGET}-combined-subs.txt

    # Find and report new subdomains discovered by dnsx
    find_new_subdomains "${DATA_DIR}/${TARGET}-filtered-subs.txt" "${DATA_DIR}/${TARGET}-dnsx-results.txt" "${DATA_DIR}/${TARGET}-new-subdomains.txt"

    echo -e "${ORANGE}Filtered alive subdomains (before applying OOS patterns):${NC}"
    cat ${DATA_DIR}/${TARGET}-combined-subs.txt

    announce_message "Running httpx on combined subdomains..."
    echo -e "${ORANGE}Running httpx on combined subdomains...${NC}"
    httpx_output=$($PROXYCHAINS_CMD httpx -silent -title -rl 5 -status-code -td -mc 200,201,202,203,204,206,301,302,303,307,308 -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36" < ${DATA_DIR}/${TARGET}-combined-subs.txt)

    echo -e "${ORANGE}httpx results:${NC}"
    echo "$httpx_output" | tee ${DATA_DIR}/${TARGET}-httpx-results.txt

    announce_message "Filtering out-of-scope patterns from httpx results..."
    echo -e "${ORANGE}Filtering OOS patterns from httpx results...${NC}"
    echo "$httpx_output" | grep -oP 'http[^\s]+' | filter_oos /dev/stdin "${DATA_DIR}/${TARGET}-final-httpx-urls.txt"
    echo -e "${ORANGE}Filtered URLs:${NC}"
    cat ${DATA_DIR}/${TARGET}-final-httpx-urls.txt

    announce_message "Running nuclei on filtered URLs..."
    run_nuclei "${DATA_DIR}/${TARGET}-final-httpx-urls.txt"

elif [[ "$SCAN_TYPE" -eq 2 ]]; then
    announce_message "Enter the target URL."
    echo -e "${ORANGE}Enter the target URL:${NC}"
    read URL

    announce_message "Running httpx on target URL..."
    httpx_output=$(echo $URL | $PROXYCHAINS_CMD httpx -silent -title -rl 5 -status-code -td -mc 200,201,202,203,204,206,301,302,303,307,308 -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")

    echo -e "${ORANGE}$httpx_output${NC}" | tee "${DATA_DIR}/${URL//[:\/]/_}-web-alive.txt"

    if [ ${#OOS_PATTERNS[@]} -eq 0 ]; then
        echo -e "${CYAN}No OOS patterns provided, proceeding with the URL.${NC}"
        url_active=$(echo "$httpx_output" | grep -oP 'http[^\s]+')
        if [[ $url_active ]]; then
            announce_message "URL is active and in scope, running nuclei scan..."
            echo -e "${ORANGE}URL is active and in scope, proceeding with nuclei scan...${NC}"
            echo $url_active > "${DATA_DIR}/${URL//[:\/]/_}-final-url.txt"
            run_nuclei "${DATA_DIR}/${URL//[:\/]/_}-final-url.txt"
        else
            announce_message "URL not active or not correctly processed."
            echo -e "${RED}URL not active or not correctly processed.${NC}"
        fi
    else
        if ! echo "$httpx_output" | grep -qE "${OOS_PATTERNS[*]}"; then
            url_active=$(echo "$httpx_output" | grep -oP 'http[^\s]+')
            if [[ $url_active ]]; then
                announce_message "URL is active and in scope, running nuclei scan..."
                echo -e "${ORANGE}URL is active and in scope, proceeding with nuclei scan...${NC}"
                echo $url_active > "${DATA_DIR}/${URL//[:\/]/_}-final-url.txt"
                run_nuclei "${DATA_DIR}/${URL//[:\/]/_}-final-url.txt"
            else
                announce_message "URL not active or not correctly processed."
                echo -e "${RED}URL not active or not correctly processed.${NC}"
            fi
        else
            announce_message "URL is out of scope."
            echo -e "${CYAN}URL is out of scope.${NC}"
        fi
    fi
else
    announce_message "Invalid option selected."
    echo -e "${RED}Invalid option selected.${NC}"
    exit 1
fi

announce_message "Nuclei scan completed."
echo -e "${GREEN}Nuclei scan completed.${NC}"
