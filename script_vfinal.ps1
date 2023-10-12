#FINAL VERSION OF THE SCRIPT
#START FROM AN UN-COMMITTED AND UN-PUSHED BRANCH
#INSERT COMMIT MESSAGE, ADD, COMMIT, PUSH NEW BRANCH
#ASK INTO WHICH BRANCHES WE HAVE TO MERGE THE CURRENT ONE
#ASK WHICH REPOSITORIES HAVE TO BE ALIGNED
#ASK THE NAME OF THE TEMPORARY BRANCH IN CASE MAIN HAS TO BE MERGED
#MERGE CURRENT BRANCH INTO THE CHOSEN ONES (AUTOMATICALLY CASCADING THE MERGE IN THE CHILD REPOSITORIES)

#TODO: CHECK IF THERE IS A WAY TO REDIRECT GIT OUTPUT TO STDOUT INSTEAD OF STDERR
    #WOULD ALLOW TO SAVE IT INTO VARIABLES AND DISPLAY ONLY THE WANTED TEXT
#TODO: SIGNAL THAT THERE IS THE NEED TO HAVE THE TEMPLATE REPO AS REMOTE IN THE CHILDREN REPOS

set-psdebug -trace 0 #used to show in the command line the executed commands
#git config --global pager.branch false #paging could affect the behavior of the script (already set in my system)

function LocalMerge {
    param(
        [string]$mergeInto, [string]$mergeFrom
    )
    $mergeError = $false

    write-output "$mergeInto <- $mergeFrom"
    git switch $mergeInto
    git pull --quiet
    
    $err = git merge $mergeFrom
    write-output "Summary of the merge, merging and pushing... "
    write-output "$err"
    while (!$mergeError) {
        if (!($err -like "*fatal*") -and !($err -like "*failed*")) {
            git push --quiet
                                        
            write-output "... done"
            $mergeError = $true
        }
        else {
            write-output "AN ERROR OCCURRED!"
            write-output "Solve the conflict: suggestion is to use Visual Studio Code's git extension, which has an easy graphical interface."
            write-output "Just solve the conflict and save the file, this script will take care of the rest."
            read-host "Hit enter when ready"
            git add .
            git commit
        }
    }
}
                                        
function TemporaryMainBranchCreation {
    param()
                                        
    $allBranch = git branch -a
    $temporaryBranch = read-host "Insert the name for a temporary branch"
    $branchNotExists = $false
    while (!$branchNotExists) {
        #check if branch already exists
        foreach ($branchI in $allBranch) {
            if ($branchI.equals("  $temporaryBranch") -or $branchI.equals("* $temporaryBranch") -or $branchI.equals("  remotes/origin/$temporaryBranch")) {
                $branchNotExists = $true
                $temporaryBranch = read-host "A branch with the name $temporaryBranch alrady exists, provide a new temporary branch name"
                break
            }
        }
                                        
        if ($branchNotExists -eq $true) {
            #if branch found, repeat the control
            $branchNotExists = $false
        }
        else {
            $branchNotExists = $true
        }
    }
                                            
    git switch main --quiet
    git branch $temporaryBranch #create temporaryBranch
    git switch $temporaryBranch --quiet
    git push -u origin $temporaryBranch --quiet
                                        
    return $temporaryBranch
}

function TmpBranchCreation {
    param()

    git switch main
    git pull --quiet
    
    #use the same name as for the temporary branch in the template repository
    git branch $temporaryMainBranch
    git push origin -u $temporaryMainBranch
}
                                        
#getting the repositories from config file (which contains global paths)
$remoteRepos = @()
foreach ($line in get-content .\config) {
    $remoteRepos = $remoteRepos + $line
}
set-location $remoteRepos[0]
write-output "Current repository: "
split-path -path $pwd -leaf
write-output ""
write-output "Remote repositories location: "
write-output $remoteRepos
write-output ""
write-output ""
                                        
$mainRepoName = split-path -path $pwd -leaf
                                        
#commit current changes
write-output "COMMIT CURRENT CHANGES"
$modificationsBranch = git branch --show-current #retrieve current branch
write-output "Current branch: $modificationsBranch"
$commitMessage = read-host "Insert the commit message"
write-output "Git does add, commit and push..."
git add .
git commit -m $commitMessage --quiet
git push -u origin $modificationsBranch --quiet
write-output "... done"
write-output ""
write-output ""

#ask which branches need to be aligned
$consentMain = read-host "Do you want to merge into branch ""main""? [y/Y if yes, any other if no]"
if ($consentMain.equals("y") -or $consentMain.equals("Y")) {
    write-output "Can't merge directly into main (needs a pull request from GitHub), need to create a temporary branch and merge into it."
    $temporaryMainBranch = TemporaryMainBranchCreation
}
$consentDevelop = read-host "Do you want to merge into branch ""develop""? [y/Y if yes, any other if no]"
$consentRelease = read-host "Do you want to merge into branch ""release""? [y/Y if yes, any other if no]"
#ask which repos need to be aligned
$needAlign = @()
for ($i = 0; $i -lt $remoteRepos.Length; $i++){
    $currentRepo = ($remoteRepos[$i] -split '\\')[-1]
    $consent = read-host "Do you want to align repo ${currentRepo}? [y/Y to proceed, any other key to skip]"
    $needAlign = $needAlign + $consent
}
write-output ""
write-output ""
write-output ""

#ORIGIN REPOSITORY
write-output "ALIGN CURRENT REPOSITORY"
split-path -path $pwd -leaf
git fetch --all --prune --quiet
                                        
if ($consentDevelop.equals("y") -or $consentDevelop.equals("Y")) {
    LocalMerge "develop" $modificationsBranch
}
write-output ""
                                        
if ($consentMain.equals("y") -or $consentMain.equals("Y")) {
    LocalMerge $temporaryMainBranch $modificationsBranch
}
write-output ""
write-output ""
write-output ""
                                        
#REMOTE REPOSITORIES
write-output "ALIGN REMOTE REPOSITORIES"
for ($i = 1; $i -lt $remoteRepos.Length; $i++) {
    set-location $remoteRepos[$i]
    split-path -path $pwd -leaf
    
    if ($needAlign[$i].equals("y") -or $needAlign[$i].equals("Y")) {
        git fetch --all --prune --quiet
        if ($consentDevelop.equals("y") -or $consentDevelop.equals("Y")) {
            LocalMerge "develop" "${mainRepoName}/develop"
        }
        write-output ""
                                        
        if ($consentRelease.equals("y") -or $consentRelease.equals("Y")) {
            LocalMerge "release" "develop"
        }
        write-output ""
                                        
        if ($consentMain.equals("y") -or $consentMain.equals("Y")) {
            TmpBranchCreation
            LocalMerge $temporaryMainBranch "${mainRepoName}/${temporaryMainBranch}"
        }
    }
    write-output ""
    write-output ""
    write-output ""
}
                                        
set-location $remoteRepos[0]
git switch $modificationsBranch
                                        
$consent = read-host "Delete branch ${modificationsBranch}? [y/Y if yes, any other if no]"
if ($consent.equals("y") -or $consent.equals("Y")) {
    if ($modificationsBranch.equals("main") -or $modificationsBranch.equals("develop") -or ($modificationsBranch -like "*release*")) {
        write-output "Can't delete this branch!"
    }
    else {
        git switch main
        git branch -D $modificationsBranch #force the delete
        git push origin -d $modificationsBranch --quiet
    }
}