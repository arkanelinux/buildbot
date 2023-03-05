#!/usr/bin/env bash

main () {
	update_pkgbuild
	index_packages

	# Import PGP keys from repo if any
	import_pgp_keys () {
		if [[ -d "$app_directory/keys" ]]; then
			gpg --import $app_directory/keys/pgp/*
		fi
	}

	# Check for build errors and log
	error_check () {
		if [[ ! $1 -eq 0 ]]; then
			printf "Building $current_dir failed with exit code $1\n"
			printf "$app_directory $1\n" >> "$log_dir/buildbot.log"
		fi
	}

	# Clean up build leftovers to free disk space
	cleanup() {
		if [[ $cleanup -eq 1 ]]; then
			mkdir -p $pkg_target_dir
			cp $app_directory/$pkg_pattern $pkg_target_dir
			
			cd $app_directory
			rm -rf *
			git checkout .
		fi
	}

	cd $work_dir

	# If pkg.index.old exists this is not the first run
	# so we can start checking for updates
	if [[ -f ./pkg.index.old ]]; then


		# Get both app name and version
		while read i; do
				cd $work_dir

				for j in $i; do
					if (( loop % 2 )); then
						app_version="$j"
						go_run=1
					else
						app_directory=$(dirname $j)
					fi
					(( loop=loop+1 ))
				done

				# If both app_version and app_directory are indexed look for this package in pkg.index.old
				if [[ $go_run -eq 1 ]]; then
					result=$(grep "^${app_directory}\s" ./pkg.index.old)

					# Set var to error to assure package build if app_directory is missing from the pkg.index.old
					# this will trigger when new packages are added to the repo
					if [[ $? != 0 ]]; then
						result='error'
					fi

					for q in $result; do

						if (( looptwo % 2 )); then
							old_app_version="$q"

							if [[ "$old_app_version" != "$app_version" ]]; then
								# If the app version does not match we will assume an update is available and rebuild
								printf "\e[32mNow building: $app_directory\e[0m\n"
								cd $app_directory

								# Ensure dependencies are installed
								source ./PKGBUILD
								sudo pacman -Sy --noconfirm --needed ${makedepends}

								# Import pgp keys if any
								import_pgp_keys

								# Build the package
								makepkg ${makepkg_params[@]}
								error_check $?
					
								cleanup
							fi
						fi
						(( looptwo=looptwo+1 ))
					done


					if [[ "$go_run" == 1 ]]; then
						go_run=0
					fi
				fi
		done < ./pkg.index
	else
		# If this is the first run we can assume we will have to build everything
		# not the most elegant solution but it will do for now
		printf "pkg.index.old does not exist, assuming first run\n"

		while read i; do
			cd $work_dir

			for j in $i; do
				if (( loop % 2 )); then
					go_run=1
				else
					app_directory=$(dirname $j)
				fi
				(( loop=loop+1 ))
			done

			if [[ "$go_run" -eq 1 ]]; then
				# If the app version does not match we will assume an update is available and rebuild
				printf "\e[32mNow Building: $app_directory\e[0m\n"
				cd $app_directory

				# Ensure dependencies are installed
				source ./PKGBUILD
				sudo pacman -Sy --noconfirm --needed ${makedepends}

				# Import pgp keys if any
				import_pgp_keys

				# Build the package
				makepkg ${makepkg_params[@]}
				error_check $?

				cleanup
			fi

			if [[ "$go_run" == 1 ]]; then
				go_run=0
			fi
		done < ./pkg.index
	fi
}

# Pull the latest Arch pkgbuild repo
update_pkgbuild () {
	cd $work_dir

	git_error_check () {
		if [[ ! $1 -eq 0  ]]; then
			printf "\e[31mFailed to git clone/pull '$repo' exited with '$1', quitting...\e[0m\n"
			exit 1
		fi
	}
	
	# Check if repo exists
	if [[ ! -d ./$repo_dir ]]; then
		printf "Repo does not exist, cloning $repo to $repo_dir\nthis may take a while...\n"
		git clone $repo $repo_dir
		git_error_check $?
	else
		printf "Repo $repo_dir exists, pulling diff\nthis may take a while...\n"
		cd $repo_dir
		git pull
		git_error_check $?
	fi
}

index_packages () {
	cd $work_dir

	for f in $(find "$(cd ..; pwd)" -name 'PKGBUILD'); do

		if [[ $f != @(*staging*|*testing*|*i686*) ]]; then
			source $f
			printf "$f $pkgver-$pkgrel\n" >> $work_dir/pkg.index
		fi

	done
}

# makepkg does not allow running as root, kill the program if root
if [[ $(id -u) -eq 0 ]]; then
	printf "\e[31mScript is running as root, the script should be run as a normal user, quitting...\e[0m\n"
	exit 1
fi

# If $1 is set we will assume the user is overwriting the config from the command line.
if [[ -v 1 && $1 != "-" ]]; then
	source $1

	if [[ ! $? -eq 0 ]]; then
		printf "\e[31mFailed to run custom config file '$1', quitting...\e[0m\n"
		exit 1
	fi
else
	source /etc/buildbot.conf
	
	if [[ ! $? -eq 0 ]]; then
		printf "\e[31mFailed to run default config file '/etc/buildbot.sh', quitting...\e[0m\n"
		exit 1
	fi
fi

# These variables are required to all be defined in the config file
if [[ ! -v log_dir || ! -v repo || ! -v repo_dir ]]; then
	printf "\e[31mNot all required variables have been configured in the config file, quitting...\e[0m\n"
	exit 1
fi

# Ensure log folder exists
mkdir -p $log_dir

# Ensure log file is created properly
if [[ ! -d $log_dir ]]; then
	printf "\e[31mFailed to create '$log_dir', quitting...\e[0m\n"
	exit 1
fi

# If work_dir is already defined we will assume it is purposefully being
# overwritten by the user
if [[ ! -v work_dir ]]; then
	work_dir=$(pwd)
fi

main
