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
write-output "MERGE INTO ORIGINAL BRANCH"
$allBranch = git branch
write-output "List of branches: $allBranch"

$flagBranchFound = 0
while(!$flagBranchFound){
    $originalBranch = read-host "From which branch did you create this one?"
    
    #for all available branches
    foreach($branchI in $allBranch){
        if($branchI.equals("$originalBranch") -or $branchI.equals("* $originalBranch")){
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
    git fetch --all

    git branch $modificationsBranch #create the temporary branch if not available
    git switch $modificationsBranch
    git fetch
    git pull
    foreach($line in git remote){
        if($line -ne "origin"){
            $parentRepo = $line
        }
    }
    git merge $parentRepo/$modificationsBranch --allow-unrelated-histories
    git push

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