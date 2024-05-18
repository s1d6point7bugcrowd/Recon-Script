#!/bin/bash

# Function to print text in red color
echo_red() {
    echo -e "\e[31m$1\e[0m"
}

# Function to print text in green color
echo_green() {
    echo -e "\e[32m$1\e[0m"
}

# Check if sufficient arguments are passed
if [ "$#" -lt 2 ]; then
    echo_red "Usage: $0 <mode> <target>"
    echo_red "Modes:"
    echo_red "  domain   Target is a domain name"
    echo_red "  url      Target is a specific URL"
    exit 1
fi

MODE="$1" # 'domain' or 'url'
TARGET="$2"

# Prompt for the program name
read -p "Enter the program name for the X-Bug-Bounty header: " PROGRAM_NAME

# Validate the program name input
if [ -z "$PROGRAM_NAME" ]; then
    echo_red "Program name is required. Exiting."
    exit 1
fi

# Prompt for OOS subdomains (comma-separated)
read -p "Enter Out-Of-Scope subdomains (comma-separated, leave blank for none): " OOS_SUBDOMAINS

# Prompt for OOS URLs (comma-separated)
read -p "Enter Out-Of-Scope URLs (comma-separated, leave blank for none): " OOS_URLS

# Prompt for using naabu for port scanning
read -p "Do you want to use naabu for port scanning? (yes/no): " USE_NAABU

# Convert OOS subdomains into grep-friendly patterns
if [ -n "$OOS_SUBDOMAINS" ]; then
    OOS_SUB_PATTERNS=$(echo "$OOS_SUBDOMAINS" | tr ',' '\n')
    SUB_FILTER_CMD="grep -vFf <(echo \"$OOS_SUB_PATTERNS\")"
else
    SUB_FILTER_CMD="cat"
fi

# Convert OOS URLs into grep-friendly patterns
if [ -n "$OOS_URLS" ]; then
    OOS_URL_PATTERNS=$(echo "$OOS_URLS" | tr ',' '\n')
    URL_FILTER_CMD="grep -vFf <(echo \"$OOS_URL_PATTERNS\")"
else
    URL_FILTER_CMD="cat"
fi

# Show the excluded subdomains
if [ -n "$OOS_SUBDOMAINS" ]; then
    echo_red "The following subdomains will be excluded from scanning:"
    echo_red "$OOS_SUBDOMAINS"
else
    echo_red "No subdomains will be excluded from scanning."
fi

# Show the excluded URLs
if [ -n "$OOS_URLS" ]; then
    echo_red "The following URLs will be excluded from scanning:"
    echo_red "$OOS_URLS"
else
    echo_red "No URLs will be excluded from scanning."
fi

# Construct the custom header
CUSTOM_HEADER="X-Bug-Bounty:researcher@$PROGRAM_NAME"
echo_red "Using custom header: $CUSTOM_HEADER"

# Conditional execution based on mode
if [ "$MODE" == "domain" ]; then
    echo_green "Running subfinder..."
    subfinder -d "$TARGET" -silent | eval "$SUB_FILTER_CMD" | anew "${TARGET}-subs.txt"
    cat "${TARGET}-subs.txt"

    echo_green "Running dnsx..."
    dnsx -resp -silent < "${TARGET}-subs.txt" | anew "${TARGET}-alive-subs-ip.txt"
    cat "${TARGET}-alive-subs-ip.txt"

    echo_green "Running awk to extract IP addresses..."
    awk '/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/ {print $NF}' < "${TARGET}-alive-subs-ip.txt" | anew "${TARGET}-alive-subs.txt"
    cat "${TARGET}-alive-subs.txt"

    if [ "$USE_NAABU" == "yes" ]; then
        echo_green "Running naabu for port scanning..."
        sudo naabu -top-ports 1000 -c 25 -silent < "${TARGET}-alive-subs.txt" | anew "${TARGET}-openports.txt"
    else
        echo_green "Skipping naabu. Using alive subs for further scanning..."
        cp "${TARGET}-alive-subs.txt" "${TARGET}-openports.txt"
    fi
    cat "${TARGET}-openports.txt"

    echo_green "Running httpx..."
    httpx -td -silent --rate-limit 5 -title -status-code -mc 200,403,400,500 < "${TARGET}-openports.txt" | anew "${TARGET}-web-alive.txt"
    cat "${TARGET}-web-alive.txt"

    echo_green "Running gospider..."
    awk '{print $1}' < "${TARGET}-web-alive.txt" | gospider -t 10 -o "${TARGET}crawl" | anew "${TARGET}-crawled.txt"
    cat "${TARGET}-crawled.txt"

    echo_green "Running unfurl..."
    unfurl format %s://%d%p < "${TARGET}-crawled.txt" | httpx -td --rate-limit 5 -silent -title -status-code | anew "${TARGET}-crawled-interesting.txt"
    cat "${TARGET}-crawled-interesting.txt"

    echo_green "Running grep for interesting endpoints..."
    grep -E "(admin|dashboard|control|panel|manage|login|signin|signup|register|backup|config|secret|token|error|api|v1|v2|graphql|\\.js)" "${TARGET}-crawled-interesting.txt" | anew "${TARGET}-interesting.txt"
    cat "${TARGET}-interesting.txt"

    echo_green "Running gau..."
    awk '{print $1}' < "${TARGET}-interesting.txt" | gau -b eot,svg,woff,ttf,png,jpg,gif,otf,bmp,pdf,mp3,mp4,mov --subs | anew "${TARGET}-gau.txt"
    cat "${TARGET}-gau.txt"

    echo_green "Running httpx on gau results..."
    httpx -silent --rate-limit 5 -title -status-code -mc 200,301,302 < "${TARGET}-gau.txt" | eval "$URL_FILTER_CMD" | anew "${TARGET}-web-alive.txt"
    cat "${TARGET}-web-alive.txt"

    echo_green "Running nuclei..."
    awk '{print $1}' < "${TARGET}-web-alive.txt" | nuclei -rl 5 -ss template-spray -H "$CUSTOM_HEADER"

elif [ "$MODE" == "url" ]; then
    echo_green "Running nuclei on the specified URL..."
    echo "$TARGET" | nuclei -include-tags misc -rl 5 -ss template-spray -H "$CUSTOM_HEADER"

else
    echo_red "Invalid mode specified. Use 'domain' or 'url'."
    exit 1
fi
