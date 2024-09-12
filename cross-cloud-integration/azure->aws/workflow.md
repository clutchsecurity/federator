Azure-AWS-AssumeRole - Managed Identity - Object (principal) ID - 89db5217-9f6f-4148-b0ed-f125c0d8c125

azure_aws_assume_role - App Roles - e277fc03-f004-4644-b7c8-6c0ed89ae577

PrincipalID = Object ID

ResourceID = 1e6f2537-375c-40fa-8a64-f53bcf5550b7

New-AzureADServiceAppRoleAssignment -ObjectId <ObjectID> -Id <ID> -PrincipalId <PrincipalID> -ResourceId <ResourceID>

curl -X POST https://graph.microsoft.com/v1.0/servicePrincipals/89db5217-9f6f-4148-b0ed-f125c0d8c125/appRoleAssignments \
-H "Authorization: Bearer $accessToken" \
-H "Content-Type: application/json" \
-d '{
    "principalId": "89db5217-9f6f-4148-b0ed-f125c0d8c125",
    "resourceId": "1e6f2537-375c-40fa-8a64-f53bcf5550b7",
    "appRoleId": "e277fc03-f004-4644-b7c8-6c0ed89ae577"
}'

```
az rest --method POST --uri "https://graph.microsoft.com/v1.0/servicePrincipals/89db5217-9f6f-4148-b0ed-f125c0d8c125/appRoleAssignments" --body '{
    "principalId": "89db5217-9f6f-4148-b0ed-f125c0d8c125",
    "resourceId": "1e6f2537-375c-40fa-8a64-f53bcf5550b7",
    "appRoleId": "e277fc03-f004-4644-b7c8-6c0ed89ae577"
}'
{
  "@odata.context": "https://graph.microsoft.com/v1.0/$metadata#servicePrincipals('89db5217-9f6f-4148-b0ed-f125c0d8c125')/appRoleAssignments/$entity",
  "appRoleId": "e277fc03-f004-4644-b7c8-6c0ed89ae577",
  "createdDateTime": "2024-05-16T17:40:25.3586982Z",
  "deletedDateTime": null,
  "id": "F1LbiW-fSEGw7fElwNjBJWVkVAvmO7FIsR94xDJWEl8",
  "principalDisplayName": "Azure-AWS-AssumeRole",
  "principalId": "89db5217-9f6f-4148-b0ed-f125c0d8c125",
  "principalType": "ServicePrincipal",
  "resourceDisplayName": "azure_aws_assume_role",
  "resourceId": "1e6f2537-375c-40fa-8a64-f53bcf5550b7"
}
```

 "tenantId": "b506ae5f-374f-4e03-ad64-c1bc65e5ba82",

Azure-AWSAssumeRole
{
    "Version": "2012-10-17",
    "Statement": [{
        "Effect": "Allow",
        "Principal": {
            "Federated": "arn:aws:iam::558267956267:oidc-provider/sts.windows.net/b506ae5f-374f-4e03-ad64-c1bc65e5ba82/"
        },
        "Action": "sts:AssumeRoleWithWebIdentity",
        "Condition": {
            "StringEquals": {
                "sts.windows.net/b506ae5f-374f-4e03-ad64-c1bc65e5ba82/:aud": "urn://aws-account",
                "sts.windows.net/b506ae5f-374f-4e03-ad64-c1bc65e5ba82/:sub": "89db5217-9f6f-4148-b0ed-f125c0d8c125"
            }
        }
    }]
}

---
AUDIENCE="urn://aws-account"
ROLE_ARN="arn:aws:iam:: :role/Azure-AWSAssumeRole"
access_token=$(curl "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=${AUDIENCE}" -H "Metadata:true" -s| jq -r '.access_token')

# Create credentials following JSON format required by AWS CLI
credentials=$(aws sts assume-role-with-web-identity –role-arn ${ROLE_ARN} –web-identity-token $access_token –role-session-name AWSAssumeRole|jq '.Credentials' | jq '.Version=1')

# Write credentials to STDOUT for AWS CLI to pick up
echo $credentials 

$ curl -v \
      --header "Content-Type: application/x-www-form-urlencoded" \
        --data "Action=AssumeRoleWithWebIdentity" \
        --data "Version=2011-06-15" \
        --data "DurationSeconds=3600" \
        --data "RoleSessionName=sesss" \
        --data "RoleArn=${ROLE_ARN}" \
        --data "WebIdentityToken="$access_token \
      POST https://sts.amazonaws.com