#!/bin/bash



echo "Do you want to scan a domain (1) or a single URL (2)?"

read SCAN_TYPE



echo "Enter comma-separated out-of-scope patterns (e.g., *.example.com, example.example.com):"

read OOS_INPUT

if [ -z "$OOS_INPUT" ]; then

    OOS_PATTERNS="^$" # Empty pattern that matches nothing

else

    OOS_PATTERNS=$(echo $OOS_INPUT | sed 's/,/\|/g' | sed 's/\*/.*/g') # Convert to regex OR format and handle wildcards

fi



echo "Enter the bug bounty program name:"

read PROGRAM_NAME

CUSTOM_HEADER="X-Bug-Bounty: researcher@$PROGRAM_NAME"



if [[ $SCAN_TYPE -eq 1 ]]; then

    echo "Enter the target domain:"

    read TARGET



    # Domain enumeration and reduced toolchain without naabu

    subfinder -d $TARGET -silent -all | anew ${TARGET}-subs.txt && \

    dnsx -resp -silent < ${TARGET}-subs.txt | anew ${TARGET}-alive-subs-ip.txt && \

    awk '{print $1}' < ${TARGET}-alive-subs-ip.txt | anew ${TARGET}-alive-subs.txt && \

    httpx -silent -rate-limit 5 -td -title -status-code -mc 200,403,400,500 < ${TARGET}-alive-subs.txt | anew ${TARGET}-web-alive.txt && \

    awk '{print $1}' < ${TARGET}-web-alive.txt | gospider -t 10 -o ${TARGET}crawl | anew ${TARGET}-crawled.txt && \

    unfurl format %s://dtp < ${TARGET}-crawled.txt | anew ${TARGET}-crawled-interesting.txt && \

    awk '{print $1}' < ${TARGET}-crawled-interesting.txt | gau -b eot,svg,woff,ttf,png,jpg,gif,otf,bmp,pdf,mp3,mp4,mov --subs | anew ${TARGET}-gau.txt && \

    grep -Ev "$OOS_PATTERNS" ${TARGET}-gau.txt | anew ${TARGET}-filtered-gau.txt && \

    httpx -silent -rate-limit 5 -td -title -status-code -mc 200,403,400,500 < ${TARGET}-filtered-gau.txt | anew ${TARGET}-web-alive.txt && \

    awk '{print $1}' < ${TARGET}-web-alive.txt | nuclei -rl 5 -ss template-spray -H "$CUSTOM_HEADER" | tee ${TARGET}-nuclei-output.txt



elif [[ $SCAN_TYPE -eq 2 ]]; then

    echo "Enter the target URL:"

    read URL



    # Direct steps for a single URL, omitting gospider and gau

    httpx_output=$(echo $URL | httpx -rate-limit 5 -td -silent -title -status-code -mc 200,403,400,500)

    echo "$httpx_output" | tee "${URL//[:\/]/_}-web-alive.txt"



    if echo "$httpx_output" | grep -qv "$OOS_PATTERNS"; then

        url_active=$(echo "$httpx_output" | awk '{print $1}')

        if [[ $url_active ]]; then

            echo "URL is active and in scope, proceeding with nuclei scan..."

            echo $url_active | nuclei -rl 5 -ss template-spray -H "$CUSTOM_HEADER" | tee "${URL//[:\/]/_}-nuclei-output.txt"

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

