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


# Utility functions
function qrLog {
    echo -e "\e[96m$@\e[39m" 1>&2
}
function qubesRecipeClone {
    local originalTemplateName="$1"
    local cloneTemplateName="$2"
    qrLog "Cloning '$cloneTemplateName' from '$originalTemplateName'"
    #qvm-clone $originalTemplateName $cloneTemplateName
}
function qubesRecipeRunSynchronously {
    local targetQube="$1"
    local targetCommand="$2"
    qrLog "Connecting to '$targetQube' to run '$targetCommand'"
    #qvm-run --pass-io "$targetQube" "$targetCommand"
}
function qubesRecipeStart {
    local targetQube="$1"
    qrLog "Starting '$targetQube'"
    #qvm-start "$targetQube"
}
function qubesRecipeShutdown {
    local targetQube="$1"
    qrLog "Shutting down '$targetQube'"
    #qvm-shutdown "$targetQube"
}
function qubesRecipeFirewallPolicy {
    local targetQube="$1"
    local targetPolicy="$2"
    qrLog "Firewall for '$targetQube' set to '$targetPolicy'"
    #qvm-firewall -P "$targetPolicy" "$targetQube"
}
function qubesRecipeTemplateSetup {
    local targetQube="$1"
    qrLog "Setting up '$targetQube' for customisation"
    qubesRecipeStart "$targetQube"
    qubesRecipeFirewallPolicy "$targetQube" "allow"
}
function qubesRecipeTemplateTeardown {
    local targetQube="$1"
    qrLog "Tearing down '$targetQube' from customisation"
    qubesRecipeFirewallPolicy "$targetQube" "deny"
    qubesRecipeShutdown "$targetQube"
}
function qubesRecipeTemplateNewApp {
    local templateQube="$1"
    local appQube="$2"
    local appColor="$3"
    qrLog "Creating AppVM '$appQube' from TemplateVM '$templateQube'"
    #qvm-create -t "$templateQube" -l "$appColor" "$appQube"
}
function qubesRecipeAppSetPref {
    local targetQube="$1"
    local prefKey="$2"
    local prefValue="$3"
    qrLog "Setting config for AppVM '${targetQube}': ${prefKey} = ${prefValue}"
    #qvm-prefs -s "$targetQube" "$prefKey" "$prefValue"
}
function qubesRecipeAppRemoveNetwork {
    local targetQube="$1"
    qrLog "Removing network from '$targetQube'"
    qubesRecipeAppSetPref "$targetQube" netvm none
}
function qubesRecipeAppSetColor {
    local targetQube="$1"
    local labelColor="$2"
    qrLog "Coloring '$targetQube' as '$labelColor'"
    qubesRecipeAppSetPref "$targetQube" label "$labelColor"
}

# Subshell functions
function qubesRecipeSubTemplateNameExotic {
    # Run as subshell - stdout = exoticTemplateName
    local originalTemplateName="$1"
    local exoticTemplateName="${originalTemplateName}${exoticSuffix}"
    qrLog "Generated exotic template name '$exoticTemplateName'"
    echo "$exoticTemplateName"
}

# Recipes
function qubesRecipeRecipeDebianExotic {
    qrLog "Starting DebianExotic recipe"

    # Clone new TemplateVM
    qrLog "Making exotic TemplateVM for third-party packages"
    local workingTemplate=$(qubesRecipeSubTemplateNameExotic "$vanillaTemplateDebian")
    qubesRecipeClone "$vanillaTemplateDebian" "$workingTemplate"

    ## Setup
    qubesRecipeTemplateSetup "$workingTemplate"

    ## Add new repos
    ### Add chrome repo
    qubesRecipeRunSynchronously "$workingTemplate" 'wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add - && echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee -a /etc/apt/sources.list.d/google.list'

    ### Add spotify repo
    qubesRecipeRunSynchronously "$workingTemplate" 'sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys BBEBDCB318AD50EC6865090613B00F1FD2C19886 && echo deb http://repository.spotify.com stable non-free | sudo tee /etc/apt/sources.list.d/spotify.list'

    ## Update package lists
    qubesRecipeRunSynchronously "$workingTemplate" 'sudo apt-get update'

    ## Install packages
    qubesRecipeRunSynchronously "$workingTemplate" 'sudo apt-get --yes install google-chrome-stable spotify-client'

    ## Teardown
    qubesRecipeTemplateTeardown "$workingTemplate"

    # Generate AppVMs
    qrLog "Creating AppVMs"
    # juke (jukebox, media playback)
    qubesRecipeTemplateNewApp "$workingTemplate" juke orange
}
function qubesRecipeRecipeFedoraExotic {
    qrLog "Starting FedoraExotic recipe"

    # Clone new TemplateVM
    qrLog "Making exotic TemplateVM for third-party packages"
    local workingTemplate=$(qubesRecipeSubTemplateNameExotic "$vanillaTemplateFedora")
    qubesRecipeClone "$vanillaTemplateFedora" "$workingTemplate"

    ## Setup
    qubesRecipeTemplateSetup "$workingTemplate"

    ## Add new repos

    ## Update package lists
    qubesRecipeRunSynchronously "$workingTemplate" 'sudo apt-get update'

    ## Install packages
    qubesRecipeRunSynchronously "$workingTemplate" 'sudo apt-get --yes install google-chrome-stable spotify-client'

    ## Teardown
    qubesRecipeTemplateTeardown "$workingTemplate"

    # Generate AppVMs
    qrLog "Creating AppVMs"
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
    qrLog "Starting Fedora recipe"

    # Clone new TemplateVM
    qrLog "Making exotic TemplateVM for third-party packages"
    local workingTemplate="$vanillaTemplateFedora"

    # Generate AppVMs
    qrLog "Creating AppVMs"
    # banking (online banking only)
    qubesRecipeTemplateNewApp "$workingTemplate" banking blue
    # vault (offline KeepassX storage; passwords, keys)
    local workingApp="vault"
    qubesRecipeTemplateNewApp "$workingTemplate" "$workingApp" black
    qubesRecipeAppRemoveNetwork "$workingApp"
}


# Main
qrLog "Running qubes-recipes"
qubesRecipeRecipeFedora
qubesRecipeRecipeFedoraExotic
qubesRecipeRecipeDebianExotic
