## Installation

### Generic

Flight Manage requires a recent version of `ruby` (2.5.1<=) and `bundler`.
The following will install from source using `git`:
```
git clone https://github.com/openflighthpc/flight-manage.git
cd flight-manage
bundle install
```

The entry script is located at `bin/manage`

## Installing with Flight Runway

Flight Runway (and Flight Tools) provides the Ruby environment and command-line helpers for running openflightHPC tools.

To install Flight Runway, see the [Flight Runway installation docs](https://github.com/openflighthpc/flight-runway#installation>) and for Flight Tools, see the [Flight Tools installation docs](https://github.com/openflighthpc/openflight-tools#installation>).

These instructions assume that `flight-runway` and `flight-tools` have been installed from the openflightHPC yum repository and [system-wide integration](https://github.com/openflighthpc/flight-runway#system-wide-integration) enabled.

Integrate Flight Manage to runway:

```
[root@myhost ~]# flintegrate /opt/flight/opt/openflight-tools/tools/flight-manage.yml
Loading integration instructions ... OK.
Verifying instructions ... OK.
Downloading from URL: https://github.com/openflighthpc/flight-manage/archive/master.zip ... OK.
Extracting archive ... OK.
Performing configuration ... OK.
Integrating ... OK.
```

Flight Manage is now available via the `flight` tool::

```
[root@myhost ~]# flight manage
  NAME:

    flight manage

  DESCRIPTION:

    Remote executor of shared scripts.

  COMMANDS:

    help           Display global or [command] help documentation
    node           Manage nodes
    script         Manage scripts
    <snip>
```
