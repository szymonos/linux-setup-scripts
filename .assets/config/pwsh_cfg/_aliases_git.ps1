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
        if ($branches = git branch -a --format='%(refname:short)') {
            $branch = $branches.Replace('origin/', '') `
            | Select-String $branchMatch -Raw `
            | Sort-Object -Unique `
            | Select-Object -First 1
        }
        if (-not $branch) {
            if ($BranchName) {
                Write-Host "invalid reference: $BranchName"
            }
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
function gba { Invoke-WriteExecuteCommand -Command 'git branch --all' -Arguments $args }
function gbd { Invoke-WriteExecuteCommand -Command 'git branch --delete' -Arguments $args }
function gbl { Invoke-WriteExecuteCommand -Command 'git blame -b -w' -Arguments $args }
function gbnm { Invoke-WriteExecuteCommand -Command 'git branch --no-merged' -Arguments $args }
function gbr { Invoke-WriteExecuteCommand -Command 'git branch --remote' -Arguments $args }
function gbs { Invoke-WriteExecuteCommand -Command 'git bisect' -Arguments $args }
function gbsb { Invoke-WriteExecuteCommand -Command 'git bisect bad' -Arguments $args }
function gbsg { Invoke-WriteExecuteCommand -Command 'git bisect good' -Arguments $args }
function gbsr { Invoke-WriteExecuteCommand -Command 'git bisect reset' -Arguments $args }
function gbss { Invoke-WriteExecuteCommand -Command 'git bisect start' -Arguments $args }
function gcv { Invoke-WriteExecuteCommand -Command 'git commit --verbose' -Arguments $args }
function gc! { Invoke-WriteExecuteCommand -Command 'git commit --verbose --amend' -Arguments $args }
function gca { Invoke-WriteExecuteCommand -Command 'git commit --verbose --all' -Arguments $args }
function gca! { Invoke-WriteExecuteCommand -Command 'git commit --verbose --all --amend' -Arguments $args }
function gcam { Invoke-WriteExecuteCommand -Command 'git commit --all -m' -Arguments $args }
function gcamp { gcam @args; gpush ($args | Select-String '^-WhatIf$|^-Quiet$').Line }
function gcan! { Invoke-WriteExecuteCommand -Command 'git commit --verbose --all --no-edit --amend' -Arguments $args }
function gcanp! { gcan! @args; gpush! ($args | Select-String '^-WhatIf$|^-Quiet$').Line }
function gcans! { Invoke-WriteExecuteCommand -Command 'git commit --verbose --all --signoff --no-edit --amend' -Arguments $args }
function gcf { Invoke-WriteExecuteCommand -Command 'git config --list' -Arguments $args }
function gcl { Invoke-WriteExecuteCommand -Command 'git clone --recursive' -Arguments $args }
function gclean { Invoke-WriteExecuteCommand -Command 'git clean --force -d' -Arguments $args }
function gcmsg { Invoke-WriteExecuteCommand -Command 'git commit -m' -Arguments $args }
function gcmsgp { gcmsg @args; gpush ($args | Select-String '^-WhatIf$|^-Quiet$').Line }
function gcn! { Invoke-WriteExecuteCommand -Command 'git commit --verbose --no-edit --amend' -Arguments $args }
function gcnp! { gcn! @args; gpush! ($args | Select-String '^-WhatIf$|^-Quiet$').Line }
function gco { Invoke-WriteExecuteCommand -Command 'git checkout' -Arguments $args }
function gcount { Invoke-WriteExecuteCommand -Command 'git shortlog --summary --numbered' -Arguments $args }
function gcp { Invoke-WriteExecuteCommand -Command 'git cherry-pick' -Arguments $args }
function gcpa { Invoke-WriteExecuteCommand -Command 'git cherry-pick --abort' -Arguments $args }
function gcpc { Invoke-WriteExecuteCommand -Command 'git cherry-pick --continue' -Arguments $args }
function gcps { Invoke-WriteExecuteCommand -Command 'git cherry-pick --signoff' -Arguments $args }
function gcsm { Invoke-WriteExecuteCommand -Command 'git commit --signoff -m' -Arguments $args }
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
function gignored { Invoke-WriteExecuteCommand -Command 'git ls-files -v | Select-String "^[a-z]" -CaseSensitive' -Arguments ($args | Select-String '^-WhatIf$|^-Quiet$').Line }
function glg { Invoke-WriteExecuteCommand -Command 'git log --stat' -Arguments $args }
function glgg { Invoke-WriteExecuteCommand -Command 'git log --graph' -Arguments $args }
function glgga { Invoke-WriteExecuteCommand -Command 'git log --graph --decorate --all' -Arguments $args }
function glgm { Invoke-WriteExecuteCommand -Command 'git log --graph --max-count=10' -Arguments $args }
function glgp { Invoke-WriteExecuteCommand -Command 'git log --stat --patch' -Arguments $args }
function glo { Invoke-WriteExecuteCommand -Command 'git log --oneline --decorate' -Arguments $args }
function glog { Invoke-WriteExecuteCommand -Command 'git log --oneline --decorate --graph' -Arguments $args }
function gloga { Invoke-WriteExecuteCommand -Command 'git log --oneline --decorate --graph --all' -Arguments $args }
function glol { Invoke-WriteExecuteCommand -Command 'git log --graph --pretty="%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset" --abbrev-commit' -Arguments $args }
function glola { Invoke-WriteExecuteCommand -Command 'git log --graph --pretty="%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset" --abbrev-commit --all' -Arguments $args }
function gmg { Invoke-WriteExecuteCommand -Command 'git merge' -Arguments $args }
function gmgom { Invoke-WriteExecuteCommand -Command 'git merge origin/master' -Arguments $args }
function gmgum { Invoke-WriteExecuteCommand -Command 'git merge upstream/master' -Arguments $args }
function gmt { Invoke-WriteExecuteCommand -Command 'git mergetool --no-prompt' -Arguments $args }
function gmtvim { Invoke-WriteExecuteCommand -Command 'git mergetool --no-prompt --tool=vimdiff' -Arguments $args }
function gpl { Invoke-WriteExecuteCommand -Command "git pull origin $(Get-GitCurrentBranch)" -Arguments $args }
function gpristine { Invoke-WriteExecuteCommand -Command 'git reset --hard && git clean -dfx' -Arguments ($args | Select-String '^-WhatIf$|^-Quiet$').Line }
function gpull { Invoke-WriteExecuteCommand -Command 'git pull' -Arguments $args }
function gpullr { Invoke-WriteExecuteCommand -Command 'git pull --rebase' -Arguments $args }
function gpullra { Invoke-WriteExecuteCommand -Command 'git pull --rebase --autostash' -Arguments $args }
function gpullrav { Invoke-WriteExecuteCommand -Command 'git pull --rebase --autostash --verbose' -Arguments $args }
function gpullrv { Invoke-WriteExecuteCommand -Command 'git pull --rebase --verbose' -Arguments $args }
function gpullum { Invoke-WriteExecuteCommand -Command 'git pull upstream master' -Arguments $args }
function gpush { Invoke-WriteExecuteCommand -Command 'git push origin' -Arguments $args }
function gpush! { Invoke-WriteExecuteCommand -Command 'git push origin --force' -Arguments $args }
function gpushd { Invoke-WriteExecuteCommand -Command 'git push --dry-run' -Arguments $args }
function gpushoat { Invoke-WriteExecuteCommand -Command 'git push origin --all && git push origin --tags' -Arguments ($args | Select-String '^-WhatIf$|^-Quiet$').Line }
function gpushsup { Invoke-WriteExecuteCommand -Command "git push --set-upstream origin $(Get-GitCurrentBranch)" -Arguments $args }
function gpushu { Invoke-WriteExecuteCommand -Command 'git push upstream' -Arguments $args }
function gr { Invoke-WriteExecuteCommand -Command 'git remote' -Arguments $args }
function gra { Invoke-WriteExecuteCommand -Command 'git remote add' -Arguments $args }
function grb { Invoke-WriteExecuteCommand -Command 'git rebase' -Arguments $args }
function grba { Invoke-WriteExecuteCommand -Command 'git rebase --abort' -Arguments $args }
function grbc { Invoke-WriteExecuteCommand -Command 'git rebase --continue' -Arguments $args }
function grbi { Invoke-WriteExecuteCommand -Command 'git rebase --interactive' -Arguments $args }
function grbm { Invoke-WriteExecuteCommand -Command 'git rebase master' -Arguments $args }
function grbs { Invoke-WriteExecuteCommand -Command 'git rebase --skip' -Arguments $args }
function grh { Invoke-WriteExecuteCommand -Command 'git reset --hard' -Arguments $args }
function grho { Invoke-WriteExecuteCommand -Command "git fetch && git reset --hard origin/$(Get-GitCurrentBranch)" -Arguments $args }
function grmc { Invoke-WriteExecuteCommand -Command 'git rm --cached' -Arguments $args }
function grm! { Invoke-WriteExecuteCommand -Command 'git rm --force' -Arguments $args }
function grmrc { Invoke-WriteExecuteCommand -Command 'git rm -r --cached' -Arguments $args }
function grmr! { Invoke-WriteExecuteCommand -Command 'git rm -r --force' -Arguments $args }
function grrm { Invoke-WriteExecuteCommand -Command 'git remote remove' -Arguments $args }
function grrn { Invoke-WriteExecuteCommand -Command 'git remote rename' -Arguments $args }
function grs { Invoke-WriteExecuteCommand -Command 'git reset --soft' -Arguments $args }
function grset { Invoke-WriteExecuteCommand -Command 'git remote set-url' -Arguments $args }
function grsmb { Invoke-WriteExecuteCommand -Command "git reset `$(git merge-base origin/$(Get-GitResolvedBranch $args.Where({ $_ -notin $('-WhatIf', '-Quiet') })) HEAD)" -Arguments ($args | Select-String '^-WhatIf$|^-Quiet$').Line }
function grt { Invoke-WriteExecuteCommand -Command "Set-Location '$(git rev-parse --show-toplevel 2>$null || '.')'" -Arguments ($args | Select-String '^-WhatIf$|^-Quiet$').Line }
function gru { Invoke-WriteExecuteCommand -Command 'git reset --' -Arguments $args }
function grup { Invoke-WriteExecuteCommand -Command 'git remote update origin' -Arguments $args }
function grupp { Invoke-WriteExecuteCommand -Command 'git remote update origin --prune' -Arguments $args }
function grv { Invoke-WriteExecuteCommand -Command 'git remote --verbose' -Arguments $args }
function gs { Invoke-WriteExecuteCommand -Command "git switch $(Get-GitResolvedBranch $args.Where({ $_ -notin $('-WhatIf', '-Quiet') }))" -Arguments ($args | Select-String '^-WhatIf$|^-Quiet$').Line }
function gs! { Invoke-WriteExecuteCommand -Command "git switch $(Get-GitResolvedBranch $args.Where({ $_ -notin $('-WhatIf', '-Quiet') })) --force" -Arguments ($args | Select-String '^-WhatIf$|^-Quiet$').Line }
function gsc { Invoke-WriteExecuteCommand -Command 'git switch --create' -Arguments $args }
function gsd { Invoke-WriteExecuteCommand -Command "git switch --detach" -Arguments $args }
function gsmi { Invoke-WriteExecuteCommand -Command 'git submodule init' -Arguments $args }
function gsps { Invoke-WriteExecuteCommand -Command 'git show --pretty=short --show-signature' -Arguments $args }
function gst { Invoke-WriteExecuteCommand -Command 'git status' -Arguments $args }
function gstas { Invoke-WriteExecuteCommand -Command 'git stash save' -Arguments $args }
function gstaa { Invoke-WriteExecuteCommand -Command 'git stash apply' -Arguments $args }
function gstac { Invoke-WriteExecuteCommand -Command 'git stash clear' -Arguments $args }
function gstad { Invoke-WriteExecuteCommand -Command 'git stash drop' -Arguments $args }
function gstal { Invoke-WriteExecuteCommand -Command 'git stash list' -Arguments $args }
function gstap { Invoke-WriteExecuteCommand -Command 'git stash pop' -Arguments $args }
function gstast { Invoke-WriteExecuteCommand -Command 'git stash show --text' -Arguments $args }
function gstb { Invoke-WriteExecuteCommand -Command 'git status --short --branch' -Arguments $args }
function gsts { Invoke-WriteExecuteCommand -Command 'git status --short' -Arguments $args }
function gsu { Invoke-WriteExecuteCommand -Command 'git submodule update' -Arguments $args }
function gsup { Invoke-WriteExecuteCommand -Command "git branch --set-upstream-to=origin/$(Get-GitCurrentBranch)" -Arguments $args }
function gsvnd { Invoke-WriteExecuteCommand -Command 'git svn dcommit' -Arguments $args }
function gsvnr { Invoke-WriteExecuteCommand -Command 'git svn rebase' -Arguments $args }
function gt { Invoke-WriteExecuteCommand -Command 'git tag' -Arguments $args }
function gts { Invoke-WriteExecuteCommand -Command 'git tag --sign' -Arguments $args }
function gtr { Invoke-WriteExecuteCommand -Command 'git show-ref --tags' -Arguments $args }
function gunignore { Invoke-WriteExecuteCommand -Command 'git update-index --no-assume-unchanged' -Arguments $args }
function gwch { Invoke-WriteExecuteCommand -Command 'git whatchanged -p --abbrev-commit --pretty=medium' -Arguments $args }
#endregion
