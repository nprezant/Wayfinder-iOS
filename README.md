# Wayfinder

Make your best way forward.

### Developer Notes

Copying files to simulator devices:
Make a folder in the "On My iPhone" folder in the Files app. Give it a descriptive, unique name.

Run this command in the terminal to find that folder's location:

```console
find /Users/noah/Library/Developer/CoreSimulator/Devices/ -name "8Plus"
```

In Zsh can cd directly:

```console
cd "$(find /Users/noah/Library/Developer/CoreSimulator/Devices/ -name "8Plus")"
open .
```

Now copy files to and from that folder as usual and they'll show up in the simulator.
