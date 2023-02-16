# Buildbot
The Arkane Buildbot is a script used to pull, index and build Arch Linux pkgbuild Git repos.

## Setup
### 1. Allow user to run pacman -S without sudo password
The script is run as a normal non-privileged user, however it will require passwordless sudo access to run pacman when installing build dependencies.

We will have to set up the sudoers file to allow for this by adding the following line.
```
builduser	ALL=(root)	NOPASSWD: SETENV: /usr/bin/pacman
```

### 2. Set the target repo
Change `repo` and `repo_dir` in `buildbot.conf`, by default located at `/etc/buildbot.conf`, alternatively also overwritable with `$1`.

### 3. (Optional) Set custom build settings
Edit `/etc/makepkg.conf` with your custom build environment settings.

For example, change the compiler flags;
```
CFLAGS="-march=x86-64-v3 -mtune=generic -O2 -pipe -fno-plt -fexceptions \
        -Wp,-D_FORTIFY_SOURCE=2 -Wformat -Werror=format-security \
        -fstack-clash-protection -fcf-protection"
CXXFLAGS="$CFLAGS -Wp,-D_GLIBCXX_ASSERTIONS"
RUSTFLAGS="-C opt-level=3 -C target-cpu=x86-64-v3"
MAKEFLAGS="-j16"
```

## Usage
### Running the program
```
./buildscript.sh [FILE]
```

### Options and arguments
| Argument | Description | Example |
| --- | --- | --- |
| [FILE] | The optional argument `$1` is utilized for overwriting the default configuration file. Inputting a `-` will make it use the default file instead. | `buildscript ./custom.conf` |
