# Automated Git Tool
This tool was developed to align fork repositories with the changes made inside the original/template repository, useful in projects where there is a repository used for development and other repositories that have to be kept to date with the new changes. <br>

## Setup
- Clone all the repositories you need and set the original/template as a remote inside the forks.
- Paste in the config file the full paths to the repositories (the first is the path to the original/template, then there are the forks).

## How it works
Run the Powershell script and it will:
- Commit and push the new changes
- The script asks which repositories are to be aligned and which branches among main, develop and release have to be aligned (the branches can be easily changes in the script)
- The script was set to work with a protected main branch which needs a PR to be merged (a temporary branch is used to perform the merge)