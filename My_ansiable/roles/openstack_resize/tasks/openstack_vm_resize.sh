#!/bin/bash
# --------------------------------------------------------------------------------------
# Filename:     my_resize.sh
# Version:      v1.0
# Author:       wusongen
# Create Date:  2020/06/18
# Description:  Shell script to resize vm
# Notes:        resize to vm
# --------------------------------------------------------------------------------------

# 清除旧数据
if [[ -e /root/my_resize ]]
then
	/bin/rm -rf /root/my_resize && /bin/mkdir /root/my_resize >> /dev/null 2>&1
else
	/bin/mkdir /root/my_resize >> /dev/null 2>&1
fi


#-----------设置变量start-----------

# 设置控制节点
#controller_ip="10.1.1.1"
read -p "输入控制节点ip  >  " controller_ip  
printf "\n" 

# 设置环境变量信息（必填）
tenant="admin"
user="admin"
passwd="123456"
url="http://$controller_ip:35357/v2.0"

# 设置需核对flavor（必填）
check_flavor="2C4G50*"

# 在此处输入虚拟机uuid（必填）
resize_vm="
4a89f3cd-afe0-4388-8170-39be3a1b9e7f
dc5272d9-3813-4b05-b117-8fea49159303
"

# 设置目标flavor（必填）
target_flavor="4C8G50GB"

# 设置目标主机（必填）
target_host="10.1.1.2"

#------------设置变量end------------


# 生效环境变量
export OS_TENANT_NAME=$tenant
export OS_USERNAME=$user
export OS_PASSWORD=$passwd
export OS_AUTH_URL=$url


# 生成host_list文件
cat >> /root/my_resize/host_list << EOF
$resize_vm
EOF


# 开启目标宿主机
enable_target_host()
{
	/usr/bin/nova service-enable $target_host  nova-compute
}

# 关闭目标宿主机
disable_target_host()
{
	/usr/bin/nova service-disable $target_host  nova-compute
}


# 收集并判断flavor
collection_and_judge()
{
	for uuid in `cat /root/my_resize/host_list` ; 
	do
		nova=`nova show $uuid | grep flavor | awk -F '|' '{print $3}' | awk '{print $1}'` 
		nova show $uuid | grep flavor | awk -F '|' '{print $3}' | awk '{print $1}' >> /root/my_resize/host_flavor ;
		
		for flavor in `cat /root/my_resize/host_flavor` ; 
			do 
				echo null >> /dev/null 2>&1
			done
		
		if [[ $nova == $check_flavor ]]
		then
			echo "$uuid" >> /root/my_resize/host_succeed
		else
			echo "$uuid + $flavor (failed)" >> /root/my_resize/host_failed
		fi
	done
}


# 判断flavor
#judge()
#{
#	for flavor in `cat /root/my_resize/host_flavor` ;
#	do
#		if [ $flavor == $check_flavor ]
#		then
#			echo "$uuid" >> /root/my_resize/host_succeed
#		else
#			echo "$uuid  +  $flavor (failed)" >> /root/my_resize/host_failed
#		fi
#	done
#}


# 开始resize
begin()
{
	for succeed in `cat /root/my_resize/host_succeed` ; 
	do
		nova=`nova flavor-list | grep $target_flavor | awk -F '|' '{print $2}'`
		nova resize $succeed $nova
		result=`nova show $succeed | grep task_state | awk -F '|' '{print $3}'`
		echo "虚拟机状态："  $result
		printf "\n\n\n\n\n"
	done
}


InitConf()
{
enable_target_host
collection_and_judge
#judge
begin
disable_target_host
}


main()
{
  echo "go-go-go"
  printf "\n\n\n\n\n"
  InitConf
}

#exec main
main

