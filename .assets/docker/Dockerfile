FROM ubuntu:24.04

# avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

# optional GitHub token build-arg. forwarded to linux_setup.sh below so the
# get_gh_release_latest helper in source.sh can authenticate against
# api.github.com - shared CI runner IPs routinely exhaust the 60/hr public
# rate limit. CI passes secrets.GITHUB_TOKEN; local builds work without it.
ARG GITHUB_TOKEN=""

# copy the entire .assets folder into the container
COPY .assets /home/ubuntu/source/lss/.assets
COPY modules /home/ubuntu/source/lss/modules

# install dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends sudo \
    # allow ubuntu user to run sudo without password
    && echo "ubuntu ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ubuntu-nopasswd \
    && chmod 0440 /etc/sudoers.d/ubuntu-nopasswd \
    # change ownership to the ubuntu user
    && chown -R ubuntu:ubuntu /home/ubuntu/source \
    # setup the container for the ubuntu user. su -c clears env, so inject
    # GITHUB_TOKEN as a command-prefix env var (the build-arg expands here).
    && su - ubuntu -c 'cd "$HOME/source/lss" && GITHUB_TOKEN='"'$GITHUB_TOKEN'"' .assets/scripts/linux_setup.sh --skip_gh_auth true --scope "pwsh" --omp_theme base' \
    #
    # clean up
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/* /home/ubuntu/source

# switch to the 'ubuntu' user
USER ubuntu

# set the working directory
WORKDIR /home/ubuntu

# switch back to dialog for any ad-hoc use of apt
ENV DEBIAN_FRONTEND=dialog

# use PowerShell as the default shell
ENTRYPOINT [ "/usr/bin/pwsh" ]
