#!/bin/bash

echo "🚀 SYNTHER DEPLOYMENT SCRIPT"
echo "============================"
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}Choose deployment option:${NC}"
echo "1. Vercel (Recommended - Instant deploy)"
echo "2. Netlify (Drag & drop option)"
echo "3. Firebase Hosting (Google infrastructure)"
echo "4. Surge.sh (Simplest option)"
echo "5. Build APK for Android"
echo "6. Prepare for all platforms"
echo ""

read -p "Enter your choice (1-6): " choice

case $choice in
    1)
        echo -e "${GREEN}Deploying to Vercel...${NC}"
        if ! command -v vercel &> /dev/null; then
            echo "Installing Vercel CLI..."
            npm install -g vercel
        fi
        vercel --prod
        ;;
        
    2)
        echo -e "${GREEN}Preparing for Netlify...${NC}"
        if ! command -v netlify &> /dev/null; then
            echo "Installing Netlify CLI..."
            npm install -g netlify-cli
        fi
        netlify deploy --dir=build/web --prod
        echo -e "${YELLOW}Or drag the 'build/web' folder to https://app.netlify.com/drop${NC}"
        ;;
        
    3)
        echo -e "${GREEN}Deploying to Firebase...${NC}"
        if ! command -v firebase &> /dev/null; then
            echo "Installing Firebase CLI..."
            npm install -g firebase-tools
        fi
        firebase deploy --only hosting
        ;;
        
    4)
        echo -e "${GREEN}Deploying to Surge...${NC}"
        if ! command -v surge &> /dev/null; then
            echo "Installing Surge..."
            npm install -g surge
        fi
        cd build/web
        surge
        cd ../..
        ;;
        
    5)
        echo -e "${GREEN}Building Android APK...${NC}"
        flutter build apk --release
        echo -e "${GREEN}APK created at: ${NC}build/app/outputs/flutter-apk/app-release.apk"
        echo -e "${YELLOW}Upload this APK to:${NC}"
        echo "- GitHub Releases"
        echo "- Google Drive"
        echo "- Any file sharing service"
        ;;
        
    6)
        echo -e "${GREEN}Preparing all deployment files...${NC}"
        
        # Build web
        echo "Building web version..."
        flutter build web --release
        
        # Build Android APK
        echo "Building Android APK..."
        flutter build apk --release
        
        # Create deployment package
        mkdir -p deployment_package
        cp -r build/web deployment_package/
        cp build/app/outputs/flutter-apk/app-release.apk deployment_package/
        
        echo -e "${GREEN}All builds complete!${NC}"
        echo "- Web build: deployment_package/web/"
        echo "- Android APK: deployment_package/app-release.apk"
        echo ""
        echo -e "${YELLOW}Ready for deployment to any platform!${NC}"
        ;;
        
    *)
        echo -e "${RED}Invalid choice!${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}✨ Deployment complete!${NC}"
echo ""
echo -e "${BLUE}Share your app and start getting users!${NC}"
echo "Remember: All these options are FREE until you scale big!"