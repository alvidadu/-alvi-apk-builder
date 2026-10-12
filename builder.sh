#!/data/data/com.termux/files/usr/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

banner() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "=========================================================="
    echo "          🚀 ALVI AUTOMATED APK BUILDER TOOL 🚀           "
    echo "              Developed by: Developer Alvi                "
    echo "=========================================================="
    echo -e "${NC}"
}

upload_project() {
    banner
    echo -e "${BOLD}${BLUE}--- [1] GitHub Project Upload & Auto-Repo ---${NC}\n"

    read -p "🔹 GitHub Username: " GITHUB_USER
    read -p "🔹 GitHub Token (ghp_...): " GITHUB_TOKEN
    read -p "🔹 Repository Name: " REPO_NAME
    read -p "🔹 Project Folder Path: " SOURCE_DIR

    if [ -z "$GITHUB_USER" ] || [ -z "$GITHUB_TOKEN" ] || [ -z "$REPO_NAME" ] || [ -z "$SOURCE_DIR" ]; then
        echo -e "\n${RED}[!] Odeeffannoo hunda guutuun dirqama!${NC}"
        read -p "Gara fuula duraatti deebi'uuf Enter tuqi..."
        return
    fi

    if [ ! -d "$SOURCE_DIR" ]; then
        echo -e "\n${RED}[!] Galmeen (folder) hin argamne: $SOURCE_DIR${NC}"
        read -p "Gara fuula duraatti deebi'uuf Enter tuqi..."
        return
    fi

    # Qindaa'ina Git kan yaaddoo 'Killed / Signal 9' ittisu
    git config --global core.compression 0
    git config --global pack.threads 1
    git config --global pack.windowMemory "10m"
    git config --global pack.packSizeLimit "20m"
    git config --global http.postBuffer 524288000

    echo -e "\n${YELLOW}[*] Kuusaan (Repository) GitHub irratti qophaa'aa jira...${NC}"
    curl -s -H "Authorization: token $GITHUB_TOKEN" \
         -d "{\"name\":\"$REPO_NAME\", \"private\":false}" \
         https://api.github.com/user/repos > /dev/null 2>&1

    echo -e "${YELLOW}[*] Faayilota barbaachisoo qofa filuun qulqulleessaa jira...${NC}"
    cd ~
    rm -rf ~/UploadProject
    mkdir -p ~/UploadProject

    # Faayilota ijaarsa APK qofa kooppii gochuu
    if [ -d "$SOURCE_DIR/app" ]; then
        mkdir -p ~/UploadProject/app
        [ -d "$SOURCE_DIR/app/src" ] && cp -rf "$SOURCE_DIR/app/src" ~/UploadProject/app/
        [ -d "$SOURCE_DIR/app/libs" ] && cp -rf "$SOURCE_DIR/app/libs" ~/UploadProject/app/
        cp -f "$SOURCE_DIR/app"/build.gradle* ~/UploadProject/app/ 2>/dev/null
        cp -f "$SOURCE_DIR/app"/proguard-rules.pro ~/UploadProject/app/ 2>/dev/null
    fi

    [ -d "$SOURCE_DIR/gradle" ] && cp -rf "$SOURCE_DIR/gradle" ~/UploadProject/
    cp -f "$SOURCE_DIR"/build.gradle* ~/UploadProject/ 2>/dev/null
    cp -f "$SOURCE_DIR"/settings.gradle* ~/UploadProject/ 2>/dev/null
    cp -f "$SOURCE_DIR"/gradle.properties* ~/UploadProject/ 2>/dev/null
    cp -f "$SOURCE_DIR"/gradlew* ~/UploadProject/ 2>/dev/null

    cd ~/UploadProject

    # Faayilota hin barbaachifne, kanneen akka cache fi gurguddoo hunda balleessuu
    rm -rf build app/build .git .gradle .idea .acside .kotlin *.iml app/*.iml
    find . -type f -size +3M -delete 2>/dev/null
    find . -type f \( -name "*.apk" -o -name "*.zip" -o -name "*.tar.gz" -o -name "*.mp3" -o -name "*.mp4" \) -delete 2>/dev/null

    echo -e "${YELLOW}[*] GitHub Actions Workflow qophaa'aa jira...${NC}"
    git init > /dev/null 2>&1
    git config user.name "$GITHUB_USER"
    git config user.email "${GITHUB_USER}@users.noreply.github.com"
    git branch -M main > /dev/null 2>&1

    mkdir -p .github/workflows
    cat << 'WORKFLOW_EOF' > .github/workflows/build.yml
name: Build Android APK

on:
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '17'

      - name: Make Gradlew Executable
        run: chmod +x gradlew

      - name: Build Debug APK
        run: ./gradlew assembleDebug

      - name: Upload APK
        uses: actions/upload-artifact@v4
        with:
          name: app-debug
          path: app/build/outputs/apk/debug/*.apk
WORKFLOW_EOF

    echo -e "${YELLOW}[*] Koodiin qulqulluun gara GitHub tti fe'amaa jira...${NC}"
    git add -A
    git commit -m "Auto upload clean source code" > /dev/null 2>&1
    git remote remove origin 2>/dev/null
    git remote add origin "https://${GITHUB_USER}:${GITHUB_TOKEN}@github.com/${GITHUB_USER}/${REPO_NAME}.git"

    if git push -u origin main --force; then
        echo -e "\n${GREEN}[✔] Faayiloonni barbaachisoo qofti milkaa'inaan fe'amaniiru!${NC}"
    else
        echo -e "\n${RED}[!] Fe'uun hin milkoofne! Hayyama Token keessanii mirkaneeffadhaa.${NC}"
    fi

    echo ""
    read -p "Gara fuula duraatti deebi'uuf Enter tuqi..."
}

build_and_download() {
    banner
    echo -e "${BOLD}${BLUE}--- [2] Cloud irratti APK Ijaaruu & Buusuu ---${NC}\n"

    read -p "🔹 GitHub Username: " GITHUB_USER
    read -p "🔹 GitHub Token (ghp_...): " GITHUB_TOKEN
    read -p "🔹 Repository Name: " REPO_NAME

    if [ -z "$GITHUB_USER" ] || [ -z "$GITHUB_TOKEN" ] || [ -z "$REPO_NAME" ]; then
        echo -e "\n${RED}[!] Odeeffannoo hunda guutuun dirqama!${NC}"
        read -p "Gara fuula duraatti deebi'uuf Enter tuqi..."
        return
    fi

    echo -e "\n${YELLOW}[*] Hojiin ijaarsaa GitHub Actions irratti eegalamaa jira...${NC}"
    curl -s -X POST \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: Bearer $GITHUB_TOKEN" \
      https://api.github.com/repos/${GITHUB_USER}/${REPO_NAME}/actions/workflows/build.yml/dispatches \
      -d '{"ref":"main"}' > /dev/null 2>&1

    echo -e "${CYAN}[*] Sarvariin qophaa'aa jira, sekondii 20 eegaa...${NC}"
    sleep 20

    RUN_ID=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
      https://api.github.com/repos/${GITHUB_USER}/${REPO_NAME}/actions/runs \
      | jq -r '.workflow_runs[0].id' 2>/dev/null)

    if [ -z "$RUN_ID" ] || [ "$RUN_ID" = "null" ]; then
        echo -e "${RED}[!] Hojiin eegaluu hin dandeenye. Maqaa fi Token keessan ilaalaa.${NC}"
        read -p "Gara fuula duraatti deebi'uuf Enter tuqi..."
        return
    fi

    echo -e "${BLUE}[*] Adeemsi ijaarsaa eegalameera (Run ID: $RUN_ID)${NC}"
    echo -e "${YELLOW}[*] Hanga xumuramutti eegaa (daqiiqaa 2-3 fudhachuu danda'a)...${NC}"

    while true; do
      STATUS_DATA=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
        https://api.github.com/repos/${GITHUB_USER}/${REPO_NAME}/actions/runs/$RUN_ID)
      
      STATUS=$(echo "$STATUS_DATA" | jq -r '.status')
      CONCLUSION=$(echo "$STATUS_DATA" | jq -r '.conclusion')

      if [ "$STATUS" = "completed" ]; then
        if [ "$CONCLUSION" = "success" ]; then
          echo -e "\n${GREEN}[✔] APK milkaa'inaan ijaarameera!${NC}"
          break
        else
          echo -e "\n${RED}[!] Ijaarsi kufeera! Sababa: $CONCLUSION${NC}"
          read -p "Gara fuula duraatti deebi'uuf Enter tuqi..."
          return
        fi
      fi
      echo -e "${CYAN}⏳ Hojiin jira... (sekondii 10 booda irra deebiin ilaallama)${NC}"
      sleep 10
    done

    echo -e "\n${YELLOW}[*] APK buusuun bilbila keessanitti ergaa jira...${NC}"
    ARTIFACT_URL=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
      https://api.github.com/repos/${GITHUB_USER}/${REPO_NAME}/actions/runs/$RUN_ID/artifacts \
      | jq -r '.artifacts[0].archive_download_url')

    if [ -z "$ARTIFACT_URL" ] || [ "$ARTIFACT_URL" = "null" ]; then
        echo -e "${RED}[!] Geessituun buufannaa hin argamne!${NC}"
        read -p "Gara fuula duraatti deebi'uuf Enter tuqi..."
        return
    fi

    curl -L -s -H "Authorization: Bearer $GITHUB_TOKEN" "$ARTIFACT_URL" -o ~/app-debug.zip
    unzip -o ~/app-debug.zip -d /storage/emulated/0/Download/ > /dev/null 2>&1
    rm -f ~/app-debug.zip

    echo -e "\n${GREEN}${BOLD}==========================================================${NC}"
    echo -e "${GREEN}${BOLD}🎉 APK milkaa'inaan buufameera!${NC}"
    echo -e "${BOLD}📁 Bakka faayilii:${NC} ${CYAN}/storage/emulated/0/Download/app-debug.apk${NC}"
    echo -e "${GREEN}${BOLD}==========================================================${NC}\n"
    read -p "Gara fuula duraatti deebi'uuf Enter tuqi..."
}

while true; do
    banner
    echo -e "${BOLD}Filannoo keessan filadhaa:${NC}\n"
    echo -e " [${GREEN}1${NC}] Upload Project to GitHub (Faayilota filachuun fe'uu)"
    echo -e " [${GREEN}2${NC}] Build & Download APK (Ijaaruu fi buusuu)"
    echo -e " [${RED}3${NC}] Exit (Bahuuf)\n"

    read -p "Filadhaa [1-3]: " OPTION

    case $OPTION in
        1) upload_project ;;
        2) build_and_download ;;
        3) 
           echo -e "\n${YELLOW}Fayyadamuu keessaniif galatoomaa!${NC}"
           exit 0 
           ;;
        *) 
           echo -e "\n${RED}[!] Filannoo dogoggoraa! 1, 2 ykn 3 filadhaa.${NC}"
           sleep 2
           ;;
    esac
done
