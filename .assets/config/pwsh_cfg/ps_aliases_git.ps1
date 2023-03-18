#region helper functions
<#
.SYNOPSIS
Get current branch name.
#>
function Get-GitCurrentBranch {
    git branch --show-current
}

<#
.SYNOPSIS
Resolve main, dev, stage branch names.

.PARAMETER BranchName
Name of the branch to switch to.
#>
function Get-GitResolvedBranch ([string]$BranchName) {
    begin {
        $branchMatch = switch ($BranchName) {
            '' { '(^|/)dev(|el|elop|elopment)$|(^|/)ma(in|ster)$|(^|/)trunk$' }
            d { '(^|/)dev(|el|elop|elopment)$' }
            m { '(^|/)ma(in|ster)$' }
            s { '(^|/)stage$' }
            t { '(^|/)trunk$' }
            Default { $BranchName }
        }
    }
    process {
        $branch = $(git branch -a --format='%(refname:short)').Replace('origin/', '') `
        | Select-String $branchMatch -Raw `
        | Sort-Object -Unique `
        | Select-Object -First 1
        if (-not $branch) {
            Write-Host "invalid reference: $BranchName"
            break
        }
    }
    end {
        return $branch
    }
}

<#
.SYNOPSIS
Get git log object.

.PARAMETER All
Switch whether to get all commits, otherwise only last 50 will be shown.
.PARAMETER Quiet
Switch whether to write command.
#>
function Get-GitLogObject {
    param (
        [switch]$All,

        [switch]$Quiet
    )
    $cmd = "git log --pretty=format:`"%h`f%ai`f%s`f%an <%ae>`"$($All ? '' : ' -50')"
    if (-not $Quiet) {
        Write-Host $cmd.Replace("`f", '`f') -ForegroundColor Magenta
    }
    [string[]]$commit = Invoke-Expression $cmd
    if ($commit) {
        @("Commit`fDate`fSubject`fAuthor", $commit) `
        | ConvertFrom-Csv -Delimiter "`f" `
        | Select-Object Commit, @{ Name = 'DateUTC'; Expression = { [TimeZoneInfo]::ConvertTimeToUtc($_.Date).ToString('s') } }, Subject, Author `
        | Sort-Object DateUTC
    }
}

<#
.SYNOPSIS
Clean local branches.

.PARAMETER DeleteNoMerged
Switch whether to delete no merged branches.
.PARAMETER WhatIf
Switch whether to see what the command would have done instead of making changes.
#>
function Remove-GitLocalBranches {
    param (
        [switch]$DeleteNoMerged,

        [switch]$WhatIf
    )
    begin {
        # *switch to dev/main branch
        git switch $(Get-GitResolvedBranch)
        # *update repo
        git remote update origin --prune
        if (git status -b --porcelain | Select-String 'behind' -Quiet) {
            git pull --rebase
        }
    }
    process {
        # *get list of branches
        filter branchFilter { $_.Where({ $_ -notmatch '^ma(in|ster)$|^dev(|el|elop)$|^qa$|^stage$|^trunk$' }) }
        $merged = git branch --format='%(refname:short)' --merged | branchFilter
        # *delete branches
        foreach ($branch in $merged) {
            $param = @{ Command = "git branch --delete $branch" }
            if ($WhatIf) {
                $param.Arguments = '-WhatIf'
            }
            Invoke-WriteExecuteCommand @param
        }
        if ($DeleteNoMerged) {
            $no_merged = git branch --format='%(refname:short)' --no-merged | branchFilter
            foreach ($branch in $no_merged) {
                if ((Read-Host -Prompt "Do you want to remove branch: `e[1;97m$branch`e[0m? [y/N]") -eq 'y') {
                    $param = @{ Command = "git branch -D $branch" }
                    if ($WhatIf) {
                        $param.Arguments = '-WhatIf'
                    }
                    Invoke-WriteExecuteCommand @param
                }
            }
        }
    }
}
#endregion

#region function aliases
Set-Alias -Name ggcb -Value Get-GitCurrentBranch
Set-Alias -Name gglo -Value Get-GitLogObject
Set-Alias -Name ggrb -Value Get-GitResolvedBranch
Set-Alias -Name gbda -Value Remove-GitLocalBranches
#endregion

#region alias functions
function ga { Invoke-WriteExecuteCommand -Command 'git add' -Arguments $args }
function gaa { Invoke-WriteExecuteCommand -Command 'git add --all' -Arguments $args }
function gapa { Invoke-WriteExecuteCommand -Command 'git add --patch' -Arguments $args }
function gau { Invoke-WriteExecuteCommand -Command 'git add --update' -Arguments $args }
function gb { Invoke-WriteExecuteCommand -Command 'git branch' -Arguments $args }
function gba { Invoke-WriteExecuteCommand -Command 'git branch -a' -Arguments $args }
function gbd { Invoke-WriteExecuteCommand -Command 'git branch -d' -Arguments $args }
function gbl { Invoke-WriteExecuteCommand -Command 'git blame -b -w' -Arguments $args }
function gbnm { Invoke-WriteExecuteCommand -Command 'git branch --no-merged' -Arguments $args }
function gbr { Invoke-WriteExecuteCommand -Command 'git branch --remote' -Arguments $args }
function gbs { Invoke-WriteExecuteCommand -Command 'git bisect' -Arguments $args }
function gbsb { Invoke-WriteExecuteCommand -Command 'git bisect bad' -Arguments $args }
function gbsg { Invoke-WriteExecuteCommand -Command 'git bisect good' -Arguments $args }
function gbsr { Invoke-WriteExecuteCommand -Command 'git bisect reset' -Arguments $args }
function gbss { Invoke-WriteExecuteCommand -Command 'git bisect start' -Arguments $args }
function gc { Invoke-WriteExecuteCommand -Command 'git commit -v' -Arguments $args }
function gc! { Invoke-WriteExecuteCommand -Command 'git commit -v --amend' -Arguments $args }
function gca { Invoke-WriteExecuteCommand -Command 'git commit -v -a' -Arguments $args }
function gca! { Invoke-WriteExecuteCommand -Command 'git commit -v -a --amend' -Arguments $args }
function gcam { Invoke-WriteExecuteCommand -Command 'git commit -a -m' -Arguments $args }
function gcamp {
    Invoke-WriteExecuteCommand -Command 'git commit -a -m' -Arguments $args
    $param = @{ Command = "git push origin $(Get-GitCurrentBranch)" }
    if ('-WhatIf' -in $args) {
        $param.Arguments = '-WhatIf'
    }
    Invoke-WriteExecuteCommand @param
}
function gcan! { Invoke-WriteExecuteCommand -Command 'git commit -v -a --no-edit --amend' -Arguments $args }
function gcanp! {
    Invoke-WriteExecuteCommand -Command 'git commit -v -a --no-edit --amend' -Arguments $args
    $param = @{ Command = "git push origin $(Get-GitCurrentBranch) --force" }
    if ('-WhatIf' -in $args) {
        $param.Arguments = '-WhatIf'
    }
    Invoke-WriteExecuteCommand @param
}
function gcans! { Invoke-WriteExecuteCommand -Command 'git commit -v -a -s --no-edit --amend' -Arguments $args }
function gcb { Invoke-WriteExecuteCommand -Command 'git checkout -b' -Arguments $args }
function gcf { Invoke-WriteExecuteCommand -Command 'git config --list' -Arguments $args }
function gcl { Invoke-WriteExecuteCommand -Command 'git clone --recursive' -Arguments $args }
function gclean { Invoke-WriteExecuteCommand -Command 'git clean -fd' -Arguments $args }
function gcmsg { Invoke-WriteExecuteCommand -Command 'git commit -m' -Arguments $args }
function gcn! { Invoke-WriteExecuteCommand -Command 'git commit -v --no-edit --amend' -Arguments $args }
function gcnp! { Invoke-WriteExecuteCommand -Command 'git commit -v --no-edit --amend' -Arguments $args }
function gco { Invoke-WriteExecuteCommand -Command 'git checkout' -Arguments $args }
function gcount { Invoke-WriteExecuteCommand -Command 'git shortlog -sn' -Arguments $args }
function gcp { Invoke-WriteExecuteCommand -Command 'git cherry-pick' -Arguments $args }
function gcpa { Invoke-WriteExecuteCommand -Command 'git cherry-pick --abort' -Arguments $args }
function gcpc { Invoke-WriteExecuteCommand -Command 'git cherry-pick --continue' -Arguments $args }
function gcps { Invoke-WriteExecuteCommand -Command 'git cherry-pick -s' -Arguments $args }
function gcs { Invoke-WriteExecuteCommand -Command 'git commit -S' -Arguments $args }
function gcsm { Invoke-WriteExecuteCommand -Command 'git commit -s -m' -Arguments $args }
function gd { Invoke-WriteExecuteCommand -Command 'git diff' -Arguments $args }
function gdca { Invoke-WriteExecuteCommand -Command 'git diff --cached' -Arguments $args }
function gdct { Invoke-WriteExecuteCommand -Command 'git describe --tags `git rev-list --tags --max-count=1`' -Arguments $args }
function gdt { Invoke-WriteExecuteCommand -Command 'git diff-tree --no-commit-id --name-only -r' -Arguments $args }
function gdw { Invoke-WriteExecuteCommand -Command 'git diff --word-diff' -Arguments $args }
function gf { Invoke-WriteExecuteCommand -Command 'git fetch' -Arguments $args }
function gfa { Invoke-WriteExecuteCommand -Command 'git fetch --all --prune' -Arguments $args }
function gfo { Invoke-WriteExecuteCommand -Command 'git fetch origin' -Arguments $args }
function gg { Invoke-WriteExecuteCommand -Command 'git gui citool' -Arguments $args }
function gga { Invoke-WriteExecuteCommand -Command 'git gui citool --amend' -Arguments $args }
function ggr { Invoke-WriteExecuteCommand -Command 'git grep --ignore-case' -Arguments $args }
function ggre { Invoke-WriteExecuteCommand -Command 'git grep --ignore-case --extended-regexp' -Arguments $args }
function ggrp { Invoke-WriteExecuteCommand -Command 'git grep --ignore-case --perl-regexp' -Arguments $args }
function ghh { Invoke-WriteExecuteCommand -Command 'git help' -Arguments $args }
function gignore { Invoke-WriteExecuteCommand -Command 'git update-index --assume-unchanged' -Arguments $args }
function gignored { Invoke-WriteExecuteCommand -Command 'git ls-files -v | Select-String "^[a-z]" -CaseSensitive' }
function glg { Invoke-WriteExecuteCommand -Command 'git log --stat' -Arguments $args }
function glgg { Invoke-WriteExecuteCommand -Command 'git log --graph' -Arguments $args }
function glgga { Invoke-WriteExecuteCommand -Command 'git log --graph --decorate --all' -Arguments $args }
function glgm { Invoke-WriteExecuteCommand -Command 'git log --graph --max-count=10' -Arguments $args }
function glgp { Invoke-WriteExecuteCommand -Command 'git log --stat -p' -Arguments $args }
function glo { Invoke-WriteExecuteCommand -Command 'git log --oneline --decorate' -Arguments $args }
function glog { Invoke-WriteExecuteCommand -Command 'git log --oneline --decorate --graph' -Arguments $args }
function gloga { Invoke-WriteExecuteCommand -Command 'git log --oneline --decorate --graph --all' -Arguments $args }
function glol { Invoke-WriteExecuteCommand 'git log --graph --pretty="%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset" --abbrev-commit' $args }
function glola { Invoke-WriteExecuteCommand 'git log --graph --pretty="%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset" --abbrev-commit --all' $args }
function glum { Invoke-WriteExecuteCommand -Command 'git pull upstream master' -Arguments $args }
function gm { Invoke-WriteExecuteCommand -Command 'git merge' -Arguments $args }
function gmom { Invoke-WriteExecuteCommand -Command 'git merge origin/master' -Arguments $args }
function gmt { Invoke-WriteExecuteCommand -Command 'git mergetool --no-prompt' -Arguments $args }
function gmtvim { Invoke-WriteExecuteCommand -Command 'git mergetool --no-prompt --tool=vimdiff' -Arguments $args }
function gmum { Invoke-WriteExecuteCommand -Command 'git merge upstream/master' -Arguments $args }
function gp { Invoke-WriteExecuteCommand -Command 'git push' -Arguments $args }
function gpd { Invoke-WriteExecuteCommand -Command 'git push --dry-run' -Arguments $args }
function gpl { Invoke-WriteExecuteCommand -Command "git pull origin $(Get-GitCurrentBranch)" -Arguments $args }
function gpoat { Invoke-WriteExecuteCommand -Command 'git push origin --all && git push origin --tags' }
function gpristine { Invoke-WriteExecuteCommand -Command 'git reset --hard && git clean -dfx' }
function gpsup { Invoke-WriteExecuteCommand -Command "git push --set-upstream origin $(Get-GitCurrentBranch)" -Arguments $args }
function gpu { Invoke-WriteExecuteCommand -Command 'git push upstream' -Arguments $args }
function gpull { Invoke-WriteExecuteCommand -Command 'git pull origin' -Arguments $args }
function gpush { Invoke-WriteExecuteCommand -Command 'git push origin' -Arguments $args }
function gpush! { Invoke-WriteExecuteCommand -Command 'git push origin --force' -Arguments $args }
function gpv { Invoke-WriteExecuteCommand -Command 'git push -v' -Arguments $args }
function gr { Invoke-WriteExecuteCommand -Command 'git remote' -Arguments $args }
function gra { Invoke-WriteExecuteCommand -Command 'git remote add' -Arguments $args }
function grb { Invoke-WriteExecuteCommand -Command 'git rebase' -Arguments $args }
function grba { Invoke-WriteExecuteCommand -Command 'git rebase --abort' -Arguments $args }
function grbc { Invoke-WriteExecuteCommand -Command 'git rebase --continue' -Arguments $args }
function grbi { Invoke-WriteExecuteCommand -Command 'git rebase -i' -Arguments $args }
function grbm { Invoke-WriteExecuteCommand -Command 'git rebase master' -Arguments $args }
function grbs { Invoke-WriteExecuteCommand -Command 'git rebase --skip' -Arguments $args }
function grh { Invoke-WriteExecuteCommand -Command 'git reset --hard' -Arguments $args }
function grho { Invoke-WriteExecuteCommand -Command "git reset --hard origin/$(Get-GitCurrentBranch)" -Arguments $args }
function grmb { Invoke-WriteExecuteCommand -Command "git reset `$(git merge-base origin/$(Get-GitResolvedBranch) HEAD)" }
function grmv { Invoke-WriteExecuteCommand -Command 'git remote rename' -Arguments $args }
function grrm { Invoke-WriteExecuteCommand -Command 'git remote remove' -Arguments $args }
function grs { Invoke-WriteExecuteCommand -Command 'git reset --soft' -Arguments $args }
function grset { Invoke-WriteExecuteCommand -Command 'git remote set-url' -Arguments $args }
function grt { Invoke-WriteExecuteCommand -Command "Set-Location '$(git rev-parse --show-toplevel 2>$null || '.')'" }
function gru { Invoke-WriteExecuteCommand -Command 'git reset --' -Arguments $args }
function grup { Invoke-WriteExecuteCommand -Command 'git remote update origin' -Arguments $args }
function grupp { Invoke-WriteExecuteCommand -Command 'git remote update origin --prune' -Arguments $args }
function grv { Invoke-WriteExecuteCommand -Command 'git remote -v' -Arguments $args }
function gs { Invoke-WriteExecuteCommand -Command "git switch $(Get-GitResolvedBranch)" -Arguments $args }
function gs! { Invoke-WriteExecuteCommand -Command "git switch $(Get-GitResolvedBranch) --force" -Arguments $args }
function gsb { Invoke-WriteExecuteCommand -Command 'git status -sb' -Arguments $args }
function gsd { Invoke-WriteExecuteCommand -Command 'git svn dcommit' -Arguments $args }
function gsi { Invoke-WriteExecuteCommand -Command 'git submodule init' -Arguments $args }
function gsps { Invoke-WriteExecuteCommand -Command 'git show --pretty=short --show-signature' -Arguments $args }
function gsr { Invoke-WriteExecuteCommand -Command 'git svn rebase' -Arguments $args }
function gss { Invoke-WriteExecuteCommand -Command 'git status -s' -Arguments $args }
function gst { Invoke-WriteExecuteCommand -Command 'git status' -Arguments $args }
function gsta { Invoke-WriteExecuteCommand -Command 'git stash save' -Arguments $args }
function gstaa { Invoke-WriteExecuteCommand -Command 'git stash apply' -Arguments $args }
function gstc { Invoke-WriteExecuteCommand -Command 'git stash clear' -Arguments $args }
function gstd { Invoke-WriteExecuteCommand -Command 'git stash drop' -Arguments $args }
function gstl { Invoke-WriteExecuteCommand -Command 'git stash list' -Arguments $args }
function gstp { Invoke-WriteExecuteCommand -Command 'git stash pop' -Arguments $args }
function gsts { Invoke-WriteExecuteCommand -Command 'git stash show --text' -Arguments $args }
function gsu { Invoke-WriteExecuteCommand -Command 'git submodule update' -Arguments $args }
function gsup { Invoke-WriteExecuteCommand -Command "git branch --set-upstream-to=origin/$(Get-GitCurrentBranch)" -Arguments $args }
function gts { Invoke-WriteExecuteCommand -Command 'git tag -s' -Arguments $args }
function gtv { Invoke-WriteExecuteCommand -Command 'git tag' -Arguments $args }
function gunignore { Invoke-WriteExecuteCommand -Command 'git update-index --no-assume-unchanged' -Arguments $args }
function gup { Invoke-WriteExecuteCommand -Command 'git pull --rebase' -Arguments $args }
function gupa { Invoke-WriteExecuteCommand -Command 'git pull --rebase --autostash' -Arguments $args }
function gupav { Invoke-WriteExecuteCommand -Command 'git pull --rebase --autostash -v' -Arguments $args }
function gupv { Invoke-WriteExecuteCommand -Command 'git pull --rebase -v' -Arguments $args }
function gwch { Invoke-WriteExecuteCommand -Command 'git whatchanged -p --abbrev-commit --pretty=medium' -Arguments $args }
#endregion
