FROM ubuntu:16.04
MAINTAINER Yuanhui Liu <46682884@qq.com>

#===============================
# Customize sources for apt-get
#===============================
RUN echo "deb http://archive.ubuntu.com/ubuntu xenial main universe\n" > /etc/apt/sources.list \
  && echo "deb http://archive.ubuntu.com/ubuntu xenial-updates main universe\n" >> /etc/apt/sources.list \
  && echo "deb http://security.ubuntu.com/ubuntu xenial-security main universe\n" >> /etc/apt/sources.list

#===================================================================
# Miscellaneous packages
# Includes minimal runtime used for executing non GUI Java programs
#===================================================================
RUN apt-get update -qqy \
  && apt-get -qqy --no-install-recommends install \
    ca-certificates \
    openjdk-8-jdk-headless \
    wget \
  && rm -rf /var/lib/apt/lists/* \
  && sed -i 's/securerandom\.source=file:\/dev\/random/securerandom\.source=file:\/dev\/urandom/' ./usr/lib/jvm/java-8-openjdk-amd64/jre/lib/security/java.security

#=============
# Android SDK
#=============
ENV ANDROID_SDK_VERSION 24.4.1
ENV ANDROID_HOME /opt/android-sdk-linux
ENV PATH ${PATH}:${ANDROID_HOME}/tools:${ANDROID_HOME}/platform-tools
RUN cd /opt \
  && wget --no-verbose http://dl.google.com/android/android-sdk_r$ANDROID_SDK_VERSION-linux.tgz -O android-sdk.tgz \
  && tar xzf android-sdk.tgz \
  && rm -f android-sdk.tgz \
  && cd android-sdk-linux/tools \
  && mv -f emulator64-arm emulator \
  && rm -f emulator64* emulator-* \
  && chmod +x android emulator

#=====================
# Android SDK Manager
#=====================
ENV ANDROID_COMPONENTS platform-tools,build-tools-25.0.3
RUN echo y | android update sdk --all --force --no-ui --filter ${ANDROID_COMPONENTS}

#===================
# Nodejs and Appium
#===================
USER appium
ENV APPIUM_VERSION 1.4.16
RUN apt-get update -qqy \
  && apt-get -qqy --no-install-recommends install \
    nodejs \
    npm \
  && ln -s /usr/bin/nodejs /usr/bin/node \
  && npm install -g appium@$APPIUM_VERSION \
  && npm cache clean \
  && apt-get remove --purge -y npm \
  && apt-get autoremove --purge -y \
  && rm -rf /var/lib/apt/lists/*

#============================================
# Add udev rules file with USB configuration
#============================================
USER root

ENV UDEV_REMOTE_FILE https://raw.githubusercontent.com/M0Rf30/android-udev-rules/master/51-android.rules
RUN mkdir /etc/udev/rules.d \
  && wget --no-verbose $UDEV_REMOTE_FILE -O /etc/udev/rules.d/51-android.rules

#===========================================
# Robot Framework For Appium
#===========================================
RUN apt-get install -y python-pip \
    && pip install --upgrade pip \
    && pip install robotframework==3.* \
    && pip install robotframework-appiumlibrary==1.4.6 \
    && pip install robotframework-faker \
    && pip install robotframework-debuglibrary \
    && pip install robotframework-databaselibrary \
    && pip install robotframework-mongodblibrary==0.3.4 \
    && pip install robotframework-excellibrary==0.0.2 \
    
# Appium server port
EXPOSE 4723

CMD appium