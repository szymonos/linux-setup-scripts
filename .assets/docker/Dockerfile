FROM mcr.microsoft.com/powershell

# copy configuration files
COPY .assets/config/pwsh_cfg/* /tmp/cfg/
COPY .assets/config/omp_cfg/base.omp.json /tmp/cfg/

RUN \
    # install common utilities
    apt-get update && apt-get install -y curl dnsutils exa git man-db openssl tree unzip vim \
    # setup PS modules
    && pwsh -nop -c \
    "Install-Module PowerShellGet -AllowPrerelease -Scope AllUsers -Force \
    && Set-PSResourceRepository -Name PSGallery -Trusted \
    && Install-PSResource -Name posh-git -Scope AllUsers \
    && Update-Help" \
    # install oh-my-posh
    && curl -LsOk "https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-amd64" \
    && install -o root -g root -m 0755 posh-linux-amd64 /usr/bin/oh-my-posh && rm -f posh-linux-amd64 \
    # install profile
    && mkdir -p /opt/microsoft/powershell/7 \
    && install -o root -g root -m 0644 /tmp/cfg/profile.ps1 /opt/microsoft/powershell/7 \
    # install aliases functions
    && mkdir -p /usr/local/share/powershell/Scripts \
    && install -o root -g root -m 0644 /tmp/cfg/_aliases_common.ps1 /usr/local/share/powershell/Scripts \
    && install -o root -g root -m 0644 /tmp/cfg/_aliases_git.ps1 /usr/local/share/powershell/Scripts \
    && install -o root -g root -m 0644 /tmp/cfg/_aliases_linux.ps1 /usr/local/share/powershell/Scripts \
    # install oh-my-posh theme
    && mkdir -p /usr/local/share/oh-my-posh \
    && install -o root -g root -m 0644 /tmp/cfg/base.omp.json /usr/local/share/oh-my-posh/theme.omp.json \
    # cleanup
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/* /tmp/*

# use PowerShell as the default shell
ENTRYPOINT [ "/usr/bin/pwsh", "-Login" ]
