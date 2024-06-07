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



echo "Enter the bug bounty program name:"

read PROGRAM_NAME

CUSTOM_HEADER="X-Bug-Bounty: researcher@$PROGRAM_NAME"



if [[ $SCAN_TYPE -eq 1 ]]; then

    echo "Enter the target domain:"

    read TARGET



    # Domain enumeration and full toolchain

    subfinder -d $TARGET -silent | anew ${DATA_DIR}/${TARGET}-subs.txt && \

    dnsx -resp -silent < ${DATA_DIR}/${TARGET}-subs.txt | anew ${DATA_DIR}/${TARGET}-alive-subs-ip.txt && \

    awk '{print $1}' < ${DATA_DIR}/${TARGET}-alive-subs-ip.txt | anew ${DATA_DIR}/${TARGET}-alive-subs.txt && \

    httpx -title -rate-limit 5 -td -status-code -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36" < ${DATA_DIR}/${TARGET}-alive-subs.txt | anew ${DATA_DIR}/${TARGET}-web-alive.txt && \

    awk '{print $1}' < ${DATA_DIR}/${TARGET}-web-alive.txt | gospider -t 10 -o ${TARGET}crawl | anew ${DATA_DIR}/${TARGET}-crawled.txt && \

    unfurl format %s://dtp < ${DATA_DIR}/${TARGET}-crawled.txt | anew ${DATA_DIR}/${TARGET}-crawled-interesting.txt && \

    awk '{print $1}' < ${DATA_DIR}/${TARGET}-crawled-interesting.txt | gau -b eot,svg,woff,ttf,png,jpg,gif,otf,bmp,pdf,mp3,mp4,mov --subs | anew ${DATA_DIR}/${TARGET}-gau.txt && \

    grep -Ev "$OOS_PATTERNS" ${DATA_DIR}/${TARGET}-gau.txt | anew ${DATA_DIR}/${TARGET}-filtered-gau.txt && \

    httpx -title -rate-limit 5 -td -status-code < ${DATA_DIR}/${TARGET}-filtered-gau.txt | anew ${DATA_DIR}/${TARGET}-web-alive.txt && \

    awk '{print $1}' < ${DATA_DIR}/${TARGET}-web-alive.txt | nuclei -rl 5 -ss template-spray -H "$CUSTOM_HEADER" | tee ${DATA_DIR}/${TARGET}-nuclei-output.txt



elif [[ $SCAN_TYPE -eq 2 ]]; then

    echo "Enter the target URL:"

    read URL



    # Direct steps for a single URL, using verbose output for HTTPX

    httpx_output=$(echo $URL | httpx -verbose -title -rate-limit 5 -status-code -td -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36")

    echo "$httpx_output" | tee "${DATA_DIR}/${URL//[:\/]/_}-web-alive.txt"



    if ! echo "$httpx_output" | grep -qE "$OOS_PATTERNS"; then

        url_active=$(echo "$httpx_output" | awk '{print $1}')

        if [[ $url_active ]]; then

            echo "URL is active and in scope, proceeding with nuclei scan..."

            echo $url_active | nuclei -rl 5 -ss template-spray -H "$CUSTOM_HEADER" | tee "${DATA_DIR}/${URL//[:\/]/_}-nuclei-output.txt"

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

