# KasmVNC 기반 리눅스 GUI 개발환경

이 도커 이미지는 Ubuntu 22.04 기반의 XFCE4 데스크톱 환경을 제공하며, 웹 브라우저를 통해 접근할 수 있습니다.

## 목차
- [주요 기능](#주요-기능)
- [사전 준비](#사전-준비)
  - [Windows](#windows에서-docker-설치)
  - [macOS](#macos에서-docker-설치)
  - [Linux](#linux에서-docker-설치)
- [빌드 및 실행 방법](#빌드-및-실행-방법-docker-compose)
- [접속 방법](#접속-방법)
- [환경 변수](#환경-변수)
- [AppImage 실행 방법](#appimage-실행-방법)
- [데이터 보존](#데이터-보존)
- [문제 해결](#문제-해결)

## 주요 기능

- Ubuntu 22.04 LTS 기반
- XFCE4 데스크톱 환경
- KasmVNC를 이용한 웹 브라우저 기반 원격 접속
- 한국어 지원 (폰트, 입력기)
- Firefox 최신 버전 (한국어 지원)
- VS Code 개발 환경 포함
- AppImage 실행을 위한 FUSE 지원
- 브라우저 창 크기에 맞게 조정되는 화면

## 사전 준비

### Windows에서 Docker 설치

1. [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop) 다운로드 및 설치
2. WSL2 기능 활성화 (Docker Desktop 설치 과정에서 안내됨)
3. Docker Desktop 시작 및 설정 확인
4. 명령 프롬프트 또는 PowerShell에서 다음 명령어로 설치 확인:
   ```
   docker --version
   docker-compose --version
   ```

### macOS에서 Docker 설치

1. [Docker Desktop for Mac](https://www.docker.com/products/docker-desktop) 다운로드 및 설치
2. Docker Desktop 시작 및 설정 확인
3. 터미널에서 다음 명령어로 설치 확인:
   ```
   docker --version
   docker-compose --version
   ```

### Linux에서 Docker 설치

Ubuntu를 기준으로 설명합니다:

```bash
# 필요한 패키지 설치
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common

# Docker 공식 GPG 키 추가
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# Docker 리포지토리 추가
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Docker 설치
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Docker Compose 설치
sudo curl -L "https://github.com/docker/compose/releases/download/v2.18.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 사용자를 docker 그룹에 추가 (sudo 없이 docker 명령어 실행을 위해)
sudo usermod -aG docker $USER
```

설치 후 로그아웃했다가 다시 로그인하면 docker 명령어를 sudo 없이 사용할 수 있습니다.

## 빌드 및 실행 방법 (Docker Compose)

프로젝트에서 이미 제공되는 `docker-compose.yml` 파일을 사용하면 복잡한 매개변수 없이 KasmVNC 환경을 쉽게 실행할 수 있습니다. 이 방법을 가장 권장합니다.

1. 프로젝트 다운로드:
   ```bash
   # 직접 저장소 파일 다운로드
   # 또는 원하는 위치에 프로젝트 파일 준비
   
   # 프로젝트 디렉토리로 이동
   cd <프로젝트_디렉토리>
   ```

2. 실행: 컨테이너 빌드 및 실행
   ```bash
   docker-compose up -d
   ```

3. 컨테이너 상태 확인:
   ```bash
   docker-compose ps
   ```

4. 로그 확인:
   ```bash
   docker-compose logs
   ```

5. 컨테이너 종료:
   ```bash
   docker-compose down
   ```

## 환경 변수

환경 변수는 `docker-compose.yml` 파일에서 설정할 수 있습니다.

- `VNC_PASSWORD`: VNC 접속 비밀번호 (지정하지 않으면 자동 생성됨)
- `RESOLUTION`: 화면 해상도 (기본값: 1920x1080)

## 접속 방법

웹 브라우저에서 다음 URL로 접속합니다:

```
http://localhost:6901
```

또는 서버 IP를 사용하여 접속:

```
http://<서버IP>:6901
```

## AppImage 실행 방법

다운로드 받은 AppImage 파일에 실행 권한을 부여한 후 실행합니다:

```bash
chmod +x myapp.AppImage
./myapp.AppImage
```

## 데이터 보존

`./data` 디렉토리가 컨테이너 내부의 `/home/kasm-user/data` 디렉토리에 마운트됩니다. 
중요한 파일들은 이 디렉토리에 저장하여 컨테이너를 재시작하거나 재구축해도 데이터가 유지되도록 하세요.

## 문제 해결

### Firefox 실행 문제

Firefox가 실행되지 않는 경우 다음 명령어를 터미널에서 실행해보세요:

```bash
# 터미널에서 직접 실행
firefox --no-sandbox
```

### 한국어 입력기 문제

한국어 입력기가 작동하지 않는 경우 다음 명령어를 실행하여 입력기를 재시작해보세요:

```bash
fcitx -r
```

### FUSE 관련 문제

AppImage 실행 시 FUSE 관련 오류가 발생하는 경우 다음 사항을 확인하세요:

1. 컨테이너가 `--privileged` 모드로 실행 중인지 확인
2. `/dev/fuse` 장치가 마운트되어 있는지 확인
3. 필요한 경우 다음 명령어로 FUSE 모듈이 로드되어 있는지 확인:
   ```bash
   lsmod | grep fuse
   ```

### Docker 직접 실행 (고급 사용자용)

Docker Compose를 사용하지 않고 직접 Docker 명령어로 실행하려면 다음 명령어를 사용할 수 있습니다:

```bash
# 이미지 빌드
docker build -t kasmvnc-xfce4 .

# 컨테이너 실행
docker run -d --privileged \
  -p 6901:6901 \
  -e VNC_PASSWORD=mypassword \
  --device /dev/fuse \
  -v /dev/fuse:/dev/fuse \
  -v ./data:/home/kasm-user/data \
  --cap-add SYS_ADMIN \
  --security-opt apparmor:unconfined \
  --name kasmvnc-desktop \
  kasmvnc-xfce4
``` 