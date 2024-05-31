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



# Prompt for using specific Nuclei templates or tags

read -p "Do you want to use specific Nuclei templates or tags? (yes/no): " USE_SPECIFIC_TEMPLATES_OR_TAGS



if [ "$USE_SPECIFIC_TEMPLATES_OR_TAGS" == "yes" ]; then

    read -p "Enter the path(s) to Nuclei templates or tags (comma separated): " NUCLEI_TEMPLATES_OR_TAGS

    if [[ $NUCLEI_TEMPLATES_OR_TAGS == *"/"* ]]; then

        # If input contains "/", treat it as template paths

        NUCLEI_TEMPLATES_OPTION="-t $(echo $NUCLEI_TEMPLATES_OR_TAGS | tr ',' ' ')"

    else

        # Otherwise, treat it as tags

        NUCLEI_TEMPLATES_OPTION="-tags $(echo $NUCLEI_TEMPLATES_OR_TAGS | tr ',' ' ')"

    fi

else

    # Default Nuclei command options

    NUCLEI_TEMPLATES_OPTION="-ss template-spray -include-tags misc -etags aem"

fi



# Define a function to create files based on user's choice

create_file() {

    if [ "$STORE_LOCALLY" == "yes" ]; then

        touch "$1"

        echo "$1"

    else

        mktemp

    fi

}



# Function to sanitize URLs for filenames

sanitize_filename() {

    echo "$1" | tr -d '[:punct:]' | tr '[:upper:]' '[:lower:]' | tr ' ' '_'

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

SUBS_FILE=$(create_file "$(sanitize_filename "${TARGET}-subs.txt")")

FILTERED_SUBS_FILE=$(create_file "$(sanitize_filename "${TARGET}-filtered-subs.txt")")

ALIVE_SUBS_IP_FILE=$(create_file "$(sanitize_filename "${TARGET}-alive-subs-ip.txt")")

ALIVE_SUBS_FILE=$(create_file "$(sanitize_filename "${TARGET}-alive-subs.txt")")

OPEN_PORTS_FILE=$(create_file "$(sanitize_filename "${TARGET}-openports.txt")")

FINAL_OPEN_PORTS_FILE=$(create_file "$(sanitize_filename "${TARGET}-final-openports.txt")")

WEB_ALIVE_FILE=$(create_file "$(sanitize_filename "${TARGET}-web-alive.txt")")

NUCLEI_READY_FILE=$(create_file "$(sanitize_filename "${TARGET}-nuclei-ready.txt")")

NUCLEI_RESULTS_FILE=$(create_file "$(sanitize_filename "${TARGET}-nuclei-results.txt")")

TEMP_FILE=$(create_file "$(sanitize_filename "temp-file.txt")")

WAYBACK_URLS_FILE=$(create_file "$(sanitize_filename "wayback-urls.txt")")



# Function to remove brackets from IP addresses

remove_brackets() {

    sed 's/\[\([^]]*\)\]/\1/g'

}



# Function to filter URLs and handle out-of-scope URLs

filter_urls() {

    local input_file=$1

    local output_file=$2

    while read -r url; do

        if is_oos "$url"; then

            echo -e "\033[33mSkipping OOS URL: $url\033[0m"

        else

            echo "$url" >> $output_file

        fi

    done < $input_file

}



# Function to run subfinder, dnsx, and httpx

run_subfinder_dnsx_httpx() {

    echo -e "\033[33mRunning subfinder...\033[0m"

    subfinder -d $TARGET -silent -all > $SUBS_FILE

    echo -e "\033[33mSubdomains discovered by subfinder:\033[0m"

    cat "$SUBS_FILE"  # Display all subdomains discovered by subfinder



    echo -e "\033[33mFiltering subdomains...\033[0m"

    filter_urls $SUBS_FILE $FILTERED_SUBS_FILE

    echo -e "\033[33mFiltered subdomains (excluding OOS):\033[0m"

    cat "$FILTERED_SUBS_FILE"



    echo -e "\033[33mRunning dnsx...\033[0m"

    dnsx -resp -a -silent < $FILTERED_SUBS_FILE | tee $ALIVE_SUBS_IP_FILE



    awk '{print $1}' < $ALIVE_SUBS_IP_FILE > $ALIVE_SUBS_FILE



    echo -e "\033[33mRunning httpx...\033[0m"

    httpx -silent --rate-limit 5 -title -status-code -mc 200 < $ALIVE_SUBS_FILE | remove_brackets | tee $WEB_ALIVE_FILE



    # Filter for https URLs only

    grep -E '^https://' $WEB_ALIVE_FILE > $NUCLEI_READY_FILE

}



# Function to run waybackurls and analyze output

run_waybackurls() {

    echo -e "\033[33mRunning waybackurls...\033[0m"

    echo "$TARGET" | waybackurls > $WAYBACK_URLS_FILE

    # Filter the waybackurls output for OOS URLs

    filter_urls $WAYBACK_URLS_FILE $WAYBACK_URLS_FILE

}



# Main workflow

if [ "$MODE" == "domain" ]; then

    run_subfinder_dnsx_httpx



    if [ "$USE_WAYBACKURLS" == "yes" ]; then

        run_waybackurls

    fi



    if [ "$USE_NAABU" == "yes" ]; then

        echo -e "\033[33mRunning naabu...\033[0m"

        sudo naabu -top-ports 1000 -silent < $ALIVE_SUBS_FILE | tee $OPEN_PORTS_FILE



        cut -d ":" -f1 < $OPEN_PORTS_FILE > $FINAL_OPEN_PORTS_FILE



        echo -e "\033[33mRunning httpx on open ports...\033[0m"

        httpx -silent --rate-limit 5 -title -status-code -mc 200 < $FINAL_OPEN_PORTS_FILE | remove_brackets | tee $WEB_ALIVE_FILE



        # Filter for https URLs only

        grep -E '^https://' $WEB_ALIVE_FILE > $NUCLEI_READY_FILE

    fi



    if [ ! -s "$NUCLEI_READY_FILE" ]; then

        echo -e "\033[33mNo live web targets found by httpx. Exiting.\033[0m"

        exit 1

    fi



    echo -e "\033[33mURLs being sent to nuclei:\033[0m"

    cat $NUCLEI_READY_FILE



    echo -e "\033[33mRunning nuclei...\033[0m"

    cat $NUCLEI_READY_FILE | nuclei $NUCLEI_TEMPLATES_OPTION -rl 5 -H "$CUSTOM_HEADER" -o $NUCLEI_RESULTS_FILE &

    NUCLIE_PID=$!

    wait $NUCLIE_PID



    cat "$NUCLEI_RESULTS_FILE"



elif [ "$MODE" == "url" ]; then

    if is_oos "$TARGET"; then

        echo -e "\033[33mSkipping OOS URL: $TARGET\033[0m"

    else

        echo -e "\033[33mRunning dnsx...\033[0m"

        echo "$TARGET" | dnsx -silent | tee $NUCLEI_READY_FILE



        echo -e "\033[33mRunning httpx...\033[0m"

        cat $NUCLEI_READY_FILE | httpx -silent --rate-limit 5 -title -status-code -mc 200 | tee $TEMP_FILE



        # Filter for https URLs only

        grep -E '^https://' $TEMP_FILE > $NUCLEI_READY_FILE



        if [ "$USE_WAYBACKURLS" == "yes" ]; then

            run_waybackurls

        fi



        echo -e "\033[33mURLs being sent to nuclei:\033[0m"

        cat $NUCLEI_READY_FILE



        echo -e "\033[33mRunning nuclei...\033[0m"

        cat $NUCLEI_READY_FILE | nuclei $NUCLEI_TEMPLATES_OPTION -rl 5 -H "$CUSTOM_HEADER" -o $NUCLEI_RESULTS_FILE &

        NUCLIE_PID=$!

        wait $NUCLIE_PID



        cat "$NUCLEI_RESULTS_FILE"

    fi

else

    echo -e "\033[33mInvalid mode specified. Use 'domain' or 'url'.\033[0m"

    exit 1

fi

