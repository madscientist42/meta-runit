# meta-runit
Provide init services ultimately using either busybox's runit variant or the full-on one.

Currently, the layer, in it's current state of affairs, is using madscientist42's runit fork (Current maintained, using CMake for build and packaging).  Future iterations will use either version depending on needs.  Current source is intended to be used with Sumo (2.5), Thud (2.6), Warrior (2.7), and Zeus (2.8) of Yocto as supported by this project as of the date of this update of the README.md file (June 16th, 2020).  It is still a bit of an early release of metadata- if it breaks, you get _**ALL**_ of the pieces; all other warranties, implied or expressed are inoperative.  That being said, for what little has been bolted in/on to this as .bbappends to do this more the "right" way than past attempts at this to showcase what runit brings to the table, it seems to work _**WELL**_. _**(REALLY WELL...  There are three embedded distributions (PHA Linux and two others...) aggressively leveraging this layer in their product dev.)**_

_**How to use: (Currently)**_

Add this to your project metadata layer set in whatever manner you see fit and add it to your conf/bblayers.conf file as a valid layer.

Once there, you need only add "runit" to your DISTRO_FEATURES to turn on runit itself along with install the currently provided/supported services.  If you want to run it as a full-on init replacement (C'mon, you _**KNOW**_ you want to...) you need only add "runit-init" to the DISTRO_FEATURES and remove "sysvinit" from them.  This enables the full support currently available for things.

In order to add a package to support this, you need only inherit from runit.bbclass and have the services setup (i.e. /etc/sv/\<foo\>/run script at minimum) in your SRC_URI set and it will package it accordingly for you and enable it based on rules set in the RUNIT_SERVICES variable in your package declarations as follows:

- If you specify, "DEFAULT" in all caps, in that variable, it will explicitly provision each and every sv/<foo> configuration, applying the "default" modifier to each in turn.  Specifying modifiers in RUNIT_DEFAULT_MODS will apply all modifiers other than "single" (as this isn't supported for this mode) to each service specified in the installed /etc/sv for the package inheriting from runit.bbclass.
- If you specify the names of the services that you want enabled in a space separated list (where the name is \<foo\> for sv/\<foo\> ) with or without modifiers.  Order doesn't matter on the modifiers as it will apply the modifiers accordingly on boot. This will provision this service with the specified modifiers. (e.g. "syslog;log" would set the syslog service with a default logging service to be provided for the same, ran at the default runlevel.)

Currently supported modifiers:

- "single" - Enable service for Single-user mode (Can only be one of "single" or "default")
- "default" - Enable service for Multi-user/processing mode, presumed without specifying this (Can only be one of "single" or "default")
- "log" - Enable basic default svlogd logging support for the service. (Logging presumes there is a "log" user!)
- "log-no-ts" - Enable basic default svlogd logging without timestamps.
- "once" - Set the service to start but be allowed to exit without any further supervision. (Planned, not in the runit support yet.)
- "down" - Set the service available for supervision, but down at startup.

_**Services Groups**_

This feature extends the above to allow you to specify a set of services groups associated with either the current recipe's definitions or to make a separate recipe that allows you to control specific start orders of services without losing the full performance and capabilities of runit.

inherit runit-services-groups and it enables the support for the feature.  Use is as follows:

Specify NUM_SVC_GROUPS to number the desired number of groups (e.g. NUM_SVC_GROUPS = "2") to let the bbclass know how many groups you intend to specify.  One group is only relevant if you're trying to avoid specifying your services definitions lexocographically to control order, so if you don't care about start order, etc. and don't need controlled startup sequencing of more than one group, you may not need this feature.  The maximum is 998 for this.

Once this number is specified, you need to declare the group lists, which is named SVC_GROUP_< X > where < X > is 1 to the count of groups. You specify the service names you desire to put into the grouping and the order of startup within that group is as you specify them.

Service group start up is in order of the number, where the only checking is if the previous group, excepting there is none for group 1, is claiming to be running via "sv check".  

Anything remaining in the recipe's setup for sv/<foo> that is not specified in those lists will be assigned to ${PN}-999 and will be executed last in the order of the groupings.  If you do not specify in the recipe any runit launcher sets to be processed by runit.bbclass, it will attempt to generate proper down files for you so that the services, if they are installed by other packaging, will be in the down state at startup to allow the service group to manage supervision, etc.

The groups are normal runit launchers, dynamically generated by the bbclass so you can provide supervision control to the whole of the group for check, down, up, etc. in the large by specifying "sv < cmd > ${PN}-< group >" where < cmd > is the SV command to be ran against the group, ${PN} is the recipe packagename, and < group > is the group number desired.
  

_**Current State of Affairs**_

We have a decent mix of baseline services working in the layer.  This is now something previewable and usable in it's base form along with minimal mods with your distribution (pha-linux, etc...) to support using Connman and IWD (Or not...we reccomend you contemplate that though...  While the "tried and true" wpa-supplicant "works", it's clumsy/quirky and doesn't always do consistent things with any of the connection managers.  Connman and IWD tip work largely properly together along with the Kernel of 5.4 and later.  IWD is smaller, lighter.  Much of the support for this is here.  Hints on how to splice it in to your distribution if it's not PHA Linux is in PHA Linux...)

This layer accepts any sort of reasonable pull requests to add to this repository's functionality.  Any layer that's currently used and makes sense can have an "external" entry put in for your needs.
