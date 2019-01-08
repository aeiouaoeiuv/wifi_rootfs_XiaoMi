#!/bin/sh 

# this script will be called when reset router.

#uninstall all plugins
rm -rf /userdisk/datacenterConfig
rm -rf /userdisk/BroadLink

rm -rf /userdisk/appdata
rm -rf /userdisk/kuaipan
rm -rf /userdisk/ThunderDB

rm -rf /userdisk/cachecenter

rm -f /etc/datacenterconfig/datacenter
rm -f /etc/datacenterconfig/umntpath.cfg
rm -f /etc/datacenterconfig/nonLoginMac.cfg
rm -f /etc/datacenterconfig/mitvMac.cfg

#curl http://127.0.0.1:9000/unbind
touch /userdisk/reset_flag_file
touch /userdisk/download_reset_flag_file
