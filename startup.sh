#!/bin/bash

# KasmVNC 시작 설정 스크립트
set -e

# Set default screen resolution
RESOLUTION="${RESOLUTION:-1920x1080}"

echo "Starting KasmVNC server with resolution: $RESOLUTION"

# FUSE 모듈 로드 시도 (권한이 있는 경우)
if [ -e /dev/fuse ]; then
    echo "FUSE 장치가 감지되었습니다."
    
    # FUSE 설정 확인
    if [ -f /etc/fuse.conf ]; then
        echo "FUSE 설정 확인: user_allow_other 옵션이 활성화되어 있습니다."
        grep "user_allow_other" /etc/fuse.conf || echo "경고: user_allow_other 옵션이 활성화되어 있지 않을 수 있습니다."
    fi
    
    # FUSE 모듈 로드 시도
    if command -v modprobe > /dev/null 2>&1 && [ "$(id -u)" -eq 0 ]; then
        modprobe fuse 2>/dev/null || echo "FUSE 모듈을 로드할 수 없습니다. 이미 로드되어 있거나 권한이 없습니다."
    else
        echo "권한이 없거나 modprobe 명령을 찾을 수 없어 FUSE 모듈을 로드할 수 없습니다."
    fi
else
    echo "경고: /dev/fuse 장치를 찾을 수 없습니다. FUSE 지원이 제한될 수 있습니다."
fi

# 이전 X 서버 락 파일 정리
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1 2>/dev/null || true

# 환경 변수 설정
export LANG=ko_KR.UTF-8
export LC_ALL=ko_KR.UTF-8
export XDG_RUNTIME_DIR=/tmp/runtime-$(id -u)
export DISPLAY=:1
export XCURSOR_THEME=Adwaita

# XDG Runtime 디렉토리 생성
mkdir -p $XDG_RUNTIME_DIR
chmod 700 $XDG_RUNTIME_DIR

# dbus 설정 (세션 및 시스템 dbus)
mkdir -p /var/run/dbus
sudo dbus-daemon --system --fork --nopidfile
mkdir -p $HOME/.config/dbus
dbus-daemon --session --address=unix:path=$XDG_RUNTIME_DIR/bus --fork

# 한국어 입력기 설정
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx

# VNC 비밀번호 설정 (비밀번호가 제공되지 않은 경우 랜덤 생성)
if [ -z "$VNC_PASSWORD" ]; then
    VNC_PASSWORD=$(openssl rand -base64 8)
    echo "Generated random password: $VNC_PASSWORD"
fi

# VNC 비밀번호 설정
mkdir -p $HOME/.vnc
echo -n "$VNC_PASSWORD" > $HOME/.vnc/passwd
chmod 600 $HOME/.vnc/passwd

# KasmVNC 사용자 비밀번호 설정
echo "kasm-user:$VNC_PASSWORD" > $HOME/.kasmpasswd
chmod 600 $HOME/.kasmpasswd

# Xauthority 파일 생성
touch $HOME/.Xauthority
chmod 600 $HOME/.Xauthority

# KasmVNC 사용자 설정 파일 생성
mkdir -p $HOME/.vnc
cat > $HOME/.vnc/config.yaml << EOF
http:
  listen: 0.0.0.0:6901
  key: null
  cert: null
  sslOnly: false
  noVncAuth: true
  DisableBasicAuth: true

rfb:
  listen: 0.0.0.0:5901

permissions:
  user_has_write_access: true
  skip_prompt: true
  default_allow_methods: true

session:
  securityTypes: ["None"]
  uidMode: "unique"
  
session_defaults:
  fullscreen_allowed: true
  scale_mode: "remote"
  quality: 9
  frame_rate: 60
  view_only: false
  autoconnect: true
  reconnect_dialog: true
  clipboard_up: true
  clipboard_down: true
  bell: true
  resize: true
  notification_position: "bottom-right"

logging:
  level: "info"
EOF

# 자동 화면 크기 조정 설정
mkdir -p $HOME/.config/autostart
cat > $HOME/.config/autostart/kasmvnc-resize.desktop << EOF
[Desktop Entry]
Type=Application
Name=KasmVNC Auto Resize
Exec=bash -c "while true; do sleep 5; if xrandr > /dev/null 2>&1; then current=\$(xrandr | grep current | awk '{print \$8\" \"\$10}' | sed 's/,//g'); browser=\$(xwininfo -root | grep -E 'Width|Height' | awk '{print \$2}' | tr '\n' ' ' | sed 's/ \$//g'); if [ \"\$current\" != \"\$browser\" ]; then xrandr -s \$browser; fi; fi; done"
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

# XFCE 패널 불필요한 경고 메시지 제거를 위한 설정
mkdir -p $HOME/.config/xfce4/xfconf/xfce-perchannel-xml
cat > $HOME/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-power-manager.xml << EOF
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-power-manager" version="1.0">
  <property name="xfce4-power-manager" type="empty">
    <property name="show-tray-icon" type="bool" value="false"/>
    <property name="show-panel-label" type="int" value="0"/>
  </property>
</channel>
EOF

# KasmVNC 서버 시작 (수정된 방식)
echo "Starting KasmVNC server in non-interactive mode..."

# 백그라운드에서 Xvnc 직접 실행
Xvnc :1 -geometry $RESOLUTION \
    -FrameRate=60 \
    -PreferBandwidth=1 \
    -AllowOverride=FullScreen \
    -httpd ${KASM_VNC_PATH}/www \
    -websocketPort 6901 \
    -DisableBasicAuth=1 \
    -interface 0.0.0.0 \
    -BlacklistThreshold=0 \
    -FreeKeyMappings=1 \
    -SecurityTypes=None \
    -AlwaysShared=1 \
    -depth 24 &

# Xvnc이 시작될 때까지 대기
sleep 2

# XFCE 세션 시작 - 여기서는 dbus-launch를 사용하여 시작
dbus-launch --exit-with-session startxfce4 &

# fcitx 입력기 시작
fcitx -d &

# 컨테이너 상태 모니터링
echo "KasmVNC 환경이 시작되었습니다."
echo "웹 브라우저에서 http://localhost:6901 으로 접속하세요."
echo "보안 설정이 비활성화되어 있습니다. 비밀번호 없이 접속이 가능합니다."

# 프로세스가 종료되지 않도록 유지
tail -f /dev/null 