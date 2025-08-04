#!/bin/bash

# Function to clean up file paths and remove surrounding quotes
sanitize_path() {
    echo "$1" | sed -e 's/^["'\''"]//;s/["'\''"]$//'
}

# Function to select a file using zenity within a folder with specific extension
zenity_select_file_from_dir() {
    local ext="$1"
    local title="$2"
    local folder="$3"
    local result_var="$4"
    local exclude_pattern="$5"

    if [[ ! -d "$folder" ]]; then
        echo "Directory $folder does not exist."
        return 1
    fi

    local find_cmd
    if [[ -n "$exclude_pattern" ]]; then
        find_cmd=(find "$folder" -maxdepth 1 -type f -iname "*.$ext" ! -iname "*$exclude_pattern*")
    else
        find_cmd=(find "$folder" -maxdepth 1 -type f -iname "*.$ext")
    fi

    mapfile -t files < <("${find_cmd[@]}" | sort)

    if [ ${#files[@]} -eq 0 ]; then
        echo "No .$ext files found in $folder."
        return 1
    fi

    local selection
    selection=$(zenity --list \
        --title="$title" \
        --column="Filename" \
        "${files[@]}")

    if [[ -z "$selection" || ! -f "$selection" ]]; then
        echo "No file selected or file not found."
        return 1
    fi

    printf -v "$result_var" '%s' "$(realpath "$selection")"
    return 0
}

# Function to select IPSW from anywhere using zenity
zenity_select_ipsw_file() {
    local file
    file=$(zenity --file-selection --title="Select IPSW file for downgrade" --file-filter="*.ipsw")
    if [[ -z "$file" || ! -f "$file" ]]; then
        echo "No IPSW file selected or file not found."
        return 1
    fi
    IPSW=$(realpath "$file")
    return 0
}

# Prompt for sudo upfront and cache credentials
if ! sudo -v; then
    echo "Sudo authentication failed. Exiting."
    exit 1
fi

# Keep sudo timestamp alive until script exits
( while true; do sudo -n true; sleep 60; done ) 2>/dev/null &
SUDO_KEEP_ALIVE_PID=$!

# Ensure background sudo keep-alive is killed when script exits
trap 'kill $SUDO_KEEP_ALIVE_PID 2>/dev/null' EXIT

# Anti-Tamper Version Check
EXPECTED_VERSION="1.0"
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
    echo "Congratulations! pwnerblu UI is now updated to version $EXPECTED_VERSION"
    echo "Cleaning up temporary update files..."
    rm -rf temporary
    echo "Cleanup complete. Please run the script again to use it."
    exit 0
fi

# Update Checker
echo "Checking for updates..."
rm -f corefiles/server-version.txt
curl -L -o corefiles/server-version.txt https://raw.githubusercontent.com/pwnerblu/pwnerblu-UI/refs/heads/main/corefiles/server-version.txt

VERSION_FILE="corefiles/server-version.txt"
if [[ ! -f "$VERSION_FILE" ]]; then
    echo "Update check failed: could not fetch version data."
    echo "This script will not run until it's checked for updates."
    exit 0
fi

ACTUAL_VERSION=$(<"$VERSION_FILE" | tr -d '\r\n')

version_gt() {
    [[ "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" != "$1" ]]
}

if version_gt "$ACTUAL_VERSION" "$EXPECTED_VERSION"; then
    echo "A newer version is available: $ACTUAL_VERSION"
    read -p "Would you like to update to the latest version? (y/n): " update_confirm
    if [[ "$update_confirm" =~ ^[Yy]$ ]]; then
        echo "Downloading the update files for version $ACTUAL_VERSION..."
        mkdir temporary
        curl -L -o temporary/pwnerblu-UI.sh https://raw.githubusercontent.com/pwnerblu/pwnerblu-UI/refs/heads/main/pwnerblu-UI.sh
        curl -L -o temporary/pwnerblu-UI-version.txt https://raw.githubusercontent.com/pwnerblu/pwnerblu-UI/refs/heads/main/corefiles/pwnerblu-UI-version.txt
        curl -L -o temporary/update.sh https://raw.githubusercontent.com/pwnerblu/pwnerblu-UI/refs/heads/main/corefiles/update.sh
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

# Check for turdus merula binaries
echo "Checking if the turdus merula binary exists..."

if [[ -f "./ra1n_libusb" && -f "./idevicerestore" ]]; then
    echo "Found turdus merula binaries."
    chmod +x ra1n_libusb
    chmod +x idevicerestore
else
    echo "Missing turdus merula binaries (ra1n_libusb and/or idevicerestore)."
    echo "Downloading turdus merula..."
    curl -L -o turdus_merula_v1.0.1-1_linux.tar https://sep.lol/files/releases/test/v1.0.1-linux/turdus_merula_v1.0.1-1_linux.tar
    tar -xf turdus_merula_v1.0.1-1_linux.tar
    rm -rf turdus_merula_v1.0.1-1_linux.tar
    cp -f turdus_merula_v1.0.1-1_linux/* .
    rm -rf turdus_merula_v1.0.1-1_linux
    chmod +x ra1n_libusb
    chmod +x idevicerestore
fi

# Dependency check
echo "Checking for required dependencies..."

DEPENDENCIES=(libusb-1.0-0-dev libusbmuxd-tools libimobiledevice-utils usbmuxd libimobiledevice6 zenity)
MISSING_PACKAGES=()

for pkg in "${DEPENDENCIES[@]}"; do
    if ! dpkg -s "$pkg" &>/dev/null; then
        MISSING_PACKAGES+=("$pkg")
    fi
done

if [ ${#MISSING_PACKAGES[@]} -ne 0 ]; then
    echo "Missing packages detected: ${MISSING_PACKAGES[*]}"
    echo "Installing missing dependencies..."
    sudo apt update
    sudo apt install -y "${MISSING_PACKAGES[@]}"
else
    echo "All dependencies are installed."
fi


# Welcome Message
echo "pwnerblu UI - v1.0"
echo "This is a user interface to make turdus merula easier to use."
echo "Supports every device that can be downgraded with turdus merula. (A9/A10)"
echo "By pwnerblu (not affiliated with turdus merula developers)."
echo "Uses test build: turdus_merula_v1.0.1-1_linux"

# Device Selection
echo ""
echo "What device do you have?"
echo "If you are downgrading to iOS 10 on an A10 device, the baseband and SEP will be incompatible."
echo "The baseband warning may be ignored if you have an iPod Touch or a Wi-Fi only iPad."
echo "1) A10 (iPhone 7 and 7 Plus, iPad 6 and 7, iPod Touch 7th Generation)"
echo "2) A9 (iPhone 6s and 6s Plus, iPhone SE 1st Generation, iPad 5th Generation)"
echo "3) Other devices (limited support)"
read -p "Enter choice [1-3]: " device_choice

case $device_choice in
    1) DEVICE_TYPE="A10" ;;
    2) DEVICE_TYPE="A9" ;;
    3) DEVICE_TYPE="Other" ;;
    *) echo "Invalid selection. Exiting."; exit 1 ;;
esac

# Main Menu Loop
while true; do
    echo ""
    echo "Main Menu:"
    echo "1) Restore to the latest iOS"

    if [[ "$DEVICE_TYPE" == "A10" ]]; then
        echo "2) Boot Tethered"
        echo "3) Downgrade Tethered"
        echo "4) Enter pwnDFU mode"
        echo "5) Downgrade Untethered (with SHSH blobs)"
    elif [[ "$DEVICE_TYPE" == "A9" ]]; then
        echo "2) Boot Tethered"
        echo "3) Downgrade Tethered"
        echo "4) Enter pwnDFU mode"
        echo "5) Downgrade Untethered (with SHSH blobs)"
    else
        echo "Do not select 2 to 5."
    fi

    echo "6) Exit"
    read -p "Enter choice [1-6]: " choice

    case $choice in
        1)
            read -p "Would you like to do an update (type N then press enter if you want an erase instead)? (y/n): " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                sudo ./idevicerestore -l 
            else
                sudo ./idevicerestore -l -e 
            fi
            ;;
        2)
            if [[ "$DEVICE_TYPE" == "A10" ]]; then

                if ! zenity_select_file_from_dir "im4p" "Select target SEP (.im4p)" "./image4" targetSEP; then continue; fi
                if ! zenity_select_file_from_dir "img4" "Select iBoot (.img4, excludes SEP)" "./image4" iBoot "SEP"; then continue; fi
                if ! zenity_select_file_from_dir "img4" "Select signed SEP (.img4, excludes iBoot)" "./image4" signedSEP "iBoot"; then continue; fi

                echo ""
                echo "Running Boot Tethered with:"
                echo "Target SEP: $targetSEP"
                echo "iBoot: $iBoot"
                echo "Signed SEP: $signedSEP"

                read -p "Is your device in DFU mode? (y/n): " confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    sudo ./ra1n_libusb -t "$iBoot" -i "$signedSEP" -p "$targetSEP"
                    echo "Boot process complete. If it hangs at boot, hard reset the device, enter DFU mode, then re-attempt Boot Tethered."
                else
                    echo "Please put device into DFU mode and try again."
                fi

            elif [[ "$DEVICE_TYPE" == "A9" ]]; then

                # Enforced PTEBlock selection from ./blocks dir, only matching *pteblock*.bin
                mapfile -t PTEBLOCK_FILES < <(find ./blocks -maxdepth 1 -type f -iname "*pteblock*.bin" | sort)

                if [[ ${#PTEBLOCK_FILES[@]} -eq 0 ]]; then
                    echo "No matching PTEBlock files found in ./blocks"
                    continue
                fi

                PTEBLOCK=$(zenity --list \
                    --title="Select PTEBlock file (*pteblock*.bin)" \
                    --column="Filename" \
                    "${PTEBLOCK_FILES[@]}")

                if [[ -z "$PTEBLOCK" || ! -f "$PTEBLOCK" ]]; then
                    echo "Invalid or no PTEBlock selected."
                    continue
                fi

                PTEBLOCK_PATH=$(realpath "$PTEBLOCK")
                echo ""
                echo "Running Boot Tethered with:"
                echo "PTEBlock: $PTEBLOCK_PATH"

                read -p "Is your device in DFU mode? (y/n): " confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    sudo ./ra1n_libusb -TP "$PTEBLOCK_PATH"
                    echo "Boot process complete. If it hangs at boot, hard reset the device, enter DFU mode, then re-attempt Boot Tethered."
                else
                    echo "Please put device into DFU mode and try again."
                fi

            else
                echo "Boot Tethered is not available for this device type: $DEVICE_TYPE"
            fi
            ;;
        3)
            if [[ "$DEVICE_TYPE" == "A10" ]]; then
                if ! zenity_select_ipsw_file; then continue; fi

                echo "Downgrade Tethered with IPSW: $IPSW"
                read -p "Is your device in pwnDFU mode? (y/n): " confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    sudo ./idevicerestore -o "$IPSW"
                else
                    sudo ./ra1n_libusb -ED
                    sudo ./idevicerestore -o "$IPSW"
                fi

                echo "Downgrade finished. Use Boot Tethered to boot your device."

            elif [[ "$DEVICE_TYPE" == "A9" ]]; then
                if ! zenity_select_ipsw_file; then continue; fi

                echo "Selected IPSW: $IPSW"

                IPSW_VERSION=$(basename "$IPSW" | grep -oE '[^0-9][0-9]{1,2}\.[0-9]+(\.[0-9]+)?' | grep -oE '[0-9]{1,2}\.[0-9]+(\.[0-9]+)?' | awk -F. '$1 >= 9' | head -n1)
                if [[ -z "$IPSW_VERSION" ]]; then
                    echo "Unable to detect iOS version from IPSW filename (must be 9.0 or higher)."
                    read -p "Please enter the iOS version manually (e.g. 12.0): " IPSW_VERSION
                    if [[ ! "$IPSW_VERSION" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
                        echo "Invalid version format. Exiting."
                        continue
                    fi
                fi
                echo "Detected iOS version: $IPSW_VERSION"

                read -p "Is your device in DFU mode? (y/n): " confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    echo "Entering pwnDFU..."
                    sudo ./ra1n_libusb -ED
                    sleep 2
                    echo "Getting SHCBlock..."
                    sudo ./idevicerestore --get-shcblock "$IPSW"
                else
                    echo "Please enter DFU mode and try again."
                    continue
                fi

                mapfile -t SHCBLOCK_FILES < <(find ./blocks -type f -iname "*shcblock*${IPSW_VERSION}*.bin" | sort)
                if [[ ${#SHCBLOCK_FILES[@]} -eq 0 ]]; then
                    echo "No matching SHCBlock files found for iOS $IPSW_VERSION"
                    continue
                fi
                SHCBLOCK=$(zenity --list --title="Select SHCBlock for iOS $IPSW_VERSION" --column="File" "${SHCBLOCK_FILES[@]}")
                if [[ -z "$SHCBLOCK" || ! -f "$SHCBLOCK" ]]; then
                    echo "Invalid or no SHCBlock selected."
                    continue
                fi
                echo "Selected SHCBlock: $SHCBLOCK"

                read -p "Is your device in DFU mode? (y/n): " confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    echo "Entering pwnDFU..."
                    sudo ./ra1n_libusb -ED
                    sleep 2
                    echo "Getting PTEBlock..."
                    sudo ./idevicerestore --get-pteblock --load-shcblock "$SHCBLOCK" "$IPSW"
                else
                    echo "Please enter DFU mode and try again."
                    continue
                fi

                mapfile -t PTEBLOCK_FILES < <(find ./blocks -type f -iname "*pteblock*${IPSW_VERSION}*.bin" | sort)
                if [[ ${#PTEBLOCK_FILES[@]} -eq 0 ]]; then
                    echo "No matching PTEBlock files found for iOS $IPSW_VERSION"
                    continue
                fi
                PTEBLOCK=$(zenity --list --title="Select PTEBlock for iOS $IPSW_VERSION" --column="File" "${PTEBLOCK_FILES[@]}")
                if [[ -z "$PTEBLOCK" || ! -f "$PTEBLOCK" ]]; then
                    echo "Invalid or no PTEBlock selected."
                    continue
                fi
                echo "Selected PTEBlock: $PTEBLOCK"

                read -p "Is your device in DFU mode? (y/n): " confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    echo "Entering pwnDFU..."
                    sudo ./ra1n_libusb -ED
                    sleep 2
                    echo "Starting downgrade..."
                    sudo ./idevicerestore -o --load-pteblock "$PTEBLOCK" "$IPSW"
                    sleep 2
                else
                    echo "Please enter DFU mode and try again."
                    continue
                fi

                echo "Downgrade finished! Use Boot Tethered to boot your device."

            else
                echo "Tethered downgrade not supported on this device type."
            fi
            ;;


        4)
            if [[ "$DEVICE_TYPE" == "Other" ]]; then echo "Not available."; continue; fi
            read -p "Is your device in DFU mode? (y/n): " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                sudo ./ra1n_libusb -ED
            else
                echo "Put device into DFU mode and try again."
            fi
            ;;
        5)
            if [[ "$DEVICE_TYPE" != "A10" && "$DEVICE_TYPE" != "A9" ]]; then
                echo "Not supported on this device."
                continue
            fi

            if ! command -v zenity &>/dev/null; then
                echo "Zenity is required. Please install it."
                continue
            fi

            SHSH_PATH=$(zenity --file-selection --title="Select SHSH blob" --file-filter="*.shsh *.shsh2")
            if [[ -z "$SHSH_PATH" || ! -f "$SHSH_PATH" ]]; then
                echo "Invalid SHSH."
                continue
            fi

            echo "Selected SHSH: $SHSH_PATH"
            GENERATOR=$(grep -A 1 "generator" "$SHSH_PATH" | grep -o '0x[a-fA-F0-9]\+')
            if [[ -z "$GENERATOR" ]]; then
                echo "Failed to extract generator."
                continue
            fi
            echo "Found generator: $GENERATOR"

            if ! zenity_select_ipsw_file; then continue; fi
            echo "Selected IPSW: $IPSW"

            if [[ "$DEVICE_TYPE" == "A10" ]]; then
                echo "Downgrading with SHSH and IPSW for A10..."
                read -p "Is your device in DFU mode? (y/n): " confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    sudo ./ra1n_libusb -EDb "$GENERATOR"
                    sudo ./idevicerestore -w --load-shsh "$SHSH_PATH" "$IPSW"
                    echo "Restore complete. Your device should boot."
                    exit 0
                else
                    echo "Please enter DFU mode and try again."
                fi

            elif [[ "$DEVICE_TYPE" == "A9" ]]; then
                echo "Downgrading with SHSH and IPSW for A9..."
                read -p "Is your device in DFU mode? (y/n): " confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    sudo ./ra1n_libusb -ED
                    sudo ./idevicerestore --get-shcblock "$IPSW"
                else
                    echo "Please enter DFU mode and try again."
                    continue
                fi

                # Prompt for SHCBlock
                IPSW_VERSION=$(basename "$IPSW" | grep -oE '[^0-9][0-9]{1,2}\.[0-9]+(\.[0-9]+)?' | grep -oE '[0-9]{1,2}\.[0-9]+(\.[0-9]+)?' | awk -F. '$1 >= 9' | head -n1)
                if [[ -z "$IPSW_VERSION" ]]; then
                    read -p "Unable to auto-detect iOS version. Enter manually (e.g. 12.3): " IPSW_VERSION
                fi

                mapfile -t SHCBLOCK_FILES < <(find ./blocks -type f -iname "*shcblock*${IPSW_VERSION}*.bin" | sort)
                if [[ ${#SHCBLOCK_FILES[@]} -eq 0 ]]; then
                    echo "No SHCBlock files found for iOS $IPSW_VERSION"
                    continue
                fi

                SHCBLOCK=$(zenity --list \
                    --title="Select SHCBlock for iOS $IPSW_VERSION" \
                    --column="File" \
                    "${SHCBLOCK_FILES[@]}")

                if [[ -z "$SHCBLOCK" || ! -f "$SHCBLOCK" ]]; then
                    echo "Invalid or no SHCBlock selected."
                    continue
                fi

                echo "Selected SHCBlock: $SHCBLOCK"
                read -p "Is your device in DFU mode again? (y/n): " confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    sudo ./ra1n_libusb -EDb "$GENERATOR"
                    sleep 1
                    echo "Starting downgrade..."
                    sudo ./idevicerestore -w --load-shsh "$SHSH_PATH" --load-shcblock "$SHCBLOCK" "$IPSW"
                    echo "Restore complete. Your device should boot."
                    exit 0
                else
                    echo "Please enter DFU mode and try again."
                fi
            fi
            ;;

        6)
            echo "Goodbye!"
            exit 0
            ;;
        *)
            echo "Invalid choice."
            ;;
    esac
done
