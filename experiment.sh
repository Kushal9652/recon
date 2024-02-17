#!/bin/bash

# Function to display usage information
show_help() {
    echo "Usage: $0 <target_domain(s) | target_file> [output_file]"
    echo "Enumerates subdomains for the target domain(s) or from a file and writes live URLs to a file."
    echo "Arguments:"
    echo "  <target_domain(s) | target_file>: Domain(s) to enumerate subdomains for or a file containing target URLs."
    echo "  [output_file]: Optional - Specify the output file. If not provided, the script will not create an output file."
}

# Checking if no arguments are provided or if the user requests help
if [ $# -eq 0 ] || [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    show_help
    exit 0
fi

# Parsing the arguments
output_file=${@: -1} # Last argument is the output file
targets=$1 # First argument is the target domain(s) or file

if [ -f "$targets" ]; then
    # If the input is a file, read target domains from the file
    target_domains=$(cat "$targets")
else
    # If the input is not a file, treat it as a list of target domains
    target_domains=$targets
fi

# Temporary file to store all subdomains
temp_file="temp.txt"

# Looping through each target domain provided
for domain in $target_domains; do
    echo "[-] Enumerating subdomains for $domain..."

    # Running subdomain enumeration tools
    echo "[+] Running subfinder for $domain..."
    subfinder -d "$domain" -pc /home/anonyomus/subfinderconfig.txt>> "$temp_file" 2>&1

    echo "[+] Running assetfinder for $domain..."
    assetfinder "$domain" >> "$temp_file" 2>&1

    echo "[+] Running sublist3r for $domain..."
    sublist3r --domain "$domain" >> "$temp_file" 2>&1

    echo "[+] Running findomain for $domain..."
    findomain -t "$domain" >> "$temp_file" 2>&1
done

# Combine all results and extract unique subdomains
echo "[-] Combining and extracting unique subdomains..."
sort -u "$temp_file" -o "$temp_file"

# Check for live URLs and write them to the output file
echo "[-] Checking live URLs and writing to $output_file..."
httprobe -c 80 < "$temp_file" >> "$output_file" || { echo "Error: Cannot write to $output_file"; exit 1; }

# Cleanup: Remove temporary file
rm "$temp_file"
