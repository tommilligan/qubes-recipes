#!/usr/bin/env/python

import argparse

from pyqubes.vm import TemplateVM


def quinine(dry_run=False):
    vm_vanilla_fedora = TemplateVM('fedora-23')
    vm_vanilla_debian = TemplateVM('debian-8', operating_system='debian')

    for vm in [vm_vanilla_fedora, vm_vanilla_debian]:
        with vm.animate():
            vm.update()

    # Third party Debian TemplateVM
    vm_exotic_debian = vm_vanilla_debian.clone('debian-8-exotic')
    with vm_exotic_debian.animate():
        # Add Chrome, Spotify repos
        with vm_exotic_debian.internet():
            vm_exotic_debian.run('wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add - && echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google.list')
            vm_exotic_debian.run('sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys BBEBDCB318AD50EC6865090613B00F1FD2C19886 && echo deb http://repository.spotify.com stable non-free | sudo tee /etc/apt/sources.list.d/spotify.list')
        vm_exotic_debian.run('sudo apt-get update')
        # Install Chrome, Spotify
        vm_exotic_debian.run('sudo apt-get -y install google-chrome-stable spotify-client')

    # Debian AppVMs
    vm_exotic_debian.create_app('juke', label='yellow')

    # Third party Fedora TemplateVM
    vm_exotic_fedora = vm_vanilla_fedora.clone('fedora-23-exotic')
    with vm_exotic_fedora.animate():
        # Add Chrome, VSCode repos
        vm_exotic_fedora.run(r'echo -e "[google-chrome]\nname=google-chrome - \$basearch\nbaseurl=http://dl.google.com/linux/chrome/rpm/stable/\$basearch\nenabled=1\ngpgcheck=1\ngpgkey=https://dl-ssl.google.com/linux/linux_signing_key.pub" | sudo tee /etc/yum.repos.d/google-chrome.repo')
        vm_exotic_fedora.run('sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc')
        vm_exotic_fedora.run(r'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo')
        vm_exotic_fedora.run('dnf check-update')
        # Install Chrome, VSCode, Audacity
        vm_exotic_fedora.run('sudo dnf -y install google-chrome-stable code audacity')

        with vm_exotic_fedora.internet():
            commands = ['wget -P /tmp/ https://repo.skype.com/latest/skypeforlinux-64.rpm',
                    'sudo dnf -y install /tmp/skypeforlinux-64.rpm',
                    'rm /tmp/skypeforlinux-64.rpm']
            for command in commands:
                vm_exotic_fedora.run(command)

    # Fedora AppVMs
    vm_vanilla_fedora.create_app('banking', label='blue')
    vm_app_vault = vm_vanilla_fedora.create_app('vault', label='black')
    vm_exotic_fedora.create_app('av', label='orange')
    vm_exotic_fedora.create_app('dev', label='orange')
    vm_app_usb = vm_exotic_fedora.create_app('usb', label='yellow')
    # TODO remove usb network connectivity here

def main_parser():
    parser = argparse.ArgumentParser(description='Setup a quinine workstation')
    parser.add_argument('--dry-run', action='store_true',
                        help='Only echo steps to be taken')
    return parser

def main():
    parser = main_parser()
    args = parser.parse_args()
    quinine(dry_run=args.dry_run)

if __name__ == '__main__':
    main()
