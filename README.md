# qubes-recipes

This recipe documents my current personal QubesOS setup,
and provides automated setup should I need to replicate it from scratch.

This recipe assumes local installation of the `fedora-23` and `debian-8` TemplateVMs.


## Installation

Download the repo (or just the shell script) to an AppVM

```
# clone repo
git clone https://github.com/tommilligan/qubes-recipes
# or download recipe only
wget https://raw.githubusercontent.com/tommilligan/qubes-recipes/master/recipe.sh
```


## Usage

For obvious reasons, qubes makes it non-trivial to run arbitary code as dom0.

To do so, dom0 asks the AppVM to read the contents of the recipe to `stdout`,
and we then pass this to bash to execute.

```
bash <(qvm-run --pass-io <src-vm> 'cat ~/Documents/qubes-recipe.sh')
```


