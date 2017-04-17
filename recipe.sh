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
function echoerr {
    echo -e "\e[96m$@\e[39m" 1>&2
}
function qubesRecipeClone {
    local originalTemplateName="$1"
    local cloneTemplateName="$2"
    echoerr "Cloning $originalTemplateName --> $cloneTemplateName"
    qvm-clone $originalTemplateName $cloneTemplateName
}
function qubesRecipeRunSynchronously {
    local targetQube="$1"
    local targetCommand="$2"
    echoerr "Connecting to $targetQube to run '$targetCommand'"
    qvm-run --pass-io "$targetQube" "$targetCommand"
}
function qubesRecipeStart {
    local targetQube="$1"
    echoerr "Starting $targetQube"
    qvm-start "$targetQube"
}
function qubesRecipeShutdown {
    local targetQube="$1"
    echoerr "Shutting down $targetQube"
    qvm-shutdown "$targetQube"
}
function qubesRecipeFirewallPolicy {
    local targetQube="$1"
    local targetPolicy="$2"
    echoerr "Firewall for $targetQube set to '$targetPolicy'"
    qvm-firewall -P "$targetPolicy" "$targetQube"
}
function qubesRecipeTemplateSetup {
    local targetQube="$1"
    echoerr "Setup $targetQube for customisation"
    qubesRecipeStart "$targetQube"
    qubesRecipeFirewallPolicy "$targetQube" "allow"
}
function qubesRecipeTemplateTeardown {
    local targetQube="$1"
    echoerr "Setup $targetQube for customisation"
    qubesRecipeFirewallPolicy "$targetQube" "deny"
    qubesRecipeShutdown "$targetQube"
}

# Subshell functions
function qubesRecipeSubTemplateNameExotic {
    # Run as subshell - stdout = exoticTemplateName
    local originalTemplateName="$1"
    local exoticTemplateName="${originalTemplateName}${exoticSuffix}"
    echoerr "Generated exotic template name $exoticTemplateName"
    echo "$exoticTemplateName"
}

# Recipes
function qubesRecipeRecipeDebianExotic {
    # Recipe for Debian based VMs
    echoerr "Starting Debian recipe"

    ## debian-8-exotic
    ### Clone new TemplateVM
    echoerr "Making exotic TemplateVM for third-party packages"
    local exoticTemplateDebian=$(qubesRecipeSubTemplateNameExotic "$vanillaTemplateDebian")
    qubesRecipeClone "$vanillaTemplateDebian" "$exoticTemplateDebian"

    #### Setup
    qubesRecipeTemplateSetup "$exoticTemplateDebian"

    #### Add new repos
    ##### Add chrome repo
    qubesRecipeRunSynchronously "$exoticTemplateDebian" 'wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add - && echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee -a /etc/apt/sources.list.d/google.list'

    ##### Add spotify repo
    qubesRecipeRunSynchronously "$exoticTemplateDebian" 'sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys BBEBDCB318AD50EC6865090613B00F1FD2C19886 && echo deb http://repository.spotify.com stable non-free | sudo tee /etc/apt/sources.list.d/spotify.list'

    #### Update package lists
    #qubesRecipeRunSynchronously "$exoticTemplateDebian" 'sudo apt-get update'

    #### Install packages
    qubesRecipeRunSynchronously "$exoticTemplateDebian" 'sudo apt-get --yes install google-chrome-stable spotify-client'

    #### Teardown
    qubesRecipeTemplateTeardown "$exoticTemplateDebian"

    ## Generate AppVMs
    echoerr "Creating AppVMs"
    ### juke (jukebox, media playback)
    qvm-create -t "$exoticTemplateDebian" -l orange juke
}
function qubesRecipeRecipeDebianExotic {
    # Recipe for Debian based VMs
    echoerr "Starting Debian recipe"

    ## debian-8-exotic
    ### Clone new TemplateVM
    echoerr "Making exotic TemplateVM for third-party packages"
    local exoticTemplateDebian=$(qubesRecipeSubTemplateNameExotic "$vanillaTemplateFedora")
    qubesRecipeClone "$vanillaTemplateFedora" "$exoticTemplateDebian"

    #### Setup
    qubesRecipeTemplateSetup "$exoticTemplateDebian"

    #### Add new repos
    ##### Add chrome repo
    qubesRecipeRunSynchronously "$exoticTemplateDebian" 'wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add - && echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee -a /etc/apt/sources.list.d/google.list'

    ##### Add spotify repo
    qubesRecipeRunSynchronously "$exoticTemplateDebian" 'sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys BBEBDCB318AD50EC6865090613B00F1FD2C19886 && echo deb http://repository.spotify.com stable non-free | sudo tee /etc/apt/sources.list.d/spotify.list'

    #### Update package lists
    #qubesRecipeRunSynchronously "$exoticTemplateDebian" 'sudo apt-get update'

    #### Install packages
    qubesRecipeRunSynchronously "$exoticTemplateDebian" 'sudo apt-get --yes install google-chrome-stable spotify-client'

    #### Teardown
    qubesRecipeTemplateTeardown "$exoticTemplateDebian"

    ## Generate AppVMs
    echoerr "Creating AppVMs"
    ### juke (jukebox, media playback)
    qvm-create -t "$exoticTemplateDebian" -l orange juke
}


# Main
echoerr "Running qubes-recipes"
#qubesRecipeRecipeDebianExotic
qubesRecipeRecipeFedoraExotic


