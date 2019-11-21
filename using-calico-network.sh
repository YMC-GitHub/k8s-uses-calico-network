#!/bin/sh

rm -rf /etc/cni/net.d/*

export POD_SUBNET=10.100.0.1/20
#网络目录
CALICO_DIR=calico   #存放calico网络文件的目录
#网络版本
#CALICO_VERSION=v3.10
CALICO_VERSION=v3.8 #calico的版本

mkdir -p $CALICO_DIR
mkdir -p "$CALICO_DIR/$CALICO_VERSION"
# 下配置文件
######
# policy and networking
######
CALICO_TYPE=""
CALICO_LOCAL_FILE=calico.yaml
URL="https://docs.projectcalico.org/${CALICO_VERSION}/manifests/${CALICO_LOCAL_FILE}"
curl $URL -o ${CALICO_LOCAL_FILE} --progress
echo "calcio.yaml file url:$URL"
mv --force "${CALICO_LOCAL_FILE}" "${CALICO_DIR}/${CALICO_VERSION}/${CALICO_LOCAL_FILE}"
WORK_FILE_NAME="${CALICO_DIR}/${CALICO_VERSION}/${CALICO_LOCAL_FILE}"
######
# with the etcd datastore
######

######
# policy-only
######
:: <<config-policy-only
CALICO_TYPE="policy-only"
CALICO_LOCAL_FILE=calico-${CALICO_TYPE}.yaml
curl https://docs.projectcalico.org/${CALICO_VERSION}/manifests/${CALICO_LOCAL_FILE} -o ${CALICO_DIR}/${CALICO_VERSION}/${CALICO_LOCAL_FILE} --progress
config-policy-only

#cat $WORK_FILE_NAME | grep "kind"
# 设子网网段:pod-network-cidr
#2 calico.yaml中的IP和kubeadm-init.yaml需要保持一致, 要么初始化前修改kubeadm-init.yaml, 要么初始化后修改calico.yaml.
:: <<set-pod-network-cidr-way01
sed -i "s#192\.168\.0\.0/16#${POD_SUBNET}#" $WORK_FILE_NAME
set-pod-network-cidr-way01
#ip a|grep -oE '([0-9]{1,3}.?){4}/[0-9]{2}'
#cat --number $WORK_FILE_NAME
OLD_SUBNETWORK=$(cat --number $WORK_FILE_NAME | grep -oE '([0-9]{1,3}.?){4}/[0-9]{2}')
#NEW_SUBNETWORK=POD_SUBNET
#cat kubeadm-init-k8s-${K8S_VERISON}.yaml | grep -oE 'serviceSubnet: *([0-9]{1,3}.?){4}/[0-9]{2}' |grep -oE '([0-9]{1,3}.?){4}/[0-9]{2}'
NEW_SUBNETWORK=$(cat kubeadm-init-k8s-${K8S_VERISON}.yaml | grep -oE 'podSubnet: *([0-9]{1,3}.?){4}/[0-9]{2}' | grep -oE '([0-9]{1,3}.?){4}/[0-9]{2}')
echo $OLD_SUBNETWORK
echo $NEW_SUBNETWORK
sed -i "s#${OLD_SUBNETWORK}#${NEW_SUBNETWORK}#" $WORK_FILE_NAME
cat --number $WORK_FILE_NAME | grep -oE '([0-9]{1,3}.?){4}/[0-9]{2}'

# 查看所需镜像
# cat $WORK_FILE_NAME | grep "image"

# 用国内镜像（替换）
# calico3.8.4镜像开头不是quay.io（image: calico/xxx）！不能用以下操作！可以不翻墙！可以不换镜像！
#debug-note:cat $WORK_FILE_NAME | grep "image"
#debug-note:cat $WORK_FILE_NAME | grep "quay.io/calico"
#sed -i 's@image: quay.io/calico/@image: registry.cn-shanghai.aliyuncs.com/gcr-k8s/calico-@g' $WORK_FILE_NAME
#debug-note:cat $WORK_FILE_NAME | grep "image"
#image: calico/cni:v3.8.4

# 用国外镜像（还原）
#sed -i 's@image: registry.cn-shanghai.aliyuncs.com/gcr-k8s/calico-@image: quay.io/calico/@g' $WORK_FILE_NAME
# Modify the replica count in theDeployment named calico-typha to the desired number of replicas.
#cat $WORK_FILE_NAME | grep "kind"

#cat $WORK_FILE_NAME | grep "replicas:"
#sed -i 's/replicas: 1/replicas:5/g' $WORK_FILE_NAME | grep "replicas:"

# 用配置文件
kubectl apply --filename $WORK_FILE_NAME

#2 查看所需镜像
cat --number $WORK_FILE_NAME | grep "image"
#2查看已下镜像
docker image ls | grep "calico"
#2查看节点状态
kubectl get node #此处的Ready状态是因为网络已配置好。
# 查看单元状态
kubectl get pods --namespace kube-system
# 查看服务
kubectl get svc --namespace kube-system
# 查看部署
kubectl get deployment --namespace kube-system
# 查看控制
kubectl get rc --namespace kube-system
# 删除
# kubectl delete --filename $WORK_FILE_NAME

#########
# 遇到问题
#########
# 问题：Unable to connect to the server: net/http: TLS handshake timeout
# 解决：https://blog.csdn.net/qq_40806970/article/details/99296983
# 原因：可能是虚拟机的内存分小了。

# 问题：curl: (7) Failed to connect to 2400:6180:0:d1::575:a001: Network is unreachable
# 解决：
# 原因：可能是https://zhidao.baidu.com/question/532067827.html

# 问题：ImagePullBackOff
# 解决：
# 参考:https://blog.csdn.net/i042416/article/details/88073423
# 原因：可能是实现翻墙的原因

#########
# 成功案例
#########
# docker18.09.9-k8s1.15.3-calcio3.8.4

#########
# 参考文献
#########
#
# https://docs.projectcalico.org
# https://yq.aliyun.com/articles/680081/
# https://www.kubernetes.org.cn/4960.html
# https://www.cnblogs.com/goldsunshine/p/10701242.html

# Installing Calico for policy and networking
# https://docs.projectcalico.org/v3.10/getting-started/kubernetes/installation/calico
# Installing with the etcd datastore
#
# Installing Calico for policy
# https://docs.projectcalico.org/v3.10/getting-started/kubernetes/installation/other
# 跟着官方文档从零搭建K8S
# https://juejin.im/post/5d7fb46d5188253264365dcf#heading-17
# Linux之grep及正则表达式
# https://www.cnblogs.com/Jeffding/p/7230487.html
