#!/bin/bash

echo "Do you want to store the data permanently? (y/n)"
read STORE_PERMANENTLY

# Set the directory based on user input
if [ "$STORE_PERMANENTLY" == "n" ]; then
    DATA_DIR="/tmp"
else
    DATA_DIR="./data"
    mkdir -p $DATA_DIR
fi

echo "Do you want to scan a domain (1) or a single URL (2)?"
read SCAN_TYPE

echo "Enter comma-separated out-of-scope patterns (e.g., *.example.com, example.example.com):"
read OOS_INPUT
if [ -z "$OOS_INPUT" ]; then
    OOS_PATTERNS="^$" # Empty pattern that matches nothing
else
    OOS_PATTERNS=$(echo $OOS_INPUT | sed 's/[.[\*^$(){}|+?]/\\&/g' | sed 's/,/\\|/g') # Convert to regex OR format and escape special characters
fi

echo "Debug: OOS_PATTERNS='$OOS_PATTERNS'"

echo "Enter the bug bounty program name:"
read PROGRAM_NAME
CUSTOM_HEADER="X-Bug-Bounty: researcher@$PROGRAM_NAME"

if [[ $SCAN_TYPE -eq 1 ]]; then
    echo "Enter the target domain:"
    read TARGET

    # Domain enumeration and full toolchain with OOS filtering
    echo "Running subfinder..."
    subfinder -d $TARGET -silent | anew ${DATA_DIR}/${TARGET}-subs.txt
    echo "Subfinder completed. Filtering OOS patterns..."
    grep -Ev "$OOS_PATTERNS" ${DATA_DIR}/${TARGET}-subs.txt | anew ${DATA_DIR}/${TARGET}-filtered-subs.txt
    echo "Filtered subdomains:"
    cat ${DATA_DIR}/${TARGET}-filtered-subs.txt

    echo "OOS filtering completed. Running dnsx..."
    dnsx -resp -silent < ${DATA_DIR}/${TARGET}-filtered-subs.txt | tee ${DATA_DIR}/${TARGET}-dnsx-results.txt
    echo "dnsx completed. Extracting IPs..."
    awk '{print $1}' < ${DATA_DIR}/${TARGET}-dnsx-results.txt | anew ${DATA_DIR}/${TARGET}-alive-subs.txt
    echo "Filtered alive subdomains (before applying OOS patterns):"
    cat ${DATA_DIR}/${TARGET}-alive-subs.txt

    # Filter out OOS subdomains again after dnsx
    grep -Ev "$OOS_PATTERNS" ${DATA_DIR}/${TARGET}-alive-subs.txt | anew ${DATA_DIR}/${TARGET}-final-alive-subs.txt
    echo "Filtered alive subdomains (after applying OOS patterns):"
    cat ${DATA_DIR}/${TARGET}-final-alive-subs.txt

    echo "Running httpx on alive subdomains and passing results to nuclei..."
    httpx_output="${DATA_DIR}/${TARGET}-httpx-results.txt"
    httpx -title -rate-limit 5 -td -status-code -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36" < ${DATA_DIR}/${TARGET}-final-alive-subs.txt | tee ${httpx_output}
    
    echo "httpx results:"
    cat ${httpx_output}

    cat ${httpx_output} | grep -Ev "$OOS_PATTERNS" | nuclei -rl 5 -retries 10 -ss template-spray -H "$CUSTOM_HEADER" | tee ${DATA_DIR}/${TARGET}-nuclei-output.txt

elif [[ $SCAN_TYPE -eq 2 ]]; then
    echo "Enter the target URL:"
    read URL

    # Direct steps for a single URL, using verbose output for httpx
    httpx_output=$(echo $URL | httpx -verbose -title -rate-limit 5 -status-code -td -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36")
    echo "$httpx_output" | tee "${DATA_DIR}/${URL//[:\/]/_}-web-alive.txt"

    if ! echo "$httpx_output" | grep -qE "$OOS_PATTERNS"; then
        url_active=$(echo "$httpx_output" | awk '{print $1}')
        if [[ $url_active ]]; then
            echo "URL is active and in scope, proceeding with nuclei scan..."
            echo $url_active | nuclei -rl 5 -retries 10 -ss template-spray -H "$CUSTOM_HEADER" | tee "${DATA_DIR}/${URL//[:\/]/_}-nuclei-output.txt"
        else
            echo "URL not active or not correctly processed."
        fi
    else
        echo "URL is out of scope."
    fi

else
    echo "Invalid option selected."
    exit 1
fi
