# vim: set ts=4 sw=4 et:

# This is an intent to tidy up the volatiles support in meta-runit derived
# systems.  It aims to simplify the script and make it a lot less noisy
# as the original was kind-of, sort-of needed and yet NOT so.  It was cribbed
# from out of Yocto's original noisy (..and NASTY...) sysvinit scripts- it was a
# make-do that went for entirely too long.    FCE (08-30-2023)

CONFIGS_DIR="/etc/default/volatiles"

# Call order : USER GROUP PERMS FILE (SOURCE)
create_file() {
    # Check to see if the name exists...if so, wipe it
    [ -e $4 ] && rm -rf $4

    # First, make or copy the content to it's location...copy when we have something other than, "none"
    # in the final column of the config...
	[ "$5" = "none" ] && touch '$4' || cp $5 $4
    [ $? -eq 0 ] || msg_error "Unable to create $1" && return

    # Now, set ownership and permissions accordingly...not a failure
    # per se, but needs to be flagged as warnings...
    chown $1:$2 $4 || msg_warn "$4 : unable to chown $1:$2"
    chmod $3 $1 || msg_warn "$4 : unable to chmod $3"
}

# Call order : USER GROUP PERMS DIR
make_dir() {
    # Check to see if the name exists...if so, wipe it.
    [ -e $4 ] && rm -rf $4

    # Attempt to make the directory...
    mkdir -p $4 || msg_error "Unable to mkdir $4" && return

    # Now, set ownership and permissions accordingly...not a failure
    # per se, but needs to be flagged as warnings...
    chown $1:$2 $4 || msg_warn "$4 : unable to chown $1:$2"
    chmod $3 $4 || msg_warn "$4 : unable to chmod $3"
}

# Call order : DEST SOURCE
do_symlink() {
    # Presume an -f for symlinks.  They are to be done as commanded
    # by the config files. ALWAYS.  Don't do anything fancy- it's not
    # needed.
    ln -sf $2 $1 || msg_error "Unable to link $2 to $1" && return
}

# Dogsbody for the config file processing.  Main loop of the script
# processes the directory for each config, which can be added by
# any recipe or .bbappend accordingly.
apply_config() {
    # Strip out comments...we allow shell-type comments in config files.  Process the
    # entries accordingly...
	cat $1 | sed 's/#*//' | while read TTYPE TUSER TGROUP TMODE TNAME TLTARGET; do
        # Consider JUST the first character of the TTYPE variable...if it even is in the
        # the line we're processing.  If nothing's there?  Skip it.
        if [ ! -z "$TTYPE" ]; then
            case "$TTYPE" in
                # File generation called for...
                f*) create_file $TUSER $TGROUP $TMODE $TNAME $TLTARGET
                    ;;

                # Directory generation called for...$TLTARGET is ignored here...
                d*) make_dir $TUSER $TGROUP $TMODE $TNAME
                    ;;

                # Generate a symlink...   Only $TNAME AND $TLTARGET matter...
                l*) do_symlink $TNAME $TLTARGET
                    ;;

                # Tattle to the user that someone did something we didn't support...
                *)  msg_warn "Invalid type ($TTYPE) provided for $TNAME, skipping."
                    ;;
            esac
        fi
        # If it doesn't have a type value, skip it.  Empty line read...no sense in
    done
}

# Quick check to see if this is even needed to run.  Need the /etc/default/volatiles
# directory present before we move on...
if [ -e $CONFIGS_DIR ] ; then
    msg "Found volatiles config directory, processing."
    for CONFIG_FILE in $CONFIGS_DIR/*; do
        apply_config $CONFIG_FILE
    done
fi
