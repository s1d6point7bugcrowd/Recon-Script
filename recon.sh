#!/bin/bash

# Define colors for output using RGB
ORANGE='\033[38;2;255;165;0m'
NC='\033[0m' # No Color
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
# New color for newly discovered subdomains
PURPLE='\033[0;35m'

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

# Prompt to enable debug and verbose flags
echo -e "${ORANGE}Do you want to enable debug and verbose mode? (y/n)${NC}"
read ENABLE_DEBUG

# Set DEBUG_FLAG based on user input
if [ "$ENABLE_DEBUG" == "y" ]; then
    DEBUG_FLAG="-debug -vv"
else
    DEBUG_FLAG=""
fi

# Welcome message
announce_message "Voice notifications activated."

# Pause to display the banner and clear the screen
sleep 0
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

# Prompt to use Nuclei cloud features
announce_message "Do you want to use Nuclei cloud features? Enter yes or no."
echo -e "${ORANGE}Do you want to use Nuclei cloud features? (y/n)${NC}"
read USE_NUCLEI_CLOUD

# Set cloud upload flag based on user input
if [ "$USE_NUCLEI_CLOUD" == "y" ]; then
    CLOUD_UPLOAD_FLAG="-cloud-upload"
else
    CLOUD_UPLOAD_FLAG=""
fi

# Prompt to scan a domain or a single URL
announce_message "Do you want to test a domain or a single URL? Enter one for domain or two for URL."
echo -e "${ORANGE}Do you want to test a domain (1) or a single URL (2)?${NC}"
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
    echo -e "${CYAN}No OOS patterns provided. Skipping OOS filtering.${NC}"
else
    OOS_PATTERNS=(${OOS_INPUT//,/ })
fi

# Debug: Display out-of-scope patterns
echo -e "${CYAN}Debug: OOS_PATTERNS='${OOS_PATTERNS[*]}'${NC}"

# Prompt for bug bounty program name
announce_message "Enter the bug bounty program name."
echo -e "${ORANGE}Enter the bug bounty program name:${NC}"
read PROGRAM_NAME
CUSTOM_HEADER="x-bug-bounty-research: researcher@$PROGRAM_NAME"

# Prompt for Nuclei template paths
announce_message "Enter the Nuclei template paths (comma-separated)."
echo -e "${ORANGE}Enter the Nuclei template paths (comma-separated):${NC}"
read TEMPLATE_PATHS

# Handle Nuclei template paths
if [ -z "$TEMPLATE_PATHS" ]; then
    TEMPLATE_PATHS="/home/kali/nuclei-templates/"
    echo -e "${CYAN}No Nuclei template paths provided. Using default path: /home/kali/nuclei-templates/${NC}"
    TEMPLATE_PATHS_ARRAY=("$TEMPLATE_PATHS")
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

# Prompt for Nuclei severity levels
announce_message "Enter the Nuclei severity levels (comma-separated)."
echo -e "${ORANGE}Enter the Nuclei severity levels (comma-separated):${NC}"
read SEVERITY_LEVELS

# Handle Nuclei severity levels
if [ -z "$SEVERITY_LEVELS" ]; then
    SEVERITY_FLAG=""
else
    SEVERITY_FLAG="-s ${SEVERITY_LEVELS}"
fi

# Prompt for Nuclei rate limit
announce_message "Enter the rate limit for Nuclei requests per second (default is 5)."
echo -e "${ORANGE}Enter the rate limit for Nuclei requests per second (default is 5):${NC}"
read RATE_LIMIT

# Set default rate limit if not provided
if [ -z "$RATE_LIMIT" ]; then
    RATE_LIMIT=5
fi

# Prompt for resolver list (used by puredns)
announce_message "Enter the path to the default resolver list (press enter to use default)."
echo -e "${ORANGE}Enter the path to the default resolver list:${NC}"
read RESOLVER_LIST

# Set default resolver list if none provided
if [ -z "$RESOLVER_LIST" ]; then
    RESOLVER_LIST="/home/kali/resolvers/resolvers-trusted.txt"
    echo -e "${CYAN}Using default resolver list: $RESOLVER_LIST${NC}"
fi

# Prompt for custom status codes in httpx
announce_message "Enter the status codes you want to include (comma-separated). Leave blank to use defaults."
echo -e "${ORANGE}Enter the status codes for httpx (comma-separated, or press enter to use defaults):${NC}"
read STATUS_CODES

# Set default status codes if none provided
if [ -z "$STATUS_CODES" ]; then
    STATUS_CODES="200,302"
    echo -e "${CYAN}Using default httpx status codes: $STATUS_CODES${NC}"
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
    local nuclei_cmd="nuclei -rl $RATE_LIMIT -ss template-spray -bs 10 -fr -retries 3 -c 2 -timeout 5 -et /home/kali/nuclei-templates/dns/ -H \"$CUSTOM_HEADER\" $SEVERITY_FLAG $CLOUD_UPLOAD_FLAG $DEBUG_FLAG"

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

# Function to find new subdomains discovered by resolution tool (shuffledns or puredns)
function find_new_subdomains() {
    local original_file=$1
    local new_file=$2
    local output_file=$3

    # Use comm to find subdomains that are in new_file but not in original_file
    comm -13 <(sort "$original_file") <(sort "$new_file") > "$output_file"

    if [ -s "$output_file" ]; then
        echo -e "${ORANGE}New subdomains discovered by resolution tool:${NC}"
        # Print each new subdomain in purple
        while read -r sub; do
            echo -e "${PURPLE}$sub${NC}"
        done < "$output_file"
    else
        echo -e "${CYAN}No new subdomains discovered by resolution tool.${NC}"
    fi
}

# Main logic for domain or URL scan
if [[ "$SCAN_TYPE" -eq 1 ]]; then
    announce_message "Enter the target domain."
    echo -e "${ORANGE}Enter the target domain:${NC}"
    read TARGET

    announce_message "Running Subfinder..."
    echo -e "${ORANGE}Running Subfinder...${NC}"
    $PROXYCHAINS_CMD subfinder -d "$TARGET" -silent -all | anew "${DATA_DIR}/${TARGET}-subs.txt"

    announce_message "Filtering out-of-scope patterns from subfinder results..."
    echo -e "${ORANGE}Subfinder subdomain enumeration completed. Filtering OOS patterns...${NC}"
    filter_oos "${DATA_DIR}/${TARGET}-subs.txt" "${DATA_DIR}/${TARGET}-filtered-subs.txt"
    echo -e "${ORANGE}Filtered subdomains:${NC}"
    cat "${DATA_DIR}/${TARGET}-filtered-subs.txt"

    ### START: Option to use shuffledns or puredns for subdomain resolution ###
    echo -e "${ORANGE}Do you want to use shuffledns for subdomain resolution? (y/n)${NC}"
    read USE_SHUFFLEDNS

    if [ "$USE_SHUFFLEDNS" == "y" ]; then
        announce_message "Running shuffledns on filtered subdomains..."
        echo -e "${ORANGE}OOS filtering completed. Running shuffledns...${NC}"
        $PROXYCHAINS_CMD shuffledns -mode bruteforce \
            -d "$TARGET" \
            -l "${DATA_DIR}/${TARGET}-filtered-subs.txt" \
            -w "/home/kali/SecLists/Discovery/DNS/subdomains-top1million-5000.txt" \
            -r "/home/kali/resolvers/resolvers-community.txt" \
            -silent \
            -o "${DATA_DIR}/${TARGET}-shuffledns-results.txt"

        if [ ! -f "${DATA_DIR}/${TARGET}-shuffledns-results.txt" ]; then
            echo -e "${CYAN}shuffledns did not produce any output, creating an empty results file.${NC}"
            touch "${DATA_DIR}/${TARGET}-shuffledns-results.txt"
        fi

        RESOLUTION_RESULTS="${DATA_DIR}/${TARGET}-shuffledns-results.txt"
    else
        # Prompt for puredns wordlist
        announce_message "Enter the path to the puredns wordlist (press enter to use default)."
        echo -e "${ORANGE}Enter the path to the puredns wordlist:${NC}"
        read PUREDNS_WORDLIST
        if [ -z "$PUREDNS_WORDLIST" ]; then
            PUREDNS_WORDLIST="/home/kali/SecLists/Discovery/DNS/subdomains-top1million-5000.txt"
            echo -e "${CYAN}Using default puredns wordlist: $PUREDNS_WORDLIST${NC}"
        fi

        announce_message "Running puredns bruteforce on target domain..."
        echo -e "${ORANGE}OOS filtering completed. Running puredns bruteforce...${NC}"
        $PROXYCHAINS_CMD puredns bruteforce "$PUREDNS_WORDLIST" "$TARGET" -r "$RESOLVER_LIST" -l 10000  -w "${DATA_DIR}/${TARGET}-puredns-results.txt"
        RESOLUTION_RESULTS="${DATA_DIR}/${TARGET}-puredns-results.txt"
    fi
    ### END: Option to use shuffledns or puredns ###

    # Combine results from resolution tool with filtered subdomains and deduplicate
    cat "${RESOLUTION_RESULTS}" "${DATA_DIR}/${TARGET}-filtered-subs.txt" | sort -u > "${DATA_DIR}/${TARGET}-combined-subs.txt"

    # Find and report new subdomains discovered by resolution tool
    find_new_subdomains "${DATA_DIR}/${TARGET}-filtered-subs.txt" "${RESOLUTION_RESULTS}" "${DATA_DIR}/${TARGET}-new-subdomains.txt"

    # Highlight newly discovered subdomains in the final combined list
    echo -e "${ORANGE}Full combined subdomain list, highlighting new subdomains in purple:${NC}"
    while read -r domain; do
        if grep -Fxq "$domain" "${DATA_DIR}/${TARGET}-new-subdomains.txt"; then
            echo -e "${PURPLE}$domain${NC}"
        else
            echo "$domain"
        fi
    done < "${DATA_DIR}/${TARGET}-combined-subs.txt"

    # Prompt to use httpx dashboard upload
    announce_message "Do you want to enable httpx dashboard upload? Enter yes or no."
    echo -e "${ORANGE}Do you want to enable httpx dashboard upload? (y/n)${NC}"
    read USE_HTTPX_DASHBOARD

    if [ "$USE_HTTPX_DASHBOARD" == "y" ]; then
        HTTPX_DASHBOARD_FLAG="-dashboard"
    else
        HTTPX_DASHBOARD_FLAG=""
    fi

    announce_message "Running httpx on combined subdomains..."
    echo -e "${ORANGE}Running httpx on combined subdomains...${NC}"
    httpx_output=$($PROXYCHAINS_CMD httpx -silent -title -rl 5 -status-code -td -mc "$STATUS_CODES" $HTTPX_DASHBOARD_FLAG \
      -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36" \
      < "${DATA_DIR}/${TARGET}-combined-subs.txt")

    echo -e "${ORANGE}httpx results:${NC}"
    echo "$httpx_output" | tee "${DATA_DIR}/${TARGET}-httpx-results.txt"

    announce_message "Filtering out-of-scope patterns from httpx results..."
    echo -e "${ORANGE}Filtering OOS patterns from httpx results...${NC}"
    echo "$httpx_output" | grep -oP 'http[^\s]+' | filter_oos /dev/stdin "${DATA_DIR}/${TARGET}-final-httpx-urls.txt"
    echo -e "${ORANGE}Filtered URLs:${NC}"
    cat "${DATA_DIR}/${TARGET}-final-httpx-urls.txt"

    announce_message "Running nuclei on filtered URLs..."
    run_nuclei "${DATA_DIR}/${TARGET}-final-httpx-urls.txt"

elif [[ "$SCAN_TYPE" -eq 2 ]]; then
    announce_message "Enter the target URL."
    echo -e "${ORANGE}Enter the target URL:${NC}"
    read URL

    # Prompt to use httpx dashboard upload
    announce_message "Do you want to enable httpx dashboard upload? Enter yes or no."
    echo -e "${ORANGE}Do you want to enable httpx dashboard upload? (y/n)${NC}"
    read USE_HTTPX_DASHBOARD

    if [ "$USE_HTTPX_DASHBOARD" == "y" ]; then
        HTTPX_DASHBOARD_FLAG="-dashboard"
    else
        HTTPX_DASHBOARD_FLAG=""
    fi

    announce_message "Running httpx on target URL..."
    httpx_output=$(echo $URL | $PROXYCHAINS_CMD httpx -silent -title -rl 5 -status-code -td -mc "$STATUS_CODES" $HTTPX_DASHBOARD_FLAG \
      -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
    
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
