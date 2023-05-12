## ALIAS UNIX <br>
cd -> set-location <br>
echo -> write-output <br>
ls -> dir, get-childitem <br>
mkdir -> new-item -name test -itemtype "directory" <br>
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