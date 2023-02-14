#!/usr/bin/env bash

# If $1 is set we will assume the user is overwriting the config from the command line.
if [[ -v 1 && $1 != "-" ]]; then
	source $1

	if [[ ! $? -eq 0 ]]; then
		printf "Failed to run custom config file '$1', quitting...\n"
		exit 1
	fi
else
	source /etc/buildbot.conf
	
	if [[ ! $? -eq 0 ]]; then
		printf "Failed to run default config file '/etc/buildbot.sh', quitting...\n"
		exit 1
	fi
fi

# If work_dir is already defined we will assume it is purposefully being
# overwritten by the user
if [[ ! -v work_dir ]]; then
	work_dir=$(pwd)
fi

main () {
	update_pkgbuild
	index_packages
	
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
						app_directory="$j"
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
								echo $app_directory
								cd $app_directory

								# Ensure dependencies are intalled
								source ./PKGBUILD
								sudo pacman -S --noconfirm --needed "${makedepends} ${depends}"

								# Build the package
								makepkg
							fi
						fi
						(( looptwo=looptwo+1 ))
					done

					go_run=0
				fi
		done < ./pkg.index
	else
		# If this is the first run we can assume we will have to build everything
		# not the most elegant solution but it will do for now
		echo "pkg.index.old does not exist, assuming first run"

		while read i; do
			cd $work_dir

			for j in $i; do
				if (( loop % 2 )); then
					go_run=1
				else
					app_directory="$j"
				fi
				(( loop=loop+1 ))
			done

			if [[ "$go_run" -eq 1 ]]; then
				# If the app version does not match we will assume an update is available and rebuild
				echo $app_directory
				cd $app_directory

				# Ensure dependencies are intalled
				source ./PKGBUILD
				sudo pacman -S --noconfirm --needed "${makedepends} ${depends}"

				# Build the package
				makepkg
			fi

			if [[ "$go_run" == 1 ]]; then
				go_run=0
			fi
		done < ./pkg.index
	fi
}

# Check for build errors and log
error_check () {
	if [[ ! $1 -eq 0 ]]; then
		echo "Building $pkgdir failed with exit code $1"
		echo "$pkg $1" >> ./error.log
	fi
}

# Pull the latest Arch pkgbuild repo
update_pkgbuild () {
	cd $work_dir
	
	# Check if repo exists
	if [[ ! -d ./$repo_dir ]]; then
		printf "Repo does not exist, cloning $repo to $repo_dir\nthis may take a while...\n"
		git clone $repo $repo_dir
	else
		printf "Repo $repo_dir exists, pulling diff\nthis may take a while...\n"
		cd $repo_dir
		git pull
	fi
}

# Create an index of all packages
index_packages () {
	cd $work_dir

	if [[ -f ./pkg.index ]]; then
		mv pkg.index pkg.index.old
	fi

	for dir in $work_dir/$repo_dir/*; do
		# dir = full filepath to package, eg. cowsay
		# sub_dir = Typically repos and trunk
		# package_dir = dir inside of repos, eg. community-x86_64
		#
		# sub_dir step could technically be removed and hard coded,
		# but I am leaving it in for now
		if [[ -d "$dir" ]]; then
			cd $dir

			for sub_dir in *; do
				if [[ "$sub_dir" != 'trunk' ]]; then
					for package_dir in $sub_dir/*;
					do
						# Lets not build testing nor staging packages
						if [[ "$package_dir" != *staging* && "$package_dir" != *testing* && "$package_dir" != *i686* && -d "$package_dir" ]]; then
							cd $dir/$package_dir

							if [[ -e ./PKGBUILD ]]; then
								source ./PKGBUILD
							else
								printf "No PKGBUILD file for $dir/$package_dir\n"
							fi

							echo "$dir/$package_dir $pkgver-$pkgrel" >> $work_dir/pkg.index
						fi
					done
				fi
			done
		fi
	done
}

run_build () {
	if [[ "$first_run" == 1 ]]; then
		echo firstrun
	else
		echo not firstrun
	fi
}

main
