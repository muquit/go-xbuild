#!/bin/bash

########################################################################
# Cross compile mailsend-go
#
# Please look at platforms.txt if you want to compile for a specific 
# platform.
#
# It was written from the frustration of using  GoReleaser. I do not release 
# often but whenever the time comes to release using GoReleaser, something
# has changed.
#
# muquit@muquit.com Nov-26-2023 
########################################################################

# script constants
readonly MYDIR=$(dirname $0)
readonly BINDIR=${MYDIR}/bin
readonly PROJECT_NAME=$(basename $(pwd))
readonly VERSION_FILE="${MYDIR}/VERSION"
readonly PLATFORMS_FILE="${MYDIR}/platforms.txt"
readonly CHECKSUMS_FILE="checksums.txt"

# common build flags
readonly LDFLAGS='-s -w'
readonly BUILD_FLAGS="-trimpath"

# verify required files exist
init() {
    [[ -f ${VERSION_FILE} ]] || fail "version file not found: ${VERSION_FILE}"
    [[ -f ${PLATFORMS_FILE} ]] || fail "platforms file not found: ${PLATFORMS_FILE}"
    mkdir -p ${BINDIR} || fail "could not create bin directory: ${BINDIR}"
    echo "building project: ${PROJECT_NAME}"
}

# get version from VERSION file
get_version() {
    cat ${VERSION_FILE}
}

# print error and exit
fail() {
    local -r msg="$1"
    echo "error: ${msg}" >&2
    exit 1
}

# calculate sha256 checksum and append to checksums file
take_checksum() {
    local -r version=$1
    local -r archive=$2
    local -r checksum_file="${BINDIR}/${PROJECT_NAME}-${version}-${CHECKSUMS_FILE}"
    sha256sum "${archive}" >> "${checksum_file}"
}

# copy required files to distribution directory
cp_files() {
    local -r bin=$1
    local -r dist_dir=$2
    mkdir -p "${dist_dir}"
    cp -f "${bin}" "${dist_dir}/"
    # copy documentation files if they exist
    [[ -f "${MYDIR}/README.md" ]] && cp -f "${MYDIR}/README.md" "${dist_dir}/"
    [[ -f "${MYDIR}/docs/${PROJECT_NAME}.1" ]] && cp -f "${MYDIR}/docs/${PROJECT_NAME}.1" "${dist_dir}/"
    [[ -f "${MYDIR}/LICENSE.txt" ]] && cp -f "${MYDIR}/LICENSE.txt" "${dist_dir}/"
}

# remove temporary directory
cleanup_dir() {
    local -r dir="$1"
    [[ -d ${dir} ]] && rm -rf "${dir}"
}

# create archive (zip for windows, tar.gz for others)
create_archive() {
    local -r version=$1
    local -r dist_dir=$2
    local archive_name
    
    # create appropriate archive based on OS
    if [[ ${GOOS} == 'windows' ]]; then
        archive_name="${dist_dir}.zip"
        zip -r "${archive_name}" "${dist_dir}" || fail "failed to create zip archive"
    else
        archive_name="${dist_dir}.tar.gz"
        # handle macos tar quirks
        local tar_opts=""
        [[ $(uname) == 'Darwin' ]] && tar_opts="--no-xattrs"
        tar ${tar_opts} -czf "${archive_name}" "${dist_dir}" || fail "failed to create tar archive"
    fi
    
    # move archive to bin directory and cleanup
    mv "${archive_name}" "${BINDIR}/" || fail "failed to move archive to bin directory"
    take_checksum "${version}" "${BINDIR}/$(basename ${archive_name})"
    cleanup_dir "${dist_dir}"
}

# build for raspberry pi
build_pi() {
    local -r version=$1
    local -r variant=$2
    local -r arm_version=$3
    
    local -r dist_dir="${PROJECT_NAME}-${version}-raspberry-pi${variant}.d"
    local -r binary_name="${PROJECT_NAME}-${version}-raspberry-pi${variant}"
    
    # set raspberry pi build environment
    export GOOS=linux
    export GOARCH=arm
    export GOARM=${arm_version}
    
    echo "building for raspberry pi${variant} (arm${arm_version})"
    go build -ldflags="-${LDFLAGS}" ${BUILD_FLAGS} -o "${binary_name}"
    
    cp_files "${binary_name}" "${dist_dir}"
    create_archive "${version}" "${dist_dir}"
    rm -f "${binary_name}"
    
    # cleanup environment
    unset GOOS GOARCH GOARM
}

# main build process
main() {
    init
    local -r version=$(get_version)
    echo "building ${PROJECT_NAME} version ${version}"
    
    # clean existing checksums
    rm -f "${BINDIR}/${PROJECT_NAME}-${version}-${CHECKSUMS_FILE}"
    
    # build for platforms in platforms.txt
    while read -r line; do
        [[ ${line} =~ ^#.*$ ]] && continue
        export GOOS=$(echo ${line} | cut -d/ -f1)
        export GOARCH=$(echo ${line} | cut -d/ -f2)
        
        echo "building for ${GOOS}/${GOARCH}"
        
        local dist_dir="${PROJECT_NAME}-${version}-${GOOS}-${GOARCH}.d"
        local binary_name="${PROJECT_NAME}-${version}-${GOOS}-${GOARCH}"
        [[ ${GOOS} == 'windows' ]] && binary_name="${binary_name}.exe"
        
        go build -ldflags="-${LDFLAGS}" ${BUILD_FLAGS} -o "${binary_name}"
        cp_files "${binary_name}" "${dist_dir}"
        create_archive "${version}" "${dist_dir}"
        rm -f "${binary_name}"
        
    done < "${PLATFORMS_FILE}"
    
    # build for raspberry pi variants
    build_pi "${version}" "" "7"     # modern pi
    build_pi "${version}" "-jessie" "6"  # pi jessie
    
    echo "build complete. artifacts are in ${BINDIR}"
}

main
