########
# USAGE
# 
# save this file in an AppVM
# run in dom0 shell by using:
# bash <(qvm-run --pass-io <src-vm> 'cat ~/Documents/qubes-recipe.sh')
########

# Base template names
vanillaTemplateDebian="debian-8"
vanillaTemplateFedora="fedora-23"
exoticSuffix="-exotic-test"

# Debug options
## Do not clone or create VMs
debugNoCreateTemplateVMs=true
debugNoCreateAppVMs=true


# Utility functions
function qrInfo {
    echo -e "\e[36mqubes-recipes|INFO|$@\e[39m" 1>&2
}
function qrWarn {
    echo -e "\e[33mqubes-recipes|WARN|$@\e[39m" 1>&2
}
function qubesRecipeClone {
    local originalTemplateName="$1"
    local cloneTemplateName="$2"
    qrInfo "Cloning '$cloneTemplateName' from '$originalTemplateName'"
    if [ "$debugNoCreateTemplateVMs" = true ] ; then
        qrWarn 'debugNoCreateTemplateVMs - no TemplateVM created'
    else
        qvm-clone $originalTemplateName $cloneTemplateName
    fi
}
function qubesRecipeRunSynchronously {
    local targetQube="$1"
    local targetCommand="$2"
    qrInfo "Connecting to '$targetQube' to run '$targetCommand'"
    qvm-run --pass-io "$targetQube" "$targetCommand"
}
function qubesRecipeStart {
    local targetQube="$1"
    qrInfo "Starting '$targetQube'"
    qvm-start "$targetQube"
}
function qubesRecipeShutdown {
    local targetQube="$1"
    qrInfo "Shutting down '$targetQube'"
    qvm-shutdown "$targetQube" --wait
}
function qubesRecipeFirewallPolicy {
    local targetQube="$1"
    local targetPolicy="$2"
    qrInfo "Firewall for '$targetQube' set to '$targetPolicy'"
    qvm-firewall -P "$targetPolicy" "$targetQube"
}
function qubesRecipeTemplateStart {
    local targetQube="$1"
    qrInfo "Starting '$targetQube'"
    qubesRecipeStart "$targetQube"
}
function qubesRecipeTemplateDisableFirewall {
    local targetQube="$1"
    qrInfo "Opening firewall for '$targetQube'"
    qubesRecipeFirewallPolicy "$targetQube" "allow"
}
function qubesRecipeTemplateTeardown {
    local targetQube="$1"
    qrInfo "Tearing down '$targetQube' from customisation"
    qubesRecipeFirewallPolicy "$targetQube" "deny"
    qubesRecipeShutdown "$targetQube"
}
function qubesRecipeTemplateNewApp {
    local templateQube="$1"
    local appQube="$2"
    local appColor="$3"
    qrInfo "Creating AppVM '$appQube' from TemplateVM '$templateQube'"
    if [ "$debugNoCreateAppVMs" = true ] ; then
        qrWarn 'debugNoCreateAppVMs - no AppVM created'
    else
        qvm-create -t "$templateQube" -l "$appColor" "$appQube"
    fi
}
function qubesRecipeAppSetPref {
    local targetQube="$1"
    local prefKey="$2"
    local prefValue="$3"
    qrInfo "Setting config for AppVM '${targetQube}': ${prefKey} = ${prefValue}"
    qvm-prefs -s "$targetQube" "$prefKey" "$prefValue"
}
function qubesRecipeAppRemoveNetwork {
    local targetQube="$1"
    qrInfo "Removing network from '$targetQube'"
    qubesRecipeAppSetPref "$targetQube" netvm none
}
function qubesRecipeAppSetColor {
    local targetQube="$1"
    local labelColor="$2"
    qrInfo "Coloring '$targetQube' as '$labelColor'"
    qubesRecipeAppSetPref "$targetQube" label "$labelColor"
}

# Subshell functions
function qubesRecipeSubTemplateNameExotic {
    # Run as subshell - stdout = exoticTemplateName
    local originalTemplateName="$1"
    local exoticTemplateName="${originalTemplateName}${exoticSuffix}"
    qrInfo "Generated exotic template name '$exoticTemplateName'"
    echo "$exoticTemplateName"
}

# Recipes
function qubesRecipeUpgradeVanilla {
    qrInfo "Ensuring vanilla TemplateVMs are upgraded"

    # Fedora
    local workingTemplate="$vanillaTemplateFedora"
    qubesRecipeStart "$workingTemplate"
    qubesRecipeRunSynchronously "$workingTemplate" 'sudo dnf check-update && sudo dnf -y upgrade'
    qubesRecipeShutdown "$workingTemplate"

    # Debian
    local workingTemplate="$vanillaTemplateDebian"
    qubesRecipeStart "$workingTemplate"
    qubesRecipeRunSynchronously "$workingTemplate" 'sudo apt-get update && sudo apt-get -y upgrade'
    qubesRecipeShutdown "$workingTemplate"
}
function qubesRecipeRecipeDebianExotic {
    qrInfo "Starting DebianExotic recipe"

    # Clone new TemplateVM
    qrInfo "Making exotic TemplateVM for third-party packages"
    local workingTemplate=$(qubesRecipeSubTemplateNameExotic "$vanillaTemplateDebian")
    qubesRecipeClone "$vanillaTemplateDebian" "$workingTemplate"

    ## Setup
    qubesRecipeTemplateStart "$workingTemplate"
    qubesRecipeTemplateDisableFirewall "$workingTemplate"

    ## Add new repos
    ### Add chrome repo
    qubesRecipeRunSynchronously "$workingTemplate" 'wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add - && echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google.list'

    ### Add spotify repo
    qubesRecipeRunSynchronously "$workingTemplate" 'sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys BBEBDCB318AD50EC6865090613B00F1FD2C19886 && echo deb http://repository.spotify.com stable non-free | sudo tee /etc/apt/sources.list.d/spotify.list'

    ## Update package lists
    qubesRecipeRunSynchronously "$workingTemplate" 'sudo apt-get update'

    ## Install from repos
    qubesRecipeRunSynchronously "$workingTemplate" 'sudo apt-get -y install google-chrome-stable spotify-client'

    ## Teardown
    qubesRecipeTemplateTeardown "$workingTemplate"

    # Generate AppVMs
    qrInfo "Creating AppVMs"
    # juke (jukebox, media playback)
    qubesRecipeTemplateNewApp "$workingTemplate" juke orange
}
function qubesRecipeRecipeFedoraExotic {
    qrInfo "Starting FedoraExotic recipe"

    # Clone new TemplateVM
    qrInfo "Making exotic TemplateVM for third-party packages"
    local workingTemplate=$(qubesRecipeSubTemplateNameExotic "$vanillaTemplateFedora")
    qubesRecipeClone "$vanillaTemplateFedora" "$workingTemplate"

    ## Setup
    qubesRecipeTemplateStart "$workingTemplate"
    qubesRecipeTemplateDisableFirewall "$workingTemplate"

    ## Add new repos
    ### Add chrome repo
    qubesRecipeRunSynchronously "$workingTemplate" 'echo -e "[google-chrome]\nname=google-chrome - \$basearch\nbaseurl=http://dl.google.com/linux/chrome/rpm/stable/\$basearch\nenabled=1\ngpgcheck=1\ngpgkey=https://dl-ssl.google.com/linux/linux_signing_key.pub" | sudo tee /etc/yum.repos.d/google-chrome.repo'
    ### Add VSCode repo
    qubesRecipeRunSynchronously "$workingTemplate" 'sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc'
    qubesRecipeRunSynchronously "$workingTemplate" 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo'

    ### Audacity is provided by default

    ## Update package lists
    qubesRecipeRunSynchronously "$workingTemplate" 'dnf check-update'

    ## Install from repos
    qubesRecipeRunSynchronously "$workingTemplate" 'sudo dnf -y install google-chrome-stable code audacity'

    ## Install .rpm packages
    ### Skype
    qubesRecipeRunSynchronously "$workingTemplate" 'wget -P /tmp/ https://repo.skype.com/latest/skypeforlinux-64.rpm'
    qubesRecipeRunSynchronously "$workingTemplate" 'sudo dnf -y install /tmp/skypeforlinux-64.rpm'
    qubesRecipeRunSynchronously "$workingTemplate" 'rm /tmp/skypeforlinux-64.rpm'

    ## Teardown
    qubesRecipeTemplateTeardown "$workingTemplate"

    # Generate AppVMs
    qrInfo "Creating AppVMs"
    # av (online banking only)
    qubesRecipeTemplateNewApp "$workingTemplate" av orange
    # dev (online banking only)
    qubesRecipeTemplateNewApp "$workingTemplate" dev orange
    # usb (offline KeepassX storage; passwords, keys)
    local workingApp="usb"
    qubesRecipeTemplateNewApp "$workingTemplate" "$workingApp" yellow
    qubesRecipeAppRemoveNetwork "$workingApp"
}
function qubesRecipeRecipeFedora {
    qrInfo "Starting Fedora recipe"

    local workingTemplate="$vanillaTemplateFedora"

    # Generate AppVMs
    qrInfo "Creating AppVMs"
    # banking (online banking only)
    qubesRecipeTemplateNewApp "$workingTemplate" banking blue
    # vault (offline KeepassX storage; passwords, keys)
    local workingApp="vault"
    qubesRecipeTemplateNewApp "$workingTemplate" "$workingApp" black
    qubesRecipeAppRemoveNetwork "$workingApp"
}

# Main
function qubesRecipe {
    qrInfo "Running qubes-recipes"

    # Check we're all up to date before starting'
    qubesRecipeUpgradeVanilla

    # Run recipes
    qubesRecipeRecipeFedora
    qubesRecipeRecipeFedoraExotic
    qubesRecipeRecipeDebianExotic
}

qubesRecipe
