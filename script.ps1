set-psdebug -trace 1 # Used to show in the command line the executed commands
#git config --global pager.branch false #paging could affect the behavior of the script

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

$currentBranch = git branch --show-current
write-output "Current branch: $currentBranch"
write-output ""
write-output ""

write-output "MERGE REMOTE REPOSITORIES"
for($i=0;$i -lt $remoteRepos.Length; $i++){
    set-location $remoteRepos[$i]
    get-location
    git fetch --all
    git switch $currentBranch
    foreach($line in git remote){
        if($line -ne "origin"){
            $parentRepo = $line
        }
    }
    git merge $parentRepo/$currentBranch --allow-unrelated-histories

    write-output ""
    write-output ""
}

#$allBranch = git branch -a
#write-output "List of branches: $allBranch"

#$flagBranchFound = 0

#while(!$flagBranchFound){
    #$chosenBranch = read-host "Choose a branch to write into"
    #write-output "Branch chosen: $chosenBranch"
    
    ##for all available branches
    #foreach($branchI in $allBranch){
        ##assume branch is local, try to find it
        #if($branchI.equals("$chosenBranch") -or $branchI.equals("* $chosenBranch")){
            #$flagBranchFound = 1
            #write-output "valid branch: $branchI - flag: $flagBranchFound"
        #}
    #}

    #if(!$flagBranchFound) {write-output "Branch not found, please insert a valid branch"}
#}




##plan: i have changes here in the main repo on the branch X and have to merge them all
##into the branch develop. Then need to merge this branch develop into the children repos,
##in their own branch develop.
##Assumption: at the moment the branch exists in the remote branches:
    ##it does not have to be created by the script