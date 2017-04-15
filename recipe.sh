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

# Utility functions
echoerr() {
    echo -e "\e[96m$@\e[39m" 1>&2
}

# Clone new TemplateVMs for third-party software
exoticTemplateDebian="${vanillaTemplateDebian}-exotic2"
exoticTemplateFedora="${vanillaTemplateFedora}-exotic2"

function qubesRecipeClone {
    originalTemplateName="$1"
    cloneTemplateName="$2"
    echoerr "Cloning $originalTemplateName --> $cloneTemplateName"
    qvm-clone $originalTemplateName $cloneTemplateName
}

echoerr "Cloning base templates"
qubesRecipeCloneExotic "$vanillaTemplateDebian" "$exoticTemplateDebian"
#qubesRecipeCloneExotic "$vanillaTemplateFedora" "$exoticTemplateFedora"

# Adjust new TemplateVMs packages
function qubesRecipeRunSynchronously {
    targetQube="$1"
    targetCommand="$2"
    echoerr "Connecting to $targetQube to run '$targetCommand'"
    qvm-run --pass-io "$targetQube" "$targetCommand"
}
function qubesRecipeStart {
    targetQube="$1"
    echoerr "Starting $targetQube"
    qvm-start "$targetQube"
}
function qubesRecipeShutdown {
    targetQube="$1"
    echoerr "Shutting down $targetQube"
    qvm-shutdown "$targetQube"
}
function qubesRecipeFirewallPolicy {
    targetQube="$1"
    targetPolicy="$2"
    echoerr "Firewall for $targetQube set to '$targetPolicy'"
    qvm-firewall -P "$targetPolicy" "$targetQube"
}

# debian-8-exotic
# - juke (jukebox, media playback)

qubesRecipeStart "$exoticTemplateDebian"
qubesRecipeFirewallPolicy "$exoticTemplateDebian" "allow"

# Add new repos
## Add chrome repo
qubesRecipeRunSynchronously "$exoticTemplateDebian" 'wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add - && echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee -a /etc/apt/sources.list.d/google.list'

## Add spotify repo
qubesRecipeRunSynchronously "$exoticTemplateDebian" 'sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys BBEBDCB318AD50EC6865090613B00F1FD2C19886 && echo deb http://repository.spotify.com stable non-free | sudo tee /etc/apt/sources.list.d/spotify.list'

# Update package lists
qubesRecipeRunSynchronously "$exoticTemplateDebian" 'sudo apt-get update'

# Install packages
qubesRecipeRunSynchronously "$exoticTemplateDebian" 'sudo apt-get --yes install google-chrome-stable spotify-client'

qubesRecipeFirewallPolicy "$exoticTemplateDebian" "deny"
qubesRecipeShutdown "$exoticTemplateDebian"
