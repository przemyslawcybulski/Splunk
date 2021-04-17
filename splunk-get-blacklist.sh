#!/bin/bash
# ---------------------------------------------------------------------- #
#    script splunk-get-blacklist.sh 
#    
#       author:  przemyslaw@cybulski.waw.pl
#         type:  bash script
#      version:  1.0
#
#    changeLog:
#                1.0   2021-04-17 cy3ul Initial release
#
# ---------------------------------------------------------------------- #

download_file=ipblocklist.txt
outputfile=blacklists.csv
outputfile2=blacklists.tmp
lookupfile=blacklistsplunk.csv
lookuppath=/opt/splunk/etc/apps/Splunk_TA_lan_lookup/lookups/

#Download blacklist from feodotracker.abuse.ch
wget https://feodotracker.abuse.ch/downloads/ipblocklist_aggressive.csv -O $download_file
#Remove unused characters

cat $download_file | grep -v '#' >> $outputfile2
#sed -i 's/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9],//g' $outputfile2
cat $outputfile2 | awk -F ',' '{print $2}' > $outputfile
sed -i 's/"//' $outputfile
sed -i 's/"//' $outputfile
sed -i 's/dst_ip//' $outputfile
sort $outputfile > $outputfile2
uniq $outputfile2 > $outputfile
#Delete unused files
rm -f $outputfile2 $download_file
#Copy date to lookup file
echo "ip" > $lookupfile
cat $outputfile >> $lookupfile
#Delete empty lines
sed -i '/^[[:space:]]*$/d' $lookupfile

#Download blacklist from feodotracker.abuse.ch
wget http://rules.emergingthreats.net/blockrules/compromised-ips.txt -O $download_file
cat $download_file >> $lookupfile
#Delete unused files
mv -f $lookupfile $lookuppath
rm -f $outputfile $download_file $lookupfile
