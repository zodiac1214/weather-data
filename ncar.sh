#!/bin/bash

# Get current script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Input parameters
start_date_str=$1  # Start date in YYYYMMDD format
num_days=${2:-1}   # Number of days to process (default is 1)

if [ -z "$start_date_str" ]; then
    echo "Usage: $0 <start_date_YYYYMMDD> [<num_days>]"
    exit 1
fi

# Function to calculate date offsets
get_date() {
    local base_date=$1
    local offset=$2
    date -u -d "$base_date +$offset days" +"%Y%m%d"
}

mkdir -p output

for (( i=0; i<num_days; i++ ))
do
    date_str=$(get_date "$start_date_str" "$i")
    echo "Processing date: $date_str"

    # Get year, month, day
    year=${date_str:0:4}
    month=${date_str:4:2}
    day=${date_str:6:2}

    # Remove any existing temporary GRIB2 files
    rm -f output/gfs.0p25.${date_str}*.grib2

    # Download data for 00, 06, 12, 18 UTC
    for hour in 00 06 12 18
    do
        # Skip if snow data already exists
        curl -s https://api.github.com/repos/zodiac1214/weather-data/releases/latest | grep "gfs.0p25.${date_str}${hour}.f006.grib2" > /dev/null
        if [ $? -eq 0 ]; then
            echo "Skipping ${date_str}${hour}"
            continue
        fi
        
        url="https://data.rda.ucar.edu/d084001/${year}/${year}${month}${day}/gfs.0p25.${date_str}${hour}.f006.grib2"
        output_file="gfs.0p25.${date_str}${hour}.f006.grib2"
        echo "Downloading ${url}"
        curl -s -o "${output_file}" "${url}"

        # Check if download was successful
        if [ ! -s "${output_file}" ]; then
            echo "Failed to download ${url}"
            continue
        fi

        # Extract SNOD variable
        ${SCRIPT_DIR}/bin/linux-wgrib2 "${output_file}" -match_fs "SNOD" -grib "output/gfs.0p25.${date_str}${hour}.f006.grib2"
    done
done
