cd ~
rm -rf ~/alvi-apk-builder
mkdir -p ~/alvi-apk-builder
cd ~/alvi-apk-builder

# ১. সম্পূর্ণ টুলস স্ক্রিপ্ট তৈরি (builder.sh)
cat << 'EOF' > builder.sh
#!/data/data/com.termux/files/usr/bin/bash

# কালার কোড
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

# অপশন ১: ফাইল আপলোড ও অটো-রিপোজিটরি তৈরি
upload_project() {
    banner
    echo -e "${BOLD}${BLUE}--- [1] GitHub প্রজেক্ট আপলোড ও অটো-রিপোজিটরি ---${NC}\n"

    read -p "🔹 GitHub Username: " GITHUB_USER
    read -p "🔹 GitHub Token (ghp_...): " GITHUB_TOKEN
    read -p "🔹 Repository Name: " REPO_NAME
    read -p "🔹 Project Folder Path (যেমন: /storage/emulated/0/dark): " SOURCE_DIR

    if [ -z "$GITHUB_USER" ] || [ -z "$GITHUB_TOKEN" ] || [ -z "$REPO_NAME" ] || [ -z "$SOURCE_DIR" ]; then
        echo -e "\n${RED}[!] সকল তথ্য দেওয়া বাধ্যতামূলক!${NC}"
        read -p "মূল মেনুতে ফিরতে Enter চাপুন..."
        return
    fi

    if [ ! -d "$SOURCE_DIR" ]; then
        echo -e "\n${RED}[!] ফোল্ডারটি পাওয়া যায়নি: $SOURCE_DIR${NC}"
        read -p "মূল মেনুতে ফিরতে Enter চাপুন..."
        return
    fi

    # GitHub-এ অটোমেটিক রিপোজিটরি তৈরি
    echo -e "\n${YELLOW}[*] GitHub-এ রিপোজিটরি প্রস্তুত করা হচ্ছে...${NC}"
    curl -s -H "Authorization: token $GITHUB_TOKEN" \
         -d "{\"name\":\"$REPO_NAME\", \"private\":false}" \
         https://api.github.com/user/repos > /dev/null 2>&1

    echo -e "${YELLOW}[*] ফাইল কপি ও ক্যাশ পরিষ্কার করা হচ্ছে...${NC}"
    cd ~
    rm -rf ~/UploadProject
    mkdir -p ~/UploadProject
    cp -rf "$SOURCE_DIR"/* ~/UploadProject/ 2>/dev/null
    cd ~/UploadProject
    rm -rf .git .gradle build app/build .kotlin .acside .idea *.iml app/*.iml

    echo -e "${YELLOW}[*] Build Workflow প্রস্তুত করা হচ্ছে...${NC}"
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

    echo -e "${YELLOW}[*] GitHub-এ পুশ করা হচ্ছে...${NC}"
    git add -A
    git commit -m "Uploaded via Alvi APK Builder" > /dev/null 2>&1
    git remote remove origin 2>/dev/null
    git remote add origin "https://${GITHUB_USER}:${GITHUB_TOKEN}@github.com/${GITHUB_USER}/${REPO_NAME}.git"

    if git push -u origin main --force; then
        echo -e "\n${GREEN}[✔] রিপোজিটরি তৈরি ও ফাইল আপলোড সফলভাবে সম্পন্ন হয়েছে!${NC}"
    else
        echo -e "\n${RED}[!] পুশ ব্যর্থ হয়েছে! টোকেনের repo ও workflow পারমিশন নিশ্চিত করুন।${NC}"
    fi

    echo ""
    read -p "মূল মেনুতে ফিরে যেতে Enter চাপুন..."
}

# অপশন ২: ক্লাউড বিল্ড ও ডাউনলোড
build_and_download() {
    banner
    echo -e "${BOLD}${BLUE}--- [2] ক্লাউডে APK বিল্ড ও অটো-ডাউনলোড ---${NC}\n"

    read -p "🔹 GitHub Username: " GITHUB_USER
    read -p "🔹 GitHub Token (ghp_...): " GITHUB_TOKEN
    read -p "🔹 Repository Name: " REPO_NAME

    if [ -z "$GITHUB_USER" ] || [ -z "$GITHUB_TOKEN" ] || [ -z "$REPO_NAME" ]; then
        echo -e "\n${RED}[!] সকল তথ্য দেওয়া বাধ্যতামূলক!${NC}"
        read -p "মূল মেনুতে ফিরতে Enter চাপুন..."
        return
    fi

    echo -e "\n${YELLOW}[*] GitHub Actions-এ বিল্ড রিকোয়েস্ট পাঠানো হচ্ছে...${NC}"
    curl -s -X POST \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: Bearer $GITHUB_TOKEN" \
      https://api.github.com/repos/${GITHUB_USER}/${REPO_NAME}/actions/workflows/build.yml/dispatches \
      -d '{"ref":"main"}' > /dev/null 2>&1

    echo -e "${CYAN}[*] ক্লাউড সার্ভার প্রস্তুত হচ্ছে, ২০ সেকেন্ড অপেক্ষা করুন...${NC}"
    sleep 20

    RUN_ID=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
      https://api.github.com/repos/${GITHUB_USER}/${REPO_NAME}/actions/runs \
      | jq -r '.workflow_runs[0].id' 2>/dev/null)

    if [ -z "$RUN_ID" ] || [ "$RUN_ID" = "null" ]; then
        echo -e "${RED}[!] বিল্ড ট্রিগার করা যায়নি। রিপোজিটরি নাম ও টোকেন সঠিক কিনা যাচাই করুন।${NC}"
        read -p "মূল মেনুতে ফিরতে Enter চাপুন..."
        return
    fi

    echo -e "${BLUE}[*] বিল্ড প্রসেস শুরু হয়েছে (Run ID: $RUN_ID)${NC}"
    echo -e "${YELLOW}[*] বিল্ড শেষ হওয়া পর্যন্ত অপেক্ষা করুন (সাধারণত ২-৩ মিনিট সময় লাগে)...${NC}"

    while true; do
      STATUS_DATA=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
        https://api.github.com/repos/${GITHUB_USER}/${REPO_NAME}/actions/runs/$RUN_ID)
      
      STATUS=$(echo "$STATUS_DATA" | jq -r '.status')
      CONCLUSION=$(echo "$STATUS_DATA" | jq -r '.conclusion')

      if [ "$STATUS" = "completed" ]; then
        if [ "$CONCLUSION" = "success" ]; then
          echo -e "\n${GREEN}[✔] ক্লাউডে APK সফলভাবে তৈরি হয়েছে!${NC}"
          break
        else
          echo -e "\n${RED}[!] বিল্ড ফেইল করেছে! কনক্লুশন: $CONCLUSION${NC}"
          read -p "মূল মেনুতে ফিরতে Enter চাপুন..."
          return
        fi
      fi
      echo -e "${CYAN}⏳ বিল্ড চলছে... (১০ সেকেন্ড পর আবার চেক করা হবে)${NC}"
      sleep 10
    done

    echo -e "\n${YELLOW}[*] APK ডাউনলোড করে ফোনে এক্সট্র্যাক্ট করা হচ্ছে...${NC}"
    ARTIFACT_URL=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
      https://api.github.com/repos/${GITHUB_USER}/${REPO_NAME}/actions/runs/$RUN_ID/artifacts \
      | jq -r '.artifacts[0].archive_download_url')

    if [ -z "$ARTIFACT_URL" ] || [ "$ARTIFACT_URL" = "null" ]; then
        echo -e "${RED}[!] ডাউনলোড লিংক পাওয়া যায়নি!${NC}"
        read -p "মূল মেনুতে ফিরতে Enter চাপুন..."
        return
    fi

    curl -L -s -H "Authorization: Bearer $GITHUB_TOKEN" "$ARTIFACT_URL" -o ~/app-debug.zip
    unzip -o ~/app-debug.zip -d /storage/emulated/0/Download/ > /dev/null 2>&1
    rm -f ~/app-debug.zip

    echo -e "\n${GREEN}${BOLD}==========================================================${NC}"
    echo -e "${GREEN}${BOLD}🎉 APK সফলভাবে ডাউনলোড হয়েছে!${NC}"
    echo -e "${BOLD}📁 ফাইলের লোকেশন:${NC} ${CYAN}/storage/emulated/0/Download/app-debug.apk${NC}"
    echo -e "${GREEN}${BOLD}==========================================================${NC}\n"
    read -p "মূল মেনুতে ফিরতে Enter চাপুন..."
}

# মূল মেনু
while true; do
    banner
    echo -e "${BOLD}মেনু থেকে অপশন বেছে নিন:${NC}\n"
    echo -e " [${GREEN}1${NC}] Upload Project to GitHub (অটো রিপোজিটরি ও ফাইল আপলোড)"
    echo -e " [${GREEN}2${NC}] Build & Download APK (অটোমেটিক বিল্ড ও ডাউনলোড)"
    echo -e " [${RED}3${NC}] Exit (বের হয়ে যান)\n"

    read -p "অপশন নির্বাচন করুন [1-3]: " OPTION

    case $OPTION in
        1) upload_project ;;
        2) build_and_download ;;
        3) 
           echo -e "\n${YELLOW}টুলসটি ব্যবহার করার জন্য ধন্যবাদ!${NC}"
           exit 0 
           ;;
        *) 
           echo -e "\n${RED}[!] ভুল অপশন! ১, ২ অথবা ৩ সিলেক্ট করুন।${NC}"
           sleep 2
           ;;
    esac
done
EOF

# ২. ইনস্টলার স্ক্রিপ্ট (install.sh)
cat << 'EOF' > install.sh
#!/data/data/com.termux/files/usr/bin/bash
clear
echo "Installing Dependencies (git, curl, jq, unzip)..."
termux-setup-storage
pkg update -y
pkg install git curl jq unzip -y
chmod +x builder.sh
echo ""
echo "Installation Complete!"
echo "Run using: ./builder.sh"
EOF

# ৩. প্রফেশনাল README ফাইল
cat << 'EOF' > README.md
# 🚀 Alvi Multi-Tool APK Builder

Android Project to GitHub Auto-Uploader & Cloud APK Builder Tool.
Developed by: **Developer Alvi**

## 📦 Installation
```bash
pkg update -y && pkg install git -y
git clone [https://github.com/alvidadu/alvi-apk-builder.git](https://github.com/alvidadu/alvi-apk-builder.git)
cd alvi-apk-builder
bash install.sh
