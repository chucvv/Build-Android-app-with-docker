#Created date 04/18/2020
##Overview##
#0. Setup python to support run automatic task
#1. Setup gralde
#2. Android sdk
#3. Firebase testlab
#4. Firebase CLI to deploy to Firebase App Distribution
#5. Download some Robolectric lib to Robolectric can work offline behind the proxy
#   (Using Robolectric version is 4.3.1)
#6. Ruby env to run Danger

FROM ubuntu:18.04
LABEL maintainer "chucvv"

ARG ANDROID_API_LEVEL=28
ARG ANDROID_BUILD_TOOLS_LEVEL=28.0.3
ARG PROXY_HOST=172.0.0.1
ARG PROXY_PORT=3128
ARG PROXY="http://$PROXY_HOST:$PROXY_PORT"

ENV http_proxy $PROXY
ENV https_proxy $PROXY

ENV SDKMAN_OPTS="--proxy=http --proxy_host=${PROXY_HOST} --proxy_port=${PROXY_PORT}"

RUN export HTTP_PROXY=$PROXY
RUN export HTTPS_PROXY=$PROXY

ARG ANDROID_SDK_VERSION="sdk-tools-linux-4333796.zip"

ARG ANDROID_PLATFORM_VERSION="platforms;android-${ANDROID_API_LEVEL}"
ARG ANDROID_BUILD_TOOL="build-tools;${ANDROID_BUILD_TOOLS_LEVEL}"
ARG ANDROID_GOOGLE_REPOS="extras;android;m2repository extras;google;google_play_services extras;google;m2repository"
ARG ANDROID_SDK_PACKAGES="${ANDROID_PLATFORM_VERSION} ${ANDROID_BUILD_TOOL} platform-tools ${ANDROID_GOOGLE_REPOS}"

SHELL ["/bin/bash", "-c"]
RUN apt clean && apt update && apt install -y locales && rm -rf /var/lib/apt/lists/* \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8
RUN apt clean && apt update && apt install -y git curl openjdk-8-jdk wget unzip 

# Setup Python env for auto dev
RUN yes Y | apt install -y python-pip
RUN yes Y | apt install build-essential libssl-dev libffi-dev python-dev #There are a few more packages and development tools to install to ensure that we have a robust set-up for our programming environment
RUN yes Y | pip install --upgrade google-api-python-client oauth2client
RUN yes Y | pip install requests
# gradle
ENV GRADLE_USER_HOME=/cache
VOLUME $GRADLE_USER_HOME

# Download Android SDK
ENV ANDROID_HOME="/usr/local/android-sdk"
RUN mkdir "$ANDROID_HOME" .android 
RUN wget https://dl.google.com/android/repository/$ANDROID_SDK_VERSION -P /tmp
RUN unzip -d $ANDROID_HOME /tmp/$ANDROID_SDK_VERSION
ENV PATH "$PATH:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools"

# Android NDK (optinal), size of sdk so big
#ENV ANDROID_NDK_HOME /opt/android-ndk
#RUN mkdir /opt/android-ndk-tmp
#RUN cd /opt/android-ndk-tmp && wget -q http://dl.google.com/android/ndk/android-ndk-r10e-linux-x86_64.bin
#RUN cd /opt/android-ndk-tmp && chmod a+x ./android-ndk-r10e-linux-x86_64.bin
#RUN cd /opt/android-ndk-tmp && ./android-ndk-r10e-linux-x86_64.bin
#RUN cd /opt/android-ndk-tmp && mv ./android-ndk-r10e /opt/android-ndk
#RUN rm -rf /opt/android-ndk-tmp
#ENV PATH ${PATH}:${ANDROID_NDK_HOME}

# sdkmanager
RUN mkdir -p /root/.android && touch /root/.android/repositories.cfg
RUN yes Y | sdkmanager --licenses $SDKMAN_OPTS 
RUN $ANDROID_HOME/tools/bin/sdkmanager --update $SDKMAN_OPTS
RUN yes Y | sdkmanager --verbose --no_https  $SDKMAN_OPTS $ANDROID_SDK_PACKAGES

# Install gcloud for Firebase test lab
RUN export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)" && echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

# Install Firebase CLI to deploy app to Firebae app distribution
RUN curl -Lo /usr/local/bin/firebase https://firebase.tools/bin/linux/latest
RUN chmod +x /usr/local/bin/firebase
RUN curl -sL firebase.tools | upgrade=true bash
# Download dependencies lib for ready in use behind the proxy
ARG DEPENDENCIES_PATH="/opt/libs/robolectric"
RUN mkdir -p $DEPENDENCIES_PATH
#Make sure you're using Robolectri version 4.3.1 to match these files or you need to change
RUN curl -Lo $DEPENDENCIES_PATH/android-all-9-robolectric-4913185-2.jar https://repo1.maven.org/maven2/org/robolectric/android-all/9-robolectric-4913185-2/android-all-9-robolectric-4913185-2.jar
RUN curl -Lo $DEPENDENCIES_PATH/android-all-5.0.2_r3-robolectric-r0.jar https://repo1.maven.org/maven2/org/robolectric/android-all/5.0.2_r3-robolectric-r0/android-all-5.0.2_r3-robolectric-r0.jar 
ENV ROBOLECTRIC_HOME=$DEPENDENCIES_PATH

## Setup Ruby env to support Danger 
# Dependencies required to install Ruby:
RUN apt install -y autoconf bison build-essential libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libncurses5-dev libffi-dev libgdbm5 libgdbm-dev
# Config proxy for git
RUN git config --global url."https://github.com/".insteadOf git@github.com:
RUN git config --global url."https://".insteadOf git://
# Install rbenv
ENV RUBY_HOME=/root
RUN git clone https://github.com/rbenv/rbenv.git $RUBY_HOME/.rbenv \
  &&  echo 'export PATH="$RUBY_HOME/.rbenv/bin:$RUBY_HOME/.rbenv/shims:$PATH"' >> ~/.bashrc \
  &&  echo 'eval "$(rbenv init -)"' >> ~/.bashrc
RUN source ~/.bashrc
ENV PATH "$PATH:$RUBY_HOME/.rbenv/bin:$RUBY_HOME/.rbenv/shims"
RUN rbenv init -
RUN type rbenv
# Install ruby build
RUN git clone https://github.com/rbenv/ruby-build.git $RUBY_HOME/.rbenv/plugins/ruby-build
ENV PATH "$PATH:$RUBY_HOME/.rbenv/plugins/ruby-build/bin"
# Install ruby version and setting it up
ENV RUBY_VERSION=2.6.3
RUN rbenv install $RUBY_VERSION
RUN rbenv global $RUBY_VERSION
RUN rbenv global
RUN ruby -v
RUN echo "gem: --no-document" >> $RUBY_HOME/.gemrc
RUN gem update --system
RUN gem install bundler

# clean up
RUN  apt remove -y unzip wget && apt clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* 
# make working dir in container
RUN mkdir /application
WORKDIR /application
