# gitlab-ci-runner-nodejs ¯\_(ツ)_/¯.

FROM ubuntu:14.04
MAINTAINER  Khang Hoang "hoangtrieukhang@gmail.com"

# Based on https://github.com/gitlabhq/gitlab-ci-runner/blob/master/Dockerfile
# by Sytse Sijbrandij <sytse@gitlab.com>

# This script will start a runner in a docker container.
#
# First build the container and give a name to the resulting image:
# docker build -t codingforce/gitlab-ci-runner-nodejs github.com/bkw/gitlab-ci-runner-nodejs
#
# Then set the environment variables and run the gitlab-ci-runner in the container:
# docker run -e CI_SERVER_URL=https://ci.example.com -e REGISTRATION_TOKEN=replaceme -e HOME=/root -e GITLAB_SERVER_FQDN=gitlab.example.com codingforce/gitlab-ci-runner-nodejs
#
# After you start the runner you can send it to the background with ctrl-z
# The new runner should show up in the GitLab CI interface on /runners
#
# You can start an interactive session to test new commands with:
# docker run -e CI_SERVER_URL=https://ci.example.com -e REGISTRATION_TOKEN=replaceme -e HOME=/root -i -t codingforce/gitlab-ci-runner-nodejs:latest /bin/bash
#
# If you ever want to freshly rebuild the runner please use:
# docker build -no-cache -t codingforce/gitlab-ci-runner-nodejs github.com/bkw/gitlab-ci-runner-nodejs

# Set the HOME directory to /root
ENV HOME /root

# Update your packages and install the ones that are needed to compile Ruby
RUN apt-get update -y
RUN apt-get install -y \
  wget \
  curl \
  gcc \
  libxml2-dev \
  libxslt-dev \
  libcurl4-openssl-dev \
  libreadline6-dev \
  libc6-dev \
  libssl-dev \
  make \
  build-essential \
  zlib1g-dev \
  openssh-server \
  git-core \
  libyaml-dev \
  postfix \
  libicu-dev \
  libfreetype6 \
  libfontconfig1 \
  python-software-properties \
  libfreetype6

# Fix upstart under a virtual host https://github.com/dotcloud/docker/issues/1024
# RUN dpkg-divert --local --rename --add /sbin/initctl
# RUN ln -nfs /bin/true /sbin/initctl

# Set the right locale
RUN echo "LC_ALL=\"en_US.UTF-8\"" >> /etc/default/locale
RUN locale-gen en_US.UTF-8
RUN update-locale LANG=en_US.UTF-8

# Download Ruby and compile it
RUN mkdir /tmp/ruby && cd /tmp/ruby && curl -s http://ftp.ruby-lang.org/pub/ruby/ruby-2.0-stable.tar.bz2 | tar xj --strip-components=1
RUN cd /tmp/ruby && ./configure --disable-install-rdoc --silent && make && make install
RUN rm -rf /tmp/ruby

# don't install ruby rdocs or ri:
RUN echo "gem: --no-rdoc --no-ri" >> /usr/local/etc/gemrc

# Prepare a known host file for non-interactive ssh connections
RUN mkdir -p /root/.ssh
RUN touch /root/.ssh/known_hosts

# Install the runner
RUN mkdir /gitlab-ci-runner && cd /gitlab-ci-runner && curl -sL https://github.com/gitlabhq/gitlab-ci-runner/archive/v5.0.0.tar.gz | tar xz --strip-components=1

# Install the gems for the runner
RUN cd /gitlab-ci-runner && gem install bundler && bundle install

# Install some usefull gems for web development
RUN gem install compass sass

# Download nodejs and compile it
RUN mkdir /tmp/node && cd /tmp/node && curl -s http://nodejs.org/dist/node-latest.tar.gz | tar xz --strip-components=1
RUN cd /tmp/node  && ./configure && make && make install
RUN rm -rf /tmp/node

# update npm and install some basics
RUN ["/bin/bash","-i","-l","-c","npm update -g npm"]
RUN ["/bin/bash","-i","-l","-c","npm install -g grunt grunt-cli bower jshint jsxhint gulp"]

# When the image is started add the remote server key, install the runner and run it
WORKDIR /gitlab-ci-runner
CMD ["/bin/bash","-i","-l","-c","ssh-keyscan -H $GITLAB_SERVER_FQDN >> /root/.ssh/known_hosts & bundle exec ./bin/setup_and_run"]

