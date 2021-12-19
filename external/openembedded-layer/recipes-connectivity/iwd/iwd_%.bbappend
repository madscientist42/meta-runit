# NOTE : This doesn't exist in meta or meta-openembedded right now!
#        (It's a WIP, but a cool one that should get there eventually)
#        So, if you don't have this in the layers, bitbake will 
#        complain about it.  Look for meta-pha or pull the recipe
#        for it and ELLout out and put it in your layer first...)

# Extend the search path to here first...
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# Add the services set(s)...
SRC_URI += " \
    file://sv/iwd/run \
    "

# Next, make it a runit capable package...
inherit runit

# And declare it to be auto-enabled as default...
RUNIT-SERVICES = "DEFAULT"
RUNIT_DEFAULT_MODS = "log"


