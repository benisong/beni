#!/bin/bash
set -e

echo ""
echo "=============================="
echo " SillyTavern-WeChat-Next 一键安装"
echo "=============================="
echo ""

cd "$(dirname "$0")/.."

# 1. 安装 Node.js 20
if ! command -v node >/dev/null 2>&1; then
  echo "未检测到 Node.js，正在安装 Node.js 20..."
  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
  sudo apt-get install -y nodejs
fi

# 2. 安装 pm2、serve
if ! command -v pm2 >/dev/null 2>&1; then
  sudo npm install -g pm2
fi
if ! command -v serve >/dev/null 2>&1; then
  sudo npm install -g serve
fi

# 3. 安装后端依赖
echo "== 安装后端依赖 =="
cd backend
npm install

# 4. 初始化 SQLite 数据库
if [ ! -f db.sqlite ]; then
  touch db.sqlite
  echo "已创建 db.sqlite 数据库文件"
fi

# 5. 安装前端依赖并构建
cd ../frontend
echo "== 安装前端依赖 =="
npm install
echo "== 前端打包 =="
npm run build

# 6. 防火墙放行端口
echo "== 配置防火墙放行 3000 和 3001 端口 =="
if command -v ufw >/dev/null 2>&1; then
  sudo ufw allow 3000
  sudo ufw allow 3001
  sudo ufw reload
fi

# 7. 生成一键启动脚本
echo "== 生成一键启动脚本 deploy/run.sh =="
cat > ../deploy/run.sh << EOF
#!/bin/bash
cd \$(dirname "\$0")/..
pm2 startOrReload deploy/pm2.config.js
EOF
chmod +x ../deploy/run.sh

# 8. 生成 pm2 配置文件（生态方式统一管理）
cd ..
cat > deploy/pm2.config.js << EOF
module.exports = {
  apps : [
    {
      name   : "sillytavern-backend",
      cwd    : "./backend",
      script : "app.js",
      watch  : false,
      env: { "PORT": 3001 }
    },
    {
      name   : "sillytavern-frontend",
      cwd    : "./frontend",
      script : "node_modules/.bin/serve",
      args   : "-s build -l 3000",
      watch  : false
    }
  ]
}
EOF

# 9. 启动全部服务
echo "== 启动全部服务 =="
pm2 startOrReload deploy/pm2.config.js

# 10. 配置 pm2 开机自启
echo "== 配置 pm2 开机自启 =="
pm2 startup systemd -u $USER --hp $HOME | tail -2 | head -1 | bash
pm2 save

echo ""
echo "============================================"
echo " ✅ 安装完成！服务已自动启动并配置开机自启"
echo " 前端: http://你的VPS-IP:3000"
echo " 后端: http://你的VPS-IP:3001"
echo ""
echo " 以后重启服务只需运行: bash deploy/run.sh"
echo ""
echo " PM2管理命令示例: pm2 status | pm2 logs sillytavern-backend"
echo "============================================"
