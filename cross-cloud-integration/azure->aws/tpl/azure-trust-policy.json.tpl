{
    "Version": "2012-10-17",
    "Statement": [{
        "Effect": "Allow",
        "Principal": {
            "Federated": "arn:aws:iam::${aws_account_id}:oidc-provider/sts.windows.net/${azure_tenant_id}/"
        },
        "Action": "sts:AssumeRoleWithWebIdentity",
        "Condition": {
            "StringEquals": {
                "sts.windows.net/${azure_tenant_id}/:aud": "${identifier_uri}",
                "sts.windows.net/${azure_tenant_id}/:sub": "${principal_id}"
            }
        }
    }]
}
