##############################################################
# Title: NutClientConf.sh
# Author: Ryuk1h3i
# Description: Installing and configuring NUT client easily
# This script has been created to easy up personal projects,
# feel free to take it and modify it as you wish
##############################################################

#!bin/bash
echo "This script will configure this machine as a NUT CLIENT"
echo "Please enter the NUT Server address, make sure to type it correctly as this script does not have syntax checking"
read ipserver
echo "what is the name of the UPS on the server $ipserver ?"
read upsname
echo "Configuring UPS $upsname from server $ipserver"

sleep 5

apt update && apt install nut -y

systemctl enable nut-client

sed -i '/mode=none/a\mode=netclient' /etc/nut/nut.conf

echo "MONITOR $upsname@$ipserver 1 upsmon upsmon slave" >> /etc/nut/upsmon.conf

cat <<EOT >> /etc/nut/upssched.conf
AT ONBATT * START-TIMER onbatt 300
AT ONLINE * CANCEL-TIMER onbatt online
AT LOWBATT * EXECUTE onbatt
AT COMMBAD * EXECUTE commbad_message
AT COMMOK * EXECUTE  commok_message
AT NOCOMM * EXECUTE nocomm_message
AT SHUTDOWN * EXECUTE shutdown_message
AT SHUTDOWN * EXECUTE powerdow
EOT

cat <<EOT >> /bin/upssched-cmd
       onbatt)
               logger -t upssched-cmd "UPS is on Battery mode"
               /usr/sbin/upsmon -c fsd
               ;;
       commbad_message)
               echo "Lost connection with UPS" | mail -s "$hostname lost connection with UPS" root@localhost
               ;;
       online)
               logger -t upssched-cmd "UPS is on Line mode"
               ;;
       commok_message)
               echo "Connection to UPS enstablished" | mail -s "$hostname connection to UPS enstablished" root@localhost
               ;;
       nocomm_message)
               echo "Lost connection with UPS" | mail -s "$hostname lost connection with UPS" root@localhost
               ;;
       shutdown_message)
               echo "Shutting down" | mail -s "$hostname Critical battery level, shutting down."
EOT

systemctl restart nut-client

upsc $upsname@$ipserver

##EOS
