function ga { Write-Host "git add $args" -ForegroundColor Magenta; git add @args }
function gaa { Write-Host "git add --all $args" -ForegroundColor Magenta; git add --all @args }
function gapa { Write-Host "git add --patch $args" -ForegroundColor Magenta; git add --patch @args }
function gau { Write-Host "git add --update $args" -ForegroundColor Magenta; git add --update @args }
function gb { Write-Host "git branch $args" -ForegroundColor Magenta; git branch @args }
function gba { Write-Host "git branch -a $args" -ForegroundColor Magenta; git branch -a @args }
function gbc { git branch --show-current }
function gbd { Write-Host "git branch -d $args" -ForegroundColor Magenta; git branch -d @args }
function gbda {
    Write-Host 'git branch --no-color --merged --delete' -ForegroundColor Magenta
    git branch --no-color --merged `
    | Select-String -NotMatch '^(\*|\s*(main|master|stage|qa|dev|devel|develop)\s*$)' `
    | ForEach-Object {
        git branch --delete $_
    }
}
function gbl { Write-Host "git blame -b -w $args" -ForegroundColor Magenta; git blame -b -w @args }
function gbnm { Write-Host "git branch --no-merged $args" -ForegroundColor Magenta; git branch --no-merged @args }
function gbr { Write-Host "git branch --remote $args" -ForegroundColor Magenta; git branch --remote @args }
function gbs { Write-Host "git bisect $args" -ForegroundColor Magenta; git bisect @args }
function gbsb { Write-Host "git bisect bad $args" -ForegroundColor Magenta; git bisect bad @args }
function gbsg { Write-Host "git bisect good $args" -ForegroundColor Magenta; git bisect good @args }
function gbsr { Write-Host "git bisect reset $args" -ForegroundColor Magenta; git bisect reset @args }
function gbss { Write-Host "git bisect start $args" -ForegroundColor Magenta; git bisect start @args }
function gc { Write-Host "git commit -v $args" -ForegroundColor Magenta; git commit -v @args }
function gc! { Write-Host "git commit -v --amend $args" -ForegroundColor Magenta; git commit -v --amend @args }
function gca { Write-Host "git commit -v -a $args" -ForegroundColor Magenta; git commit -v -a @args }
function gca! { Write-Host "git commit -v -a --amend $args" -ForegroundColor Magenta; git commit -v -a --amend @args }
function gcam { Write-Host "git commit -a -m $args" -ForegroundColor Magenta; git commit -a -m @args }
function gcamp {
    $head = gbc
    Write-Host "git commit -a -m $args && git push origin $head" -ForegroundColor Magenta
    git commit -a -m @args && git push origin $head
}
function gcan! { Write-Host "git commit -v -a --no-edit --amend $args" -ForegroundColor Magenta; git commit -v -a --no-edit --amend @args }
function gcans! { Write-Host "git commit -v -a -s --no-edit --amend $args" -ForegroundColor Magenta; git commit -v -a -s --no-edit --amend @args }
function gcb { Write-Host "git checkout -b $args" -ForegroundColor Magenta; git checkout -b @args }
function gcf { Write-Host "git config --list $args" -ForegroundColor Magenta; git config --list @args }
function gcl { Write-Host "git clone --recursive $args" -ForegroundColor Magenta; git clone --recursive @args }
function gclean { Write-Host "git clean -fd $args" -ForegroundColor Magenta; git clean -fd @args }
function gcmsg { Write-Host "git commit -m $args" -ForegroundColor Magenta; git commit -m @args }
function gcn! { Write-Host "git commit -v --no-edit --amend $args" -ForegroundColor Magenta; git commit -v --no-edit --amend @args }
function gco { Write-Host "git checkout $args" -ForegroundColor Magenta; git checkout @args }
function gcount { Write-Host "git shortlog -sn $args" -ForegroundColor Magenta; git shortlog -sn @args }
function gcp { Write-Host "git cherry-pick $args" -ForegroundColor Magenta; git cherry-pick @args }
function gcpa { Write-Host "git cherry-pick --abort $args" -ForegroundColor Magenta; git cherry-pick --abort @args }
function gcpc { Write-Host "git cherry-pick --continue $args" -ForegroundColor Magenta; git cherry-pick --continue @args }
function gcps { Write-Host "git cherry-pick -s $args" -ForegroundColor Magenta; git cherry-pick -s @args }
function gcs { Write-Host "git commit -S $args" -ForegroundColor Magenta; git commit -S @args }
function gcsm { Write-Host "git commit -s -m $args" -ForegroundColor Magenta; git commit -s -m @args }
function gd { Write-Host "git diff $args" -ForegroundColor Magenta; git diff @args }
function gdca { Write-Host "git diff --cached $args" -ForegroundColor Magenta; git diff --cached @args }
function gdct { Write-Host "git describe --tags `git rev-list --tags --max-count=1` $args" -ForegroundColor Magenta; git describe --tags `git rev-list --tags --max-count=1` @args }
function gdt { Write-Host "git diff-tree --no-commit-id --name-only -r $args" -ForegroundColor Magenta; git diff-tree --no-commit-id --name-only -r @args }
function gdw { Write-Host "git diff --word-diff $args" -ForegroundColor Magenta; git diff --word-diff @args }
function gf { Write-Host "git fetch $args" -ForegroundColor Magenta; git fetch @args }
function gfa { Write-Host "git fetch --all --prune $args" -ForegroundColor Magenta; git fetch --all --prune @args }
function gfo { Write-Host "git fetch origin $args" -ForegroundColor Magenta; git fetch origin @args }
function gg { Write-Host "git gui citool $args" -ForegroundColor Magenta; git gui citool @args }
function gga { Write-Host "git gui citool --amend $args" -ForegroundColor Magenta; git gui citool --amend @args }
function ggpull { Write-Host "git pull origin $(gbc) $args" -ForegroundColor Magenta; git pull origin $(gbc) @args }
function ggpush { Write-Host "git push origin $(gbc) $args" -ForegroundColor Magenta; git push origin $(gbc) @args }
function ggsup { Write-Host "git branch --set-upstream-to=origin/$(gbc) $args" -ForegroundColor Magenta; git branch --set-upstream-to=origin/$(gbc) @args }
function ghh { Write-Host "git help $args" -ForegroundColor Magenta; git help @args }
function gignore { Write-Host "git update-index --assume-unchanged $args" -ForegroundColor Magenta; git update-index --assume-unchanged @args }
function gignored { Write-Host 'git ls-files -v | grep '^[[:lower:]]" $args" -ForegroundColor Magenta; git ls-files -v | grep '^[[:lower:]]' @args }
function gpl { Write-Host "git pull $args" -ForegroundColor Magenta; git pull @args }
function glg { Write-Host "git log --stat $args" -ForegroundColor Magenta; git log --stat @args }
function glgg { Write-Host "git log --graph $args" -ForegroundColor Magenta; git log --graph @args }
function glgga { Write-Host "git log --graph --decorate --all $args" -ForegroundColor Magenta; git log --graph --decorate --all @args }
function glgm { Write-Host "git log --graph --max-count=10 $args" -ForegroundColor Magenta; git log --graph --max-count=10 @args }
function glgp { Write-Host "git log --stat -p $args" -ForegroundColor Magenta; git log --stat -p @args }
function glo {
    Write-Host 'git log --pretty' -ForegroundColor Magenta
    "Commit`u{00A6}Subject`u{00A6}Author`u{00A6}Date", (git log --pretty=format:"%h`u{00A6}%s`u{00A6}%an <%ae>`u{00A6}%ai") `
    | ConvertFrom-Csv -Delimiter "`u{00A6}" `
    | Select-Object Commit, Subject, Author, @{ Name = 'Date'; Expression = { [System.DateTimeOffset]$_.Date } } `
    | Sort-Object Date
}
function glog { Write-Host "git log --oneline --decorate --graph $args" -ForegroundColor Magenta; git log --oneline --decorate --graph @args }
function gloga { Write-Host "git log --oneline --decorate --graph --all $args" -ForegroundColor Magenta; git log --oneline --decorate --graph --all @args }
function glol { Write-Host "git log --graph --pretty='\''%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset'\'' --abbrev-commit $args" -ForegroundColor Magenta; git log --graph --pretty='\''%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset'\'' --abbrev-commit @args }
function glola { Write-Host "git log --graph --pretty='\''%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset'\'' --abbrev-commit --all $args" -ForegroundColor Magenta; git log --graph --pretty='\''%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset'\'' --abbrev-commit --all @args }
function glum { Write-Host "git pull upstream master $args" -ForegroundColor Magenta; git pull upstream master @args }
function gm { Write-Host "git merge $args" -ForegroundColor Magenta; git merge @args }
function gmom { Write-Host "git merge origin/master $args" -ForegroundColor Magenta; git merge origin/master @args }
function gmt { Write-Host "git mergetool --no-prompt $args" -ForegroundColor Magenta; git mergetool --no-prompt @args }
function gmtvim { Write-Host "git mergetool --no-prompt --tool=vimdiff $args" -ForegroundColor Magenta; git mergetool --no-prompt --tool=vimdiff @args }
function gmum { Write-Host "git merge upstream/master $args" -ForegroundColor Magenta; git merge upstream/master @args }
function gp { Write-Host "git push $args" -ForegroundColor Magenta; git push @args }
function gpd { Write-Host "git push --dry-run $args" -ForegroundColor Magenta; git push --dry-run @args }
function gpoat { Write-Host "git push origin --all && git push origin --tags $args" -ForegroundColor Magenta; git push origin --all && git push origin --tags @args }
function gpristine { Write-Host "git reset --hard && git clean -dfx $args" -ForegroundColor Magenta; git reset --hard && git clean -dfx @args }
function gpsup { Write-Host "git push --set-upstream origin $(gbc) $args" -ForegroundColor Magenta; git push --set-upstream origin $(gbc) @args }
function gpu { Write-Host "git push upstream $args" -ForegroundColor Magenta; git push upstream @args }
function gpv { Write-Host "git push -v $args" -ForegroundColor Magenta; git push -v @args }
function gr { Write-Host "git remote $args" -ForegroundColor Magenta; git remote @args }
function gra { Write-Host "git remote add $args" -ForegroundColor Magenta; git remote add @args }
function grb { Write-Host "git rebase $args" -ForegroundColor Magenta; git rebase @args }
function grba { Write-Host "git rebase --abort $args" -ForegroundColor Magenta; git rebase --abort @args }
function grbc { Write-Host "git rebase --continue $args" -ForegroundColor Magenta; git rebase --continue @args }
function grbi { Write-Host "git rebase -i $args" -ForegroundColor Magenta; git rebase -i @args }
function grbm { Write-Host "git rebase master $args" -ForegroundColor Magenta; git rebase master @args }
function grbs { Write-Host "git rebase --skip $args" -ForegroundColor Magenta; git rebase --skip @args }
function grh { Write-Host "git reset HEAD $args" -ForegroundColor Magenta; git reset HEAD @args }
function grhh { Write-Host "git reset HEAD --hard $args" -ForegroundColor Magenta; git reset HEAD --hard @args }
function grmv { Write-Host "git remote rename $args" -ForegroundColor Magenta; git remote rename @args }
function grrm { Write-Host "git remote remove $args" -ForegroundColor Magenta; git remote remove @args }
function grset { Write-Host "git remote set-url $args" -ForegroundColor Magenta; git remote set-url @args }
function grt { Write-Host "cd $(git rev-parse --show-toplevel || Write-Output '.') $args" -ForegroundColor Magenta; Set-Location $(git rev-parse --show-toplevel || Write-Output '.') @args }
function gru { Write-Host "git reset -- $args" -ForegroundColor Magenta; git reset -- @args }
function grup { Write-Host "git remote update $args" -ForegroundColor Magenta; git remote update @args }
function grv { Write-Host "git remote -v $args" -ForegroundColor Magenta; git remote -v @args }
function gs {
    param (
        [Parameter(Position = 0)]
        [string]$br = 'd'
    )
    $branchMatch = switch ($br) {
        d { 'dev(|el|elop)' }
        q { '(qa|stage)' }
        m { 'ma(in|ster)' }
        Default { $br }
    }
    $branch = "$((git branch -a --format='%(refname:short)') -match "\b${branchMatch}$" | Select-Object -First 1)".Replace('origin/', '')
    if ($branch) {
        Write-Host "git switch $branch" -ForegroundColor Magenta
        git switch $branch
    } else {
        Write-Host "invalid reference: $br" -ForegroundColor Magenta
    }
}
function gsb { Write-Host "git status -sb $args" -ForegroundColor Magenta; git status -sb @args }
function gsd { Write-Host "git svn dcommit $args" -ForegroundColor Magenta; git svn dcommit @args }
function gsi { Write-Host "git submodule init $args" -ForegroundColor Magenta; git submodule init @args }
function gsps { Write-Host "git show --pretty=short --show-signature $args" -ForegroundColor Magenta; git show --pretty=short --show-signature @args }
function gsr { Write-Host "git svn rebase $args" -ForegroundColor Magenta; git svn rebase @args }
function gss { Write-Host "git status -s $args" -ForegroundColor Magenta; git status -s @args }
function gst { Write-Host "git status $args" -ForegroundColor Magenta; git status @args }
function gsta { Write-Host "git stash save $args" -ForegroundColor Magenta; git stash save @args }
function gstaa { Write-Host "git stash apply $args" -ForegroundColor Magenta; git stash apply @args }
function gstc { Write-Host "git stash clear $args" -ForegroundColor Magenta; git stash clear @args }
function gstd { Write-Host "git stash drop $args" -ForegroundColor Magenta; git stash drop @args }
function gstl { Write-Host "git stash list $args" -ForegroundColor Magenta; git stash list @args }
function gstp { Write-Host "git stash pop $args" -ForegroundColor Magenta; git stash pop @args }
function gsts { Write-Host "git stash show --text $args" -ForegroundColor Magenta; git stash show --text @args }
function gsu { Write-Host "git submodule update $args" -ForegroundColor Magenta; git submodule update @args }
function gts { Write-Host "git tag -s $args" -ForegroundColor Magenta; git tag -s @args }
function gtv { Write-Host "git tag $args" -ForegroundColor Magenta; git tag @args }
function gunignore { Write-Host "git update-index --no-assume-unchanged $args" -ForegroundColor Magenta; git update-index --no-assume-unchanged @args }
function gup { Write-Host "git pull --rebase $args" -ForegroundColor Magenta; git pull --rebase @args }
function gupa { Write-Host "git pull --rebase --autostash $args" -ForegroundColor Magenta; git pull --rebase --autostash @args }
function gupav { Write-Host "git pull --rebase --autostash -v $args" -ForegroundColor Magenta; git pull --rebase --autostash -v @args }
function gupv { Write-Host "git pull --rebase -v $args" -ForegroundColor Magenta; git pull --rebase -v @args }
function gwch { Write-Host "git whatchanged -p --abbrev-commit --pretty=medium $args" -ForegroundColor Magenta; git whatchanged -p --abbrev-commit --pretty=medium @args }
