#!/bin/bash

NSX='yournsxmanagerhere'
NSXUSER='yournsxuserhere'
#NSXPASS='yournsxpasswordhere'

read -s -p "Password: " NSXPASS

echo "Checking TNP Profiles"

curl -s -k -u $NSXUSER:$NSXPASS "https://$NSX/policy/api/v1/infra/host-transport-node-profiles" -X GET -H "Content-Type:application/json" | grep '"display_name"' > tnp_names.json

curl -s -k -u $NSXUSER:$NSXPASS "https://$NSX/policy/api/v1/infra/host-transport-node-profiles" -X GET -H "Content-Type:application/json" | grep '"path"' > tnp_path.json

sleep 1

paste -d " " tnp_names.json tnp_path.json > tnp.list

#GNU

#sed -i 's/ //g' tnp.list
#sed -i 's/:/\t/g' tnp.list
#sed -i 's/,/\t/g' tnp.list
#sed -i 's/"//g' tnp.list


#MACOS

sed -i'' -e 's/ //g' tnp.list
sed -i'' -e 's/:/\t/g' tnp.list
sed -i'' -e 's/,/\t/g' tnp.list
sed -i'' -e 's/"//g' tnp.list


SECTION="tnp.list"

echo 'Do you want to rollback some TNP profile?'
echo ''
read -p "Answer(Y/N): " ROLLBACK

if [[ $ROLLBACK =~ ^[Yy]$ ]];

then

echo "Which TNP Profile do you want to rollback the VTEP HA config?"
echo ''

echo `cat -n $SECTION | awk 'BEGIN{FS=OFS="\t"} { print $1,$3 }'`


echo ''
read -p "Answer: " ROLLBACKANSWER

if [[ "$ROLLBACKANSWER" -le 0 ]]

then

echo "doing nothing"

sleep 1

exit 0


else

echo "$ROLLBACKANSWER"
echo "Rolling back TNP Profile $ROLLBACKANSWER"

sleep 1

sed -n $ROLLBACKANSWER,999p tnp.list > tnp2.list
sed -n 1,1p tnp2.list > tnp.list


#echo `cat tnp.list`

TNPPATH=`cat tnp.list | awk 'BEGIN{FS=OFS="\t"} { print $4 }'`

echo "$TNPPATH"

curl -s -k -u $NSXUSER:$NSXPASS "https://$NSX/policy/api/v1$TNPPATH" -X GET -H "Content-Type:application/json" > tnpconfig.json


sed -n 1,10p tnpconfig.json > tnp_rollback.json
sed -n 14,199p tnpconfig.json >> tnp_rollback.json



curl -s -k -u $NSXUSER:$NSXPASS "https://$NSX/policy/api/v1$TNPPATH" -X PUT -H "Content-Type:application/json" --data @tnp_rollback.json

read -p "Do you want to delete the .json files created in this script? (Y/N)" -n 1 -r CHOICE
echo    #
if [[ $CHOICE =~ ^[Yy]$ ]];

then

echo "Deleting .json files"
rm -rf *.json
rm -rf *.list
rm -rf *.list-e
else
echo "Saving the .json files"

fi

fi

fi

echo 'Do you want to DELETE a TEP Uplink profile?'
echo ''
read -p "Answer(Y/N): " ANSWERTEPDEL

if [[ $ANSWERTEPDEL =~ ^[Yy]$ ]];

then

curl -s -k -u $NSXUSER:$NSXPASS "https://$NSX/policy/api/v1/infra/host-switch-profiles" -X GET | grep '"path"' > tepprofile.list

sed -i'' -e 's/ //g' tepprofile.list
sed -i'' -e 's/:/\t/g' tepprofile.list
sed -i'' -e 's/,/\t/g' tepprofile.list
sed -i'' -e 's/"//g' tepprofile.list



echo "Which TEP Uplink Profile do you want to Delete?"
echo ''
echo `cat -n tepprofile.list | awk 'BEGIN{FS=OFS="\t"} { print $1,$3 }'`

read -p "Answer: " TEPDELNUMBER

if [[ "$TEPDELNUMBER" -le 0 ]]

then

echo "doing nothing"

sleep 1


else

echo "Deleting TEP Uplink Profile $TEPDELNUMBER"

sleep 1

sed -n $TEPDELNUMBER,999p tepprofile.list > tepprofile2.list
sed -n 1,1p tepprofile2.list > tepprofile.list

TEPUPLINKPATH=`cat tepprofile.list | awk 'BEGIN{FS=OFS="\t"} { print $2 }'`

#echo "$TEPUPLINKPATH"

curl -s -k -u $NSXUSER:$NSXPASS "https://$NSX/policy/api/v1$TEPUPLINKPATH" -X DELETE

read -p "Do you want to delete the .json files created in this script? (Y/N)" -n 1 -r CHOICE
echo    #
if [[ $CHOICE =~ ^[Yy]$ ]];

then

echo "Deleting .json files"
rm -rf *.json
rm -rf *.list
rm -rf *.list-e
else
echo "Saving the .json files"

fi

fi

fi

echo 'Configuring the TNP Profiles then'
echo ''

read -p "VTEP HA profile name (Default: vtephaprofile1): " VTEPHAPROFILEREAD

if [[ -z $VTEPHAPROFILEREAD ]]

then

VTEPHAPROFILE=vtephaprofile1

else

VTEPHAPROFILE=$VTEPHAPROFILEREAD

fi

cat > $VTEPHAPROFILE.json << EOL
{
  "enabled": "true",
  "failover_timeout":"5",
  "auto_recovery" : "true",
  "auto_recovery_initial_wait" : "300",
  "auto_recovery_max_backoff" : "86400",
  "resource_type": "PolicyVtepHAHostSwitchProfile",
  "display_name": "$VTEPHAPROFILE"
}
EOL

echo "Creating VTEP HA Uplink Profile"

curl -s -k -u $NSXUSER:$NSXPASS "https://$NSX/policy/api/v1/infra/host-switch-profiles/$VTEPHAPROFILE" -X PUT -H "Content-Type:application/json" --data @$VTEPHAPROFILE.json

sleep 1


echo "Which TNP Profile do you want to apply the VTEP HA Uplink Profile?"
echo ''

echo `cat -n $SECTION | awk 'BEGIN{FS=OFS="\t"} { print $1,$3 }'`


echo ''
read -p "Answer: " ANSWER

if [[ "$ANSWER" -le 0 ]]

then

echo "doing nothing"

sleep 1

exit 0


else

echo "$ANSWER"
echo "Updating TNP Profile $ANSWER"

sleep 1

sed -n $ANSWER,999p tnp.list > tnp2.list
sed -n 1,1p tnp2.list > tnp.list


#echo `cat tnp.list`

TNPPATH=`cat tnp.list | awk 'BEGIN{FS=OFS="\t"} { print $4 }'`

#echo $TNPPATH


curl -s -k -u $NSXUSER:$NSXPASS "https://$NSX/policy/api/v1$TNPPATH" -X GET -H "Content-Type:application/json" > tnpconfig.json

cat > tnp4.json << EOL
        "key" : "VtepHAHostSwitchProfile",
        "value" : "/infra/host-switch-profiles/$VTEPHAPROFILE"
EOL


sed -n 1,10p tnpconfig.json > tnp3.json
echo '      }, {' >> tnp3.json
cat tnp4.json >> tnp3.json
sed -n 11,199p tnpconfig.json >> tnp3.json

curl -s -k -u $NSXUSER:$NSXPASS "https://$NSX/policy/api/v1$TNPPATH" -X PUT -H "Content-Type:application/json" --data @tnp3.json


fi

read -p "Do you want to delete the .json files created in this script? (Y/N)" -n 1 -r CHOICE
echo    #
if [[ $CHOICE =~ ^[Yy]$ ]];

then

echo "Deleting .json files"
rm -rf *.json
rm -rf *.list
rm -rf *.list-e
else
echo "Saving the .json files"

fi
