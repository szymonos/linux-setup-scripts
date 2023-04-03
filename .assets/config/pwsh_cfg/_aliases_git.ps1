#region internal functions
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
function Get-GitResolvedBranch {
    [CmdletBinding()]
    param (
        [string[]]$BranchName
    )

    begin {
        [string]$BranchName = $BranchName.Where({ $_ -notmatch '^-WhatIf$|^-Quiet$' })
        $branchMatch = switch ($BranchName) {
            '' { '(^|/)dev(|el|elop|elopment)$|(^|/)ma(in|ster)$|(^|/)trunk$' }
            d { '(^|/)dev(|el|elop|elopment)$' }
            m { '(^|/)ma(in|ster)$' }
            s { '(^|/)stage$' }
            t { '(^|/)trunk$' }
            Default { "(^|/)$BranchName$" }
        }
    }

    process {
        $branches = $(git branch -a --format='%(refname:short)').Replace('origin/', '') `
        | Where-Object { $_ -ne 'HEAD' } `
        | Sort-Object -Unique
        if ($branches) {
            $branch = $branches | Select-String $branchMatch -Raw | Select-Object -First 1
        }
        if (-not $branch) {
            if ($BranchName) {
                Write-Host "invalid reference: $BranchName`nvalid branch names: $branches"
            }
            break
        }
    }

    end {
        return $branch
    }
}
#endregion

#region helper functions
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

Set-Alias -Name gglo -Value Get-GitLogObject

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

        [switch]$WhatIf,

        [switch]$Quiet
    )
    begin {
        # remove DeleteNoMerged from PSBoundParameters
        $PSBoundParameters.Remove('DeleteNoMerged') | Out-Null
        # switch to dev/main branch
        git switch $(Get-GitResolvedBranch) --quiet
        # update remote
        git remote update --prune
    }
    process {
        # *get list of branches
        filter branchFilter { $_.Where({ $_ -notmatch '^ma(in|ster)$|^dev(|el|elop)$|^qa$|^stage$|^trunk$' }) }
        $merged = git branch --format='%(refname:short)' --merged | branchFilter
        # *delete branches
        foreach ($branch in $merged) {
            Invoke-WriteExecCmd -Command "git branch --delete $branch" @PSBoundParameters
        }
        if ($DeleteNoMerged) {
            $no_merged = git branch --format='%(refname:short)' --no-merged | branchFilter
            foreach ($branch in $no_merged) {
                if ((Read-Host -Prompt "Do you want to remove branch: `e[1;97m$branch`e[0m? [y/N]") -eq 'y') {
                    Invoke-WriteExecCmd -Command "git branch -D $branch" @PSBoundParameters
                }
            }
        }
    }
}

Set-Alias -Name gbda -Value Remove-GitLocalBranches
#endregion

#region alias functions
function ga { Invoke-WriteExecCmd -Command 'git add' -Arguments $args }
function gaa { Invoke-WriteExecCmd -Command 'git add --all' -Arguments $args }
function gapa { Invoke-WriteExecCmd -Command 'git add --patch' -Arguments $args }
function gau { Invoke-WriteExecCmd -Command 'git add --update' -Arguments $args }
function gbl { Invoke-WriteExecCmd -Command 'git blame -b -w' -Arguments $args }
function gb { Invoke-WriteExecCmd -Command 'git branch' -Arguments $args }
function gba { Invoke-WriteExecCmd -Command 'git branch --all' -Arguments $args }
function gbd { Invoke-WriteExecCmd -Command 'git branch --delete' -Arguments $args }
function gbnm { Invoke-WriteExecCmd -Command 'git branch --no-merged' -Arguments $args }
function gbr { Invoke-WriteExecCmd -Command 'git branch --remote' -Arguments $args }
function gbsu { Invoke-WriteExecCmd -Command "git branch --set-upstream-to=origin/$(Get-GitCurrentBranch)" -Arguments $args }
function gbs { Invoke-WriteExecCmd -Command 'git bisect' -Arguments $args }
function gbsb { Invoke-WriteExecCmd -Command 'git bisect bad' -Arguments $args }
function gbsg { Invoke-WriteExecCmd -Command 'git bisect good' -Arguments $args }
function gbsr { Invoke-WriteExecCmd -Command 'git bisect reset' -Arguments $args }
function gbss { Invoke-WriteExecCmd -Command 'git bisect start' -Arguments $args }
function gcv { Invoke-WriteExecCmd -Command 'git commit --verbose' -Arguments $args }
function gc! { Invoke-WriteExecCmd -Command 'git commit --verbose --amend' -Arguments $args }
function gca { Invoke-WriteExecCmd -Command 'git commit --verbose --all' -Arguments $args }
function gcap { gca @args; Invoke-WriteExecCmd 'git push' -Parameters $args }
function gaca { Invoke-WriteExecCmd 'git add --all' -Parameters $args; gca @args }
function gacap { gaca @args; Invoke-WriteExecCmd 'git push' -Parameters $args }
function gca! { Invoke-WriteExecCmd -Command 'git commit --verbose --all --amend' -Arguments $args }
function gaca! { Invoke-WriteExecCmd 'git add --all' -Parameters $args; gca! @args }
function gcam { Invoke-WriteExecCmd -Command 'git commit --all -m' -Arguments $args }
function gcamp { gcam @args; Invoke-WriteExecCmd 'git push' -Parameters $args }
function gacam { Invoke-WriteExecCmd 'git add --all' -Parameters $args; gcam @args }
function gacamp { gacam @args; Invoke-WriteExecCmd 'git push' -Parameters $args }
function gcan! { Invoke-WriteExecCmd -Command 'git commit --verbose --all --no-edit --amend' -Arguments $args }
function gcanp! { gcan! @args; Invoke-WriteExecCmd 'git push --force' -Parameters $args }
function gacan! { Invoke-WriteExecCmd 'git add --all' -Parameters $args; gcan! @args }
function gacanp! { gacan! @args; Invoke-WriteExecCmd 'git push --force' -Parameters $args }
function gcans! { Invoke-WriteExecCmd -Command 'git commit --verbose --all --signoff --no-edit --amend' -Arguments $args }
function gacans! { Invoke-WriteExecCmd 'git add --all' -Parameters $args; gcans! @args }
function gcmsg { Invoke-WriteExecCmd -Command 'git commit -m' -Arguments $args }
function gcmsgp { gcmsg @args; Invoke-WriteExecCmd 'git push' -Parameters $args }
function gcn! { Invoke-WriteExecCmd -Command 'git commit --verbose --no-edit --amend' -Arguments $args }
function gcnp! { gcn! @args; Invoke-WriteExecCmd 'git push --force' -Parameters $args }
function gcsm { Invoke-WriteExecCmd -Command 'git commit --signoff -m' -Arguments $args }
function gcd { Set-Location $(git rev-parse --show-toplevel 2>$null || '.') }
function gcf { Invoke-WriteExecCmd -Command 'git config' -Arguments $args }
function gcfg { Invoke-WriteExecCmd -Command 'git config --global' -Arguments $args }
function gcfge { Invoke-WriteExecCmd -Command 'git config --global --edit' -Arguments $args }
function gcfgl { Invoke-WriteExecCmd -Command 'git config --global --list' -Arguments $args }
function gcfl { Invoke-WriteExecCmd -Command 'git config --local' -Arguments $args }
function gcfll { Invoke-WriteExecCmd -Command 'git config --local --list' -Arguments $args }
function gcfle { Invoke-WriteExecCmd -Command 'git config --local --edit' -Arguments $args }
function gcl { Invoke-WriteExecCmd -Command 'git clone --recursive' -Arguments $args }
function gclean { Invoke-WriteExecCmd -Command 'git clean --force -d' -Arguments $args }
function gclean! { Invoke-WriteExecCmd 'git reset --hard' -Parameters $args; gclean @args }
function gpristine { Invoke-WriteExecCmd 'git reset --hard' -Parameters $args; gclean -x @args }
function gco { Invoke-WriteExecCmd -Command 'git checkout' -Arguments $args }
function gcount { Invoke-WriteExecCmd -Command 'git shortlog --summary --numbered' -Arguments $args }
function gcp { Invoke-WriteExecCmd -Command 'git cherry-pick' -Arguments $args }
function gcpa { Invoke-WriteExecCmd -Command 'git cherry-pick --abort' -Arguments $args }
function gcpc { Invoke-WriteExecCmd -Command 'git cherry-pick --continue' -Arguments $args }
function gcps { Invoke-WriteExecCmd -Command 'git cherry-pick --signoff' -Arguments $args }
function gd { Invoke-WriteExecCmd -Command 'git diff' -Arguments $args }
function gdca { Invoke-WriteExecCmd -Command 'git diff --cached' -Arguments $args }
function gdt { Invoke-WriteExecCmd -Command 'git diff-tree --no-commit-id --name-only -r' -Arguments $args }
function gdw { Invoke-WriteExecCmd -Command 'git diff --word-diff' -Arguments $args }
function gdct { Invoke-WriteExecCmd -Command 'git describe --tags `git rev-list --tags --max-count=1`' -Arguments $args }
function gf { Invoke-WriteExecCmd -Command 'git fetch' -Arguments $args }
function gfa { Invoke-WriteExecCmd -Command 'git fetch --all --prune' -Arguments $args }
function gfo { Invoke-WriteExecCmd -Command 'git fetch origin' -Arguments $args }
function gg { Invoke-WriteExecCmd -Command 'git grep --ignore-case' -Arguments $args }
function gge { Invoke-WriteExecCmd -Command 'git grep --ignore-case --extended-regexp' -Arguments $args }
function ggp { Invoke-WriteExecCmd -Command 'git grep --ignore-case --perl-regexp' -Arguments $args }
function ghh { Invoke-WriteExecCmd -Command 'git help' -Arguments $args }
function gignore { Invoke-WriteExecCmd -Command 'git update-index --assume-unchanged' -Arguments $args }
function gignored { Invoke-WriteExecCmd -Command 'git ls-files -v | Select-String "^[a-z]" -CaseSensitive' -Parameters $args }
function glg { Invoke-WriteExecCmd -Command 'git log --graph' -Arguments $args }
function glga { Invoke-WriteExecCmd -Command 'git log --graph --decorate --all' -Arguments $args }
function glgm { Invoke-WriteExecCmd -Command 'git log --graph --max-count=10' -Arguments $args }
function glo { Invoke-WriteExecCmd -Command 'git log --oneline --decorate' -Arguments $args }
function gloa { Invoke-WriteExecCmd -Command 'git log --oneline --decorate --all' -Arguments $args }
function glog { Invoke-WriteExecCmd -Command 'git log --oneline --decorate --graph' -Arguments $args }
function gloga { Invoke-WriteExecCmd -Command 'git log --oneline --decorate --graph --all' -Arguments $args }
function glol { Invoke-WriteExecCmd -Command 'git log --graph --pretty="%C(yellow)%h%C(reset) %C(green)(%cr)%C(reset)%C(red)%d%C(reset) %s %C(bold blue)<%an>%C(reset)" --abbrev-commit' -Arguments $args }
function glola { Invoke-WriteExecCmd -Command 'git log --graph --pretty="%C(yellow)%h%C(reset) %C(green)(%cr)%C(reset)%C(red)%d%C(reset) %s %C(bold blue)<%an>%C(reset)" --abbrev-commit --all' -Arguments $args }
function glop { Invoke-WriteExecCmd -Command 'git log --pretty=format:"%C(yellow)%h%C(reset) %C(green)(%ai)%C(reset)%C(red)%d%C(reset) %s %C(bold blue)<%ae>%C(reset)" --abbrev-commit' -Arguments $args }
function glopa { Invoke-WriteExecCmd -Command 'git log --pretty=format:"%C(yellow)%h%C(reset) %C(green)(%ai)%C(reset)%C(red)%d%C(reset) %s %C(bold blue)<%ae>%C(reset)" --abbrev-commit --all' -Arguments $args }
function gls { Invoke-WriteExecCmd -Command 'git log --stat' -Arguments $args }
function glsp { Invoke-WriteExecCmd -Command 'git log --stat --patch' -Arguments $args }
function gmg { Invoke-WriteExecCmd -Command 'git merge' -Arguments $args }
function gmgom { Invoke-WriteExecCmd -Command 'git merge origin/master' -Arguments $args }
function gmgum { Invoke-WriteExecCmd -Command 'git merge upstream/master' -Arguments $args }
function gmt { Invoke-WriteExecCmd -Command 'git mergetool --no-prompt' -Arguments $args }
function gmtvim { Invoke-WriteExecCmd -Command 'git mergetool --no-prompt --tool=vimdiff' -Arguments $args }
function gpl { Invoke-WriteExecCmd -Command "git pull origin $(Get-GitCurrentBranch)" -Arguments $args }
function gpull { Invoke-WriteExecCmd -Command 'git pull' -Arguments $args }
function gpullr { Invoke-WriteExecCmd -Command 'git pull --rebase' -Arguments $args }
function gpullra { Invoke-WriteExecCmd -Command 'git pull --rebase --autostash' -Arguments $args }
function gpullrav { Invoke-WriteExecCmd -Command 'git pull --rebase --autostash --verbose' -Arguments $args }
function gpullrv { Invoke-WriteExecCmd -Command 'git pull --rebase --verbose' -Arguments $args }
function gpullum { Invoke-WriteExecCmd -Command 'git pull upstream master' -Arguments $args }
function gpush { Invoke-WriteExecCmd -Command 'git push' -Arguments $args }
function gpush! { Invoke-WriteExecCmd -Command 'git push --force' -Arguments $args }
function gpushd { Invoke-WriteExecCmd -Command 'git push --dry-run' -Arguments $args }
function gpushoat { Invoke-WriteExecCmd -Command 'git push origin --all && git push origin --tags' -Parameters $args }
function gpushsup { Invoke-WriteExecCmd -Command "git push --set-upstream origin $(Get-GitCurrentBranch)" -Arguments $args }
function gpushu { Invoke-WriteExecCmd -Command 'git push upstream' -Arguments $args }
function grb { Invoke-WriteExecCmd -Command 'git rebase' -Arguments $args }
function grba { Invoke-WriteExecCmd -Command 'git rebase --abort' -Arguments $args }
function grbc { Invoke-WriteExecCmd -Command 'git rebase --continue' -Arguments $args }
function grbi { Invoke-WriteExecCmd -Command 'git rebase --interactive' -Arguments $args }
function grbm { Invoke-WriteExecCmd -Command 'git rebase master' -Arguments $args }
function grbs { Invoke-WriteExecCmd -Command 'git rebase --skip' -Arguments $args }
function gr { Invoke-WriteExecCmd -Command 'git reset' -Arguments $args }
function grh { Invoke-WriteExecCmd -Command 'git reset --hard' -Arguments $args }
function grho { Invoke-WriteExecCmd "git fetch && git reset --hard origin/$(Get-GitCurrentBranch)" -Arguments $args }
function grs { Invoke-WriteExecCmd -Command 'git reset --soft' -Arguments $args }
function grsmb { Invoke-WriteExecCmd -Command "git reset `$(git merge-base origin/$(Get-GitResolvedBranch $args) HEAD)" -Parameters $args }
function grmc { Invoke-WriteExecCmd -Command 'git rm --cached' -Arguments $args }
function grm! { Invoke-WriteExecCmd -Command 'git rm --force' -Arguments $args }
function grmrc { Invoke-WriteExecCmd -Command 'git rm -r --cached' -Arguments $args }
function grmr! { Invoke-WriteExecCmd -Command 'git rm -r --force' -Arguments $args }
function grr { Invoke-WriteExecCmd -Command 'git restore' -Arguments $args }
function grrs { Invoke-WriteExecCmd -Command 'git restore --source' -Arguments $args }
function grt { Invoke-WriteExecCmd -Command 'git remote' -Arguments $args }
function grta { Invoke-WriteExecCmd -Command 'git remote add' -Arguments $args }
function grtrm { Invoke-WriteExecCmd -Command 'git remote remove' -Arguments $args }
function grtrn { Invoke-WriteExecCmd -Command 'git remote rename' -Arguments $args }
function grtsu { Invoke-WriteExecCmd -Command 'git remote set-url' -Arguments $args }
function grtup { Invoke-WriteExecCmd -Command 'git remote update origin' -Arguments $args }
function grtupp { Invoke-WriteExecCmd -Command 'git remote update origin --prune' -Arguments $args }
function grtv { Invoke-WriteExecCmd -Command 'git remote --verbose' -Arguments $args }
function gs { Invoke-WriteExecCmd -Command "git switch $(Get-GitResolvedBranch $args)" -Parameters $args }
function gs! { Invoke-WriteExecCmd -Command "git switch $(Get-GitResolvedBranch $args) --force" -Parameters $args }
function gsc { Invoke-WriteExecCmd -Command 'git switch --create' -Arguments $args }
function gsd { Invoke-WriteExecCmd -Command 'git switch --detach' -Arguments $args }
function gsmi { Invoke-WriteExecCmd -Command 'git submodule init' -Arguments $args }
function gsmu { Invoke-WriteExecCmd -Command 'git submodule update' -Arguments $args }
function gsps { Invoke-WriteExecCmd -Command 'git show --pretty=short --show-signature' -Arguments $args }
function gstas { Invoke-WriteExecCmd -Command 'git stash save' -Arguments $args }
function gstaa { Invoke-WriteExecCmd -Command 'git stash apply' -Arguments $args }
function gstac { Invoke-WriteExecCmd -Command 'git stash clear' -Arguments $args }
function gstad { Invoke-WriteExecCmd -Command 'git stash drop' -Arguments $args }
function gstal { Invoke-WriteExecCmd -Command 'git stash list' -Arguments $args }
function gstap { Invoke-WriteExecCmd -Command 'git stash pop' -Arguments $args }
function gstast { Invoke-WriteExecCmd -Command 'git stash show --text' -Arguments $args }
function gst { Invoke-WriteExecCmd -Command 'git status' -Arguments $args }
function gstb { Invoke-WriteExecCmd -Command 'git status --short --branch' -Arguments $args }
function gsts { Invoke-WriteExecCmd -Command 'git status --short' -Arguments $args }
function gsvnd { Invoke-WriteExecCmd -Command 'git svn dcommit' -Arguments $args }
function gsvnr { Invoke-WriteExecCmd -Command 'git svn rebase' -Arguments $args }
function gt { Invoke-WriteExecCmd -Command 'git tag' -Arguments $args }
function gts { Invoke-WriteExecCmd -Command 'git tag --sign' -Arguments $args }
function gtr { Invoke-WriteExecCmd -Command 'git show-ref --tags' -Arguments $args }
function gunignore { Invoke-WriteExecCmd -Command 'git update-index --no-assume-unchanged' -Arguments $args }
function gwch { Invoke-WriteExecCmd -Command 'git whatchanged -p --abbrev-commit --pretty=medium' -Arguments $args }
#endregion
