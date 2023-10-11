#FINAL VERSION OF THE SCRIPT
#START FROM AN UN-COMMITTED BRANCH (POSSIBLY ALSO FROM A COMMITTED ONE)
#INSERT COMMIT MESSAGE, ADD, COMMIT, PUSH NEW BRANCH
#ASK INTO WHICH BRANCHES WE HAVE TO MERGE THE CURRENT ONE
#MERGE CURRENT BRANCH INTO THE CHOSEN ONES (AUTOMATICALLY CASCADING THE MERGE IN THE CHILD REPOSITORIES)

#set-psdebug -trace 0 #used to show in the command line the executed commands
#git config --global pager.branch false #paging could affect the behavior of the script (already set in my system)

#TODO: MAKE AN INPUT WHERE THE USER SAYS Y/N TO WHICH BRANCHES HE WANTS TO MERGE (ALSO MERGE IN THE CHILD REPOS)
#TODO: CHECK IF THERE IS A WAY TO REDIRECT GIT OUTPUT TO STDOUT INSTEAD OF STDERR
    #WOULD ALLOW TO SAVE IT INTO VARIABLES AND DISPLAY ONLY THE WANTED TEXT
function LocalMerge {
    param(
        [string]$mergeInto, [string]$mergeFrom
    )
                                        
    write-output "$mergeInto <- $mergeFrom"
    git switch $mergeInto
    git pull --quiet
                                        
    $err = git merge $mergeFrom
    write-output "Summary of the merge, merging and pushing... "
    if (!($err -like "*fatal*") -and !($err -like "*failed*")) {
        write-output "$err"
        git push --quiet
                                        
        write-output "... done"
    }
    else {
        write-output "ERROR - $err"
        write-output "...an error occurred, check the terminal"
    }
}
                                        
function TemporaryBranchCreation {
    param([string]$temporaryBranch)
                                        
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
    git switch $temporaryBranch
    git push -u origin $temporaryBranch --quiet
                                        
    return $temporaryBranch
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
$consentDevelop = read-host "Do you want to merge into branch ""develop""? [y/Y if yes, any other if no]"
$consentMain = read-host "Do you want to merge into branch ""main""? [y/Y if yes, any other if no]"
$consentRelease = read-host "Do you want to merge into branch ""release""? [y/Y if yes, any other if no]"

#ORIGIN REPOSITORY
write-output "ALIGN CURRENT REPOSITORY"
split-path -path $pwd -leaf
git fetch --all --prune --quiet
                                        
if ($consent.equals("y") -or $consent.equals("Y")) {
    LocalMerge "develop" $modificationsBranch
}
write-output ""
                                        
if ($consent.equals("y") -or $consent.equals("Y")) {
    write-output "Can't merge directly into main (needs a pull request from GitHub), need to create a temporary branch and merge into it."
    $temporaryBranch = ""
    $temporaryBranch = TemporaryBranchCreation $temporaryBranch
    LocalMerge $temporaryBranch $modificationsBranch
}
write-output ""
write-output ""
write-output ""
                                        
#REMOTE REPOSITORIES
write-output "ALIGN REMOTE REPOSITORIES"
for ($i = 1; $i -lt $remoteRepos.Length; $i++) {
    set-location $remoteRepos[$i]
    split-path -path $pwd -leaf
    git fetch --all --prune --quiet
                                        
    $needAlign = read-host "Do you want to align this repo? [y or Y to proceed, any other key to skip]"
    if ($needAlign.equals("y") -or $needAlign.equals("Y")) {
        $consent = read-host "Do you want to align the branch ""develop""? [y or Y if yes, any other if no]"
        if ($consent.equals("y") -or $consent.equals("Y")) {
            LocalMerge "develop" "$mainRepoName/develop"
        }
        write-output ""
                                        
        $consent = read-host "Do you want to merge into branch ""release/2""? [y or Y if yes, any other if no]"
        if ($consent.equals("y") -or $consent.equals("Y")) {
            LocalMerge "release/2" "develop"
        }
        write-output ""
                                        
        $consent = read-host "Do you want to merge into branch ""main""? [y or Y if yes, any other if no]"
        if ($consent.equals("y") -or $consent.equals("Y")) {
            write-output "Can't merge directly into main (needs a pull request from GitHub), need to create a temporary branch and merge into it."
            $temporaryBranch = ""
            $temporaryBranch = TemporaryBranchCreation $temporaryBranch
            LocalMerge $temporaryBranch "$mainRepoName/main"
        }
    }
    write-output ""
    write-output ""
}
                                        
set-location $remoteRepos[0]
git switch $modificationsBranch
                                        
$consent = read-host "If you want to delete the branch $modificationsBranch insert [y or Y if yes, any other if no]"
if ($consent.equals("y") -or $consent.equals("Y")) {
    if ($modificationsBranch.equals("main") -or $modificationsBranch.equals("develop") -or ($modificationsBranch -like "*release*")) {
        write-output "Can't delete this branch!"
    }
    else {
        git switch develop
        git branch -D $modificationsBranch #force the delete
        git push origin -d $modificationsBranch --quiet
    }
}
                                        