#!/bin/sh

rm -rf /etc/cni/net.d/*

mkdir calico && cd calico
export POD_SUBNET=10.100.0.1/20
calico_version=v3.10
mkdir $calico_version

# 下配置文件
######
# policy and networking
######
calico_type=""
calico_local_file=calico.yaml
curl https://docs.projectcalico.org/${calico_version}/manifests/${calico_local_file} -o $calico_local_file --progress
######
# with the etcd datastore
######

######
# policy-only
######
::<<config-policy-only
calico_type="policy-only"
calico_local_file=calico-${calico_type}.yaml
curl https://docs.projectcalico.org/${calico_version}/manifests/${calico_local_file} -o $calico_local_file --progress
config-policy-only

cat $calico_local_file | grep "kind"
# 设子网网段:pod-network-cidr
sed -i "s#192\.168\.0\.0/16#${POD_SUBNET}#" $calico_local_file
# 用国内镜像（替换）
#debug-note:cat calico.yml | grep "quay.io/calico"
sed -i 's@image: quay.io/calico/@image: registry.cn-shanghai.aliyuncs.com/gcr-k8s/calico-@g' $calico_local_file
# 用国外镜像（还原）
#sed -i 's@image: registry.cn-shanghai.aliyuncs.com/gcr-k8s/calico-@image: quay.io/calico/@g' $calico_local_file
# Modify the replica count in theDeployment named calico-typha to the desired number of replicas.
#cat $calico_local_file | grep "kind"
# 移相关目录
mv --force $calico_local_file ${calico_version}/${calico_local_file}
#cat ${calico_version}/$calico_local_file | grep "replicas:"
#sed -i 's/replicas: 1/replicas:5/g'${calico_version}/$calico_local_file | grep "replicas:"



# 用配置文件
kubectl apply --filename ${calico_version}/$calico_local_file
# 查看节点
kubectl get node
kubectl get pods --namespace kube-system
# 查看服务
kubectl get svc --namespace kube-system
# 查看部署
kubectl get deployment --namespace kube-system
# 查看控制
kubectl get rc --namespace kube-system
# 删除
# kubectl delete --filename ${calico_version}/$calico_local_file

#########
# 遇到问题
#########
# 问题：Unable to connect to the server: net/http: TLS handshake timeout
# 解决：https://blog.csdn.net/qq_40806970/article/details/99296983
# 原因：可能是虚拟机的内存分小了。

# 问题：curl: (7) Failed to connect to 2400:6180:0:d1::575:a001: Network is unreachable
# 解决：
# 原因：可能是https://zhidao.baidu.com/question/532067827.html


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