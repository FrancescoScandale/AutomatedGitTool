set-psdebug -trace 0 #used to show in the command line the executed commands
#git config --global pager.branch false #paging could affect the behavior of the script
                                        #already set in my system

#getting the remote repositories
#config file uses global paths
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
git push -u origin $modificationsBranch
git add .
git commit -m $commitMessage --porcelain
git push --porcelain
write-output "... done"
write-output ""
write-output ""

#ORIGIN REPOSITORY
write-output "MERGE INTO THE EXISTING BRANCHES"
split-path -path $pwd -leaf
git fetch --all

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
            #if($branchI.contains($originalBranch)){
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
    git fetch
    git pull

    $err = git merge $modificationsBranch
    if(!($err.contains("fatal") -or $err.contains("failed")) -and !($originalBranch.contains("main"))){
        git push --porcelain
        
        if(!$originalBranch.contains("release")){
            #merge back into the original branch
            git switch $originalBranch
            git merge $modificationsBranch
            git push --porcelain

            git branch -D $modificationsBranch #force the delete
            git push origin -d $modificationsBranch
        }

        write-output "... done"
    } elseif($err.contains("fatal") -or $err.contains("failed")){
        write-output "An error occurred, check the log"
    } else { #can't merge into main, just push the temporary branch
        git push --porcelain

        write-output "To merge back into main, need to create a pull request from GitHub"
    }
    write-output "... done"

    $keepMerging = read-host "Do you want to merge another branch? [y or Y if yes, any other if no]"    
    write-output ""
    write-output ""
}

#write-output "MERGE INTO A TEMPORARY BRANCH FROM THE MAIN BRANCH"
#$fromMain = read-host "What would you like to call the branch from main?"
#git switch main
#git fetch
#git pull
#git branch $fromMain
#git switch $fromMain
#git merge ###########
#git push -u origin $fromMain


#REMOTE REPOSITORIES
write-output "MERGE REMOTE REPOSITORIES"
for($i=0;$i -lt $remoteRepos.Length; $i++){

    set-location $remoteRepos[$i]
    split-path -path $pwd -leaf
    git fetch --all

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
                    #if($branchI.contains($originalBranch)){
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
            git fetch
            git pull

            if(!$originalBranch.contains("release")){
                #create the temporary branch and merge into it
                git branch $modificationsBranch #(check: if the result of this command is not empty, another branch already has this name -> need to create it with another name)
                git switch $modificationsBranch
                git push -u origin $modificationsBranch
            }
            write-output "... done"

            write-output "Merging from origin, pushing, deleting temporary branch..."
            if($originalBranch.contains("release")){ #if in release, merge directly the local (aligned) develop
                $err = git merge develop --allow-unrelated-histories
            } else {
                foreach($line in git remote){
                    if($line -ne "origin"){
                        $parentRepo = $line
                    }
                }
                $err = git merge $parentRepo/$modificationsBranch --allow-unrelated-histories
            }
            if(!($err.contains("fatal") -or $err.contains("failed")) -and !($originalBranch.contains("main"))){
                git push --porcelain
                
                if(!$originalBranch.contains("release")){
                    #merge back into the original branch
                    git switch $originalBranch
                    git merge $modificationsBranch
                    git push --porcelain

                    git branch -D $modificationsBranch #force the delete
                    git push origin -d $modificationsBranch
                }

                write-output "... done"
            } elseif($err.contains("fatal") -or $err.contains("failed")){
                write-output "An error occurred, check the log"
            } else { #can't merge into main, just push the temporary branch
                git push --porcelain

                write-output "To merge back into main, need to create a pull request from GitHub"
            }

            $keepMerging = read-host "Do you want to merge another branch? [y or Y if yes, any other if no]"
        }
    }
    
    write-output ""
    write-output ""
}

set-location ..\AutomatedGitTool
git switch $modificationsBranch