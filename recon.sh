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



# Ensure files are created if they don't exist

touch ${TARGET}-subs.txt ${TARGET}-filtered-subs.txt ${TARGET}-alive-subs-ip.txt ${TARGET}-alive-subs.txt ${TARGET}-openports.txt ${TARGET}-final-openports.txt ${TARGET}-web-alive.txt ${TARGET}-filtered-crawled.txt ${TARGET}-crawled-interesting.txt ${TARGET}-waybackurls.txt ${TARGET}-filtered-waybackurls.txt ${TARGET}-final-web-alive.txt ${TARGET}-nuclei-results.txt



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

    subfinder -d $TARGET -silent | anew ${TARGET}-subs.txt

    check_file_content "${TARGET}-subs.txt"



    echo "Filtering subdomains..."

    filter_urls ${TARGET}-subs.txt ${TARGET}-filtered-subs.txt



    echo "Running dnsx..."

    dnsx -resp -silent < ${TARGET}-filtered-subs.txt | anew ${TARGET}-alive-subs-ip.txt

    check_file_content "${TARGET}-alive-subs-ip.txt"



    awk '{print $1}' < ${TARGET}-alive-subs-ip.txt | anew ${TARGET}-alive-subs.txt

    check_file_content "${TARGET}-alive-subs.txt"



    if [ "$USE_NAABU" == "yes" ]; then

        echo "Running naabu..."

        sudo naabu -top-ports 1000 -silent < ${TARGET}-alive-subs.txt | anew ${TARGET}-openports.txt

        check_file_content "${TARGET}-openports.txt"



        cut -d ":" -f1 < ${TARGET}-openports.txt | anew ${TARGET}-final-openports.txt

        check_file_content "${TARGET}-final-openports.txt"

    fi



    echo "Running httpx..."

    httpx -td -silent --rate-limit 5 -title -status-code < ${TARGET}-final-openports.txt | remove_brackets | anew ${TARGET}-web-alive.txt

    check_file_content "${TARGET}-web-alive.txt"



    echo "Running waybackurls..."

    awk '{print $1}' < ${TARGET}-web-alive.txt | waybackurls | anew ${TARGET}-waybackurls.txt

    check_file_content "${TARGET}-waybackurls.txt"



    if [ ! -s "${TARGET}-waybackurls.txt" ]; then

        echo "No data found from waybackurls. Exiting."

        exit 1

    fi



    echo "Filtering waybackurls..."

    filter_urls ${TARGET}-waybackurls.txt ${TARGET}-filtered-waybackurls.txt



    echo "Running final httpx..."

    httpx -td -silent --rate-limit 5 -title -status-code < ${TARGET}-filtered-waybackurls.txt | remove_brackets | anew ${TARGET}-final-web-alive.txt

    check_file_content "${TARGET}-final-web-alive.txt"



    # Filter URLs before sending to Nuclei based on status code

    echo "Filtering URLs for Nuclei scan based on status codes..."

    awk '$2 == "200" || $2 == "302" { print $1 }' ${TARGET}-final-web-alive.txt > ${TARGET}-nuclei-ready.txt



    echo "URLs being sent to nuclei:"

    cat ${TARGET}-nuclei-ready.txt



    echo "Running nuclei..."

    cat ${TARGET}-nuclei-ready.txt | nuclei -ss template-spray -rl 5 -H "$CUSTOM_HEADER" -o ${TARGET}-nuclei-results.txt

    check_file_content "${TARGET}-nuclei-results.txt"

    cat ${TARGET}-nuclei-results.txt



elif [ "$MODE" == "url" ]; then

    if is_oos "$TARGET"; then

        echo "Skipping OOS URL: $TARGET"

    else

        echo $TARGET | nuclei -include-tags misc -etags aem -rl 5 -H "$CUSTOM_HEADER" -o ${TARGET}-nuclei-results.txt

        check_file_content "${TARGET}-nuclei-results.txt"

        cat ${TARGET}-nuclei-results.txt

    fi

else

    echo "Invalid mode specified. Use 'domain' or 'url'."

    exit 1

fi

