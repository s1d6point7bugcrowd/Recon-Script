#!/bin/bash

# Check if sufficient arguments are passed
if [ "$#" -lt 2 ]; then
    echo -e "\033[33mUsage: $0 <mode> <target>\033[0m"
    echo -e "\033[33mModes:\033[0m"
    echo -e "\033[33m  domain    Target is a domain name\033[0m"
    echo -e "\033[33m  url       Target is a specific URL\033[0m"
    exit 1
fi

# Normalize and trim MODE input to avoid case sensitivity and trailing space issues
MODE=$(echo "$1" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')
TARGET="$2"

# Debugging output to check the value of MODE
echo -e "\033[33mMode is set to: '$MODE'\033[0m"

# Prompt for the program name
read -p "Enter the program name for the X-Bug-Bounty header: " PROGRAM_NAME

# Validate the program name input
if [ -z "$PROGRAM_NAME" ]; then
    echo -e "\033[33mProgram name is required. Exiting.\033[0m"
    exit 1
fi

# Prompt for OOS subdomains and URLs
read -p "Enter OOS subdomains and URLs (comma separated): " OOS_INPUT

# Convert the OOS input to an array
IFS=',' read -r -a OOS_PATTERNS <<< "$OOS_INPUT"

# Prompt for using Naabu for port scanning
read -p "Do you want to use Naabu for port scanning? (yes/no): " USE_NAABU

# Prompt for storing files locally
read -p "Do you want to store files locally? (yes/no): " STORE_LOCALLY

# Prompt for using waybackurls
read -p "Do you want to use waybackurls? (yes/no): " USE_WAYBACKURLS

# Define a function to create files based on user's choice
create_file() {
    if [ "$STORE_LOCALLY" == "yes" ]; then
        touch "$1"
        echo "$1"
    else
        mktemp
    fi
}

# Construct the custom header
CUSTOM_HEADER="X-Bug-Bounty:researcher@$PROGRAM_NAME"
echo -e "\033[33mUsing custom header: $CUSTOM_HEADER\033[0m"

# Function to check if a target is out of scope
is_oos() {
    local target=$1
    for pattern in "${OOS_PATTERNS[@]}"; do
        if [[ "$target" == *"$pattern"* ]]; then
            return 0
        fi
    done
    return 1
}

# Create necessary files
SUBS_FILE=$(create_file "${TARGET}-subs.txt")
FILTERED_SUBS_FILE=$(create_file "${TARGET}-filtered-subs.txt")
ALIVE_SUBS_IP_FILE=$(create_file "${TARGET}-alive-subs-ip.txt")
ALIVE_SUBS_FILE=$(create_file "${TARGET}-alive-subs.txt")
OPEN_PORTS_FILE=$(create_file "${TARGET}-openports.txt")
FINAL_OPEN_PORTS_FILE=$(create_file "${TARGET}-final-openports.txt")
WEB_ALIVE_FILE=$(create_file "${TARGET}-web-alive.txt")
WAYBACK_URLS_FILE=$(create_file "${TARGET}-waybackurls.txt")
FILTERED_WAYBACK_URLS_FILE=$(create_file "${TARGET}-filtered-waybackurls.txt")
NUCLEI_READY_FILE=$(create_file "${TARGET}-nuclei-ready.txt")
NUCLEI_RESULTS_FILE=$(create_file "${TARGET}-nuclei-results.txt")
NEW_URLS_FILE=$(create_file "${TARGET}-new-urls.txt")

# Function to remove brackets from IP addresses
remove_brackets() {
    sed 's/\[\([^]]*\)\]/\1/g'
}

# Debugging function to check file content
check_file_content() {
    local file=$1
    echo -e "\033[33mDebug: Checking content of $file\033[0m"
    if [ ! -s "$file" ]; then
        echo -e "\033[33mDebug: $file is empty.\033[0m"
    else
        echo -e "\033[33mDebug: $file has content.\033[0m"
        cat "$file" | head -n 10  # Display first 10 lines for inspection
    fi
}

# Function to filter URLs and handle out-of-scope URLs
filter_urls() {
    local input_file=$1
    local output_file=$2
    while read -r url; do
        if is_oos "$url"; then
            echo -e "\033[33mSkipping OOS URL: $url\033[0m"
        else
            echo "$url" | anew $output_file
        fi
    done < $input_file
    check_file_content $output_file
}

# Run subfinder, dnsx, and httpx
run_subfinder_dnsx_httpx() {
    echo -e "\033[33mRunning subfinder...\033[0m"
    subfinder -d $TARGET -silent | anew $SUBS_FILE
    check_file_content "$SUBS_FILE"

    echo -e "\033[33mFiltering subdomains...\033[0m"
    filter_urls $SUBS_FILE $FILTERED_SUBS_FILE

    echo -e "\033[33mRunning dnsx...\033[0m"
    dnsx -resp -silent < $FILTERED_SUBS_FILE | anew $ALIVE_SUBS_IP_FILE
    check_file_content "$ALIVE_SUBS_IP_FILE"

    awk '{print $1}' < $ALIVE_SUBS_IP_FILE | anew $ALIVE_SUBS_FILE
    check_file_content "$ALIVE_SUBS_FILE"

    echo -e "\033[33mRunning httpx...\033[0m"
    httpx -silent --rate-limit 5 -title -status-code -mc 200 < $ALIVE_SUBS_FILE | remove_brackets | anew $WEB_ALIVE_FILE
    check_file_content "$WEB_ALIVE_FILE"

    # No additional filtering needed, as httpx already filtered status codes 200 and 302
    cp $WEB_ALIVE_FILE $NUCLEI_READY_FILE
}

# Conditional execution based on mode
if [ "$MODE" == "domain" ]; then
    if [ "$USE_NAABU" == "yes" ]; then
        echo -e "\033[33mRunning subfinder...\033[0m"
        subfinder -d $TARGET -silent | anew $SUBS_FILE
        check_file_content "$SUBS_FILE"

        echo -e "\033[33mFiltering subdomains...\033[0m"
        filter_urls $SUBS_FILE $FILTERED_SUBS_FILE

        echo -e "\033[33mRunning dnsx...\033[0m"
        dnsx -resp -silent < $FILTERED_SUBS_FILE | anew $ALIVE_SUBS_IP_FILE
        check_file_content "$ALIVE_SUBS_IP_FILE"

        awk '{print $1}' < $ALIVE_SUBS_IP_FILE | anew $ALIVE_SUBS_FILE
        check_file_content "$ALIVE_SUBS_FILE"

        echo -e "\033[33mRunning naabu...\033[0m"
        sudo naabu -top-ports 1000 -silent < $ALIVE_SUBS_FILE | anew $OPEN_PORTS_FILE
        check_file_content "$OPEN_PORTS_FILE"

        cut -d ":" -f1 < $OPEN_PORTS_FILE | anew $FINAL_OPEN_PORTS_FILE
        check_file_content "$FINAL_OPEN_PORTS_FILE"

        echo -e "\033[33mRunning httpx...\033[0m"
        httpx -silent --rate-limit 5 -title -status-code -mc 200 < $FINAL_OPEN_PORTS_FILE | remove_brackets | anew $WEB_ALIVE_FILE
        check_file_content "$WEB_ALIVE_FILE"

        # No additional filtering needed, as httpx already filtered status codes 200 and 302
        cp $WEB_ALIVE_FILE $NUCLEI_READY_FILE
    else
        run_subfinder_dnsx_httpx
    fi

    if [ ! -s "$WEB_ALIVE_FILE" ]; then
        echo -e "\033[33mNo live web targets found by httpx. Exiting.\033[0m"
        exit 1
    fi

    if [ "$USE_WAYBACKURLS" == "yes" ]; then
        echo -e "\033[33mRunning waybackurls...\033[0m"
        waybackurls $TARGET | sort -u | anew $WAYBACK_URLS_FILE
        check_file_content "$WAYBACK_URLS_FILE"

        if [ ! -s "$WAYBACK_URLS_FILE" ]; then
            echo -e "\033[33mNo data found from waybackurls. Exiting.\033[0m"
            exit 1
        fi

        echo -e "\033[33mFiltering waybackurls...\033[0m"
        filter_urls $WAYBACK_URLS_FILE $FILTERED_WAYBACK_URLS_FILE

        # Find new URLs that were not discovered by httpx
        comm -23 <(sort -u $FILTERED_WAYBACK_URLS_FILE) <(sort -u $WEB_ALIVE_FILE) | anew $NEW_URLS_FILE

        echo -e "\033[33mNew URLs discovered by waybackurls:\033[0m"
        cat $NEW_URLS_FILE

        # Add waybackurls to the list for Nuclei scan
        cat $FILTERED_WAYBACK_URLS_FILE >> $NUCLEI_READY_FILE
    else
        # If not using waybackurls, just copy the alive URLs to the final list for Nuclei scan
        cp $WEB_ALIVE_FILE $NUCLEI_READY_FILE
    fi

    # Remove duplicates
    sort -u $NUCLEI_READY_FILE -o $NUCLEI_READY_FILE

    echo -e "\033[33mURLs being sent to nuclei:\033[0m"
    cat $NUCLEI_READY_FILE

    echo -e "\033[33mRunning nuclei...\033[0m"
    cat $NUCLEI_READY_FILE | nuclei -ss template-spray -rl 5 -H "$CUSTOM_HEADER" -o $NUCLEI_RESULTS_FILE
    check_file_content "$NUCLEI_RESULTS_FILE"
    cat "$NUCLEI_RESULTS_FILE"

elif [ "$MODE" == "url" ]; then
    if is_oos "$TARGET"; then
        echo -e "\033[33mSkipping OOS URL: $TARGET\033[0m"
    else
        echo $TARGET | nuclei -include-tags misc -etags aem -rl 5 -H "$CUSTOM_HEADER" -o $NUCLEI_RESULTS_FILE
        check_file_content "$NUCLEI_RESULTS_FILE"
        cat "$NUCLEI_RESULTS_FILE"
    fi
else
    echo -e "\033[33mInvalid mode specified. Use 'domain' or 'url'.\033[0m"
    exit 1
fi
