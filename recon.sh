#!/bin/bash

# Check if sufficient arguments are passed
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <mode> <target>"
    echo "Modes:"
    echo "  domain    Target is a domain name"
    echo "  url       Target is a specific URL"
    exit 1
fi

# Normalize and trim MODE input to avoid case sensitivity and trailing space issues
MODE=$(echo "$1" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')
TARGET="$2"

# Debugging output to check the value of MODE
echo "Mode is set to: '$MODE'"

# Prompt for the program name
read -p "Enter the program name for the X-Bug-Bounty header: " PROGRAM_NAME

# Validate the program name input
if [ -z "$PROGRAM_NAME" ]; then
    echo "Program name is required. Exiting."
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
echo "Using custom header: $CUSTOM_HEADER"

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

# Function to remove brackets from IP addresses
remove_brackets() {
    sed 's/\[\([^]]*\)\]/\1/g'
}

# Debugging function to check file content
check_file_content() {
    local file=$1
    echo "Debug: Checking content of $file"
    if [ ! -s "$file" ]; then
        echo "Debug: $file is empty."
    else
        echo "Debug: $file has content."
        cat "$file" | head -n 10  # Display first 10 lines for inspection
    fi
}

# Function to filter URLs and handle out-of-scope URLs
filter_urls() {
    local input_file=$1
    local output_file=$2
    while read -r url; do
        if is_oos "$url"; then
            echo "Skipping OOS URL: $url"
        else
            echo "$url" | anew $output_file
        fi
    done < $input_file
    check_file_content $output_file
}

# Conditional execution based on mode
if [ "$MODE" == "domain" ]; then
    echo "Running subfinder..."
    subfinder -d $TARGET -silent | anew $SUBS_FILE
    check_file_content "$SUBS_FILE"

    echo "Filtering subdomains..."
    filter_urls $SUBS_FILE $FILTERED_SUBS_FILE

    echo "Running dnsx..."
    dnsx -resp -silent < $FILTERED_SUBS_FILE | anew $ALIVE_SUBS_IP_FILE
    check_file_content "$ALIVE_SUBS_IP_FILE"

    awk '{print $1}' < $ALIVE_SUBS_IP_FILE | anew $ALIVE_SUBS_FILE
    check_file_content "$ALIVE_SUBS_FILE"

    if [ "$USE_NAABU" == "yes" ]; then
        echo "Running naabu..."
        sudo naabu -top-ports 1000 -silent < $ALIVE_SUBS_FILE | anew $OPEN_PORTS_FILE
        check_file_content "$OPEN_PORTS_FILE"

        cut -d ":" -f1 < $OPEN_PORTS_FILE | anew $FINAL_OPEN_PORTS_FILE
        check_file_content "$FINAL_OPEN_PORTS_FILE"
    fi

    echo "Running httpx..."
    httpx -td -silent --rate-limit 5 -title -status-code < $FINAL_OPEN_PORTS_FILE | remove_brackets | anew $WEB_ALIVE_FILE
    check_file_content "$WEB_ALIVE_FILE"

    echo "Running waybackurls..."
    waybackurls $TARGET -filter "status_code:200" | sort -u | anew $WAYBACK_URLS_FILE
    check_file_content "$WAYBACK_URLS_FILE"

    if [ ! -s "$WAYBACK_URLS_FILE" ]; then
        echo "No data found from waybackurls. Exiting."
        exit 1
    fi

    echo "Filtering waybackurls..."
    filter_urls $WAYBACK_URLS_FILE $FILTERED_WAYBACK_URLS_FILE

    # Filter URLs before sending to Nuclei based on status code
    echo "Filtering URLs for Nuclei scan based on status codes..."
    cat $FILTERED_WAYBACK_URLS_FILE > $NUCLEI_READY_FILE

    echo "URLs being sent to nuclei:"
    cat $NUCLEI_READY_FILE

    echo "Running nuclei..."
    cat $NUCLEI_READY_FILE | nuclei -ss template-spray -rl 5 -H "$CUSTOM_HEADER" -o $NUCLEI_RESULTS_FILE
    check_file_content "$NUCLEI_RESULTS_FILE"
    cat "$NUCLEI_RESULTS_FILE"

elif [ "$MODE" == "url" ]; then
    if is_oos "$TARGET"; then
        echo "Skipping OOS URL: $TARGET"
    else
        echo $TARGET | nuclei -include-tags misc -etags aem -rl 5 -H "$CUSTOM_HEADER" -o $NUCLEI_RESULTS_FILE
        check_file_content "$NUCLEI_RESULTS_FILE"
        cat "$NUCLEI_RESULTS_FILE"
    fi
else
    echo "Invalid mode specified. Use 'domain' or 'url'."
    exit 1
fi
