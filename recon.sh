#!/bin/bash

# Define colors for output using RGB
ORANGE='\033[38;2;255;165;0m'
NC='\033[0m' # No Color
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
YELLOW='\033[1;33m'

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

# Display banner with lolcat
echo -e "${BLUE}coded by: s1d6p01nt7${NC}" | lolcat

# Prompt to enable voice announcements
echo -e "${ORANGE}Do you want to enable voice announcements? (y/n)${NC}"
announce_message "Do you want to enable voice announcements? Enter yes or no."
read ENABLE_VOICE

# Prompt to enable debugging
echo -e "${ORANGE}Do you want to enable debugging output? (y/n)${NC}"
announce_message "Do you want to enable debugging output? Enter yes or no."
read ENABLE_DEBUG

# Debugging function
function debug_message() {
    if [ "$ENABLE_DEBUG" == "y" ]; then
        echo -e "$1"
        eval "$2"
    fi
}

# Welcome message
announce_message "Voice notifications activated."

# Pause to display the banner and clear the screen
sleep 2
clear

# Prompt to decide data storage
echo -e "${ORANGE}Do you want to store the data permanently? (y/n)${NC}"
announce_message "Do you want to store the data permanently? Enter yes or no."
read STORE_PERMANENTLY

# Set data directory based on user input
if [ "$STORE_PERMANENTLY" == "n" ]; then
    DATA_DIR="/tmp"
else
    DATA_DIR="./data"
    mkdir -p $DATA_DIR
fi

# Prompt to use proxychains
echo -e "${ORANGE}Do you want to use proxychains? (y/n)${NC}"
announce_message "Do you want to use proxychains? Enter yes or no."
read USE_PROXYCHAINS

# Set proxychains command based on user input
if [ "$USE_PROXYCHAINS" == "y" ]; then
    PROXYCHAINS_CMD="proxychains"
else
    PROXYCHAINS_CMD=""
fi

# Prompt to scan a domain or a single URL
echo -e "${ORANGE}Do you want to test a domain (1) or a single URL (2)?${NC}"
announce_message "Do you want to test a domain or a single URL? Enter one for domain or two for URL."
read SCAN_TYPE

# Validate SCAN_TYPE input
if [[ "$SCAN_TYPE" != "1" && "$SCAN_TYPE" != "2" ]]; then
    echo -e "${RED}Invalid option selected.${NC}"
    exit 1
fi

# Prompt for out-of-scope patterns
echo -e "${ORANGE}Enter comma-separated out-of-scope patterns (e.g., *.example.com, example.example.com):${NC}"
announce_message "Enter comma-separated out-of-scope patterns."
read OOS_INPUT

# Handle empty OOS patterns
if [ -z "$OOS_INPUT" ]; then
    OOS_PATTERNS=()
else
    OOS_PATTERNS=(${OOS_INPUT//,/ })
fi

# Debug: Display out-of-scope patterns
debug_message "${CYAN}Debug: OOS_PATTERNS='${OOS_PATTERNS[*]}'${NC}"

# Prompt for bug bounty program name
echo -e "${ORANGE}Enter the bug bounty program name:${NC}"
announce_message "Enter the bug bounty program name."
read PROGRAM_NAME
CUSTOM_HEADER="X-Bug-Bounty: researcher@$PROGRAM_NAME"

# Prompt for dnsx wordlist path
echo -e "${ORANGE}Enter the path to the dnsx wordlist (press enter to use default):${NC}"
announce_message "Enter the path to the dnsx wordlist."
read DNSX_WORDLIST

# Set default wordlist if none provided
if [ -z "$DNSX_WORDLIST" ]; then
    DNSX_WORDLIST="/home/kali/SecLists/Discovery/DNS/subdomains-top1million-5000.txt"
    debug_message "${CYAN}Using default DNSX wordlist: $DNSX_WORDLIST${NC}"
fi

# Prompt for dnsx resolver list path
echo -e "${ORANGE}Enter the path to the dnsx resolver list (press enter to use default):${NC}"
announce_message "Enter the path to the dnsx resolver list."
read RESOLVER_LIST

# Set default resolver list if none provided
if [ -z "$RESOLVER_LIST" ]; then
    RESOLVER_LIST="/home/kali/resolvers/resolvers-trusted.txt"
    debug_message "${CYAN}Using default DNSX resolver list: $RESOLVER_LIST${NC}"
fi

# Function to filter out-of-scope patterns
function filter_oos() {
    local input_file=$1
    local output_file=$2
    > "$output_file"
    while read -r line; do
        local in_scope=true
        debug_message "${BLUE}Processing: $line${NC}"
        for oos in "${OOS_PATTERNS[@]}"; do
            if [[ "$line" == "$oos" ]]; then
                in_scope=false
                debug_message "${RED}OOS Matched: $line (Pattern: $oos)${NC}"
                break
            fi
        done
        if $in_scope; then
            debug_message "${GREEN}In Scope: $line${NC}"
            echo "$line" >> "$output_file"
        fi
    done < "$input_file"
}

# Function to find new subdomains discovered by dnsx
function find_new_subdomains() {
    local original_file=$1
    local new_file=$2
    local output_file=$3

    comm -13 <(sort "$original_file") <(sort "$new_file") > "$output_file"

    if [ -s "$output_file" ]; then
        echo -e "${YELLOW}New subdomains discovered by dnsx:${NC}"
        cat "$output_file"
    else
        echo -e "${CYAN}No new subdomains discovered by dnsx.${NC}"
    fi
}

# Function to display filtered alive subdomains with color coding
function display_filtered_alive() {
    local alive_file=$1
    local subfinder_file=$2
    local dnsx_file=$3

    echo -e "${ORANGE}Filtered alive subdomains (before applying OOS patterns):${NC}"

    while read -r subdomain; do
        if grep -q "$subdomain" "$subfinder_file"; then
            echo -e "${PURPLE}$subdomain${NC}"
        elif grep -q "$subdomain" "$dnsx_file"; then
            echo -e "${YELLOW}$subdomain${NC}"
        else
            echo -e "${GREEN}$subdomain${NC}"
        fi
    done < "$alive_file"
}

# Function to run Nuclei
function run_nuclei() {
    local target_file=$1

    if [ -z "$RATE_LIMIT" ]; then
        RATE_LIMIT=5
    fi

    local nuclei_cmd="nuclei -rl $RATE_LIMIT -ss template-spray -H \"$CUSTOM_HEADER\" $SEVERITY_FLAG $CLOUD_UPLOAD_FLAG"

    if [ ${#TEMPLATE_PATHS_ARRAY[@]} -ne 0 ]; then
        for template_path in "${TEMPLATE_PATHS_ARRAY[@]}"; do
            nuclei_cmd+=" -t $template_path"
        done
    fi

    if [ ${#TEMPLATE_TAGS_ARRAY[@]} -ne 0 ]; then
        nuclei_cmd+=" -tags ${TEMPLATE_TAGS_ARRAY[*]}"
    fi

    echo -e "${ORANGE}Running nuclei command: $nuclei_cmd on targets in $target_file...${NC}"
    announce_message "Running nuclei command on targets."
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

# Main logic for domain scan
if [[ "$SCAN_TYPE" -eq 1 ]]; then
    echo -e "${ORANGE}Enter the target domain:${NC}"
    announce_message "Enter the target domain."
    read TARGET

    echo -e "${ORANGE}Running subfinder...${NC}"
    announce_message "Running subfinder."
    $PROXYCHAINS_CMD subfinder -d $TARGET -silent -all | anew ${DATA_DIR}/${TARGET}-subs.txt

    # Debugging: Show subfinder output
    debug_message "${CYAN}Subfinder output:${NC}" "cat ${DATA_DIR}/${TARGET}-subs.txt"

    echo -e "${ORANGE}Subfinder completed. Filtering OOS patterns...${NC}"
    announce_message "Filtering out-of-scope patterns from subfinder results."
    filter_oos "${DATA_DIR}/${TARGET}-subs.txt" "${DATA_DIR}/${TARGET}-filtered-subs.txt"

    # Debugging: Show filtered subdomains
    debug_message "${CYAN}Filtered subdomains:${NC}" "cat ${DATA_DIR}/${TARGET}-filtered-subs.txt"

    echo -e "${ORANGE}Running dnsx on filtered subdomains with resolver list to expand results...${NC}"
    announce_message "Running dnsx on filtered subdomains."

    $PROXYCHAINS_CMD dnsx -rl 5 -resp -silent -r $RESOLVER_LIST -w $DNSX_WORDLIST -d $TARGET -wt 5 | anew ${DATA_DIR}/${TARGET}-dnsx-results.txt

    # Debugging: Show DNSX results
    debug_message "${CYAN}DNSX results:${NC}" "cat ${DATA_DIR}/${TARGET}-dnsx-results.txt"

    anew ${DATA_DIR}/${TARGET}-dnsx-results.txt < ${DATA_DIR}/${TARGET}-filtered-subs.txt > ${DATA_DIR}/${TARGET}-combined-subs.txt

    # Debugging: Show combined subdomains before httpx
    debug_message "${CYAN}Combined subdomains before httpx:${NC}" "cat ${DATA_DIR}/${TARGET}-combined-subs.txt"

    find_new_subdomains "${DATA_DIR}/${TARGET}-filtered-subs.txt" "${DATA_DIR}/${TARGET}-dnsx-results.txt" "${DATA_DIR}/${TARGET}-new-subdomains.txt"

    display_filtered_alive "${DATA_DIR}/${TARGET}-combined-subs.txt" "${DATA_DIR}/${TARGET}-filtered-subs.txt" "${DATA_DIR}/${TARGET}-dnsx-results.txt"

    echo -e "${ORANGE}Running httpx on combined subdomains...${NC}"
    announce_message "Running httpx on combined subdomains."

    # Prompt to use httpx -dashboard flag
    echo -e "${ORANGE}Do you want to enable httpx dashboard upload? (y/n)${NC}"
    announce_message "Do you want to enable httpx dashboard upload? Enter yes or no."
    read USE_HTTPX_DASHBOARD

    if [ "$USE_HTTPX_DASHBOARD" == "y" ]; then
        HTTPX_DASHBOARD_FLAG="-dashboard"
    else
        HTTPX_DASHBOARD_FLAG=""
    fi

    httpx_output=$($PROXYCHAINS_CMD httpx -silent -title -rl 5 -status-code -td -mc 200,201,202,203,204,206,301,302,303,307,308 $HTTPX_DASHBOARD_FLAG -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36" < ${DATA_DIR}/${TARGET}-combined-subs.txt)

    # Debugging: Show httpx results
    debug_message "${CYAN}httpx results:${NC}" "echo \"$httpx_output\" | tee ${DATA_DIR}/${TARGET}-httpx-results.txt"

    echo -e "${ORANGE}Filtering OOS patterns from httpx results...${NC}"
    announce_message "Filtering out-of-scope patterns from httpx results."
    echo "$httpx_output" | grep -oP 'http[^\s]+' | filter_oos /dev/stdin "${DATA_DIR}/${TARGET}-final-httpx-urls.txt"

    # Debugging: Show filtered URLs
    debug_message "${CYAN}Filtered URLs:${NC}" "cat ${DATA_DIR}/${TARGET}-final-httpx-urls.txt"

    # Prompt for Nuclei cloud features
    echo -e "${ORANGE}Do you want to use Nuclei cloud features? (y/n)${NC}"
    announce_message "Do you want to use Nuclei cloud features? Enter yes or no."
    read USE_NUCLEI_CLOUD

    # Set cloud upload flag based on user input
    if [ "$USE_NUCLEI_CLOUD" == "y" ]; then
        CLOUD_UPLOAD_FLAG="-cloud-upload"
    else
        CLOUD_UPLOAD_FLAG=""
    fi

    # Prompt for Nuclei template paths
    echo -e "${ORANGE}Review the running tech stack and status codes, then enter the Nuclei template paths (comma-separated):${NC}"
    announce_message "Review the running tech stack and status codes, then enter the Nuclei template paths."
    read TEMPLATE_PATHS

    if [ -z "$TEMPLATE_PATHS" ]; then
        echo -e "${CYAN}No Nuclei template paths provided. Using default path: /home/kali/nuclei-templates${NC}"
        TEMPLATE_PATHS_ARRAY=("/home/kali/nuclei-templates")
    else
        TEMPLATE_PATHS_ARRAY=(${TEMPLATE_PATHS//,/ })
    fi

    # Prompt for Nuclei template tags with suggested tags (extended list)
    echo -e "${ORANGE}Suggested Nuclei template tags:${NC}"
    echo -e "${CYAN}exposed, ibm, debug, auth, mongodb, python, other, ssrf, sql_injection, sql, docker, upload, search, elk, remote_code_execution, php, kafka, detect, config, java, laravel, local_file_inclusion, api, nodejs, xss, http, header, open_redirect, aws, adobe, drupal, sap, git, google, oracle, nginx, airflow, javascript, default, apache, cve, jenkins, web, wordpress, microsoft, rabbitmq, extract, subdomain_takeover, ftp, ruby, samba, atlassian, backup, vmware, redis, netlify, magento, coldfusion, joomla, graphite, cisco, shopify, social, gcloud, perl, injection, smtp, xml_external_entity, crlf_injection, directory_listing, template_injection, graphql, mysql, fuzz, sensitive, ldap, ssh, sharepoint, kong, favicon, cross_site_request_forgery, cpanel, postgres.${NC}"
    announce_message "Review suggested Nuclei template tags, then enter your desired tags."
    echo -e "${ORANGE}Enter the Nuclei template tags (comma-separated):${NC}"
    read TEMPLATE_TAGS

    if [ -z "$TEMPLATE_TAGS" ]; then
        echo -e "${CYAN}No Nuclei template tags provided. Using default Nuclei command.${NC}"
        TEMPLATE_TAGS_ARRAY=()
    else
        TEMPLATE_TAGS_ARRAY=(${TEMPLATE_TAGS//,/ })
    fi

    # Prompt for Nuclei severity levels
    echo -e "${ORANGE}Enter the Nuclei severity levels (comma-separated):${NC}"
    announce_message "Enter the Nuclei severity levels."
    read SEVERITY_LEVELS

    if [ -z "$SEVERITY_LEVELS" ]; then
        SEVERITY_FLAG=""
    else
        SEVERITY_FLAG="-s ${SEVERITY_LEVELS}"
    fi

    # Prompt for Nuclei rate limit
    echo -e "${ORANGE}Enter the rate limit for Nuclei requests per second (default is 5):${NC}"
    announce_message "Enter the rate limit for Nuclei requests per second."
    read RATE_LIMIT

    if [ -z "$RATE_LIMIT" ]; then
        RATE_LIMIT=5
    fi

    echo -e "${ORANGE}Running nuclei on filtered URLs...${NC}"
    announce_message "Running nuclei on filtered URLs."
    run_nuclei "${DATA_DIR}/${TARGET}-final-httpx-urls.txt"

elif [[ "$SCAN_TYPE" -eq 2 ]]; then
    echo -e "${ORANGE}Enter the target URL:${NC}"
    announce_message "Enter the target URL."
    read URL

    echo -e "${ORANGE}Running httpx on target URL...${NC}"
    announce_message "Running httpx on target URL."

    # Prompt to use httpx -dashboard flag
    echo -e "${ORANGE}Do you want to enable httpx dashboard upload? (y/n)${NC}"
    announce_message "Do you want to enable httpx dashboard upload? Enter yes or no."
    read USE_HTTPX_DASHBOARD

    if [ "$USE_HTTPX_DASHBOARD" == "y" ]; then
        HTTPX_DASHBOARD_FLAG="-dashboard"
    else
        HTTPX_DASHBOARD_FLAG=""
    fi

    httpx_output=$(echo $URL | $PROXYCHAINS_CMD httpx -silent -title -rl 5 -status-code -td -mc 200,201,202,203,204,206,301,302,303,307,308 $HTTPX_DASHBOARD_FLAG -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36")

    # Debugging: Show httpx results
    debug_message "${CYAN}httpx results:${NC}" "echo \"$httpx_output\" | tee \"${DATA_DIR}/${URL//[:\/]/_}-web-alive.txt\""

    if [ ${#OOS_PATTERNS[@]} -eq 0 ]; then
        echo -e "${CYAN}No OOS patterns provided, proceeding with the URL.${NC}"
        announce_message "No OOS patterns provided, proceeding with the URL."
        url_active=$(echo "$httpx_output" | grep -oP 'http[^\s]+')
        if [[ $url_active ]]; then
            echo -e "${ORANGE}URL is active and in scope, proceeding with nuclei scan...${NC}"
            announce_message "URL is active and in scope, proceeding with nuclei scan."
            echo $url_active > "${DATA_DIR}/${URL//[:\/]/_}-final-url.txt"

            # Prompt for Nuclei cloud features
            echo -e "${ORANGE}Do you want to use Nuclei cloud features? (y/n)${NC}"
            announce_message "Do you want to use Nuclei cloud features? Enter yes or no."
            read USE_NUCLEI_CLOUD

            if [ "$USE_NUCLEI_CLOUD" == "y" ]; then
                CLOUD_UPLOAD_FLAG="-cloud-upload"
            else
                CLOUD_UPLOAD_FLAG=""
            fi

            # Prompt for Nuclei template paths
            echo -e "${ORANGE}Review the running tech stack and status codes, then enter the Nuclei template paths (comma-separated):${NC}"
            announce_message "Review the running tech stack and status codes, then enter the Nuclei template paths."
            read TEMPLATE_PATHS

            if [ -z "$TEMPLATE_PATHS" ]; then
                echo -e "${CYAN}No Nuclei template paths provided. Using default path: /home/kali/nuclei-templates${NC}"
                TEMPLATE_PATHS_ARRAY=("/home/kali/nuclei-templates")
            else
                TEMPLATE_PATHS_ARRAY=(${TEMPLATE_PATHS//,/ })
            fi

            # Prompt for Nuclei template tags with suggested tags (extended list)
            echo -e "${ORANGE}Suggested Nuclei template tags:${NC}"
            echo -e "${CYAN}exposed, ibm, debug, auth, mongodb, python, other, ssrf, sql_injection, sql, docker, upload, search, elk, remote_code_execution, php, kafka, detect, config, java, laravel, local_file_inclusion, api, nodejs, xss, http, header, open_redirect, aws, adobe, drupal, sap, git, google, oracle, nginx, airflow, javascript, default, apache, cve, jenkins, web, wordpress, microsoft, rabbitmq, extract, subdomain_takeover, ftp, ruby, samba, atlassian, backup, vmware, redis, netlify, magento, coldfusion, joomla, graphite, cisco, shopify, social, gcloud, perl, injection, smtp, xml_external_entity, crlf_injection, directory_listing, template_injection, graphql, mysql, fuzz, sensitive, ldap, ssh, sharepoint, kong, favicon, cross_site_request_forgery, cpanel, postgres.${NC}"
            announce_message "Review suggested Nuclei template tags, then enter your desired tags."
            echo -e "${ORANGE}Enter the Nuclei template tags (comma-separated):${NC}"
            read TEMPLATE_TAGS

            if [ -z "$TEMPLATE_TAGS" ]; then
                echo -e "${CYAN}No Nuclei template tags provided. Using default Nuclei command.${NC}"
                TEMPLATE_TAGS_ARRAY=()
            else
                TEMPLATE_TAGS_ARRAY=(${TEMPLATE_TAGS//,/ })
            fi

            # Prompt for Nuclei severity levels
            echo -e "${ORANGE}Enter the Nuclei severity levels (comma-separated):${NC}"
            announce_message "Enter the Nuclei severity levels."
            read SEVERITY_LEVELS

            if [ -z "$SEVERITY_LEVELS" ]; then
                SEVERITY_FLAG=""
            else
                SEVERITY_FLAG="-s ${SEVERITY_LEVELS}"
            fi

            # Prompt for Nuclei rate limit
            echo -e "${ORANGE}Enter the rate limit for Nuclei requests per second (default is 5):${NC}"
            announce_message "Enter the rate limit for Nuclei requests per second."
            read RATE_LIMIT

            if [ -z "$RATE_LIMIT" ]; then
                RATE_LIMIT=5
            fi

            echo -e "${ORANGE}Running nuclei on filtered URLs...${NC}"
            announce_message "Running nuclei on filtered URLs."
            run_nuclei "${DATA_DIR}/${URL//[:\/]/_}-final-url.txt"
        else
            echo -e "${RED}URL not active or not correctly processed.${NC}"
            announce_message "URL not active or not correctly processed."
        fi
    else
        if ! echo "$httpx_output" | grep -qE "${OOS_PATTERNS[*]}"; then
            url_active=$(echo "$httpx_output" | grep -oP 'http[^\s]+')
            if [[ $url_active ]]; then
                echo -e "${ORANGE}URL is active and in scope, proceeding with nuclei scan...${NC}"
                announce_message "URL is active and in scope, proceeding with nuclei scan."
                echo $url_active > "${DATA_DIR}/${URL//[:\/]/_}-final-url.txt"

                # Prompt for Nuclei cloud features
                echo -e "${ORANGE}Do you want to use Nuclei cloud features? (y/n)${NC}"
                announce_message "Do you want to use Nuclei cloud features? Enter yes or no."
                read USE_NUCLEI_CLOUD

                if [ "$USE_NUCLEI_CLOUD" == "y" ]; then
                    CLOUD_UPLOAD_FLAG="-cloud-upload"
                else
                    CLOUD_UPLOAD_FLAG=""
                fi

                # Prompt for Nuclei template paths
                echo -e "${ORANGE}Review the running tech stack and status codes, then enter the Nuclei template paths (comma-separated):${NC}"
                announce_message "Review the running tech stack and status codes, then enter the Nuclei template paths."
                read TEMPLATE_PATHS

                if [ -z "$TEMPLATE_PATHS" ]; then
                    echo -e "${CYAN}No Nuclei template paths provided. Using default path: /home/kali/nuclei-templates${NC}"
                    TEMPLATE_PATHS_ARRAY=("/home/kali/nuclei-templates")
                else
                    TEMPLATE_PATHS_ARRAY=(${TEMPLATE_PATHS//,/ })
                fi

                # Prompt for Nuclei template tags with suggested tags (extended list)
                echo -e "${ORANGE}Suggested Nuclei template tags:${NC}"
                echo -e "${CYAN}exposed, ibm, debug, auth, mongodb, python, other, ssrf, sql_injection, sql, docker, upload, search, elk, remote_code_execution, php, kafka, detect, config, java, laravel, local_file_inclusion, api, nodejs, xss, http, header, open_redirect, aws, adobe, drupal, sap, git, google, oracle, nginx, airflow, javascript, default, apache, cve, jenkins, web, wordpress, microsoft, rabbitmq, extract, subdomain_takeover, ftp, ruby, samba, atlassian, backup, vmware, redis, netlify, magento, coldfusion, joomla, graphite, cisco, shopify, social, gcloud, perl, injection, smtp, xml_external_entity, crlf_injection, directory_listing, template_injection, graphql, mysql, fuzz, sensitive, ldap, ssh, sharepoint, kong, favicon, cross_site_request_forgery, cpanel, postgres.${NC}"
                announce_message "Review suggested Nuclei template tags, then enter your desired tags."
                echo -e "${ORANGE}Enter the Nuclei template tags (comma-separated):${NC}"
                read TEMPLATE_TAGS

                if [ -z "$TEMPLATE_TAGS" ]; then
                    echo -e "${CYAN}No Nuclei template tags provided. Using default Nuclei command.${NC}"
                    TEMPLATE_TAGS_ARRAY=()
                else
                    TEMPLATE_TAGS_ARRAY=(${TEMPLATE_TAGS//,/ })
                fi

                # Prompt for Nuclei severity levels
                echo -e "${ORANGE}Enter the Nuclei severity levels (comma-separated):${NC}"
                announce_message "Enter the Nuclei severity levels."
                read SEVERITY_LEVELS

                if [ -z "$SEVERITY_LEVELS" ]; then
                    SEVERITY_FLAG=""
                else
                    SEVERITY_FLAG="-s ${SEVERITY_LEVELS}"
                fi

                # Prompt for Nuclei rate limit
                echo -e "${ORANGE}Enter the rate limit for Nuclei requests per second (default is 5):${NC}"
                announce_message "Enter the rate limit for Nuclei requests per second."
                read RATE_LIMIT

                if [ -z "$RATE_LIMIT" ]; then
                    RATE_LIMIT=5
                fi

                echo -e "${ORANGE}Running nuclei on filtered URLs...${NC}"
                announce_message "Running nuclei on filtered URLs."
                run_nuclei "${DATA_DIR}/${URL//[:\/]/_}-final-url.txt"
            else
                echo -e "${RED}URL not active or not correctly processed.${NC}"
                announce_message "URL not active or not correctly processed."
            fi
        else
            echo -e "${CYAN}URL is out of scope.${NC}"
            announce_message "URL is out of scope."
        fi
    fi
else
    echo -e "${RED}Invalid option selected.${NC}"
    announce_message "Invalid option selected."
    exit 1
fi

echo -e "${GREEN}Nuclei scan completed.${NC}"
announce_message "Nuclei scan completed."
