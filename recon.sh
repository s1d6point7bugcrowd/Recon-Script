#!/bin/bash



ORANGE='\033[0;33m'

NC='\033[0m' # No Color



SPEECH_RATE=130

VOICE="en+f3" # English female voice



function announce_message() {

    local message=$1

    espeak -s $SPEECH_RATE -v $VOICE "$message"

}



# Welcome message

announce_message "This tool will help you test domains or URLs for vulnerabilities and announce the findings in real time."



echo -e "${ORANGE}Do you want to store the data permanently? (y/n)${NC}"

read STORE_PERMANENTLY



# Set the directory based on user input

if [ "$STORE_PERMANENTLY" == "n" ]; then

    DATA_DIR="/tmp"

else

    DATA_DIR="./data"

    mkdir -p $DATA_DIR

fi



echo -e "${ORANGE}Do you want to scan a domain (1) or a single URL (2)?${NC}"

read SCAN_TYPE



echo -e "${ORANGE}Enter comma-separated out-of-scope patterns (e.g., *.example.com, example.example.com):${NC}"

read OOS_INPUT

if [ -z "$OOS_INPUT" ]; then

    OOS_PATTERNS="^$" # Empty pattern that matches nothing

else

    OOS_PATTERNS=$(echo $OOS_INPUT | sed 's/[.[\*^$(){}|+?]/\\&/g' | sed 's/,/\\|/g') # Convert to regex OR format and escape special characters

fi



echo -e "${ORANGE}Debug: OOS_PATTERNS='$OOS_PATTERNS'${NC}"



echo -e "${ORANGE}Enter the bug bounty program name:${NC}"

read PROGRAM_NAME

CUSTOM_HEADER="X-Bug-Bounty: researcher@$PROGRAM_NAME"



function announce_vulnerability() {

    local severity=$1

    local vuln=$2

    echo -e "${ORANGE}Announcing: $severity severity vulnerability detected: $vuln${NC}"

    espeak -s $SPEECH_RATE -v $VOICE "$severity severity vulnerability detected: $vuln"

}



# Check if espeak is installed

if ! command -v espeak &> /dev/null; then

    echo -e "${ORANGE}espeak command not found. Please install espeak to enable voice announcements.${NC}"

    exit 1

fi



if [[ $SCAN_TYPE -eq 1 ]]; then

    echo -e "${ORANGE}Enter the target domain:${NC}"

    read TARGET



    # Domain enumeration and full toolchain with OOS filtering

    echo -e "${ORANGE}Running subfinder...${NC}"

    subfinder -d $TARGET -silent -all | anew ${DATA_DIR}/${TARGET}-subs.txt

    echo -e "${ORANGE}Subfinder completed. Filtering OOS patterns...${NC}"

    grep -Ev "$OOS_PATTERNS" ${DATA_DIR}/${TARGET}-subs.txt | anew ${DATA_DIR}/${TARGET}-filtered-subs.txt

    echo -e "${ORANGE}Filtered subdomains:${NC}"

    cat ${DATA_DIR}/${TARGET}-filtered-subs.txt



    echo -e "${ORANGE}OOS filtering completed. Running dnsx...${NC}"

    dnsx -resp -silent < ${DATA_DIR}/${TARGET}-filtered-subs.txt | tee ${DATA_DIR}/${TARGET}-dnsx-results.txt

    echo -e "${ORANGE}dnsx completed. Extracting IPs...${NC}"

    awk '{print $1}' < ${DATA_DIR}/${TARGET}-dnsx-results.txt | anew ${DATA_DIR}/${TARGET}-alive-subs.txt

    echo -e "${ORANGE}Filtered alive subdomains (before applying OOS patterns):${NC}"

    cat ${DATA_DIR}/${TARGET}-alive-subs.txt



    # Filter out OOS subdomains again after dnsx

    grep -Ev "$OOS_PATTERNS" ${DATA_DIR}/${TARGET}-alive-subs.txt | anew ${DATA_DIR}/${TARGET}-final-alive-subs.txt

    echo -e "${ORANGE}Filtered alive subdomains (after applying OOS patterns):${NC}"

    cat ${DATA_DIR}/${TARGET}-final-alive-subs.txt



    echo -e "${ORANGE}Running httpx on alive subdomains...${NC}"

    httpx_output="${DATA_DIR}/${TARGET}-httpx-results.txt"

    httpx -silent -title -rate-limit 5 -td -mc 200 -status-code -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36" < ${DATA_DIR}/${TARGET}-final-alive-subs.txt | tee ${httpx_output}



    echo -e "${ORANGE}httpx results:${NC}"

    cat ${httpx_output}



    echo -e "${ORANGE}Extracting URLs from httpx results...${NC}"

    grep -oP 'http[^\s]+' ${httpx_output} | grep -Ev "$OOS_PATTERNS" | anew ${DATA_DIR}/${TARGET}-httpx-urls.txt



    echo -e "${ORANGE}Running nuclei on extracted URLs...${NC}"

    cat ${DATA_DIR}/${TARGET}-httpx-urls.txt | nuclei -rl 5 -retries 10 -ss template-spray -H "$CUSTOM_HEADER" | tee ${DATA_DIR}/${TARGET}-nuclei-output.txt | while read -r line; do

        echo "$line"

        if echo "$line" | grep -iq 'medium'; then

            vuln=$(echo "$line" | grep -oP '\[[^\]]+\]' | head -1 | tr -d '[]')

            announce_vulnerability "Medium" "$vuln"

        elif echo "$line" | grep -iq 'high'; then

            vuln=$(echo "$line" | grep -oP '\[[^\]]+\]' | head -1 | tr -d '[]')

            announce_vulnerability "High" "$vuln"

        elif echo "$line" | grep -iq 'critical'; then

            vuln=$(echo "$line" | grep -oP '\[[^\]]+\]' | head -1 | tr -d '[]')

            announce_vulnerability "Critical" "$vuln"

        fi

    done



elif [[ $SCAN_TYPE -eq 2 ]]; then

    echo -e "${ORANGE}Enter the target URL:${NC}"

    read URL



    # Direct steps for a single URL, using verbose output for httpx

    httpx_output=$(echo $URL | httpx -silent -mc 200 -title -rate-limit 5 -status-code -td -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36")

    echo -e "${ORANGE}$httpx_output${NC}" | tee "${DATA_DIR}/${URL//[:\/]/_}-web-alive.txt"



    if ! echo "$httpx_output" | grep -qE "$OOS_PATTERNS"; then

        url_active=$(echo "$httpx_output" | grep -oP 'http[^\s]+')

        if [[ $url_active ]]; then

            echo -e "${ORANGE}URL is active and in scope, proceeding with nuclei scan...${NC}"

            echo $url_active | nuclei -rl 5 -retries 10 -ss template-spray -H "$CUSTOM_HEADER" | tee "${DATA_DIR}/${URL//[:\/]/_}-nuclei-output.txt" | while read -r line; do

                echo "$line"

                if echo "$line" | grep -iq 'medium'; then

                    vuln=$(echo "$line" | grep -oP '\[[^\]]+\]' | head -1 | tr -d '[]')

                    announce_vulnerability "Medium" "$vuln"

                elif echo "$line" | grep -iq 'high'; then

                    vuln=$(echo "$line" | grep -oP '\[[^\]]+\]' | head -1 | tr -d '[]')

                    announce_vulnerability "High" "$vuln"

                elif echo "$line" | grep -iq 'critical'; then

                    vuln=$(echo "$line" | grep -oP '\[[^\]]+\]' | head -1 | tr -d '[]')

                    announce_vulnerability "Critical" "$vuln"

                fi

            done

        else

            echo -e "${ORANGE}URL not active or not correctly processed.${NC}"

        fi

    else

        echo -e "${ORANGE}URL is out of scope.${NC}"

    fi



else

    echo -e "${ORANGE}Invalid option selected.${NC}"

    exit 1

fi



echo -e "${ORANGE}Nuclei scan completed.${NC}"

