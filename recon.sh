#!/bin/bash



ORANGE='\033[0;33m'

NC='\033[0m' # No Color



SPEECH_RATE=150

VOICE="en+f3" # English female voice



function announce_message() {

    local message=$1

    if [ "$ENABLE_VOICE" == "y" ]; then

        espeak -s $SPEECH_RATE -v $VOICE "$message"

    fi

}



# Display banner with lolcat

echo "coded by: s1d6p01nt7" | lolcat



echo -e "${ORANGE}Do you want to enable voice announcements? (y/n)${NC}"

read ENABLE_VOICE



# Welcome message

announce_message "Level Up."



# Pause for a few seconds to allow the banner to be seen, then clear the screen

sleep 2

clear



announce_message "Do you want to store the data permanently? Say yes or no."

echo -e "${ORANGE}Do you want to store the data permanently? (y/n)${NC}"

read STORE_PERMANENTLY



# Set the directory based on user input

if [ "$STORE_PERMANENTLY" == "n" ]; then

    DATA_DIR="/tmp"

else

    DATA_DIR="./data"

    mkdir -p $DATA_DIR

fi



announce_message "Do you want to scan a domain or a single URL? Enter one for domain or two for URL."

echo -e "${ORANGE}Do you want to scan a domain (1) or a single URL (2)?${NC}"

read SCAN_TYPE



announce_message "Enter comma-separated out-of-scope patterns."

echo -e "${ORANGE}Enter comma-separated out-of-scope patterns (e.g., *.example.com, example.example.com):${NC}"

read OOS_INPUT

if [ -z "$OOS_INPUT" ]; then

    OOS_PATTERNS="^$" # Empty pattern that matches nothing

else

    OOS_PATTERNS=$(echo $OOS_INPUT | sed 's/[.[\*^$(){}|+?]/\\&/g' | sed 's/,/\\|/g') # Convert to regex OR format and escape special characters

fi



echo -e "${ORANGE}Debug: OOS_PATTERNS='$OOS_PATTERNS'${NC}"



announce_message "Enter the bug bounty program name."

echo -e "${ORANGE}Enter the bug bounty program name:${NC}"

read PROGRAM_NAME

CUSTOM_HEADER="X-Bug-Bounty: researcher@$PROGRAM_NAME"



function announce_vulnerability() {

    local severity=$1

    echo -e "${ORANGE}Announcing: $severity severity vulnerability detected${NC}"

    announce_message "$severity severity vulnerability detected"

}



# Check if espeak is installed

if ! command -v espeak &> /dev/null; then

    echo -e "${ORANGE}espeak command not found. Please install espeak to enable voice announcements.${NC}"

    exit 1

fi



if [[ $SCAN_TYPE -eq 1 ]]; then

    announce_message "Enter the target domain."

    echo -e "${ORANGE}Enter the target domain:${NC}"

    read TARGET



    announce_message "Running subfinder..."

    echo -e "${ORANGE}Running subfinder...${NC}"

    subfinder -d $TARGET -silent -all | anew ${DATA_DIR}/${TARGET}-subs.txt



    announce_message "Filtering out-of-scope patterns from subfinder results..."

    echo -e "${ORANGE}Subfinder completed. Filtering OOS patterns...${NC}"

    grep -Ev "$OOS_PATTERNS" ${DATA_DIR}/${TARGET}-subs.txt | anew ${DATA_DIR}/${TARGET}-filtered-subs.txt

    echo -e "${ORANGE}Filtered subdomains:${NC}"

    cat ${DATA_DIR}/${TARGET}-filtered-subs.txt



    announce_message "Running dnsx on filtered subdomains..."

    echo -e "${ORANGE}OOS filtering completed. Running dnsx...${NC}"

    dnsx -resp -silent < ${DATA_DIR}/${TARGET}-filtered-subs.txt | tee ${DATA_DIR}/${TARGET}-dnsx-results.txt

    echo -e "${ORANGE}dnsx completed. Extracting IPs...${NC}"

    awk '{print $1}' < ${DATA_DIR}/${TARGET}-dnsx-results.txt | anew ${DATA_DIR}/${TARGET}-alive-subs.txt

    echo -e "${ORANGE}Filtered alive subdomains (before applying OOS patterns):${NC}"

    cat ${DATA_DIR}/${TARGET}-alive-subs.txt



    announce_message "Filtering out-of-scope patterns from dnsx results..."

    # Filter out OOS subdomains again after dnsx

    grep -Ev "$OOS_PATTERNS" ${DATA_DIR}/${TARGET}-alive-subs.txt | anew ${DATA_DIR}/${TARGET}-final-alive-subs.txt

    echo -e "${ORANGE}Filtered alive subdomains (after applying OOS patterns):${NC}"

    cat ${DATA_DIR}/${TARGET}-final-alive-subs.txt



    announce_message "Running httpx on alive subdomains..."

    echo -e "${ORANGE}Running httpx on alive subdomains...${NC}"

    httpx_output=$(httpx -silent -title -rate-limit 5 -td -status-code -mc 200,201,202,203,204,206,301,302,303,307,308 -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36" < ${DATA_DIR}/${TARGET}-final-alive-subs.txt)



    echo -e "${ORANGE}httpx results:${NC}"

    echo "$httpx_output"



    announce_message "Extracting URLs from httpx results..."

    echo -e "${ORANGE}Extracting URLs from httpx results...${NC}"

    echo "$httpx_output" | grep -oP 'http[^\s]+' | grep -Ev "$OOS_PATTERNS" | anew ${DATA_DIR}/${TARGET}-httpx-urls.txt



    announce_message "Running nuclei on extracted URLs..."

    echo -e "${ORANGE}Running nuclei on extracted URLs...${NC}"

    cat ${DATA_DIR}/${TARGET}-httpx-urls.txt | nuclei -rl 5 -ss template-spray -H "$CUSTOM_HEADER" | tee ${DATA_DIR}/${TARGET}-nuclei-output.txt | while read -r line; do

        echo "$line"

        if echo "$line" | grep -iq 'medium'; then

            announce_vulnerability "Medium"

        elif echo "$line" | grep -iq 'high'; then

            announce_vulnerability "High"

        elif echo "$line" | grep -iq 'critical'; then

            announce_vulnerability "Critical"

        fi

    done



elif [[ $SCAN_TYPE -eq 2 ]]; then

    announce_message "Enter the target URL."

    echo -e "${ORANGE}Enter the target URL:${NC}"

    read URL



    announce_message "Running httpx on target URL..."

    # Direct steps for a single URL, using verbose output for httpx

    httpx_output=$(echo $URL | httpx -silent -title -rate-limit 5 -status-code -td -mc 200,201,202,203,204,206,301,302,303,307,308 -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36")

    echo -e "${ORANGE}$httpx_output${NC}" | tee "${DATA_DIR}/${URL//[:\/]/_}-web-alive.txt"



    if ! echo "$httpx_output" | grep -qE "$OOS_PATTERNS"; then

        url_active=$(echo "$httpx_output" | grep -oP 'http[^\s]+')

        if [[ $url_active ]]; then

            announce_message "URL is active and in scope, running nuclei scan..."

            echo -e "${ORANGE}URL is active and in scope, proceeding with nuclei scan...${NC}"

            echo $url_active | nuclei -rl 5 -ss template-spray -H "$CUSTOM_HEADER" | tee "${DATA_DIR}/${URL//[:\/]/_}-nuclei-output.txt" | while read -r line; do

                echo "$line"

                if echo "$line" | grep -iq 'medium'; then

                    announce_vulnerability "Medium"

                elif echo "$line" | grep -iq 'high'; then

                    announce_vulnerability "High"

                elif echo "$line" | grep -iq 'critical'; then

                    announce_vulnerability "Critical"

                fi

            done

        else

            announce_message "URL not active or not correctly processed."

            echo -e "${ORANGE}URL not active or not correctly processed.${NC}"

        fi

    else

        announce_message "URL is out of scope."

        echo -e "${ORANGE}URL is out of scope.${NC}"

    fi



else

    announce_message "Invalid option selected."

    echo -e "${ORANGE}Invalid option selected.${NC}"

    exit 1

fi



announce_message "Nuclei scan completed."

echo -e "${ORANGE}Nuclei scan completed.${NC}"

