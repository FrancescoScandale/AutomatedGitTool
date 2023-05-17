## ALIAS UNIX <br>
cd -> set-location <br>
echo -> write-output <br>
ls -> dir, get-childitem <br>
mkdir -> new-item -name test -itemtype "directory" <br>
pwd -> get-location
rm -> remove-item <br>
touch -> new-item -name file.txt -itemtype "file" <br><br>

## COMMANDS
- Print environment variable
    - $env:envVarName
        - This gets just the content
    - get-childitem -path Env:envVarName
        - This gets name and content of the environment variable
- Print environment variable and split the values
    - $env:Path -split ';'
- Get properties of an object/variable (called "var")
    - get-member -inputobject var
- Get methods of an object/variable (called "var")
    - get-member -inputobject var -MemberType method
- Write (overwrite) a file (either existing or created on the spot)
    - "test if this works" | set-content -path content.txt -encoding utf8
    - "$var" | set-content -path content.txt -encoding utf8
- Write (append) a file
    - "test if this works" | add-content -path content.txt
    - "$var" | add-content -path content.txt

## GIT
- Merging from a remote branch
    - git merge RemoteRepoName/BranchName
    - If there is the error "fatal: unrelated histories"
        - git merge RemoteRepoName/BranchName --allow-unrelated-histories
- Disable paging in the branch command
    - git config --global pager.branch false
- Remove branches that have been deleted from remote repositories
    - git fetch -a -p
    - (i.e. git fetch --all --prune)