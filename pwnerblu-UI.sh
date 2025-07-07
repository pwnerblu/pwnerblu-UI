#!/bin/bash

# Function to clean up file paths and remove surrounding quotes
sanitize_path() {
    echo "$1" | sed -e 's/^["'\''"]//;s/["'\''"]$//'
}

# Prompt for sudo password
read -s -p "Enter your password to continue: " user_pass
echo
echo "$user_pass" | sudo -S true 2>/dev/null

if [ $? -ne 0 ]; then
    echo "Authentication failed. Exiting."
    exit 1
fi

# Welcome Message
echo "pwnerblu UI - beta v0.6"
echo "This is a user interface to make turdus merula easier to use."
echo "This script is for A10 devices as of right now. A9/A9X support is not in this script yet."
echo "This script is by pwnerblu."
echo "NOTE: I did not originally create turdus merula, nor am I affiliated with the developers of turdus merula."
echo "This works on the test build of turdus merula (turdus_merula_v1.0.1-1_linux) for Linux."
echo "If there is any issue with this script, please let me know."

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
            echo "Select target SEP file..."
            read -e -p "Path to target SEP: " targetSEP
            targetSEP=$(sanitize_path "$targetSEP")
            targetSEP=$(realpath "$targetSEP" 2>/dev/null)

            echo "Select iBoot file..."
            read -e -p "Path to iBoot: " iBoot
            iBoot=$(sanitize_path "$iBoot")
            iBoot=$(realpath "$iBoot" 2>/dev/null)

            echo "Select signed SEP file..."
            read -e -p "Path to signed SEP: " signedSEP
            signedSEP=$(sanitize_path "$signedSEP")
            signedSEP=$(realpath "$signedSEP" 2>/dev/null)

            # Confirm existence of files
            for file in "$targetSEP" "$iBoot" "$signedSEP"; do
                if [ ! -f "$file" ]; then
                    echo "Error: File not found — $file"
                    continue 2
                fi
            done

            echo "Running Boot Tethered with:"
            echo "Target SEP: $targetSEP"
            echo "iBoot: $iBoot"
            echo "Signed SEP: $signedSEP"

            read -p "Is your device already in DFU mode? (y/n): " confirm
            if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                sudo ./ra1n_libusb -t "$iBoot" -i "$signedSEP" -p "$targetSEP"
                echo "Your device should now finish booting."
            else
                echo "Please put your device into DFU mode and try again."
            fi
            ;;

        2)
            echo "Select IPSW file for downgrade..."
            read -e -p "Path to target IPSW: " IPSW
            IPSW=$(sanitize_path "$IPSW")
            IPSW=$(realpath "$IPSW" 2>/dev/null)

            if [ ! -f "$IPSW" ]; then
                echo "Error: IPSW file not found — $IPSW"
                continue
            fi

            echo "Running Downgrade Tethered with:"
            echo "IPSW: $IPSW"

            read -p "Is your device already in pwnDFU mode? (y/n): " confirm
            if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                sudo ./idevicerestore -o "$IPSW"
                echo "Downgrade Finished! Your device will now boot to recovery mode. Put your device into DFU mode and then use the Boot Tethered option."
                echo "Every time your device reboots or shuts down, you have to put your device into DFU mode and use Boot Tethered to boot it up again."
            else
                sudo ./ra1n_libusb -ED
                sudo ./idevicerestore -o "$IPSW"
                echo "Downgrade Finished! Your device will now boot to recovery mode. Put your device into DFU mode and then use the Boot Tethered option."
                echo "Every time your device reboots or shuts down, you have to put your device into DFU mode and use Boot Tethered to boot it up again."
            fi
            ;;

        3)
            read -p "Is your device already in DFU mode? (y/n): " confirm
            if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
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

