#!/bin/bash

# Function to clean up file paths and remove surrounding quotes
sanitize_path() {
    echo "$1" | sed -e 's/^["'\''"]//;s/["'\''"]$//'
}

# Function to select a file from a folder with specific extension and optional exclusion pattern
select_file_from_dir() {
    local ext="$1"
    local prompt="$2"
    local result_var="$3"
    local exclude_pattern="$4"

    if [[ -n "$exclude_pattern" ]]; then
        mapfile -t files < <(find "./image4" -maxdepth 1 -type f -name "*.$ext" ! -iname "*$exclude_pattern*" | sort)
    else
        mapfile -t files < <(find "./image4" -maxdepth 1 -type f -name "*.$ext" | sort)
    fi

    if [ ${#files[@]} -eq 0 ]; then
        echo "No .$ext files found in ./image4/ matching criteria."
        return 1
    fi

    echo "$prompt"
    select file in "${files[@]}"; do
        if [[ -n "$file" ]]; then
            full_path=$(realpath "$file")
            printf -v "$result_var" '%s' "$full_path"
            break
        else
            echo "Invalid selection. Try again."
        fi
    done
    return 0
}

# Function to select IPSW from script directory
select_ipsw_file() {
    mapfile -t ipsw_files < <(find . -maxdepth 1 -type f -iname "*.ipsw" | sort)
    if [ ${#ipsw_files[@]} -eq 0 ]; then
        echo "No IPSW files found in this directory. Returning to main menu..."
        return 1
    fi

    echo "Select IPSW file for downgrade:"
    select ipsw in "${ipsw_files[@]}"; do
        if [[ -n "$ipsw" ]]; then
            IPSW=$(basename "$ipsw")
            return 0
        else
            echo "Invalid selection. Try again."
        fi
    done
}

# Prompt for sudo password
read -s -p "Enter your password to continue: " user_pass
echo
echo "$user_pass" | sudo -S true 2>/dev/null

if [ $? -ne 0 ]; then
    echo "Authentication failed. Exiting."
    exit 1
fi

# Anti-Tamper Version Check
EXPECTED_VERSION="0.8.5"
VERSION_FILE="corefiles/pwnerblu-UI-version.txt"

if [[ ! -f "$VERSION_FILE" ]]; then
    echo "Version file missing. This script will not run."
    exit 1
fi

ACTUAL_VERSION=$(<"$VERSION_FILE")

if [[ "$ACTUAL_VERSION" != "$EXPECTED_VERSION" ]]; then
    echo "Tampering has been detected. This script will not run."
    echo "Expected version: $EXPECTED_VERSION"
    echo "Found version: $ACTUAL_VERSION"
    exit 1
fi

if [[ "$1" == "-cleanup" ]]; then
    echo "Congratulations! pwnerblu UI is now updated to version 0.8.5"
    echo "Cleaning up temporary update files..."
    rm -rf temporary
    echo "Cleanup complete. Please run the script again to use it."
    exit 0
fi

# Update Checker
EXPECTED_VERSION="0.8.5"
VERSION_FILE="corefiles/server-version.txt"

# Placeholder: Download the latest version file (simulated or real)
echo "Checking for updates..."
rm -f corefiles/server-version.txt
curl -L -o corefiles/server-version.txt https://raw.githubusercontent.com/pwnerblu/pwnerblu-UI/refs/heads/main/corefiles/server-version.txt

if [[ ! -f "$VERSION_FILE" ]]; then
    echo "Update check failed: could not fetch version data."
    echo "This script will not run until it's checked for updates."
    exit 0
fi

ACTUAL_VERSION=$(<"$VERSION_FILE")
ACTUAL_VERSION=$(echo "$ACTUAL_VERSION" | tr -d '\r\n')  # Clean input

# Version comparison function
version_gt() { 
    [[ "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" != "$1" ]]
}

if version_gt "$ACTUAL_VERSION" "$EXPECTED_VERSION"; then
    echo "A newer version is available: $ACTUAL_VERSION"
    read -p "Would you like to update to the latest version? (y/n): " update_confirm

    if [[ "$update_confirm" =~ ^[Yy]$ ]]; then
        echo "Downlading the update files for version $ACTUAL_VERSION..."
        mkdir temporary
        curl -L -o temporary/pwnerblu-UI.sh https://raw.githubusercontent.com/pwnerblu/pwnerblu-UI/refs/heads/main/pwnerblu-UI.sh
        curl -L -o temporary/pwnerblu-UI-version.txt https://raw.githubusercontent.com/pwnerblu/pwnerblu-UI/refs/heads/main/corefiles/pwnerblu-UI-version.txt
        curl -L -o temporary/update.sh https://download1078.mediafire.com/c13x6u78ehwgJZIfRQ8EjXYV0_8jTADaRv6skO4NPqHYnQKJTOV_h7enot11T8gLc4IG-Ou2HLxJM9CkHdmSYGWqWX6WedOpXYqRP_lib6i3m5p_nK7Ihtwr4hEutZD1pwOs6uYZr_6Jo09mWio0L-0Nz_LsnDb5hm5CGVRApRFP/8wlngaukhwx7pcn/update.sh
        echo "Download complete. Starting the update to version $ACTUAL_VERSION"
        cd temporary
        chmod +x update.sh
        sudo ./update.sh
        exit 0
    else
        echo "Update declined. Exiting..."
        exit 1
    fi
else
    echo "pwnerblu UI is up to date."
fi




# Welcome Message
echo "pwnerblu UI - beta v0.8.5"
echo "This is a user interface to make turdus merula easier to use."
echo "Currently supports A10 devices only."
echo "By pwnerblu (not affiliated with turdus merula developers)."
echo "Uses test build: turdus_merula_v1.0.1-1_linux"

# Main Menu Loop
while true; do
    echo ""
    echo "Select an option:"
    echo "1) Boot Tethered"
    echo "2) Downgrade Tethered"
    echo "3) Enter pwnDFU mode"
    echo "4) Exit"
    read -p "Enter choice [1-4]: " choice

    case $choice in
        1)
            if ! select_file_from_dir "im4p" "Select target SEP file (.im4p):" targetSEP; then continue; fi
            if ! select_file_from_dir "img4" "Select iBoot file (.img4, excludes SEP):" iBoot "SEP"; then continue; fi
            if ! select_file_from_dir "img4" "Select signed SEP file (.img4, excludes iBoot):" signedSEP "iBoot"; then continue; fi

            # Confirm existence
            for file in "$targetSEP" "$iBoot" "$signedSEP"; do
                if [ ! -f "$file" ]; then
                    echo "Error: File not found — $file"
                    continue 2
                fi
            done

            echo ""
            echo "Running Boot Tethered with:"
            echo "Target SEP: $targetSEP"
            echo "iBoot: $iBoot"
            echo "Signed SEP: $signedSEP"

            read -p "Is your device already in DFU mode? (y/n): " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                sudo ./ra1n_libusb -t "$iBoot" -i "$signedSEP" -p "$targetSEP"
                echo "Your device should now finish booting."
            else
                echo "Please put your device into DFU mode and try again."
            fi
            ;;

        2)
            if ! select_ipsw_file; then continue; fi

            echo ""
            echo "Running Downgrade Tethered with:"
            echo "IPSW: $IPSW"

            read -p "Is your device already in pwnDFU mode? (y/n): " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                sudo ./idevicerestore -o "$IPSW"
            else
                sudo ./ra1n_libusb -ED
                sudo ./idevicerestore -o "$IPSW"
            fi

            echo ""
            echo "Downgrade finished!"
            echo "Your device will now boot to recovery mode."
            echo "Put your device into DFU mode and use the Boot Tethered option."
            echo "NOTE: Every time your device reboots or shuts down, you'll need to repeat Boot Tethered."
            ;;

        3)
            read -p "Is your device already in DFU mode? (y/n): " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                sudo ./ra1n_libusb -ED
            else
                echo "Please put your device into DFU mode and try again."
            fi
            ;;

        4)
            echo "Exiting. Goodbye!"
            exit 0
            ;;

        *)
            echo "Invalid choice. Please select from 1 to 4."
            ;;
    esac
done
