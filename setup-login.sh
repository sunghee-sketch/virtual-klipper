#!/bin/bash

# Mainsail 로그인 페이지 설정 스크립트

echo "🔧 Mainsail 로그인 페이지 설정을 시작합니다..."

# 1. 로그인 페이지 파일 복사
echo "📁 로그인 페이지 파일을 복사합니다..."
sudo cp login.html /var/www/html/

# 2. Nginx 설정 파일 복사
echo "⚙️ Nginx 설정을 업데이트합니다..."
sudo cp nginx-login.conf /etc/nginx/sites-available/mainsail-login
sudo ln -sf /etc/nginx/sites-available/mainsail-login /etc/nginx/sites-enabled/

# 3. 기본 Nginx 설정 비활성화 (선택사항)
# sudo rm -f /etc/nginx/sites-enabled/default

# 4. Nginx 설정 테스트
echo "🔍 Nginx 설정을 테스트합니다..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Nginx 설정이 올바릅니다."
    
    # 5. Nginx 재시작
    echo "🔄 Nginx를 재시작합니다..."
    sudo systemctl reload nginx
    
    echo "🎉 설정이 완료되었습니다!"
    echo ""
    echo "📋 사용 방법:"
    echo "1. 브라우저에서 라즈베리파이 IP로 접속"
    echo "2. 로그인 페이지가 자동으로 나타남"
    echo "3. 사용자명: admin, 비밀번호: admin123"
    echo ""
    echo "⚠️  보안을 위해 기본 비밀번호를 변경하는 것을 권장합니다."
else
    echo "❌ Nginx 설정에 오류가 있습니다. 설정을 확인해주세요."
    exit 1
fi 