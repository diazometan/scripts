# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    iptables.sh                                        :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: lwyl-the <lwyl-the@student.42.fr>          +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2019/01/29 19:51:47 by lwyl-the          #+#    #+#              #
#    Updated: 2019/01/29 19:51:49 by lwyl-the         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

#!/bin/bash
export IPT="iptables"
#Внешний интерфейс
export WAN=enp0s3
export WAN_IP=10.0.2.1
#export LAN=enp0s8
#export LAN_IP=198.168.99.2
#Отчищаем цепочки
$IPT -F
$IPT -F -t nat
$IPT -F -t mangle
$IPT -X
$IPT -t nat -X
$IPT -t mangle -X
#Блокируем трафик, который не соответствует ни одному из правил
$IPT -P INPUT DROP
$IPT -P OUTPUT DROP
$IPT -P FORWARD DROP
#Разрешаем весь трафик локалки
$IPT -A INPUT -i lo -j ACCEPT
#$IPT -A INPUT -i $LAN -j ACCEPT
$IPT -A OUTPUT -o lo -j ACCEPT
#$IPT -A OUTPUT -o $LAN -j ACCEPT
#Открываем доступ в инет самому серверу
$IPT -A OUTPUT -o $WAN -j ACCEPT
#Разрешаем все установленные соединение и дочерние от ниx
$IPT -A INPUT -p all -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPT -A OUTPUT -p all -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPT -A FORWARD -p all -m state --state ESTABLISHED,RELATED -j ACCEPT

#Добалвяем защиту от атак

#Блокируем нулевые пакеты
$IPT -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
#Отбрасываем все пакеты, которые не имеют статуса
$IPT -A INPUT -m state --state INVALID -j DROP
$IPT -A FORWARD -m state --state INVALID -j DROP
#Закрываем от syn-flood атак
$IPT -A INPUT -p tcp ! --syn -m state --state NEW -j DROP
$IPT -A OUTPUT -p tcp ! --syn -m state --state NEW -j DROP
#Защищаем порты. Блокируем IP на 60 sec
$IPT -A INPUT -m recent --name portscan --rcheck --seconds 60 -j DROP
$IPT -A FORWARD -m recent --name portscan --rcheck --seconds 60 -j DROP
#Возвращаем их обратно
$IPT -A INPUT -m recent --name portscan --remove
$IPT -A FORWARD -m recent --name portscan --remove

$IPT -A INPUT -p tcp -m tcp --dport 139 -m recent --name portscan --set -j LOG --log-prefix "portscan:"
$IPT -A INPUT -p tcp -m tcp --dport 139 -m recent --name portscan --set -j DROP
$IPT -A FORWARD -p tcp -m tcp --dport 139 -m recent --name portscan --set -j LOG --log-prefix "portscan:"
$IPT -A FORWARD -p tcp -m tcp --dport 139 -m recent --name portscan --set -j DROP
#Открываем ssh
$IPT -A INPUT -i $LAN -p tcp --dport 33110 -j ACCEPT
#Открываем веб-сервер
$IPT -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
$IPT -A INPUT -p tcp -m tcp --dport 443 -j ACCEPT
#Открываем почтвый сервер
$IPT -A INPUT -p tcp -m tcp --dport 25 -j ACCEPT
$IPT -A INPUT -p tcp -m tcp --dport 465 -j ACCEPT
$IPT -A INPUT -p tcp -m tcp --dport 110 -j ACCEPT
$IPT -A INPUT -p tcp -m tcp --dport 995 -j ACCEPT
$IPT -A INPUT -p tcp -m tcp --dport 143 -j ACCEPT
$IPT -A INPUT -p tcp -m tcp --dport 993 -j ACCEPT
$IPT -A INPUT -p tcp -m tcp --dport 587 -j ACCEPT
#Записываем правила
/sbin/iptables-save > /etc/sysconfig/iptables