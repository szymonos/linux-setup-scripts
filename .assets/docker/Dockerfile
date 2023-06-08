FROM mcr.microsoft.com/powershell:alpine-3.17

# copy configuration files
COPY linux-setup-scripts/.assets/config/pwsh_cfg/* /tmp/cfg/
COPY linux-setup-scripts/.assets/config/omp_cfg/base.omp.json /tmp/cfg/
COPY ps-modules/modules/do-common/ /usr/local/share/powershell/Modules/do-common
COPY ps-modules/modules/do-linux/ /usr/local/share/powershell/Modules/do-linux
COPY ps-modules/modules/aliases-git/ /usr/local/share/powershell/Modules/aliases-git

RUN \
    # install common utilities
    apk add --no-cache bind-tools curl exa git iputils mandoc nmap openssh-client openssl tree tzdata unzip vim \
    # set localtime for exa
    && ln -s /usr/share/zoneinfo/UTC /etc/localtime \
    # setup PS modules
    && pwsh -nop -c \
        'Install-Module PowerShellGet -AllowPrerelease -Scope AllUsers -Force \
        && Set-PSResourceRepository -Name PSGallery -Trusted \
        && Install-PSResource -Name posh-git -Scope AllUsers \
        && Update-Help -ErrorAction SilentlyContinue || $true' \
    # install oh-my-posh
    && curl -LsOk "https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-amd64" \
    && install -m 0755 posh-linux-amd64 /usr/bin/oh-my-posh && rm -f posh-linux-amd64 \
    # install profile
    && mkdir -p /opt/microsoft/powershell/7 \
    && install -m 0644 /tmp/cfg/profile.ps1 /opt/microsoft/powershell/7 \
    # install aliases functions
    && mkdir -p /usr/local/share/powershell/Scripts \
    && install -m 0644 /tmp/cfg/_aliases_common.ps1 /usr/local/share/powershell/Scripts \
    && install -m 0644 /tmp/cfg/_aliases_linux.ps1 /usr/local/share/powershell/Scripts \
    # install and setup oh-my-posh theme
    && mkdir -p /usr/local/share/oh-my-posh \
    && install -m 0644 /tmp/cfg/base.omp.json /usr/local/share/oh-my-posh/theme.omp.json \
    && oh-my-posh disable notice \
    # cleanup
    && rm -rf /tmp/*

# use PowerShell as the default shell
ENTRYPOINT [ "/usr/bin/pwsh", "-Login" ]
