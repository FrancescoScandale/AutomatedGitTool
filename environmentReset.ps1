#!pwsh
#make sure it's executed in powershell

git switch main
git merge newtempmain
git push

git branch -D newtempmain
git push origin -d newtempmain

git switch test


Set-Location ..\AutomatedGitTool-1
git fetch --all --prune --quiet
git switch main
git merge AutomatedGitTool/main --quiet
git push --quiet

git branch -D newtempmain
git push origin -d newtempmain


Set-Location ..\AutomatedGitTool-2
git fetch --all --prune --quiet
git switch main
git merge AutomatedGitTool/main --quiet
git push --quiet

git branch -D newtempmain
git push origin -d newtempmain

set-location ..\AutomatedGitTool