#!pwsh
#make sure it's executed in powershell


#FINAL VERSION OF THE SCRIPT. BEHAVIOUR:
#START FROM AN UN-COMMITTED AND UN-PUSHED BRANCH
#INSERT COMMIT MESSAGE, ADD, COMMIT, PUSH NEW BRANCH
#ASK INTO WHICH BRANCHES WE HAVE TO MERGE THE CURRENT ONE
#ASK THE NAME OF THE TEMPORARY BRANCH IN CASE MAIN HAS TO BE MERGED
#ASK WHICH REPOSITORIES HAVE TO BE ALIGNED
#MERGE CURRENT BRANCH INTO THE CHOSEN ONES (AUTOMATICALLY CASCADING THE MERGE IN THE CHILD REPOSITORIES)

#set-psdebug -trace 0 #used to show in the command line the executed commands
#git config --global pager.branch false #paging could affect the behavior of the script

function LocalMerge {
    param(
        [string]$mergeInto, [string]$mergeFrom
    )

    write-output "$mergeInto <- $mergeFrom"
    git switch $mergeInto
    git pull --quiet
    
    $err = git merge $mergeFrom --no-edit
    write-output "Summary of the merge, merging and pushing... "
    write-output "$err"
    if (($err -like "*fatal*") -or ($err -like "*failed*")) {
        write-output "AN ERROR OCCURRED!"
        write-output "Solve the conflict: suggestion is to use Visual Studio Code's git extension, which has an easy graphical interface."
        write-output "Just solve the conflict and save the file, this script will take care of the rest."
        read-host "Hit enter when ready"
        git add .
        git commit
    }

    git push --quiet
            
    write-output "... done"
}

function TemporaryMainBranchCreation {
    param()
    
    git fetch --all --prune --quiet
    $allBranch = git branch -a
    $temporaryBranch = read-host "Insert the name for a temporary branch"
    $branchNotExists = $false
    while (!$branchNotExists) {
        #check if branch already exists
        foreach ($branchI in $allBranch) {
            if ($branchI.equals("  $temporaryBranch") -or $branchI.equals("* $temporaryBranch") -or $branchI.equals("  remotes/origin/$temporaryBranch")) {
                write-output "A branch with the name $temporaryBranch alrady exists"

                $consentBranch = read-host "Do you want to use it anyway? [y/Y if yes, any other if no]"
                if ($consentBranch.equals("y") -or $consentBranch.equals("Y")) {
                    #branch already exists, just need to pull it to get all changes
                    git switch $temporaryBranch --quiet
                    git pull --quiet
                    return $temporaryBranch
                }
                else {
                    #branch already exists but it's not to be used
                    $branchNotExists = $true
                    $temporaryBranch = read-host "Insert another name for a temporary branch"
                }
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
    git pull --quiet
    git branch $temporaryBranch #create temporaryBranch
    git push -u origin $temporaryBranch --quiet
    
    return $temporaryBranch
}

function TmpBranchCreation {
    param()

    #use the same name as for the temporary branch in the template repository

    $allBranch = git branch -a
    foreach ($branchI in $allBranch) {
        if ($branchI.equals("  $temporaryMainBranch") -or $branchI.equals("* $temporaryMainBranch") -or $branchI.equals("  remotes/origin/$temporaryMainBranch")) {
            #if branch already exists, just need to pull it to get all changes
            git switch $temporaryMainBranch --quiet
            git pull --quiet
            return
        }
    }

    #if branch does not exist
    git switch main --quiet
    git pull --quiet
    git branch $temporaryMainBranch
    git push origin -u $temporaryMainBranch --quiet
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
for ($i = 1; $i -lt $remoteRepos.Length; $i++) {
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
    
    if ($needAlign[$i - 1].equals("y") -or $needAlign[$i - 1].equals("Y")) {
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
git switch main

$consent = read-host "Delete branch ${modificationsBranch}? [y/Y if yes, any other if no]"
if ($consent.equals("y") -or $consent.equals("Y")) {
    if ($modificationsBranch.equals("main") -or $modificationsBranch.equals("develop") -or ($modificationsBranch -like "*release*")) {
        write-output "Can't delete this branch!"
    }
    else {
        git branch -D $modificationsBranch
        git push origin -d $modificationsBranch
    }
}