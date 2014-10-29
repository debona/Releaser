# Little tool to build un release .ipa

For each environments :

- It creates dir
- It builds ipa and dsym
- It generate the plist
- It open the builds directory


# Install

1. unzip it
2. cd in it
3. `gem install bundle` # if needed
4. `bundle install`

Optional:

Add this shell function to your shell profile:

	## Build and release MyProject
	#
	function release() {
		echo "release.rb -p MyProject -v $*"
		echo
		/Users/someone/somewhere/releaser/release.rb -r /where/you/want/the/build/come -p MyProject -v $*
	}

# Use it

- cd in your project
- `release.rb -r /where/you/want/the/build/come -p MyProject -v 6.6.6`

or

- `release 6.6.6` # with the shell function

# Misc

	release.rb --help

It can be configured for each project. See files in conf/project.
There is an `.xcconfig` to configure the building phase for each environment. (You can inject global macro by using `GCC_PREPROCESSOR_DEFINITIONS`)
There is a distribution plist template for each environment.


