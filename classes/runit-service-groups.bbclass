
# Inherit runit if we didn't already to ensure it's there- this only works with runit anyhow...
inherit runit

def preprocess_default_svcs(d):
    # Handle figuring out what we have in our defaults list...  This is simple as 
    # grabbing each basename of the path where there's a run...
    for root, dirs, files in os.walk(d.expand("${D}${runit-svcdir}/")) :
        if dirs :
            for dirname in dirs :
                if dirname != "log" :
                    # We're stuffing a variable that can be queried for final results.
                    d.appendVar("DEFAULT_SVC_GROUP", " " + dirname)


def generate_services_entry(d, svc_group, prior, svcs_list):
    # Just generate a run/finish/config/check that leverages this list when we have
    # a list.  We need to build a list of the stuff for a similar run through
    # the lists where we default everything NOT on a list prior to the emptys
    # as a "default" services set for the group.
    packagename = d.getVar("PN")
    filepath = d.expand("${D}${runit-svcdir}/") + packagename + "-" + str(svc_group)
    os.mkdir(filepath)
    configfile = open(filepath + "/svcs-list", "wt")
    print("# Generated, do NOT edit.  Config entries for run/finish for svcs group " + str(svc_group), file=configfile)
    print("SVCS_LIST=\"" + svcs_list + "\"", file=configfile)
    configfile.close()
    runfile = open(filepath + "/run", "wt")
    # We're going to leverage the "sv check" functionality with these.
    # (We want a start up to begin once we've done the launch of the prior
    # when applicable...), so the run needs to -e the shebang.
    print("#!/bin/sh -e", file=runfile)
    print(". ./svcs-list", file=runfile)
    if prior != 0:
        print("sv -w0 check " + packagename + "-" + str(prior), file=runfile)
    print("sv -w0 start $SVCS_LIST", file=runfile)
    print("exec pause", file=runfile)
    runfile.close()
    checkfile = open(filepath + "/check", "wt")
    print("#!/bin/sh", file=checkfile)
    print(". ./svcs-list", file=checkfile)
    print("sv -w0 check $SVCS_LIST 2>&1 > /dev/null", file=checkfile)
    checkfile.close()
    # Handle closing down services semi-gracefully.  We issue a SIGUSR1 to 
    # services needing to be told that they're being shut down (Some cases
    # of some services need to wind down over a bit longer time than is 
    # afforded by SIGTERM/SIGKILL/etc.) we then wait a small amount and 
    # then just shut down.
    finishfile = open(filepath + "/finish", "wt")
    print("#!/bin/sh", file=finishfile)
    print(". ./svcs-list", file=finishfile)
    print("sv once $SVCS_LIST", file=finishfile)
    print("sv 1 $SVCS_LIST", file=finishfile)
    print("pause 2", file=finishfile)
    print("sv stop $SVCS_LIST", file=finishfile)
    finishfile.close()    
    # Now symlink the whole there to let runit know about it all.
    os.symlink(d.expand("${runit-svcdir}/") + packagename + "-" + str(svc_group), d.expand("${D}${runit-runsvdir}/default/") + packagename + "-" + str(svc_group))


# For the specified grouping(s), generate a launcher that turns on those specified
# services (Presuming the declared/defined service launchers are down-ed).  We capture
# any services specified so we can remove them, ultimately, from a default list (Specified
# in the NUM_SVC_GROUPS but doesn't have an entry.  Presume any of the remaining in 
# THIS recipe as a final installed is the empty groups' list where this is 0 or more 
# groups as specified..
python process_service_group_entries() {
    # Check to see if we even have groupings declared...
    num_groups = d.getVar("NUM_SVC_GROUPS")
    if num_groups != "":
        # Handle the defaults pre-staging...
        preprocess_default_svcs(d)
        default_svc_grp = list(d.getVar("DEFAULT_SVC_GROUP").split(" "))
        # Strip out any instances of an "empty" value in the list...
        if default_svc_grp.count("") > 0 :
            default_svc_grp.remove("")

        # Now, generate our defined scripting for the services groups.
        svc_groups = int(num_groups)
        prior = 0
        for svc in range(1, svc_groups + 1) :
            svcs_list = d.getVar("SVC_GROUP_" + str(svc), expand=True)
            if (svcs_list) :
                # Generate our content for the packaging...
                generate_services_entry(d, svc, prior, svcs_list)
                # Handle special processing for each item in this list...
                for sv in list(svcs_list.split(" ")):
                    # Generate a down entry for the case that we don't already
                    # have one processed by any default runit.bbclass processing.
                    # (This lets us do crazy things like specifying services groups
                    #  blindly so you don't even need services entries in the recipe
                    #  that you're specifying the grouping launcher...)
                    svcpath = d.expand("${D}${runit-svcdir}/") + sv
                    os.system("mkdir -p " + svcpath)
                    os.system("touch " + svcpath + "/down")
                    
                    # Remove the defaults entry, if any for this service...
                    if default_svc_grp.count(sv) > 0:
                        default_svc_grp.remove(sv)
            prior = svc

        # Handle the defaults that remain out of the default entries list we
        # initially generated at the beginning of this and winnowed out
        # the stuff from each of the services groupings.  We have a max of 998 
        # possible services groups.  999 is the final bucket; if we don't have
        # anything in the defaults bucket, do nada.
        if default_svc_grp :
            default_svcs = ""
            for svc_item in default_svc_grp:
                default_svcs = default_svcs + str(svc_item) + " "
            generate_services_entry(d, 999, svc, default_svcs)
}
do_install[postfuncs] += "${@bb.utils.contains('DISTRO_FEATURES', 'runit', 'process_service_group_entries', '', d)} "



