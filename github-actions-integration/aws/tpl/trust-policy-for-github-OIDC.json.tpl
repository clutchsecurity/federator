{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "${oidc_arn}"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "${domain}:aud": ${audience}
                },
                "StringLike": {
                    "${domain}:sub": "repo:${github_username}/*"
                }
            }
        }
    ]
}
