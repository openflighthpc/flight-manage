# Flight Manage

Shared script management.

## Overview

Flight Manage is a tool for executing and managing the execution status of 
shared scripts on local and remote machines, storing Flight-approved bash 
scripts as well as YAML based data on nodes and their execution status of such 
scripts.


## Installation

For installation instructions please read INSTALL.md

## Configuration

It is recommended to have shared network directories for storage of scripts an 
node output data.

There is a single configuration file, `etc/manage.conf`, which is used to store
 file paths for integral parts of the tool.

`data_dir` is the path to the directory where node data YAMLs are stored.

`script_dirs` is a set of directories where scripts to be run are stored.
Please do not use scripts with whitespace in them.

`log_file` is where the Flight Manage execution log is stored.

`remote_exec` is the path to the Flight Manage/Runway executable on a remote 
system. Please note: This **must** be the path to the executable, not just the 
directory it is located in.

## Operation

The commands available are:
```
help
import
list
report
resolve
run
show
```

`import` will import scripts from a `.zip` created by openflightHPC Architect.

`list` will list available nodes/scripts, with additional flags available for 
further filtering and verbosity.

`report` prints the status of every script on every node in a table format, 
with additional flags available for filtering.

`resolve` marks a script as having been completed externally.

`run` will execute a script on the current node. Additional flags are available
 for execution on a remote node over SSH.

`show` will print data on a specific node/script. A node will show the status 
of all scripts executed on it (with flags for `stdout`/`stderr` verbosity); a 
script will show its execution data on all nodes it has been executed on (with 
similar flags).

# Contributing

Fork the project. Make your feature addition or bug fix. Send a pull
request. Bonus points for topic branches.

Read [CONTRIBUTING.md](CONTRIBUTING.md) for more details.

# Copyright and License

Eclipse Public License 2.0, see [LICENSE.txt](LICENSE.txt) for details.

Copyright (C) 2019-present Alces Flight Ltd.

This program and the accompanying materials are made available under
the terms of the Eclipse Public License 2.0 which is available at
[https://www.eclipse.org/legal/epl-2.0](https://www.eclipse.org/legal/epl-2.0),
or alternative license terms made available by Alces Flight Ltd -
please direct inquiries about licensing to
[licensing@alces-flight.com](mailto:licensing@alces-flight.com).

Flight Manage is distributed in the hope that it will be
useful, but WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER
EXPRESS OR IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR
CONDITIONS OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR
A PARTICULAR PURPOSE. See the [Eclipse Public License 2.0](https://opensource.org/licenses/EPL-2.0) for more
details.
