#!/bin/bash
###数据库查询入口程序
###功能：1、支持屏蔽mysql敏感字段 2、支持基于业务组的db查询授权 3、支持自己修改密码

base_dir=/home/db_access_portal
config_file=$base_dir/database_config.conf
log_dir=$base_dir/log
tmp_dir=$base_dir/tmp
if [ ! -d $log_dir ];then mkdir -p $log_dir;fi
if [ ! -d $tmp_dir ];then mkdir -p $tmp_dir;fi

##加载用户认证模块(为了能使script录屏log文件名含有用户名信息，将用户认证模块放到.bash_profile里)
#source $base_dir/db_access_portal_user_auth.sh

###$login_timestamp 为bash_profile入口处产生的时间戳
###子进程向父进程传递设置的变量:通过共享文件的方式
release_user=`cat /tmp/$login_timestamp.user`
group_select=`cat /tmp/$login_timestamp.group`
log_file=$log_dir/db_operations_${release_user}_$login_timestamp.log
##删除共享的临时文件
/bin/rm /tmp/$login_timestamp*

db_entrance_menu=${tmp_dir}/.db_entrance_menu_${release_user}.tmp


function_warnings (){
	echo
	echo -e "\033[32m\033[01m本系统只能对所选择的数据库进行读操作,退出操作界面，请输入quit或exit命令\033[0m"
	echo -e "\033[32m\033[01m数据库操作会被严格审计，请有权限的同学只做需要的操作，同时注意数据保密。\033[0m"
	echo -e "如果提示ERROR 1142 (42000): SELECT command denied 则说明表含有敏感字段(比如mobile、email字段)，没有select * from xxx的权限"
	echo -e "如果没有select * from xxx的权限,请尝试查询非敏感字段desc tablename"
	echo
}

###db操作子程序
function sub_db_select ()
{
	echo "---------------------------------------------"
	echo "请从下表选择所要执行读操作的数据库"
	echo "  ${release_user}  $login_timestamp"
	echo "---------------------------------------------"
	###根据用户的权限不同显示不同的选项
	echo group_select:$group_select
	if [[ $group_select = "all_group" ]];then
		cat $config_file > $db_entrance_menu
	else
		cat $config_file | grep -E "^##运行环境|$group_select" > $db_entrance_menu
	fi
	###显示配置文件字段名
	cat  $db_entrance_menu|awk '{print FNR " --> "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9}'|column  -t
	entrance_menu_line_num=`cat $db_entrance_menu|wc -l`
	####每次清空input_num，以便重复发布
	input_num=""
	function_input_num () {
		echo -en "\033[31m\033[01m请输入要读操作数据库的编号(exit退出):\033[0m"
		read input_num
		####根据用户的输入替换掉数字后为空串则说明用户输入为纯数字
		is_num=`echo $input_num | sed 's/[0-9]//g'`
	}
	###判断输入是否合法,直到用户输入为非空且全是数字且大于等于1且小于等于entrance_menu_line_num或者输入exit时退出循环
	#function_input_num
	until  	[ "$input_num" != "" ] && \
		[ "$is_num" = "" ] && \
		[ "$input_num" -gt 1 ] && \
		[ "$input_num" -le $entrance_menu_line_num ]  ||  \
		[ "$input_num" = "exit" ];do
		function_input_num
	done

	if [ "$input_num" = "exit" ];then
                echo 1秒后退出...;sleep 1;exit
	else
                ####获取菜单变量
                  db_env=$(cat $db_entrance_menu|awk 'NR==line_num_awk{print $1}' line_num_awk=$input_num)
                db_group=$(cat $db_entrance_menu|awk 'NR==line_num_awk{print $2}' line_num_awk=$input_num)
                 db_type=$(cat $db_entrance_menu|awk 'NR==line_num_awk{print $3}' line_num_awk=$input_num)
                   db_ip=$(cat $db_entrance_menu|awk 'NR==line_num_awk{print $4}' line_num_awk=$input_num)
		 db_port=$(cat $db_entrance_menu|awk 'NR==line_num_awk{print $5}' line_num_awk=$input_num)
		echo db_env:$db_env db_group:$db_group db_type:$db_type db_ip:$db_ip db_port:$db_port

		##不同的db类型连接不同的库
		if [[ $db_type = "mysql" ]];then
			mysql -h$db_ip -P$db_port
		elif [[ $db_type = "mongodb" ]];then
			#echo "mongodb数据库请输入rs.slaveOk()来开启从库读"
			mongo --host $db_ip --port $db_port
		else
			echo db_type不对请联系ops
		fi
	fi

	##判断用户是否继续对其他数据库进行读操作\033[32m\033[01m
	echo -en "\033[32m\033[01m是否要继续对其他数据库进行读操作(yes/no):\033[0m"
	read input_db_select_continue
	###判断输入是否合法
	until [ "$input_db_select_continue" = "yes" ] || [ "$input_db_select_continue" = "no" ];do
		echo -en "\033[31m\033[01m  请输入yes或者no:\033[0m"
		read input_db_select_continue
	done
	return
}

function_main (){
	function_warnings
	sub_db_select
	while [ "$input_db_select_continue" = "yes" ];do
		sub_db_select
	done
	echo 操作完成，退出系统...
	exit
}

#function_main |tee -a $log_file
function_main
