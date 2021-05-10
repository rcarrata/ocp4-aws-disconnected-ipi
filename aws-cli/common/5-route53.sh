source envs-ocp4
source aws-resources

aws route53 create-hosted-zone --name asimov.lab --caller-reference create-private-dns-stack --vpc VPCRegion=${REGION},VPCId=${VpcId} --hosted-zone-config Comment=create-private-dns-stack,PrivateZone=true

PrivateHostedId=$(aws route53 list-hosted-zones | jq -r --arg HOSTEDZONE "$PrivateHostedZone" '.HostedZones[] | select (.Name | contains ($HOSTEDZONE)) | .Id' | cut -d"/" -f3)
echo "export PrivateHostedId=$PrivateHostedId" >> ${LOGFILE}

IpPublicBastionPrivateIP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=rcarrata-public-bastion" | jq -r .Reservations[].Instances[].PrivateIpAddress)

cat << EOF >> control-record.json
{
            "Comment": "CREATE/DELETE/UPSERT a record ",
            "Changes": [{
            "Action": "CREATE",
                        "ResourceRecordSet": {
                                    "Name": "bastion.${PrivateHostedZone}",
                                    "Type": "A",
                                    "TTL": 300,
                                 "ResourceRecords": [{ "Value": "${IpPublicBastionPrivateIP}"}]
}}]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id ${PrivateHostedId} --change-batch file://control-record.json

echo "Scp the keys"
scp -i ocp4key.pem ocp4key.pem ec2-user@$IpPublicBastion:/tmp
scp -i ocp4key.pem envs-ocp4 ec2-user@$IpPublicBastion:
scp -i ocp4key.pem aws-resources ec2-user@$IpPublicBastion: