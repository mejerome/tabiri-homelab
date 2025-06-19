#! /bin/bash
managementaccount=`aws organizations describe-organization --profile root --query Organization.MasterAccountId --output text`

for account in $(aws organizations list-accounts --profile root --query 'Accounts[].Id' --output text); do
        
    if [ "$account" == "$managementaccount" ]; then
        echo 'Skipping management account.'
        continue
    fi

    # Put alternate contacts
    echo "Updating alternate contact for $account..."
    aws account put-alternate-contact --profile root --alternate-contact-type=SECURITY  --account-id $account --email-address=awssecnotice@penske.com  --phone-number="610-775-6000" --title="610-775-6000" --name="Scott Pemrick"
    
    aws account put-alternate-contact --profile root --alternate-contact-type=BILLING  --account-id $account --email-address=aws.billalert@penske.com  --phone-number="610-775-6000" --title="Program Manager" --name="Connie Showalter"

    aws account put-alternate-contact --profile root --alternate-contact-type=OPERATIONS  --account-id $account --email-address=alert.awsproduction@penske.com  --phone-number="610-775-6000" --title="Director" --name="Gary Galyas"
    sleep 0.2
done
