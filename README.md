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
Change `repo` and `repo_dir` in `buildbot.sh`.

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
Just run it with the builduser. `./buildscript.sh`

I will add a systemd-service later.
