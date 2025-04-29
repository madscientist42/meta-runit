# if the feature is turned on for the Distro, we want to FORCE depenency to ensure
# "runit" gets packaged on the target image...
RDEPENDS_${PN} += "${@bb.utils.contains('DISTRO_FEATURES', 'runit', 'runit runit-base-services', '', d)}"

# Set up some default behaviors
RUNIT-SERVICES ??= ""
runit-svcdir = "/etc/sv"
runit-coresvcsdir = "/etc/runit/core-services"
runit-runsvdir = "/etc/runit/runsvdir"

# This class will be included in any recipe that supports runit services configs,
# even if runit is not in DISTRO_FEATURES.  As such don't make any changes
# directly but check the DISTRO_FEATURES first.
python __anonymous() {
    # If the distro features have runit but not sysvinit, inhibit update-rcd
    # from doing any work so that pure-runit based images don't have redundant init
    # files/links.
    if bb.utils.contains('DISTRO_FEATURES', 'runit', True, False, d):
        if not bb.utils.contains('DISTRO_FEATURES', 'sysvinit', True, False, d):
            d.setVar("INHIBIT_UPDATERCD_BBCLASS", "1")
}

# Services specs should be set up in the files under sv in the files directory
# and specfied at least as a directory (Preferably, each piece part in the
# tree to support devtool properly)
install_runit_services() {
    if [ -d ${WORKDIR}/core-services ] ; then
        # Ensure we have a proper core-services directory in the packaging...
        install -d ${D}${runit-coresvcsdir}
        for I in ${WORKDIR}/core-services/* ; do
            install -m 0755 $I ${D}/etc/runit/core-services
        done
    fi

    if [ -d ${WORKDIR}/sv ] ; then
        # Ensure we've got a proper services directory in the packaging...
        install -d ${D}${runit-svcdir}
        cp -rap --no-preserve=ownership ${WORKDIR}/sv/* ${D}${runit-svcdir}
        find ${D}${runit-svcdir} -name run -exec chmod u+x {} \; || true
        find ${D}${runit-svcdir} -name finish -exec chmod u+x {} \; || true
        find ${D}${runit-svcdir} -name check -exec chmod u+x {} \; || true
    fi
}
do_install[postfuncs] += "${@bb.utils.contains('DISTRO_FEATURES', 'runit', 'install_runit_services', '', d)} "

# One of the other things we need to do is if we've got a corresponding service in
# the services directory for ${PN}, then we need to nuke the sysvinit entries.
# because we have a service in place.  (We'll handle any init.d entries that are
# left in there, but as people add services for runit in recipes or as the overlays
# in this metadata layer, we want to remove them...)
#
# FIXME - This just blindly removes everything in the packaging for sysvinit and systemd stuff
#         For now, this is, "fine," but needs to be revisited with "better".
cleanup_sysvinit_dirs() {
    # We probably ought to go and check if there's an /etc here before doing this.
    #
    # Scripting presumes something not in evidence if you're building out something
    # that has none of this (/etc even in ${D} at this point...) and this will blow
    # up in your face...  Accounting for a fresh start without init/supervision.
    #
    # FCE (08/24/23)
    if [ -e ${D}/etc ] ; then
        rm -rf ${D}/etc/rc*.d
        dirlist=`find ${D}/etc/ -type d -name 'init.d' -print`
        for dir in $dirlist; do
            rm -rf $dir
        done
        dirlist=`find ${D}/etc/ -name '*.service' -print`
        for dir in $dirlist; do
            rm -rf $dir
        done
    fi
}
DO_SYSVINIT_CLEANUP = "${@bb.utils.contains('DISTRO_FEATURES', 'sysvinit', '', 'cleanup_sysvinit_dirs', d)}"
do_install[postfuncs] += "${@bb.utils.contains('DISTRO_FEATURES', 'runit', '${DO_SYSVINIT_CLEANUP}', '', d)} "

# Services can be enabled in one of two ways or left disabled per package.
#
# In the first way, if you specify "DEFAULT" in all caps in the RUNIT_SERVICES
# list, it will presume everything is to be put in the default runlevel instead
# of "once" runlevel part.
#
# In the second way, we process it in steps much like we do SERIAL_CONSOLES
# wherein you specify the service name to be enabled, followed by one or more
# optional parameters where you specify "once" for run-once at start and
# "log" to enable service specific logging from the redirected output of the
# daemon binary, with the options being separated by semicolons.
enable_default_services() {
    install -d ${D}${runit-runsvdir}
    install -d ${D}${runit-runsvdir}/default
    install -d ${D}${runit-runsvdir}/single

    # Figure out default modifiers.  Default presumes "default" so we don't
    # parse "single" right now (Doesn't make sense...)
    options=`echo "${RUNIT_DEFAULT_MODS}" | awk -F ";" '{ print $1 " " $2 " " $3 " " $4 }'`

    cd ${D}${runit-svcdir}
    for svc in * ; do
        # Catch situations where we don't have ANY files (* comes back for the globbing which is broken for this.)
        # Also catch out directories that don't have a run file specified.  We do not want to process
        # symlinks for content that is things like down files in with the main recipe and services files.
        if [ ! -d "$svc" -o ! -e "$svc/run"] ; then
            continue
        fi

        # Link the services in turn...
        svc="$(basename $svc)"
        ln -s ${runit-svcdir}/$svc ${D}${runit-runsvdir}/default

        for option in $options ; do
            case $option in
                log | log-no-ts )
                    # User has specified simple logging support for the service
                    # (Which, technically, can be done out of the sv dir, but
                    #  this lets a user specify it even simpler than that way...)
                    timestamping=""
                    logsv="${D}${runit-svcdir}/$svc/log"
                    # Check to see if there's already a log runit spec file there
                    # or not...
                    if [ ! -d $logsv ] ; then
                       # Nope.  Generate one for the user since they specified logging. Check to
                        # see if they have a logging config in the service run directory, symlink it
                        # into the logging directory if we're making it.  If they don't and we have
                        # a global /etc/defaults/svlogd.conf file, symlink THAT in.  Make sure the
                        # permissions allow for read by anyone and it'll just work
                        mkdir -p $logsv
                        logsv="$logsv/run"
                        echo "#!/bin/sh" > $logsv
                        echo "[ -e /etc/default/logging ] && source /etc/default/logging" >> $logsv
                        echo "[ -z \"\$BASE_LOGGING_DIR\" ] && BASE_LOGGING_DIR=\"/var/log\"" >> $logsv
                        echo "if [ ! -e \$BASE_LOGGING_DIR/$svc ] ; then" >> $logsv
                        echo "     mkdir -p \$BASE_LOGGING_DIR/$svc"  >> $logsv
                        echo "     if [ ! -e ${runit-svcdir}/$svc/svlogd.conf ]; then" >> $logsv
                        echo "          if [ -e /etc/default/svlogd.conf ] ; then" >> $logsv
                        echo "              ln -s /etc/default/svlogd.conf \$BASE_LOGGING_DIR/$svc/config" >> $logsv
                        echo "          fi" >> $logsv
                        echo "     else" >> $logsv
                        echo "          ln -s ${runit-svcdir}/$svc/svlogd.conf \$BASE_LOGGING_DIR/$svc/config" >> $logsv
                        echo "     fi" >> $logsv
                        echo "     chown -R log:log \$BASE_LOGGING_DIR/$svc" >> $logsv
                        echo "fi" >> $logsv
                        [ "$option" = "log" ] && timestamping="-tt"
                        echo "exec chpst -ulog svlogd $timestamping \$BASE_LOGGING_DIR/$svc" >> $logsv
                        chmod a+x $logsv
                    fi
                    # Config, if it exists in the /etc/defaults dir, is global unless overridden by the recipe
                    [ ! -e ${D}${runit-svcdir}/$svc/log/config ] && ln -s /etc/default/svlogd.conf ${D}${runit-svcdir}/$svc/log/config
                    ;;

                down | once )
                    touch ${D}${runit-svcdir}/$svc/$option
                    ;;
            esac
        done
    done
}

enable_services() {
    install -d ${D}${runit-runsvdir}
    install -d ${D}${runit-runsvdir}/single
    install -d ${D}${runit-runsvdir}/default

    # Do this off of what's listed...
    tmp="${RUNIT-SERVICES}"
    for entry in $tmp; do

        # First field is always the service, followed by up to three optional values
        svc=`echo "$entry" | awk -F ";" '{ print $1 }'`
        options=`echo "$entry" | awk -F ";" '{ print $2 " " $3 " " $4 " " $5 }'`

        # Figure out where to put things...  Can be single or default, enable simple logging
        # or specify an order prefix for the runsvdir entry...  You can specify a service
        # to be in either runlevel or both (Two entries... Unlikely, but we're leaving it
        # open for people...)
        linkpath="default"
        for option in $options ; do
            case $option in
                single | default )
                    linkpath="$option"
                    ;;

                log | log-no-ts )
                    # User has specified simple logging support for the service
                    # (Which, technically, can be done out of the sv dir, but
                    #  this lets a user specify it even simpler than that way...)
                    timestamping=""
                    logsv="${D}${runit-svcdir}/$svc/log"
                    # Check to see if there's already a log runit spec file there
                    # or not...
                    if [ ! -d $logsv ] ; then
                        # Nope.  Generate one for the user since they specified logging. Check to
                        # see if they have a logging config in the service run directory, symlink it
                        # into the logging directory if we're making it.  If they don't and we have
                        # a global /etc/defaults/svlogd.conf file, symlink THAT in.  Make sure the
                        # permissions allow for read by anyone and it'll just work
                        mkdir -p $logsv
                        logsv="$logsv/run"
                        echo "#!/bin/sh" > $logsv
                        echo "[ -e /etc/default/logging ] && source /etc/default/logging" >> $logsv
                        echo "[ -z \"\$BASE_LOGGING_DIR\" ] && BASE_LOGGING_DIR=\"/var/log\"" >> $logsv
                        echo "if [ ! -e \$BASE_LOGGING_DIR/$svc ] ; then" >> $logsv
                        echo "     mkdir -p \$BASE_LOGGING_DIR/$svc"  >> $logsv
                        echo "     if [ ! -e ${runit-svcdir}/$svc/svlogd.conf ]; then" >> $logsv
                        echo "          if [ -e /etc/default/svlogd.conf ] ; then" >> $logsv
                        echo "              ln -s /etc/default/svlogd.conf \$BASE_LOGGING_DIR/$svc/config" >> $logsv
                        echo "          fi" >> $logsv
                        echo "     else" >> $logsv
                        echo "          ln -s ${runit-svcdir}/$svc/svlogd.conf \$BASE_LOGGING_DIR/$svc/config" >> $logsv
                        echo "     fi" >> $logsv
                        echo "     chown -R log:log \$BASE_LOGGING_DIR/$svc" >> $logsv
                        echo "fi" >> $logsv
                        [ "$option" = "log" ] && timestamping="-tt"
                        echo "exec chpst -ulog svlogd $timestamping \$BASE_LOGGING_DIR/$svc" >> $logsv
                        chmod a+x $logsv
                    fi
                    ;;

                down | once )
                    touch ${D}${runit-svcdir}/$svc/$option
                    ;;
            esac
        done
        ln -s ${runit-svcdir}/$svc ${D}${runit-runsvdir}/$linkpath/$order$svc
    done
}
DO_DEFAULT_SVCS = "${@bb.utils.contains('RUNIT-SERVICES', 'DEFAULT', 'enable_default_services', 'enable_services', d)}"
do_install[postfuncs] += "${@bb.utils.contains('DISTRO_FEATURES', 'runit', '${DO_DEFAULT_SVCS}', '', d)} "
