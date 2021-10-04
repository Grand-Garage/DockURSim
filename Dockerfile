FROM lsiobase/guacgui:latest

# Set Version Information
ARG BUILD_DATE="10/07/20"
ARG VERSION="5.8.2.10297"
LABEL build_version="URSim Version: ${VERSION} Build Date: ${BUILD_DATE}"
LABEL maintainer="Arran Hobson Sayers"
LABEL MAINTAINER="Arran Hobson Sayers"
ENV APPNAME="URSim"

# Set Timezone
ARG TZ="Europe/London"
ENV TZ ${TZ}

# Setup Environment
ENV DEBIAN_FRONTEND noninteractive

# Set Home Directory
ENV HOME /simulator/app

# Create workdir
WORKDIR /simulator
USER root

# Set robot model - Can be UR3, UR5 or UR10
ENV ROBOT_MODEL UR5

RUN echo "**** Installing Dependencies ****"
RUN mkdir -p /usr/share/man/man1
RUN apt-get update
RUN apt-get install -qy --no-install-recommends openjdk-8-jre psmisc
#RUN apt-get install libgcc1 lib32gcc1 lib32stdc++6 libc6-i386

 # Change java alternatives so we use openjdk8 (required by URSim) not openjdk11 that comes with guacgui
#RUN update-alternatives --config java
RUN update-alternatives --install /usr/bin/java java /usr/lib/jvm/java-8-openjdk-arm64/jre/bin/java 10000

# Setup JAVA_HOME
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-arm64
RUN export JAVA_HOME

RUN echo "**** Downloading URSim ****"
 # Download URSim Linux tar.gz
RUN curl https://s3-eu-west-1.amazonaws.com/ur-support-site/71480/URSim_Linux-5.8.2.10297.tar.gz -o /simulator/URSim-Linux.tar.gz
 # Extract tarball
RUN tar xvzf /simulator/URSim-Linux.tar.gz
 #Remove the tarball
RUN rm /simulator/URSim-Linux.tar.gz
 # Rename the URSim folder
RUN mv /simulator/ursim* /simulator/app

RUN echo "**** Installing URSim ****"
 # Make URControl and all sh files executable
RUN chmod +x /simulator/app/URControl
RUN chmod +x /simulator/app/*.sh

## Replace amd64 with arm64
#RUN sed -i 's/amd64/arm64/g' /ursim/app/install.sh

 # Stop install of unnecessary packages and install required ones quietly

 # switch into app
WORKDIR /simulator/app
RUN sed -i 's|apt-get -y install|apt-get -qy install --no-install-recommends|g' /simulator/app/install.sh
 # Skip xterm command. We dont have a desktop
RUN sed -i 's|tty -s|(exit 0)|g' /simulator/app/install.sh
 # Skip Check of Java Version as we have the correct installed and the command will fail
RUN sed -i 's|needToInstallJava$|(exit 0)|g' /simulator/app/install.sh
 # Skip install of desktop shortcuts - we dont have a desktop
RUN sed -i '/for TYPE in UR3 UR5 UR10/,$ d' /simulator/app/install.sh
 # Remove commands that are not relevant on docker as we are root user
RUN sed -i 's|pkexec ||g' /simulator/app/install.sh
RUN sed -i 's|sudo ||g' /simulator/app/install.sh
RUN sed -i 's|sudo ||g' /simulator/app/ursim-certificate-check.sh

 # Install URSim
RUN sh /simulator/app/install.sh
RUN echo "Installed URSim"

RUN echo "**** Clean Up ****"
RUN rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*

# Copy ursim run service script
COPY ursim /etc/services.d/ursim

# Expose ports
# Guacamole web browser viewer
EXPOSE 8080
# VNC viewer
EXPOSE 3389
# Modbus Port
EXPOSE 502
# Interface Ports
EXPOSE 29999
EXPOSE 30001-30004

# Mount Volumes
VOLUME /simulator

ENTRYPOINT ["/init"]
