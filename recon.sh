#!/bin/bash

# Function to print text in red color
echo_red() {
    echo -e "\e[31m$1\e[0m"
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

# Prompt for OOS items (comma-separated)
read -p "Enter Out-Of-Scope subdomains or URLs (comma-separated, leave blank for none): " OOS_ITEMS

# Convert OOS items into grep-friendly patterns for subdomains and URLs separately
FILTER_CMD="cat"
if [ -n "$OOS_ITEMS" ]; then
    OOS_SUBDOMAINS=$(echo "$OOS_ITEMS" | tr ',' '\n' | grep -v 'http' | sed 's/^/"/;s/$/"/')
    OOS_URLS=$(echo "$OOS_ITEMS" | tr ',' '\n' | grep 'http' | sed 's/^/"/;s/$/"/')
    if [ -n "$OOS_SUBDOMAINS" ]; then
        FILTER_CMD="grep -vFf <(echo -e \"$OOS_SUBDOMAINS\")"
    fi
    if [ -n "$OOS_URLS" ]; then
        FILTER_CMD="$FILTER_CMD | grep -vFf <(echo -e \"$OOS_URLS\")"
    fi
fi

# Show the excluded subdomains and URLs
if [ -n "$OOS_ITEMS" ]; then
    echo_red "The following subdomains/URLs will be excluded from scanning:"
    echo_red "$OOS_ITEMS"
else
    echo_red "No subdomains/URLs will be excluded from scanning."
fi

# Construct the custom header
CUSTOM_HEADER="X-Bug-Bounty:researcher@$PROGRAM_NAME"
echo_red "Using custom header: $CUSTOM_HEADER"

# Conditional execution based on mode
if [ "$MODE" == "domain" ]; then
    subfinder -d "$TARGET" -silent | eval "$FILTER_CMD" | anew "${TARGET}-subs.txt" && \
    dnsx -resp -silent < "${TARGET}-subs.txt" | anew "${TARGET}-alive-subs-ip.txt" && \
    awk '{print $1}' < "${TARGET}-alive-subs-ip.txt" | anew "${TARGET}-alive-subs.txt" && \
    sudo naabu -top-ports 1000 -rate 5 -c 25 -silent < "${TARGET}-alive-subs.txt" | anew "${TARGET}-openports.txt" && \
    cut -d ":" -f1 < "${TARGET}-openports.txt" | sudo naabu | anew "${TARGET}-openports.txt" && \
    httpx -td -silent --rate-limit 5 -title -status-code -mc 200,403,400,500 < "${TARGET}-openports.txt" | anew "${TARGET}-web-alive.txt" && \
    awk '{print $1}' < "${TARGET}-web-alive.txt" | gospider -t 10 -o "${TARGET}crawl" | anew "${TARGET}-crawled.txt" && \
    unfurl format %s://%d%p < "${TARGET}-crawled.txt" | httpx -td --rate-limit 5 -silent -title -status-code | anew "${TARGET}-crawled-interesting.txt" && \
    grep -E "(admin|dashboard|control|panel|manage|login|signin|signup|register|backup|config|secret|token|error|api|v1|v2|graphql|\\.js)" "${TARGET}-crawled-interesting.txt" | anew "${TARGET}-interesting.txt" && \
    awk '{print $1}' < "${TARGET}-interesting.txt" | gau -b eot,svg,woff,ttf,png,jpg,gif,otf,bmp,pdf,mp3,mp4,mov --subs | anew "${TARGET}-gau.txt" && \
    httpx -silent --rate-limit 5 -title -status-code -mc 200,301,302 < "${TARGET}-gau.txt" | anew "${TARGET}-web-alive.txt" && \
    awk '{print $1}' < "${TARGET}-web-alive.txt" | nuclei -rl 5 -ss template-spray -H "$CUSTOM_HEADER"

    # Save in-scope subdomains to subdomains.txt
    cat "${TARGET}-subs.txt" > subdomains.txt

    # Inform the user about subdomain takeover detection
    echo_red "Subdomain takeover detection in progress..."

    # Run subzy to check for subdomain takeovers
    subzy run --targets subdomains.txt --hide_fails | anew "${TARGET}-subzy-results.txt"

    # Clear subdomains.txt after use
    > subdomains.txt

elif [ "$MODE" == "url" ]; then
    echo "$TARGET" | nuclei -include-tags misc -rl 5 -ss template-spray -H "$CUSTOM_HEADER"

else
    echo_red "Invalid mode specified. Use 'domain' or 'url'."
    exit 1
fi
