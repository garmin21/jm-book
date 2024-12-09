#!/usr/bin/env sh

# 获取当前操作系统
os=$(uname -s)

# 确保脚本抛出遇到的错误
set -e

rm -rf dist

echo '生成静态文件'

pnpm build

cd dist

echo '====================================>'
git init
git add -A
git commit -m 'deploy'


echo '====================================>与远程分支建立联系'
# 与远程分支建立联系
git remote add origin git@github.com:garmin21/garmin21.github.io.git

echo '====================================>强制推送到远程main 分支'
# 强制推送到远程main 分支

case $os in
    # Linux*)
    #     echo "Linux"
    #     ;;
    Darwin*)
        echo "macOS"
        git push https://github.com/garmin21/garmin21.github.io.git garming21:main -f
        ;;
    CYGWIN*|MINGW32*|MSYS*|MINGW*)
        echo "Windows"
        git push https://github.com/garmin21/garmin21.github.io.git master:main -f
        ;;
    *)
        echo "Unknown"
        ;;
esac
# git push https://github.com/garmin21/garmin21.github.io.git master:main -f

cd ..

rm -rf dist

exit 0

# npm 官方镜像源 npm config set registry https://registry.npmjs.org/
# 淘宝镜像源 npm config set registry https://registry.npmmirror.com
# 腾讯云镜像源 `npm config set registry http://mirrors.cloud.tencent.com/npm/`
# 查看镜像源: npm config get registry
# npm install --registry=https://registry.npmmirror.com