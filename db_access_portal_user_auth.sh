#!/bin/bash
####用户认证模块
###用户名加密密码文件
passwd_file=/home/db_access_portal/user_passwd.txt
change_password_cmd=/home/db_access_portal/db_access_portal_change_password.sh
##控制变量默认值
change_password_success=no

###查询用户名子程序($1:username)
function sub_user_select()
{
        user_select=`cat $passwd_file|awk -F: '{print $1}'| grep ^$1$`
	#echo user_select:$user_select
        #判断用户是否存在,0为存在，1为不存在
        if [ "$user_select" = "" ];then
                return 1
        else
                return 0
        fi
}

###查询用户组子程序($1:username)
function sub_group_select()
{
	group_select=`cat $passwd_file|awk -F: '{print $0}'| grep ^$1:|awk -F: '{print $3}'`
	#echo  $user_select group_select:$group_select
}

###查询密码子程序($1:username,$2:newpasswd)
function sub_passwd_select()
{
        if [ "$2" != "" ];then
                input_passwd_md5=`echo $2|md5sum|awk '{print $1}'`
                passwd_select=`cat $passwd_file|grep ^$1:|awk -F: '{print $2}'`
                #判断密码是否一致,0为一致，1为不一致
                if [ "$passwd_select" = "$input_passwd_md5" ];then
                        return 0
                else
                        return 1
                fi
        else
                echo passwd null
                return 1
        fi
}


#####开始进行虚拟用户认证
###输入用户名
echo "tips:初始密码和用户名相同,请及时修改默认密码，有问题联系xxx"
echo -en "\033[31m\033[01m请输入db查询用户名(用户名为名字全拼，输入exit退出,输入password进入修改密码流程):\033[0m"
read input_user
sub_user_select $input_user
result=$?
##判断输入是否合法
until [ "$result" = "0" ] || [ "$input_user" = "exit" ] || [ "$input_user" = "password" ];do
        echo -en "\033[31m\033[01m用户不存在:\033[0m"
        read input_user
        sub_user_select $input_user
        result=$?
done
if [ "$input_user" = "exit" ];then
        echo 2秒后退出发布系统...
        sleep 2
        exit
elif [ "$input_user" = "password" ];then
	source $change_password_cmd	
	if [ $change_password_success = "yes" ];then
		echo 修改密码成功，系统自动退出,请重新登录
		exit
	fi
fi

###输入密码
echo -en "\033[31m\033[01m请输入密码(exit退出):\033[0m"
read -s input_passwd
echo
sub_passwd_select $input_user $input_passwd
passwd_result=$?
##判断输入是否合法
until [ "$passwd_result" = "0" ] || [ "$input_passwd" = "exit" ];do
        echo -en "\033[31m\033[01m密码不正确:\033[0m"
        read -s input_passwd
        echo
        sub_passwd_select $input_user $input_passwd
        passwd_result=$?
done

if [ "$input_passwd" = "exit" ];then
        echo 2秒后退出发布系统...
        sleep 2
        exit
fi


release_user=$input_user
sub_group_select $release_user
echo "用户[$release_user]认证完成,进入系统..."
##子进程向父进程传递设置的变量:通过共享文件的方式
echo $release_user > /tmp/$login_timestamp.user
echo $group_select > /tmp/$login_timestamp.group
#echo auth:login_timestamp:$login_timestamp


