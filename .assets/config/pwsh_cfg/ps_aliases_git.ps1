#region helper functions
<#
.SYNOPSIS
Prints the command passed as the parameter and then executes it.
#>
function Invoke-PrintRunCommand {
    Write-Host "$args" -ForegroundColor Magenta
    Invoke-Expression @args
}
#endregion

#region git functions
function ga { Invoke-PrintRunCommand 'git add' }
function gaa { Invoke-PrintRunCommand 'git add --all' }
function gapa { Invoke-PrintRunCommand 'git add --patch' }
function gau { Invoke-PrintRunCommand 'git add --update' }
function gb { Invoke-PrintRunCommand 'git branch' }
function gba { Invoke-PrintRunCommand 'git branch -a' }
function gbd { Invoke-PrintRunCommand 'git branch -d' }
function gbda {
    Write-Host 'git branch --no-color --merged --delete' -ForegroundColor Magenta
    git branch --no-color --merged `
    | Select-String -NotMatch '^(\*|\s*(main|master|qa|develop|dev)\s*$)' `
    | ForEach-Object {
        git branch --delete $_
    }
}
function gbl { Invoke-PrintRunCommand 'git blame -b -w' }
function gbnm { Invoke-PrintRunCommand 'git branch --no-merged' }
function gbr { Invoke-PrintRunCommand 'git branch --remote' }
function gbs { Invoke-PrintRunCommand 'git bisect' }
function gbsb { Invoke-PrintRunCommand 'git bisect bad' }
function gbsg { Invoke-PrintRunCommand 'git bisect good' }
function gbsr { Invoke-PrintRunCommand 'git bisect reset' }
function gbss { Invoke-PrintRunCommand 'git bisect start' }
function gc { Invoke-PrintRunCommand 'git commit -v' }
function gc! { Invoke-PrintRunCommand 'git commit -v --amend' }
function gca { Invoke-PrintRunCommand 'git commit -v -a' }
function gca! { Invoke-PrintRunCommand 'git commit -v -a --amend' }
function gcam { Invoke-PrintRunCommand 'git commit -a -m' }
function gcan! { Invoke-PrintRunCommand 'git commit -v -a --no-edit --amend' }
function gcans! { Invoke-PrintRunCommand 'git commit -v -a -s --no-edit --amend' }
function gcb { Invoke-PrintRunCommand 'git checkout -b' }
function gcf { Invoke-PrintRunCommand 'git config --list' }
function gcl { Invoke-PrintRunCommand 'git clone --recursive' }
function gclean { Invoke-PrintRunCommand 'git clean -fd' }
function gcmsg { Invoke-PrintRunCommand 'git commit -m' }
function gcn! { Invoke-PrintRunCommand 'git commit -v --no-edit --amend' }
function gco { Invoke-PrintRunCommand 'git checkout' }
function gcount { Invoke-PrintRunCommand 'git shortlog -sn' }
function gcp { Invoke-PrintRunCommand 'git cherry-pick' }
function gcpa { Invoke-PrintRunCommand 'git cherry-pick --abort' }
function gcpc { Invoke-PrintRunCommand 'git cherry-pick --continue' }
function gcps { Invoke-PrintRunCommand 'git cherry-pick -s' }
function gcs { Invoke-PrintRunCommand 'git commit -S' }
function gcsm { Invoke-PrintRunCommand 'git commit -s -m' }
function gd { Invoke-PrintRunCommand 'git diff' }
function gdca { Invoke-PrintRunCommand 'git diff --cached' }
function gdct { Invoke-PrintRunCommand "git describe --tags 'git rev-list --tags --max-count=1'" }
function gdt { Invoke-PrintRunCommand 'git diff-tree --no-commit-id --name-only -r' }
function gdw { Invoke-PrintRunCommand 'git diff --word-diff' }
function gf { Invoke-PrintRunCommand 'git fetch' }
function gfa { Invoke-PrintRunCommand 'git fetch --all --prune' }
function gfo { Invoke-PrintRunCommand 'git fetch origin' }
function ggpull { Invoke-PrintRunCommand "git pull origin $(git_current_branch)" }
function ggpur { Invoke-PrintRunCommand 'ggu' }
function ggpush { Invoke-PrintRunCommand "git push origin $(git_current_branch)" }
function ggsup { Invoke-PrintRunCommand "git branch --set-upstream-to=origin/$(git_current_branch)" }
function ghh { Invoke-PrintRunCommand 'git help' }
function gignore { Invoke-PrintRunCommand 'git update-index --assume-unchanged' }
function gignored { Invoke-PrintRunCommand "git ls-files -v | grep '^[[:lower:]]'" }
function gpl { Invoke-PrintRunCommand 'git pull' }
function glg { Invoke-PrintRunCommand 'git log --stat' }
function glgg { Invoke-PrintRunCommand 'git log --graph' }
function glgga { Invoke-PrintRunCommand 'git log --graph --decorate --all' }
function glgm { Invoke-PrintRunCommand 'git log --graph --max-count=10' }
function glgp { Invoke-PrintRunCommand 'git log --stat -p' }
function glo {
    Write-Host 'git log --pretty' -ForegroundColor Magenta
    "Commit`u{00A6}Subject`u{00A6}Author`u{00A6}Date", (git log --pretty=format:"%h`u{00A6}%s`u{00A6}%an <%ae>`u{00A6}%ai") `
    | ConvertFrom-Csv -Delimiter "`u{00A6}" `
    | Select-Object Commit, Subject, Author, @{ Name = 'Date'; Expression = { [System.DateTimeOffset]$_.Date } } `
    | Sort-Object Date
}
function glog { Invoke-PrintRunCommand 'git log --oneline --decorate --graph' }
function gloga { Invoke-PrintRunCommand 'git log --oneline --decorate --graph --all' }
function glol { Invoke-PrintRunCommand "git log --graph --pretty='%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit" }
function glola { Invoke-PrintRunCommand "git log --graph --pretty='%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --all" }
function glum { Invoke-PrintRunCommand 'git pull upstream master' }
function gm { Invoke-PrintRunCommand 'git merge' }
function gmom { Invoke-PrintRunCommand 'git merge origin/master' }
function gmt { Invoke-PrintRunCommand 'git mergetool --no-prompt' }
function gmtvim { Invoke-PrintRunCommand 'git mergetool --no-prompt --tool=vimdiff' }
function gmum { Invoke-PrintRunCommand 'git merge upstream/master' }
function gp { Invoke-PrintRunCommand 'git push' }
function gpd { Invoke-PrintRunCommand 'git push --dry-run' }
function gpoat { Invoke-PrintRunCommand 'git push origin --all && git push origin --tags' }
function gpristine { Invoke-PrintRunCommand 'git reset --hard && git clean -dfx' }
function gpsup { Invoke-PrintRunCommand "git push --set-upstream origin $(git_current_branch)" }
function gpu { Invoke-PrintRunCommand 'git push upstream' }
function gpv { Invoke-PrintRunCommand 'git push -v' }
function gr { Invoke-PrintRunCommand 'git remote' }
function gra { Invoke-PrintRunCommand 'git remote add' }
function grb { Invoke-PrintRunCommand 'git rebase' }
function grba { Invoke-PrintRunCommand 'git rebase --abort' }
function grbc { Invoke-PrintRunCommand 'git rebase --continue' }
function grbi { Invoke-PrintRunCommand 'git rebase -i' }
function grbm { Invoke-PrintRunCommand 'git rebase master' }
function grbs { Invoke-PrintRunCommand 'git rebase --skip' }
function grh { Invoke-PrintRunCommand 'git reset HEAD' }
function grhh { Invoke-PrintRunCommand 'git reset HEAD --hard' }
function grmv { Invoke-PrintRunCommand 'git remote rename' }
function grrm { Invoke-PrintRunCommand 'git remote remove' }
function grset { Invoke-PrintRunCommand 'git remote set-url' }
function grt { Invoke-PrintRunCommand "Set-Location $(git rev-parse --show-toplevel || Write-Output '.')" }
function gru { Invoke-PrintRunCommand 'git reset --' }
function grup { Invoke-PrintRunCommand 'git remote update' }
function grv { Invoke-PrintRunCommand 'git remote -v' }
function gsb { Invoke-PrintRunCommand 'git status -sb' }
function gsd { Invoke-PrintRunCommand 'git svn dcommit' }
function gsi { Invoke-PrintRunCommand 'git submodule init' }
function gsps { Invoke-PrintRunCommand 'git show --pretty=short --show-signature' }
function gsr { Invoke-PrintRunCommand 'git svn rebase' }
function gss { Invoke-PrintRunCommand 'git status -s' }
function gst { Invoke-PrintRunCommand 'git status' }
function gsta { Invoke-PrintRunCommand 'git stash save' }
function gstaa { Invoke-PrintRunCommand 'git stash apply' }
function gstc { Invoke-PrintRunCommand 'git stash clear' }
function gstd { Invoke-PrintRunCommand 'git stash drop' }
function gstl { Invoke-PrintRunCommand 'git stash list' }
function gstp { Invoke-PrintRunCommand 'git stash pop' }
function gsts { Invoke-PrintRunCommand 'git stash show --text' }
function gsu { Invoke-PrintRunCommand 'git submodule update' }
function gswd {
    $branch = "$((git branch -a --format='%(refname:short)') -match '\bdev\b|\bdevelop\b' | Select-Object -First 1)".Replace('origin/', '')
    Invoke-PrintRunCommand "git checkout $branch"
}
function gswm {
    $branch = "$((git branch -a --format='%(refname:short)') -match '\bmain\b|\bmaster\b' | Select-Object -First 1)".Replace('origin/', '')
    Invoke-PrintRunCommand "git checkout $branch"
}
function gts { Invoke-PrintRunCommand 'git tag -s' }
function gtv { Invoke-PrintRunCommand 'git tag | Sort-Object -V' }
function gunignore { Invoke-PrintRunCommand 'git update-index --no-assume-unchanged' }
function gunwip { Invoke-PrintRunCommand "git log -n 1 | grep -q -c '\-\-wip\-\-' && git reset HEAD~1" }
function gup { Invoke-PrintRunCommand 'git pull --rebase' }
function gupa { Invoke-PrintRunCommand 'git pull --rebase --autostash' }
function gupav { Invoke-PrintRunCommand 'git pull --rebase --autostash -v' }
function gupv { Invoke-PrintRunCommand 'git pull --rebase -v' }
function gwch { Invoke-PrintRunCommand 'git whatchanged -p --abbrev-commit --pretty=medium' }
function gwip { Invoke-PrintRunCommand "git add -A; git rm $(git ls-files --deleted) 2>/dev/null; git commit --no-verify -m '--wip-- [skip ci]'" }
#endregion
