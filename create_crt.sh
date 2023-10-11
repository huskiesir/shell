#!/bin/bash
 
# create self-signed server certificate:
 
read -p "Enter your domain [eg:liuning.fit2cloud.com]: " DOMAIN
read -p "Enter your country [eg:CN 注:控制在2个字符以内]: " COUNTRY
read -p "Enter your province [eg:shandong]: " PROVINCE
read -p "Enter your city [eg:jinan]: " CITY
read -p "Enter your company [eg:fit2cloud]: " COMPANY
read -p "Enter your ORG [eg:shouqian]: " ORG

# 生成自签名证书私钥 -out $DOMAIN.key 
openssl genrsa -out $DOMAIN.key 2048
 
# 根据自签名证书私钥生成自签名证书申请文件 -out $DOMAIN.csr

openssl req -new -key $DOMAIN.key -subj "/C=$COUNTRY/ST=$PROVINCE/L=$CITY/O=$COMPANY/OU=$ORG/CN=$DOMAIN" -sha256 -out $DOMAIN.csr

 
# 生成根证书私钥和根证书 -keyout CA-$DOMAIN.key -out CA-$DOMAIN.crt

openssl req -x509 -nodes -days 365 -newkey rsa:2048 -subj "/C=$COUNTRY/ST=$PROVINCE/L=$CITY/O=$COMPANY/OU=$ORG/CN=$DOMAIN" -keyout CA-$DOMAIN.key -out CA-$DOMAIN.crt -reqexts v3_req -extensions v3_ca

# 定义自签名证书扩展文件(解决chrome安全告警)。
# 在默认情况下生成的证书一旦选择信任，在 Edge, Firefox 等浏览器都显示为安全，但是Chrome仍然会标记为不安全并警告拦截， 这是因为 Chrome 需要证书支持扩展 Subject Alternative Name, 
# 因此生成时需要特别指定 SAN 扩展并添加相关参数,将下述内容放到命名为$DOMAIN.ext文件中，该文件与上方生成的文件放到同一个文件夹下

echo "[ req ]" >> $DOMAIN.ext
echo "default_bits        = 1024" >> $DOMAIN.ext
echo "distinguished_name  = req_distinguished_name" >> $DOMAIN.ext 
echo "req_extensions      = san" >> $DOMAIN.ext
echo "extensions          = san" >> $DOMAIN.ext
echo "[ req_distinguished_name ]" >> $DOMAIN.ext
echo "countryName         = $COUNTRY" >> $DOMAIN.ext
echo "stateOrProvinceName = $PROVINCE" >> $DOMAIN.ext
echo "localcityName       = $CITY" >> $DOMAIN.ext
echo "organizationName    = $COMPANY" >> $DOMAIN.ext
echo "[SAN]" >> $DOMAIN.ext
echo "authorityKeyIdentifier=keyid,issuer" >> $DOMAIN.ext
echo "basicConstraints=CA:FALSE" >> $DOMAIN.ext
echo "keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment" >> $DOMAIN.ext
echo "subjectAltName = DNS:$DOMAIN" >> $DOMAIN.ext

# 根据根证书私钥及根证书-CA CA-$DOMAIN.crt -CAkey CA-$DOMAIN.key、自签名证书申请文件 -in $DOMAIN.csr、自签名证书扩展文件 -extfile $DOMAIN.ext,生成自签名证书 -out $DOMAIN.crt

openssl x509 -req -days 365 -in $DOMAIN.csr -CA CA-$DOMAIN.crt -CAkey CA-$DOMAIN.key -CAcreateserial -sha256 -out $DOMAIN.crt -extfile $DOMAIN.ext -extensions SAN

rm $DOMAIN.csr $DOMAIN.ext CA-$DOMAIN.key CA-$DOMAIN.srl
