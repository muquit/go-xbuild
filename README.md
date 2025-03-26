# go-xbuild

A bash script to ross compile Go projects without the complexity of [GoReleaser](https://goreleaser.com/).
For [Go](https://go.dev/) port of this script, please look at: https://github.com/muquit/go-xbuild-go

It was written from the frustration of using [GoReleaser](https://goreleaser.com/). I don't 
release often, whenever the time comes to release using GoReleaser, 
something has changed.
I got tired of dealing with GoReleaser's complexity when I only release
software occasionally. When I release every 6-12 months or so, GoReleaser's
config often needs updates due to changes. This simple script just works.


## Features
- Simple to use and maintain
- Cross compile for multiple platforms
- Special handling for Raspberry Pi (modern and Jessie)
- Generates checksums
- Creates archives (ZIP for Windows, tar.gz for others)
- No complex configuration files
- Just uncomment platforms in platforms.txt to build for them

## Prerequisites
- [Go](https://go.dev/) installed
- Bash shell

## Installation
```bash
git clone https://github.com/muquit/go-xbuild.git
cp go-xbuild/go-xbuild.sh /your/go/project/
cp go-xbuild/platforms.txt /your/go/project/
```

## Setup
1. Copy go-xbuild.sh and platforms.txt to your project root
2. Create a VERSION file with your version (e.g., v1.0.1)
3. Edit platforms.txt to uncomment the platforms you want to build for

go programs can be cross compiled for more than 40 platforms. 
A few lines of platforms.txt is shown below:
```text
########################################################################
# GOOS/GOARCH
# generated by running: go tool dist list
# Uncomment or add platforms if needed
########################################################################
#aix/ppc64
#android/386
darwin/amd64
darwin/arm64
windows/amd64
#linux/386
linux/amd64
#linux/arm
#linux/arm64
...
```

## Usage
```bash
./go-xbuild.sh
```

The script will:
1. Detect your project name from the directory
2. Read version from VERSION file
3. Build for all uncommented platforms in platforms.txt
4. Create appropriate archives (ZIP for Windows, tar.gz for others)
5. Generate checksums for all archives
6. Place all artifacts in ./bin directory

## Output Structure
```
bin/
├── project-v1.0.0-darwin-amd64.d.tar.gz
├── project-v1.0.0-darwin-arm64.d.tar.gz
├── project-v1.0.0-windows-amd64.d.zip
├── project-v1.0.0-linux-amd64.d.tar.gz
├── project-v1.0.0-raspberry-pi.d.tar.gz
├── project-v1.0.0-raspberry-pi-jessie.d.tar.gz
└── project-v1.0.0-checksums.txt
```

## Included Files
The following files will be included in archives if they exist:
- Compiled binary
- README.md
- LICENSE.txt
- docs/project-name.1 (man page)

## Contributing
Pull requests welcome! Please keep it simple.

## License
MIT License - See LICENSE.txt file for details.

