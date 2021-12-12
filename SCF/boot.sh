#!/bin/sh

# 构建，# Build image
docker build -t scf_app . -f ./SCF/CustomRuntime/Dockerfile.build
# 创建，提取容器
docker create --name extract scf_app
# 复制，容器内，内容
docker cp extract:/staging ./install
# 删除，提取容器
docker rm -f extract
# 删除镜像
# docker image rm scf_app

######### 函数部署 ###############
# 创建启动文件
touch ./install/scf_bootstrap && chmod +x ./install/scf_bootstrap

# 写入启动内容
cat > ./install/scf_bootstrap<<EOF
#!/usr/bin/env bash
# export LD_LIBRARY_PATH=/opt/swift/usr/lib:${LD_LIBRARY_PATH}
./Run serve --env production --hostname 0.0.0.0 --port 9000
EOF

# 压缩文件夹
# zip --symlinks -r app-0.0.1.zip ./install/*

# 删除 yaml 文件
rm -rf serverless.yml

# 创建 yaml 文件
slsplus parse --output --auto-create --sls-options='{"component":"scf","name":"${env:INSTANCE_NAME}","org":"${env:TENCENT_APP_ID}","app":"${env:APP_NAME}","inputs":{"name":"${env:APP_NAME}","region":"${env:REGION}","runtime":"${env:RUNTIME}","type":"web","src":{"src":"./install","exclude":[".env"]},"memorySize":64,"environment":{"variables":{"CIAM_CLIENTID":"${env:CIAM_CLIENTID}","CIAM_CLIENTSECRET":"${env:CIAM_CLIENTSECRET}","CIAM_USERDOMAMIN":"${env:CIAM_USERDOMAMIN}","CIAM_REDIRECTURI":"${env:CIAM_REDIRECTURI}","CAIM_LOGOUTREDIRECTURL":"${env:CAIM_LOGOUTREDIRECTURL}"}},"events":[{"apigw":{"parameters":{"serviceName":"ciam_hello_serverless","description":"ciam hello","endpoints":[{"function":{"isIntegratedResponse":true},"method":"ANY","path":"/"}],"protocols":["http","https"],"environment":"release"}}}]}}' && cat serverless.yml

# 添加环境变量
# cp SCF/Template/env .env

# 部署
sls deploy --force --debug

# END
