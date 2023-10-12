git switch main
git merge tempMain
git push

git branch -D tempMain
git push origin -d tempMain

git switch test


Set-Location ..\AutomatedGitTool-1
git fetch --all --prune --quiet
git switch main
git merge AutomatedGitTool/main --quiet
git push --quiet

git branch -D tempMain
git push origin -d tempMain


Set-Location ..\AutomatedGitTool-2
git fetch --all --prune --quiet
git switch main
git merge AutomatedGitTool/main --quiet
git push --quiet

git branch -D tempMain
git push origin -d tempMain

set-location ..\AutomatedGitTool