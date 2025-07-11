pwnerblu UI is a text-based user interface designed to run with turdus merula's Linux build.
It is meant to make turdus merula easier to use. I'm not affiliated, sponsored, or endorsed by the original developers of turdus merula.
I also didn't create Turdus Merula originally.
As of now, update functionality has been implemented into this script. This is to ensure people are always on the latest version of pwnerblu-UI.

To install this UI, make sure you have turdus merula's linux build on your PC. This interface will not work fully without turdus merula.
After downloading the UI, drag "pwnerblu-UI.sh" to the turdus merula Linux folder (turdus_merula_v1.0.1-1_linux).

There is currently support for A10 devices with this UI. A9 support isn't guaranteed with this interface yet (although turdus merula does support A9/A10).
This is a BETA. Please report any bugs you may have or any polishing suggestions.
Link to download turdus merula's Linux build (this is required for this UI to work): https://sep.lol/files/releases/test/v1.0.1-linux/turdus_merula_v1.0.1-1_linux.tar

You only have to use the link if you haven't downloaded the Linux version of turdus merula already.
The pwnerblu UI doesn't give you the option to do untethered downgrades yet. Currently, it only does tethered downgrades.

How to launch the UI? Go to the turdus merula folder (that's where you should put the script at), and then type this command:

When launching for the first time, run:
chmod +x pwnerblu-UI.sh
./pwnerblu-UI.sh

When it asks for your password, type it in.

This does not mean turdus merula itself is limited to untethered downgrades.
It simply means that this UI script doesn't expose untethered options (yet).

Updates as of v0.8:

Makes file selection easier for IPSW, SEP, iBoot, and signed SEP. 
You do not have to drag the file into the terminal no more.

The IPSW must be in the turdus merula folder for the script to detect it.
If there is any issues with this script, please let me know ASAP.

Feel free to fork this repository and contribute to improvements for the interface script!
If you fork this repository, do NOT include the full turdus merula project or its files in your fork. Only the pwnerblu UI.
Instead, always redirect users to the official turdus merula website for downloading Turdus Merula.
