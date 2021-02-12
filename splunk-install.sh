#!/bin/bash
# ---------------------------------------------------------------------- #
#    scrip splunk-install.sh 
#    
#       author:  przemyslaw@cybulski.waw.pl
#         type:  bash script
#      version:  1.0
#
#    changeLog:
#                1.0   2021-02-06 cy3ul Initial release
#
# ---------------------------------------------------------------------- #

pathinstall=/opt/install

echo "============================================"
echo "Well come to initial installation of Splunk "
echo "============================================"
read -en1 -p "Does previous configuration should be deleted? [y/n] " remove
    if [[ $remove == "y" || $remove == "Y" ]]
then
    rm -rf /opt/Splunk-*
    rm -f /opt/splunk.conf
    echo "Done"
else
    echo ""
fi

#pobieranie instalek
echo -e "Downloading Splunk and Universal Forwarder"
wget -O splunk-8.1.2-545206cc9f70-Linux-x86_64.tgz 'https://www.splunk.com/bin/splunk/DownloadActivityServlet?architecture=x86_64&platform=linux&version=8.1.2&product=splunk&filename=splunk-8.1.2-545206cc9f70-Linux-x86_64.tgz&wget=true' -O $pathinstall/splunk.tgz

wget -O splunkforwarder-8.1.2-545206cc9f70-Linux-x86_64.tgz 'https://www.splunk.com/bin/splunk/DownloadActivityServlet?architecture=x86_64&platform=linux&version=8.1.2&product=universalforwarder&filename=splunkforwarder-8.1.2-545206cc9f70-Linux-x86_64.tgz&wget=true' -O $pathinstall/splunkforwarder.tgz
echo -e "Done"
#rozpakowanie i przygotowanie wzorcowych paczek 
echo -e "Checking of directory /opt/install/"

if [ -e $pathinstall ] ; then
    echo -e "Direcory exist"
else
    echo -e "Directory does not exist"
    mkdir $pathinstall
    echo -e "Created directory $pathinstall"
fi

echo -e "Extracting of packages"
tar -zxf $pathinstall/splunk.tgz -C /opt/
tar -zxf $pathinstall/splunkforwarder.tgz -C /opt/
echo -e "Done"
echo -e "Preparing of config files"
cat > /opt/splunk/etc/system/local/server.conf << _EOF_
[general]
serverName = Splunk-id 

[sslConfig]

[kvstore]
port = 8X91   

[lmpool:auto_generated_pool_download-trial]
description = auto_generated_pool_download-trial
quota = MAX
slaves = *
stack_id = download-trial

[lmpool:auto_generated_pool_forwarder]
description = auto_generated_pool_forwarder
quota = MAX
slaves = *
stack_id = forwarder

[lmpool:auto_generated_pool_free]
description = auto_generated_pool_free
quota = MAX
slaves = *
stack_id = free
_EOF_

cat > /opt/splunk/etc/system/local/web.conf << _EOF_
[settings]
httpport = 8X00 
mgmtHostPort = 127.0.0.1:8X89 
appServerPorts = 8X65 
_EOF_
echo -e "Done"

#okreslenie liczby instancji indexerow
read -n2 -p "Enter number of indexers instances: " index
for (( i = 1 ; i <= $index; i++ )) 
    do echo -e "Preparing indexer-$i";
    a=$[$index + 0]
    cp -a /opt/splunk /opt/Splunk-index$i
    cp -a /opt/splunk/etc/system/local/server.conf /opt/Splunk-index$i/etc/system/local/
    cp -a /opt/splunk/etc/system/local/web.conf /opt/Splunk-index$i/etc/system/local/
    sed  -i 's/8X91/8'$i'91/g' /opt/Splunk-index$i/etc/system/local/server.conf
    sed  -i 's/Splunk-id/index'$i'/g' /opt/Splunk-index$i/etc/system/local/server.conf
    sed  -i 's/8X00/8'$i'00/g' /opt/Splunk-index$i/etc/system/local/web.conf
    sed  -i 's/8X89/8'$i'89/g' /opt/Splunk-index$i/etc/system/local/web.conf
    sed  -i 's/8X65/8'$i'65/g' /opt/Splunk-index$i/etc/system/local/web.conf
    echo "[index$i]" >> /opt/splunk.conf
    echo "kvstoreport = 8"$i"91" >> /opt/splunk.conf
    echo "httpport = 8"$i"00" >> /opt/splunk.conf
    echo "mgmtport = 8"$i"89" >> /opt/splunk.conf
    echo "appport = 8"$i"65" >> /opt/splunk.conf
    echo -e "Finished preparing of indexer-$i"
    done

read -en1 -p "Would you like install Master Node? [y/n] " mn
    if [[ $mn == "y" || $mn == "Y" ]]
then
    a=$[$index + 1]
    echo -e "Preparing Master Node"
    cp -a /opt/splunk /opt/Splunk-mn
    cp -a /opt/splunk/etc/system/local/server.conf /opt/Splunk-mn/etc/system/local/
    cp -a /opt/splunk/etc/system/local/web.conf /opt/Splunk-mn/etc/system/local/
    sed  -i 's/8X91/8'$a'91/g' /opt/Splunk-mn/etc/system/local/server.conf
    sed  -i 's/Splunk-id/masternode/g' /opt/Splunk-mn/etc/system/local/server.conf
    sed  -i 's/8X00/8'$a'00/g' /opt/Splunk-mn/etc/system/local/web.conf
    sed  -i 's/8X89/8'$a'89/g' /opt/Splunk-mn/etc/system/local/web.conf
    sed  -i 's/8X65/8'$a'65/g' /opt/Splunk-mn/etc/system/local/web.conf
    echo "[master node]" >> /opt/splunk.conf
    echo "kvstoreport = 8"$a"91" >> /opt/splunk.conf
    echo "httpport = 8"$a"00" >> /opt/splunk.conf
    echo "mgmtport = 8"$a"89" >> /opt/splunk.conf
    echo "appport = 8"$a"65" >> /opt/splunk.conf
    echo -e "Finished preparing of Master Node"
else
    echo -e "Didn't create Master Node"
fi

read -en1 -p "Would you like install Deployment Server, Monitoring Console and License Manager? [y/n] " ds
    if [[ $ds == "y" || $ds == "Y" ]]
then
    a=$[$a + 1]
    echo -e "Preparing DS,MC and LM"
    cp -a /opt/splunk /opt/Splunk-ds_mc_lm
    cp -a /opt/splunk/etc/system/local/server.conf /opt/Splunk-ds_mc_lm/etc/system/local/
    cp -a /opt/splunk/etc/system/local/web.conf /opt/Splunk-ds_mc_lm/etc/system/local/
    sed  -i 's/8X91/8'$a'91/g' /opt/Splunk-ds_mc_lm/etc/system/local/server.conf
    sed  -i 's/Splunk-id/ds_mc_lm/g' /opt/Splunk-ds_mc_lm/etc/system/local/server.conf
    sed  -i 's/8X00/8'$a'00/g' /opt/Splunk-ds_mc_lm/etc/system/local/web.conf
    sed  -i 's/8X89/8'$a'89/g' /opt/Splunk-ds_mc_lm/etc/system/local/web.conf
    sed  -i 's/8X65/8'$a'65/g' /opt/Splunk-ds_mc_lm/etc/system/local/web.conf
    echo "[Deployment Server, Monitoring Console, License Manager]" >> /opt/splunk.conf
    echo "kvstoreport = 8"$a"91" >> /opt/splunk.conf
    echo "httpport = 8"$a"00" >> /opt/splunk.conf
    echo "mgmtport = 8"$a"89" >> /opt/splunk.conf
    echo "appport = 8"$a"65" >> /opt/splunk.conf
    echo -e "Finished preparing DS,MC,LM"
else    
    echo -e "Didn't create DS,MC,LM"
fi

read -en2 -p "Enter numbers of search heads instance: " sh
for (( i = 1 ; i <= $sh; i++ ))
    do echo -e "Preparing search head-$i";
    cp -a /opt/splunk /opt/Splunk-sh$i
    a=$[$a + 1]
    cp -a /opt/splunk/etc/system/local/server.conf /opt/Splunk-sh$i/etc/system/local/
    cp -a /opt/splunk/etc/system/local/web.conf /opt/Splunk-sh$i/etc/system/local/
    sed  -i 's/8X91/8'$a'91/g' /opt/Splunk-sh$i/etc/system/local/server.conf
    sed  -i 's/Splunk-id/searchhead/g' /opt/Splunk-sh$i/etc/system/local/server.conf
    sed  -i 's/8X00/8'$a'00/g' /opt/Splunk-sh$i/etc/system/local/web.conf
    sed  -i 's/8X89/8'$a'89/g' /opt/Splunk-sh$i/etc/system/local/web.conf
    sed  -i 's/8X65/8'$a'65/g' /opt/Splunk-sh$i/etc/system/local/web.conf
    echo "[Search Head$i]" >> /opt/splunk.conf
    echo "kvstoreport = 8"$a"91" >> /opt/splunk.conf
    echo "httpport = 8"$a"00" >> /opt/splunk.conf
    echo "mgmtport = 8"$a"89" >> /opt/splunk.conf
    echo "appport = 8"$a"65" >> /opt/splunk.conf
    echo -e "Finished preparing search head-$i"
    done

read -en1 -p "Would you like install Universal Forwarder? [y/n] " fw
    if [[ $fw == "y" || $fw == "Y" ]]
then
    a=$[$a + 1]
    echo -e "Preparing Universal Forwarder"
    cp -a /opt/splunkforwarder /opt/Splunk-forwarder
    echo "Finished preparing Forwarder"
else
    echo -e "Didn't create Universal Forwarder"
fi
echo -e "Clearing of unused files"
rm -rf /opt/splunk
rm -rf /opt/splunkforwarder

echo -e "Configuration was exported to /opt/splunk.conf"
echo -e "Thank you for using me :)"
