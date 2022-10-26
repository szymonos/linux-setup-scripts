function ga { git add }
function gaa { git add --all }
function gapa { git add --patch }
function gau { git add --update }
function gb { git branch }
function gba { git branch -a }
function gbd { git branch -d }
function gbda {
    git branch --no-color --merged `
    | Select-String -NotMatch '^(\*|\s*(master|develop|dev)\s*$)' `
    | ForEach-Object {
        git branch -d $_
    }
}
function gbl { git blame -b -w }
function gbnm { git branch --no-merged }
function gbr { git branch --remote }
function gbs { git bisect }
function gbsb { git bisect bad }
function gbsg { git bisect good }
function gbsr { git bisect reset }
function gbss { git bisect start }
function gc { git commit -v }
function gc! { git commit -v --amend }
function gca { git commit -v -a }
function gca! { git commit -v -a --amend }
function gcam { git commit -a -m }
function gcan! { git commit -v -a --no-edit --amend }
function gcans! { git commit -v -a -s --no-edit --amend }
function gcb { git checkout -b }
function gcd { git checkout develop }
function gcf { git config --list }
function gcl { git clone --recursive }
function gclean { git clean -fd }
function gcm { git checkout master }
function gcmsg { git commit -m }
function gcn! { git commit -v --no-edit --amend }
function gco { git checkout }
function gcount { git shortlog -sn }
function gcp { git cherry-pick }
function gcpa { git cherry-pick --abort }
function gcpc { git cherry-pick --continue }
function gcps { git cherry-pick -s }
function gcs { git commit -S }
function gcsm { git commit -s -m }
function gd { git diff }
function gdca { git diff --cached }
function gdct { git describe --tags `git rev-list --tags --max-count=1` }
function gdt { git diff-tree --no-commit-id --name-only -r }
function gdw { git diff --word-diff }
function gf { git fetch }
function gfa { git fetch --all --prune }
function gfo { git fetch origin }
function ggpull { git pull origin $(git_current_branch) }
function ggpur { ggu }
function ggpush { git push origin $(git_current_branch) }
function ggsup { git branch --set-upstream-to=origin/$(git_current_branch) }
function ghh { git help }
function gignore { git update-index --assume-unchanged }
function gignored { git ls-files -v | grep '^[[:lower:]]' }
function gl { git pull }
function glg { git log --stat }
function glgg { git log --graph }
function glgga { git log --graph --decorate --all }
function glgm { git log --graph --max-count=10 }
function glgp { git log --stat -p }
function glo { git log --oneline --decorate }
function glog { git log --oneline --decorate --graph }
function gloga { git log --oneline --decorate --graph --all }
function glol { git log --graph --pretty='%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit }
function glola { git log --graph --pretty='%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --all }
function glum { git pull upstream master }
function gm { git merge }
function gmom { git merge origin/master }
function gmt { git mergetool --no-prompt }
function gmtvim { git mergetool --no-prompt --tool=vimdiff }
function gmum { git merge upstream/master }
function gp { git push }
function gpd { git push --dry-run }
function gpoat { git push origin --all && git push origin --tags }
function gpristine { git reset --hard && git clean -dfx }
function gpsup { git push --set-upstream origin $(git_current_branch) }
function gpu { git push upstream }
function gpv { git push -v }
function gr { git remote }
function gra { git remote add }
function grb { git rebase }
function grba { git rebase --abort }
function grbc { git rebase --continue }
function grbi { git rebase -i }
function grbm { git rebase master }
function grbs { git rebase --skip }
function grh { git reset HEAD }
function grhh { git reset HEAD --hard }
function grmv { git remote rename }
function grrm { git remote remove }
function grset { git remote set-url }
function grt { Set-Location $(git rev-parse --show-toplevel || Write-Output '.') }
function gru { git reset -- }
function grup { git remote update }
function grv { git remote -v }
function gsb { git status -sb }
function gsd { git svn dcommit }
function gsi { git submodule init }
function gsps { git show --pretty=short --show-signature }
function gsr { git svn rebase }
function gss { git status -s }
function gst { git status }
function gsta { git stash save }
function gstaa { git stash apply }
function gstc { git stash clear }
function gstd { git stash drop }
function gstl { git stash list }
function gstp { git stash pop }
function gsts { git stash show --text }
function gsu { git submodule update }
function gts { git tag -s }
function gtv { git tag | Sort-Object -V }
function gunignore { git update-index --no-assume-unchanged }
function gunwip { git log -n 1 | grep -q -c '\-\-wip\-\-' && git reset HEAD~1 }
function gup { git pull --rebase }
function gupa { git pull --rebase --autostash }
function gupav { git pull --rebase --autostash -v }
function gupv { git pull --rebase -v }
function gwch { git whatchanged -p --abbrev-commit --pretty=medium }
function gwip { git add -A; git rm $(git ls-files --deleted) 2>/dev/null; git commit --no-verify -m '--wip-- [skip ci]' }
