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

### 2. Customize configuration
Customize your build configuration at `/etc/buildbot/`. Alternatively you can also create a new seperate config file and overwrite the config file used with `$1`, eg `arkane-buildbot /etc/buildbot/custom_config`.

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
### Running the program
```bash
arkane-buildbot [FILE]
```

### Options and arguments
| Argument | Description | Example |
| --- | --- | --- |
| [FILE] | The optional argument `$1` is utilized for overwriting the default configuration file. Inputting a `-` will make it use the default file instead. | `arkane-buildbot ./custom.conf` |
