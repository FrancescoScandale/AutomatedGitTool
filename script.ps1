set-psdebug -trace 0 # Used to show in the command line the executed commands
#git config --global pager.branch false #used to disable paging in "git branch" 
                                        #(paging could affect the behavior of the script)

$currentBranch = git branch --show-current
write-output "Current branch: $currentBranch"

$allBranch = git branch -a
write-output "List of branches: $allBranch"

$flagBranchFound = 0

while(!$flagBranchFound){
    $chosenBranch = read-host "Choose a branch to write into"
    write-output "Branch chosen: $chosenBranch"
    
    #for all available branches
    foreach($branchI in $allBranch){
        #assume branch is local, try to find it
        if($branchI.equals("$chosenBranch") -or $branchI.equals("* $chosenBranch")){
            $flagBranchFound = 1
            write-output "valid branch: $branchI - flag: $flagBranchFound"
        }
    }

    if(!$flagBranchFound) {write-output "Branch not found, please insert a valid branch"}
}



#git add .
#git commit -m "first try"
#git push