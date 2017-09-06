#!/bin/bash
####用户修改密码模块
###用户名加密密码文件
passwd_file=/home/db_access_portal/user_passwd.txt


###查询用户名子程序($1:username)
function sub_user_select()
{
        user_select=`cat $passwd_file|awk -F: '{print $1}'| grep ^$1$`
        #判断用户是否存在,0为存在，1为不存在
        if [ "$user_select" = "" ];then
                return 1
        else
                return 0
        fi
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

###修改密码子程序($1:username,$2:passwd)
function sub_passwd_change()
{
        input_new_passwd_md5=`echo $2|md5sum|awk '{print $1}'`
        old_passwd_md5_select=`cat $passwd_file|grep ^$1:|awk -F: '{print $2}'`
        sed -i s/$1:$old_passwd_md5_select/$1:$input_new_passwd_md5/ $passwd_file                
        echo $1 passwd change ok
	change_password_success=yes
        return 0
}

###确认是否修改密码子程序
function sub_change_passwd (){
	####判断是否修改密码(yes修改，no直接发布)
	#echo -en "\033[32m\033[01m是否要修改密码(yes修改，no直接进入发布系统):\033[0m"
	#read input_change_passwd_or_not
	####判断输入是否合法
	#until [ "$input_change_passwd_or_not" = "yes" ] || [ "$input_change_passwd_or_not" = "no" ];do
       	#	echo -en "\033[31m\033[01m  请输入yes或者no:\033[0m"
       	#	read input_change_passwd_or_not
	#done
	input_change_passwd_or_not=yes
	if [ "$input_change_passwd_or_not" = "yes" ];then
       		echo -en "\033[32m\033[01m请输入新密码:\033[0m" 
       		read -s input_newpasswd
       		echo
       		echo -en "\033[32m\033[01m请再次输入新密码:\033[0m"
       		read -s input_newpasswd_confirm
		###判断输入是否一致,不为空
       		until [ -n "$input_newpasswd" ] && [ "$input_newpasswd" = "$input_newpasswd_confirm" ];do
               		echo 
               		echo 2次密码输入不一致或者为空密码,请重新输入!
               		echo -en "\033[32m\033[01m请输入新密码:\033[0m" 
               		read -s input_newpasswd
              		echo
               		echo -en "\033[32m\033[01m请再次输入新密码:\033[0m"
               		read -s input_newpasswd_confirm
               		echo 
       		done 
       	sub_passwd_change $input_user $input_newpasswd
	fi
}



#####开始进行虚拟用户认证
###输入发布人用户名
echo -en "\033[31m\033[01m请输入db查询用户名(用户名为名字全拼，输入exit退出修改密码流程):\033[0m"
read input_user
sub_user_select $input_user
result=$?
##判断输入是否合法
until [ "$result" = "0" ] || [ "$input_user" = "exit" ] ;do
        echo -en "\033[31m\033[01m用户不存在:\033[0m"
        read input_user
        sub_user_select $input_user
        result=$?
done
if [ "$input_user" = "exit" ];then
        echo 2秒后退出修改密码流程...
        sleep 2
        exit
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
        echo 2秒后退出系统...
        sleep 2
        exit
fi

sub_change_passwd


