#set-psdebug -trace 0 #used to show in the command line the executed commands
#git config --global pager.branch false #paging could affect the behavior of the script
                                        #already set in my system

#getting the child repositories from config file (which contains the global paths)
$remoteRepos = @()
foreach($line in get-content .\config){
    $remoteRepos = $remoteRepos + $line
}
write-output "Current repository location: "
split-path -path $pwd -leaf
write-output ""
write-output "Remote repositories location: "
write-output $remoteRepos
write-output ""
write-output ""

#commit current changes
write-output "COMMIT CURRENT CHANGES"
$modificationsBranch = git branch --show-current #retrieve current branch
write-output "Current branch: $modificationsBranch"
$commitMessage = read-host "Insert the commit message"
write-output "Git does add, commit and push..."
git push -u origin $modificationsBranch --quiet
git add .
git commit -m $commitMessage --quiet
git push --quiet
write-output "... done"
write-output ""
write-output ""

#ORIGIN REPOSITORY
write-output "MERGE INTO THE EXISTING BRANCHES"
split-path -path $pwd -leaf
git fetch --all --quiet

$keepMerging = read-host "Do you want to merge branches in this repo? [y or Y if yes, any other if no]" 
while($keepMerging.equals("y") -or $keepMerging.equals("Y")){
    $allBranch = git branch
    write-output "List of branches:"
    git branch -a

    $flagBranchFound = 0
    while(!$flagBranchFound){
        $originalBranch = read-host "Which branch do you want to merge?"
        
        #for all available branches
        foreach($branchI in $allBranch){
            if($branchI.equals("  $originalBranch") -or $branchI.equals("* $originalBranch") -or $branchI.equals("  remotes/origin/$originalBranch")){
                $flagBranchFound = 1
                write-output "Valid branch: $originalBranch - flag: $flagBranchFound"
                break
            }
        }

        if(!$flagBranchFound) {write-output "Branch not found, please insert a valid branch"}
    }

    write-output "Switching into the branch, fetching, merging and pushing..."
    git switch $originalBranch
    git fetch --quiet
    git pull --quiet

    if($originalBranch -like "*release*"){ #if in release, merge directly the local (aligned) develop
        $err = git merge develop
    } else {
        $err = git merge $modificationsBranch
    }
    if(!($err -like "*fatal*") -and !($err -like "*failed*") -and !($originalBranch -like "*main*")){
        git push --quiet

        write-output "... done"
    } elseif(!(!($err -like "*fatal*") -and !($err -like "*failed*"))){
        write-output "ERROR - $err"
        write-output "...an error occurred, check the terminal"
    } else { #can't merge into main, just push the temporary branch
        git push --quiet

        write-output "...to merge back into main, need to create a pull request from GitHub"
    }
    write-output ""

    $keepMerging = read-host "Do you want to merge another branch? [y or Y if yes, any other if no]"    
}

write-output ""
write-output ""

#REMOTE REPOSITORIES
write-output "MERGE REMOTE REPOSITORIES"
for($i=0;$i -lt $remoteRepos.Length; $i++){

    set-location $remoteRepos[$i]
    split-path -path $pwd -leaf
    git fetch --all --quiet

    $consent = read-host "Do you want to align this repo? [y or Y to proceed, any other key to skip]"
    if($consent.equals("y") -or $consent.equals("Y")){
        $keepMerging = "y"
        while($keepMerging.equals("y") -or $keepMerging.equals("Y")){
            $allBranch = git branch -a
            write-output "List of branches:"
            git branch -a

            $flagBranchFound = 0
            while(!$flagBranchFound){
                $originalBranch = read-host "Which branch do you want to merge?"
                
                #for all available branches
                foreach($branchI in $allBranch){
                    if($branchI.equals("  $originalBranch") -or $branchI.equals("* $originalBranch") -or $branchI.equals("  remotes/origin/$originalBranch")){
                        $flagBranchFound = 1
                        write-output "Valid branch: $originalBranch - flag: $flagBranchFound"
                        break
                    }
                }

                if(!$flagBranchFound) {write-output "Branch not found, please insert a valid branch"}
            }
            write-output "Switching into the branch, creating a temporary branch, switching into it..."
            git switch $originalBranch
            git fetch --quiet
            git pull --quiet

            if(!($originalBranch -like "*release*")){
                #create the temporary branch and merge into it
                $temporaryBranch = $modificationsBranch
                $branchNotExists = $false
                while(!$branchNotExists){ #check if branch already exists
                    foreach($branchI in $allBranch){
                        if($branchI.equals("  $temporaryBranch") -or $branchI.equals("* $temporaryBranch") -or $branchI.equals("  remotes/origin/$temporaryBranch")){
                            $branchNotExists = $true
                            $temporaryBranch = read-host "A branch with the name $temporaryBranch alrady exists, provide a new temporary branch name"
                            break
                        }
                    }

                    write-output "INSIDE1 - $branchNotExists"

                    if($branchNotExists -eq $true){ #if branch found, repeat the control
                        $branchNotExists = $false
                    }

                    write-output "INSIDE2 - $branchNotExists"
                }
                git branch $temporaryBranch
                git switch $temporaryBranch
                git push -u origin $temporaryBranch --quiet
            }
            write-output "... done"

            write-output "Merging from origin, pushing, deleting temporary branch..."
            if($originalBranch -like "*release*"){ #if in release, merge directly the local (aligned) develop
                $err = git merge develop --allow-unrelated-histories
            } else {
                foreach($line in git remote){
                    if($line -ne "origin"){
                        $parentRepo = $line
                    }
                }
                $err = git merge $parentRepo/$modificationsBranch --allow-unrelated-histories
            }
            if(!($err -like "*fatal*") -and !($err -like "*failed*") -and !($originalBranch -like "*main*")){
                git push --quiet

                if(!($originalBranch -like "*release*")){
                    #merge back into the original branch
                    git switch $originalBranch
                    git merge $temporaryBranch --quiet
                    git push --quiet
                    
                    #delete temporary branch
                    git branch -D $temporaryBranch #force the delete
                    git push origin -d $temporaryBranch --quiet
                }

                write-output "... done"
            } elseif(!(!($err -like "*fatal*") -and !($err -like "*failed*"))){
                write-output "ERROR - $err"
                write-output "...an error occurred, check the terminal"
            } else { #can't merge into main, just push the temporary branch
                git push --quiet

                write-output "ERROR - $err"
                write-output "...to merge back into main, need to create a pull request from GitHub"
            }

            write-output ""
            $keepMerging = read-host "Do you want to merge another branch? [y or Y if yes, any other if no]"
        }
    }
    
    write-output ""
    write-output ""
}

set-location ..\AutomatedGitTool
git switch $modificationsBranch

$consent = read-host "If you want to delete the branch $modificationsBranch insert [y or Y if yes, any other if no]"
if($consent.equals("y") -or $consent.equals("Y")){
    if($modificationsBranch.equals("main") -or $modificationsBranch.equals("develop") -or ($modificationsBranch -like "*release*")){
        write-output "Can't delete this branch!"
    } else {
        git switch develop
        git branch -D $modificationsBranch #force the delete
        git push origin -d $modificationsBranch --quiet
    }
}