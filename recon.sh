#!/bin/bash



# Check if sufficient arguments are passed

if [ "$#" -lt 2 ]; then

    echo "Usage: $0 <mode> <target>"

    echo "Modes:"

    echo "  domain    Target is a domain name"

    echo "  url       Target is a specific URL"

    exit 1

fi



MODE="$1"  # 'domain' or 'url'

TARGET="$2"



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

touch ${TARGET}-filtered-subs.txt ${TARGET}-filtered-crawled.txt ${TARGET}-filtered-gau.txt



# Function to remove brackets from IP addresses

remove_brackets() {

    sed 's/\[\([^]]*\)\]/\1/g'

}



# Conditional execution based on mode

if [ "$MODE" == "domain" ]; then

    subfinder -d $TARGET -silent | anew ${TARGET}-subs.txt



    while read -r subdomain; do

        if is_oos "$subdomain"; then

            echo "Skipping OOS subdomain: $subdomain"

        else

            echo "$subdomain" | anew ${TARGET}-filtered-subs.txt

        fi

    done < ${TARGET}-subs.txt



    dnsx -resp -silent < ${TARGET}-filtered-subs.txt | anew ${TARGET}-alive-subs-ip.txt

    awk '{print $1}' < ${TARGET}-alive-subs-ip.txt | anew ${TARGET}-alive-subs.txt



    if [ "$USE_NAABU" == "yes" ]; then

        sudo naabu -top-ports 1000 -silent < ${TARGET}-alive-subs.txt | anew ${TARGET}-openports.txt

        cut -d ":" -f1 < ${TARGET}-openports.txt | anew ${TARGET}-final-openports.txt

        httpx -td -silent --rate-limit 5 -title -status-code -tech-detect -mc 200,403,400,500 < ${TARGET}-final-openports.txt | remove_brackets | anew ${TARGET}-web-alive.txt

    else

        httpx -td -silent --rate-limit 5 -title -status-code -tech-detect -mc 200,403,400,500 < ${TARGET}-alive-subs.txt | remove_brackets | anew ${TARGET}-web-alive.txt

    fi



    awk '{print $1}' < ${TARGET}-web-alive.txt | gospider -t 10 -o ${TARGET}crawl | anew ${TARGET}-crawled.txt



    while read -r url; do

        if is_oos "$url"; then

            echo "Skipping OOS URL: $url"

        else

            echo "$url" | anew ${TARGET}-filtered-crawled.txt

        fi

    done < ${TARGET}-crawled.txt



    unfurl format %s://dtp < ${TARGET}-filtered-crawled.txt | httpx -td --rate-limit 5 -silent -title -status-code -tech-detect | remove_brackets | anew ${TARGET}-crawled-interesting.txt

    awk '{print $1}' < ${TARGET}-crawled-interesting.txt | gau -b eot,svg,woff,ttf,png,jpg,gif,otf,bmp,pdf,mp3,mp4,mov --subs | anew ${TARGET}-gau.txt



    while read -r gau_url; do

        if is_oos "$gau_url"; then

            echo "Skipping OOS URL: $gau_url"

        else

            echo "$gau_url" | anew ${TARGET}-filtered-gau.txt

        fi

    done < ${TARGET}-gau.txt



    httpx -silent --rate-limit 5 -title -status-code -tech-detect -mc 200,301,302 < ${TARGET}-filtered-gau.txt | remove_brackets | anew ${TARGET}-final-web-alive.txt

    awk '{print $1}' < ${TARGET}-final-web-alive.txt | nuclei -ss template-spray -H "$CUSTOM_HEADER"



elif [ "$MODE" == "url" ]; then

    if is_oos "$TARGET"; then

        echo "Skipping OOS URL: $TARGET"

    else

        echo $TARGET | nuclei -include-tags misc -etags aem -rl 5 -ss template-spray -H "$CUSTOM_HEADER"

    fi

else

    echo "Invalid mode specified. Use 'domain' or 'url'."

    exit 1

fi

