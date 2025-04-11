FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV HOME=/home/kasm-user
ENV STARTUPDIR=/dockerstartup
ENV INST_SCRIPTS=/dockerstartup/install
ENV KASM_VNC_PATH=/usr/share/kasmvnc
ENV TZ=Asia/Seoul

WORKDIR $HOME

# 필수 패키지 설치
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    sudo \
    curl \
    gnupg2 \
    git \
    python3 \
    python3-pip \
    software-properties-common \
    build-essential \
    net-tools \
    locales \
    libfuse2 \
    fuse \
    kmod \
    xfce4 \
    xfce4-terminal \
    xfce4-goodies \
    fonts-noto-cjk \
    fonts-noto-cjk-extra \
    ibus \
    ibus-hangul \
    uim \
    uim-byeoru \
    fcitx \
    fcitx-hangul \
    im-config \
    tzdata \
    vim \
    alsa-utils \
    x11-utils \
    openssh-client \
    zip \
    unzip \
    htop \
    neofetch \
    dbus \
    dbus-x11 \
    policykit-1 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 시간대 설정
RUN ln -fs /usr/share/zoneinfo/$TZ /etc/localtime && dpkg-reconfigure -f noninteractive tzdata

# 로케일 설정
RUN locale-gen ko_KR.UTF-8
ENV LANG='ko_KR.UTF-8' LANGUAGE='ko_KR:ko' LC_ALL='ko_KR.UTF-8'

# KasmVNC 설치
RUN mkdir -p $INST_SCRIPTS \
    && mkdir -p $STARTUPDIR \
    && mkdir -p $KASM_VNC_PATH \
    && cd /tmp \
    && curl -fsSL -O https://github.com/kasmtech/KasmVNC/releases/download/v1.2.0/kasmvncserver_jammy_1.2.0_amd64.deb \
    && apt-get update \
    && apt-get install -y ./kasmvncserver_jammy_1.2.0_amd64.deb \
    && rm -f ./kasmvncserver_jammy_1.2.0_amd64.deb \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# VSCode 설치
RUN wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | apt-key add - \
    && add-apt-repository "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" \
    && apt-get update \
    && apt-get install -y code \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
    
# 사용자 추가
RUN useradd -m -d $HOME -s /bin/bash kasm-user \
    && echo "kasm-user ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers \
    && usermod -aG sudo kasm-user

# FUSE 권한 설정
RUN chmod a+x /usr/bin/fusermount \
    && sed -i 's/#user_allow_other/user_allow_other/g' /etc/fuse.conf

# Firefox 최신 버전 설치
RUN mkdir -p /opt/firefox \
    && wget -O /tmp/firefox-latest.tar.xz "https://download.mozilla.org/?product=firefox-latest-ssl&os=linux64&lang=ko" \
    && tar -xf /tmp/firefox-latest.tar.xz -C /opt/firefox \
    && rm /tmp/firefox-latest.tar.xz \
    && ln -s /opt/firefox/firefox/firefox /usr/local/bin/firefox \
    && chown -R kasm-user:kasm-user /opt/firefox

# Firefox 데스크톱 파일 생성
RUN mkdir -p $HOME/.local/share/applications \
    && echo "[Desktop Entry]\nVersion=1.0\nName=Firefox\nComment=Browse the Web\nExec=/opt/firefox/firefox/firefox %u\nIcon=/opt/firefox/firefox/browser/chrome/icons/default/default128.png\nTerminal=false\nType=Application\nCategories=Network;WebBrowser;\nMimeType=text/html;text/xml;application/xhtml+xml;application/vnd.mozilla.xul+xml;text/mml;x-scheme-handler/http;x-scheme-handler/https;" > $HOME/.local/share/applications/firefox.desktop \
    && chmod +x $HOME/.local/share/applications/firefox.desktop

# Firefox를 기본 웹 브라우저로 설정
RUN mkdir -p $HOME/.config/xfce4/xfconf/xfce-perchannel-xml/ \
    && echo '<?xml version="1.0" encoding="UTF-8"?>\n<channel name="xfce4-settings-manager" version="1.0">\n  <property name="last" type="empty">\n    <property name="window-width" type="int" value="640"/>\n    <property name="window-height" type="int" value="500"/>\n  </property>\n</channel>' > $HOME/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-settings-manager.xml \
    && mkdir -p $HOME/.config/mimeapps.list.d \
    && echo "[Default Applications]\ntext/html=firefox.desktop\nx-scheme-handler/http=firefox.desktop\nx-scheme-handler/https=firefox.desktop\nx-scheme-handler/about=firefox.desktop\napplication/xhtml+xml=firefox.desktop" > $HOME/.config/mimeapps.list \
    && update-alternatives --install /usr/bin/x-www-browser x-www-browser /opt/firefox/firefox/firefox 100 \
    && update-alternatives --install /usr/bin/gnome-www-browser gnome-www-browser /opt/firefox/firefox/firefox 100 \
    && xdg-settings set default-web-browser firefox.desktop

# 한국어 입력기 설정
RUN mkdir -p $HOME/.config/ibus/bus && \
    mkdir -p $HOME/.config/fcitx/conf && \
    mkdir -p $HOME/.config/autostart && \
    echo "[Desktop Entry]\nName=Fcitx\nComment=Start Fcitx\nExec=fcitx -d\nIcon=fcitx\nTerminal=false\nType=Application\nCategories=System;Utility;\nStartupNotify=false\nX-GNOME-Autostart-Phase=Applications\nX-GNOME-Autostart-Delay=0\nX-GNOME-AutoRestart=false\nX-KDE-autostart-after=panel\nX-KDE-autostart-phase=1" > $HOME/.config/autostart/fcitx.desktop

# AppImage 지원 추가
RUN apt-get update && apt-get install -y --no-install-recommends \
    libglib2.0-0 \
    libgl1-mesa-glx \
    libegl1 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 시작 스크립트 추가
COPY startup.sh $STARTUPDIR/
RUN chmod +x $STARTUPDIR/startup.sh

# X11 디렉토리 및 권한 설정
RUN mkdir -p /tmp/.X11-unix && \
    chmod 1777 /tmp/.X11-unix && \
    mkdir -p $HOME/.vnc && \
    chmod 755 $HOME/.vnc && \
    mkdir -p $HOME/.config && \
    chmod 755 $HOME/.config && \
    chown -R kasm-user:kasm-user $HOME

# dbus 설정
RUN mkdir -p /var/run/dbus && \
    chown kasm-user:kasm-user /var/run/dbus && \
    dbus-uuidgen > /etc/machine-id

# XFCE 설정
COPY xfce4 $HOME/.config/xfce4/
RUN chown -R kasm-user:kasm-user $HOME/.config

USER kasm-user

# 포트 및 볼륨 설정
EXPOSE 6901
VOLUME ["$HOME"]

# 컨테이너 시작 명령
ENTRYPOINT ["/dockerstartup/startup.sh"] 