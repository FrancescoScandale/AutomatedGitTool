set-psdebug -trace 1 #used to show in the command line the executed commands
#git config --global pager.branch false #paging could affect the behavior of the script
                                        #already set in my system

#getting the remote repositories
#config file uses global paths
$remoteRepos = @()
foreach($line in get-content .\config){
    $remoteRepos = $remoteRepos + $line
}
write-output "Remote repositories location: "
write-output $remoteRepos
write-output ""
write-output ""

#commit current changes
write-output "COMMIT CURRENT CHANGES"
$commitMessage = read-host "Insert the commit message"
git add .
git commit -m $commitMessage
git push
$modificationsBranch = git branch --show-current #retrieve current branch
write-output "Current branch: $modificationsBranch"
write-output ""
write-output ""

#merge into original branch
write-output "MERGE INTO THE EXISTING BRANCHES"
$allBranch = git branch
write-output "List of branches: $allBranch"

$flagBranchFound = 0
while(!$flagBranchFound){
    $originalBranch = read-host "Which branch do you want to merge?"
    
    #for all available branches
    foreach($branchI in $allBranch){
        if($branchI.contains($originalBranch)){
            $flagBranchFound = 1
            write-output "Valid branch: $originalBranch - flag: $flagBranchFound"
        }
    }

    if(!$flagBranchFound) {write-output "Branch not found, please insert a valid branch"}
}

git switch $originalBranch
git fetch
git pull
git merge $modificationsBranch
git push
write-output ""
write-output ""

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
    get-location

    $consent = read-host "Do you want to align this repo? [y or Y to proceed, any other key to skip]"
    if($consent.equals("y") -or $consent.equals("Y")){
        git fetch --all
        $keepMerging = 1
        while($keepMerging){
            $allBranch = git branch
            write-output "List of branches: $allBranch"
            $flagBranchFound = 0
            while(!$flagBranchFound){
                $originalBranch = read-host "Which branch do you want to merge?"
                
                #for all available branches
                foreach($branchI in $allBranch){
                    if($branchI.contains($originalBranch)){
                        $flagBranchFound = 1
                        write-output "Valid branch: $originalBranch - flag: $flagBranchFound"
                    }
                }

                if(!$flagBranchFound) {write-output "Branch not found, please insert a valid branch"}
            }
            git switch $originalBranch
            git fetch
            git pull

            #create the temporary branch and merge into it
            git branch $modificationsBranch #(check: if the result of this command is not empty, another branch already has this name -> need to create it with another name)
            git switch $modificationsBranch
            foreach($line in git remote){
                if($line -ne "origin"){
                    $parentRepo = $line
                }
            }
            $err = git merge $parentRepo/$modificationsBranch --allow-unrelated-histories
            if(!($err.contains("fatal") -or $err.contains("failed")) -and !($originalBranch.contains("main"))){
                git push

                #merge back into the original branch
                git switch $originalBranch
                git merge $modificationsBranch
                git branch -D $modificationsBranch #force the delete
            } elseif($err.contains("fatal") -or $err.contains("failed")){
                write-output "An error occurred, check the messages"
            } else { #can't merge into main, just push the temporary branch
                git push

                write-output "To merge back into main, need to create a pull request from GitHub"
            }

            $keepMerging = read-host "Do you want to merge another branch? [0 if no, 1 if yes]"
        }
    }
    
    write-output ""
    write-output ""
}

set-location ..\AutomatedGitTool


#chiedere prima di fare la modifica su ogni repo 
#(potrebbe voler essere fatta solo su un country)
    #chiedere su quale branch lo vuole portare 
        #(fai un while, potrebbe dover essere portato su più branch)
#quando chiedo se vuole allineare la realease di uno dei country, fai la merge
    #direttamente dal develop appena allineato
#controllo errori
#creazione delle pull-request direttamente da riga di comando?