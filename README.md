# arkane-buildbot
The Arkane Linux Buildbot is a script used to pull, index and build Arch Linux pkgbuild Git repos.

## Setup
### 1. Create and set up builduser
Create the user account;
```bash
useradd --create-home --home-dir /var/builduser --shell /usr/bin/nologin builduser
```

The script is run as a normal non-privileged user, however it will require passwordless sudo access to run pacman when installing build dependencies.

We will have to set up the sudoers file to allow for this by adding the following line.
```bash
builduser	ALL=(root)	NOPASSWD: SETENV: /usr/bin/pacman
```

### 2. (Optional) Customize configuration
There are a couple of default configs included, see `/etc/arkane-buildbot/` for available default configs.

> **Note** It is best to not edit these config files for they may be overwritten if you ever update arkane-buildbot, thus it is best to create a new custom config instead

You can also create a new config file under a custom name in this location.

### 3. (Optional) Set custom build settings
Edit `/etc/makepkg.conf` with your custom build environment settings, this is what Arkane is using;

```bash
CFLAGS="-march=x86-64-v3 -mtune=generic -O2 -ftree-vectorize -pipe -fno-plt -fexceptions \
        -Wp,-D_FORTIFY_SOURCE=2 -Wformat -Werror=format-security \
        -fstack-clash-protection -fcf-protection"
CXXFLAGS="$CFLAGS -Wp,-D_GLIBCXX_ASSERTIONS"
RUSTFLAGS="-C opt-level=3 -C target-cpu=x86-64-v3"
MAKEFLAGS="-j16"
```

## Usage
### Running the program manually
```bash
# If no file provided attempts to run /etc/arkane-buildbot/default instead
arkane-buildbot [FILE]
```

### Running using the systemd service
> **Note** Ensure the builduser is created and properly configured, or alternatively copy/edit the service to use a custom workdir and user

> **Note** Dashes are not valid in variables

The services takes a variable as input, provide it with the name of the config file you wish to run located in `/etc/arkane-buildbot/`.
```bash
systemctl start arkane-buildbot@arch_community.service
```

### Options and arguments
| Argument | Description | Example |
| --- | --- | --- |
| [FILE] | The `$1` argument is used to define which config file located in `/etc/arkane-buildbot/` it should utilize. If undefined or if a `-` is passed it defaults to `/etc/arkane-buildbot/default` | `arkane-buildbot custom_config` |
