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
  git reset $(git merge-base $(grt)/$br HEAD)
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
alias gbd!='git branch -D'
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
alias gac='git add --all && git commit -v -a'
alias gca!='git commit -v -a --amend'
alias gac!='git add --all && git commit -v -a --amend'
alias gcam='git commit -a -m'
alias gacm='git add --all && git commit -a -m'
alias gcan!='git commit -v -a --no-edit --amend'
alias gacn!='git add --all && git commit -v -a --no-edit --amend'
alias gcans!='git commit -v -a -s --no-edit --amend'
alias gacns!='git add --all && git commit -v -a -s --no-edit --amend'
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
alias gfo='git fetch $(grt)'
alias gg='git grep --ignore-case'
alias gge='git grep --ignore-case --extended-regexp'
alias ggp='git grep --ignore-case --perl-regexp'
alias ghh='git help'
alias gignore='git update-index --assume-unchanged'
alias gignored='git ls-files -v | grep "^[[:lower:]]"'
alias glo='git log --date=rfc'
alias gloa='git log --date=rfc --all'
alias glog='git log --date=rfc --graph'
alias gloga='git log --date=rfc --graph --decorate --all'
alias glol='git log --graph --pretty='\''%C(yellow)%h%C(reset) %C(green)(%cr)%C(reset)%C(red)%d%C(reset) %s %C(bold blue)<%an>%C(reset)'\'' --abbrev-commit'
alias glola='git log --graph --pretty='\''%C(yellow)%h%C(reset) %C(green)(%cr)%C(reset)%C(red)%d%C(reset) %s %C(bold blue)<%an>%C(reset)'\'' --abbrev-commit --all'
alias glon='git log --oneline --decorate'
alias glona='git log --oneline --decorate --all'
alias glong='git log --oneline --decorate --graph'
alias glonga='git log --oneline --decorate --graph --all'
alias glont='git log --oneline --decorate --no-walk --tags="*"'
alias glop='git log --pretty='\''%C(yellow)%h%C(reset) %C(green)(%ai)%C(reset)%C(red)%d%C(reset) %s %C(bold blue)<%ae>%C(reset)'\'' --abbrev-commit'
alias glopa='git log --pretty='\''%C(yellow)%h%C(reset) %C(green)(%ai)%C(reset)%C(red)%d%C(reset) %s %C(bold blue)<%ae>%C(reset)'\'' --abbrev-commit --all'
alias glos='git log --stat'
alias glosa='git log --stat --all'
alias glosp='git log --stat --patch'
alias glospa='git log --stat --patch --all'
alias gmg='git merge'
alias gmgo='git fetch $(grt) $(git_current_branch) --quiet && git merge $(grt)/$(git_current_branch)'
alias gmt='git mergetool --no-prompt'
alias gmtvim='git mergetool --no-prompt --tool=vimdiff'
alias gpl='git pull $(grt) $(git_current_branch)'
alias gpull='git pull'
alias gpullr='git pull --rebase'
alias gpullra='git pull --rebase --autostash'
alias gpullrav='git pull --rebase --autostash -v'
alias gpullrv='git pull --rebase -v'
alias gpush='git push'
alias gpush!='git push --force'
alias gpushd='git push --dry-run'
alias gpushoat='git push $(grt) --all && git push $(grt) --tags'
alias gpushsup='git push --set-upstream origin $(git_current_branch)'
alias gpushv='git push -v'
alias grb='git rebase'
alias grba='git rebase --abort'
alias grbc='git rebase --continue'
alias grbi='git rebase -i'
alias grbo='git fetch $(grt) $(git_current_branch) --quiet && git rebase $(grt)/$(git_current_branch)'
alias grbs='git rebase --skip'
alias gr='git reset'
alias grh='git reset --hard'
alias grho='gfa && git reset --hard $(grt)/$(git_current_branch)'
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
alias grtup='git remote update $(grt)'
alias grtupp='git remote update $(grt) --prune'
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
alias gt='git tag --sort=-v:refname'
alias gts='git tag --sign'
alias gtr="git for-each-ref refs/tags/ --sort=-v:refname --format='%1B[33m%(objectname:short)%1B[m %1B[31m%(refname:short)%1B[m %(subject) %1B[1;94m%(authorname)%1B[m %1B[36m%(authoremail)%1B[m'"
alias gunignore='git update-index --no-assume-unchanged'
alias gunwip='git log -n 1 | grep -q -c "\-\-wip\-\-" && git reset HEAD~1'
alias gwch='git whatchanged -p --abbrev-commit --pretty=medium'
alias gwip='git add -A; git rm $(git ls-files --deleted) 2>/dev/null; git commit --no-verify -m "--wip-- [skip ci]"'
#endregion
