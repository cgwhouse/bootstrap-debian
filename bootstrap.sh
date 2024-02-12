#!/bin/bash

source ./libbootstrap.sh

# Ensure root
if [ "$EUID" -ne 0 ]; then
    printf "\nRoot is required\n\n"
    exit 1
fi

# Validate no script arguments
if [ $# -gt 0 ]; then
    printf "\nUsage:\n\n"
    printf "sudo ./bootstrap.sh\n\n"
    exit 1
fi

# Ensure .env
if [ -z "$server" ] || [ -z "$username" ]; then
    printf "\nERROR: .env file is missing\n\n"
    exit 1
fi

# Run tasks, exit if a task errors

printf "\n"

# Start with server workload
if ! CreateReposDirectory; then
    exit 1
fi

if ! InstallCoreUtilities; then
    exit 1
fi

if ! ConfigureCoreUtilities; then
    exit 1
fi

if [ $server == true ]; then

    # Should always be last, because install script drops you into a zsh at the end
    if ! InstallOhMyZsh; then
        exit 1
    fi

    exit 0
fi

if ! InstallProprietaryGraphics; then
    exit 1
fi

if ! InstallDesktopEnvironment; then
    exit 1
fi

if ! InstallFonts; then
    exit 1
fi

if ! InstallPipewire; then
    exit 1
fi

if ! InstallAdditionalSoftware; then
    exit 1
fi

if ! InstallOhMyZsh; then
    exit 1
fi

printf "\n"
