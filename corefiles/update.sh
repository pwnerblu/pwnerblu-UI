echo "pwnerblu UI is updating..."
echo "Do not close the terminal until the update completes."
sleep 2
cd ..
cp -f temporary/pwnerblu-UI.sh .
cp -f temporary/pwnerblu-UI-version.txt corefiles/
chmod +x pwnerblu-UI.sh
./pwnerblu-UI.sh -cleanup
exit 0
