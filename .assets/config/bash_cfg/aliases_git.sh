#region functions
function git_current_branch {
  git branch --show-current
}

function git_resolve_branch {
  case "$1" in
  '')
    pattern='(^|/)dev(|el|elop|elopment)$|(^|/)ma(in|ster)$|(^|/)trunk$'
    ;;
  d)
    pattern='(^|/)dev(|el|elop|elopment)$'
    ;;
  m)
    pattern='(^|/)ma(in|ster)$'
    ;;
  s)
    pattern='(^|/)stage$'
    ;;
  t)
    pattern='(^|/)trunk$'
    ;;
  *)
    pattern="$1"
    ;;
  esac

  br=$(git branch -a --format='%(refname:short)' | sed -E 's/.*\///' | grep -E "$pattern" | sort -u | head -1)

  [ -n "$br" ] && echo "$br" || echo "$pattern"
}

function gsw {
  br=$(git_resolve_branch $1)
  git switch $(git_resolve_branch $br)
}

function grmb {
  br=$(git_resolve_branch $1)
  git reset $(git merge-base origin/$br HEAD)
}
#endregion

#region aliases
alias ga='git add'
alias gaa='git add --all'
alias gapa='git add --patch'
alias gau='git add --update'
alias gbl='git blame -b -w'
alias gb='git branch'
alias gba='git branch -a'
alias gbd='git branch -d'
alias gbda='git branch --format="%(refname:short)" --merged | command grep -vE "^ma(in|ster)$|^dev(|el|elop)$|^qa$|^stage$|^trunk$" | command xargs -n 1 git branch -d'
alias gbnm='git branch --no-merged'
alias gbr='git branch --remote'
alias gbsu='git branch --set-upstream-to=origin/$(git_current_branch)'
alias gbs='git bisect'
alias gbsb='git bisect bad'
alias gbsg='git bisect good'
alias gbsr='git bisect reset'
alias gbss='git bisect start'
alias gcv='git commit -v'
alias gc!='git commit -v --amend'
alias gca='git commit -v -a'
alias gaca='git add --all && git commit -v -a'
alias gca!='git commit -v -a --amend'
alias gaca!='git add --all && git commit -v -a --amend'
alias gcam='git commit -a -m'
alias gacam='git add --all && git commit -a -m'
alias gcan!='git commit -v -a --no-edit --amend'
alias gacan!='git add --all && git commit -v -a --no-edit --amend'
alias gcans!='git commit -v -a -s --no-edit --amend'
alias gacans!='git add --all && git commit -v -a -s --no-edit --amend'
alias gcmsg='git commit -m'
alias gcn!='git commit -v --no-edit --amend'
alias gcsm='git commit -s -m'
alias gcd='cd $(git rev-parse --show-toplevel || echo ".")'
alias gcf='git config'
alias gcfg='git config --global'
alias gcfge='git config --global --edit'
alias gcfgl='git config --global --list'
alias gcfl='git config --local'
alias gcfle='git config --local --edit'
alias gcfll='git config --local --list'
alias gcl='git clone --recursive'
alias gclean='git clean -fd'
alias gclean!='git reset --hard --quiet && git clean -fd'
alias gpristine='git reset --hard && git clean -dfx'
alias gco='git checkout'
alias gcount='git shortlog -sn'
alias gcp='git cherry-pick'
alias gcpa='git cherry-pick --abort'
alias gcpc='git cherry-pick --continue'
alias gcps='git cherry-pick -s'
alias gd='git diff'
alias gdca='git diff --cached'
alias gdct='git describe --tags `git rev-list --tags --max-count=1`'
alias gdt='git diff-tree --no-commit-id --name-only -r'
alias gdw='git diff --word-diff'
alias gf='git fetch'
alias gfa='git fetch --all --prune'
alias gfo='git fetch origin'
alias gg='git grep --ignore-case'
alias gge='git grep --ignore-case --extended-regexp'
alias ggp='git grep --ignore-case --perl-regexp'
alias ghh='git help'
alias gignore='git update-index --assume-unchanged'
alias gignored='git ls-files -v | grep "^[[:lower:]]"'
alias git-svn-dcommit-push='git svn dcommit && git push github master:svntrunk'
alias glg='git log --graph'
alias glga='git log --graph --decorate --all'
alias glgm='git log --graph --max-count=10'
alias glo='git log --oneline --decorate'
alias gloa='git log --oneline --decorate --all'
alias glog='git log --oneline --decorate --graph'
alias gloga='git log --oneline --decorate --graph --all'
alias glol='git log --graph --pretty='\''%C(yellow)%h%C(reset) %C(green)(%cr)%C(reset)%C(red)%d%C(reset) %s %C(bold blue)<%an>%C(reset)'\'' --abbrev-commit'
alias glola='git log --graph --pretty='\''%C(yellow)%h%C(reset) %C(green)(%cr)%C(reset)%C(red)%d%C(reset) %s %C(bold blue)<%an>%C(reset)'\'' --abbrev-commit --all'
alias glop='git log --pretty='\''%C(yellow)%h%C(reset) %C(green)(%ai)%C(reset)%C(red)%d%C(reset) %s %C(bold blue)<%ae>%C(reset)'\'' --abbrev-commit'
alias glopa='git log --pretty='\''%C(yellow)%h%C(reset) %C(green)(%ai)%C(reset)%C(red)%d%C(reset) %s %C(bold blue)<%ae>%C(reset)'\'' --abbrev-commit --all'
alias gls='git log --stat'
alias glsp='git log --stat --patch'
alias gmg='git merge'
alias gmgom='git merge origin/master'
alias gmgum='git merge upstream/master'
alias gmt='git mergetool --no-prompt'
alias gmtvim='git mergetool --no-prompt --tool=vimdiff'
alias gpl='git pull origin $(git_current_branch)'
alias gpull='git pull'
alias gpullr='git pull --rebase'
alias gpullra='git pull --rebase --autostash'
alias gpullrav='git pull --rebase --autostash -v'
alias gpullrv='git pull --rebase -v'
alias gpullum='git pull upstream master'
alias gpush='git push'
alias gpush!='git push --force'
alias gpushd='git push --dry-run'
alias gpushoat='git push origin --all && git push origin --tags'
alias gpushsup='git push --set-upstream origin $(git_current_branch)'
alias gpushu='git push upstream'
alias gpushv='git push -v'
alias grb='git rebase'
alias grba='git rebase --abort'
alias grbc='git rebase --continue'
alias grbi='git rebase -i'
alias grbm='git rebase master'
alias grbs='git rebase --skip'
alias gr='git reset'
alias grh='git reset --hard'
alias grho='git fetch && git reset --hard origin/$(git_current_branch)'
alias grs='git reset --soft'
alias gru='git reset --'
alias grmc='git rm --cached'
alias grm!='git rm --force'
alias grmrc='git rm -r --cached'
alias grmr!='git rm -r --force'
alias grr='git restore'
alias grrs='git restore --source'
alias grt='git remote'
alias grta='git remote add'
alias grtrm='git remote remove'
alias grtrn='git remote rename'
alias grtsu='git remote set-url'
alias grtup='git remote update origin'
alias grtupp='git remote update origin --prune'
alias grtv='git remote -v'
alias gswc='git switch --create'
alias gswd='git switch --detach'
alias gsmi='git submodule init'
alias gsmu='git submodule update'
alias gsps='git show --pretty=short --show-signature'
alias gstaa='git stash apply'
alias gstac='git stash clear'
alias gstad='git stash drop'
alias gstal='git stash list'
alias gstap='git stash pop'
alias gstas='git stash save'
alias gstast='git stash show --text'
alias gst='git status'
alias gstb='git status -sb'
alias gsts='git status -s'
alias gsvnd='git svn dcommit'
alias gsvnr='git svn rebase'
alias gt='git tag'
alias gts='git tag -s'
alias gtv='git tag | sort -V'
alias gunignore='git update-index --no-assume-unchanged'
alias gunwip='git log -n 1 | grep -q -c "\-\-wip\-\-" && git reset HEAD~1'
alias gwch='git whatchanged -p --abbrev-commit --pretty=medium'
alias gwip='git add -A; git rm $(git ls-files --deleted) 2>/dev/null; git commit --no-verify -m "--wip-- [skip ci]"'
#endregion
