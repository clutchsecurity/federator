#cloud-config
write_files:
  - path: /etc/profile.d/set_env_vars.sh
    content: |
      echo "Installing some pre-requisites"
      sudo snap install jq
      sudo apt update
      sudo apt -y install awscli
      export ROLE_ARN="arn:aws:iam::${account_id}:role/${aws_iam_role_name}"
      export ACCESS_TOKEN=$(curl "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=${audience}" -H "Metadata:true" -s | jq -r ".access_token")
      echo "Run the following command to test the AWS connectivity: "
      echo 'curl -s --header "Content-Type: application/x-www-form-urlencoded" --data "Action=${app_role}" --data "Version=2011-06-15" --data "DurationSeconds=3600" --data "RoleSessionName=session" --data "RoleArn=$ROLE_ARN" --data "WebIdentityToken=$ACCESS_TOKEN" https://sts.amazonaws.com'
      response=$(curl -s --header "Content-Type: application/x-www-form-urlencoded" --data "Action=${app_role}" --data "Version=2011-06-15" --data "DurationSeconds=3600" --data "RoleSessionName=session" --data "RoleArn=$ROLE_ARN" --data "WebIdentityToken=$ACCESS_TOKEN" https://sts.amazonaws.com)
      AccessKeyId=$(echo $response | grep -oP '<AccessKeyId>\K[^<]+')
      SecretAccessKey=$(echo $response | grep -oP '<SecretAccessKey>\K[^<]+')
      SessionToken=$(echo $response | grep -oP '<SessionToken>\K[^<]+')
      # Set them as environment variables
      export AWS_ACCESS_KEY_ID=$AccessKeyId
      export AWS_SECRET_ACCESS_KEY=$SecretAccessKey
      export AWS_SESSION_TOKEN=$SessionToken
      # Verify environment variable setting
      echo "AWS_ACCESS_KEY_ID is set to: $AWS_ACCESS_KEY_ID"
      echo "AWS_SECRET_ACCESS_KEY is set to: $AWS_SECRET_ACCESS_KEY"
      echo "AWS_SESSION_TOKEN is set to: $AWS_SESSION_TOKEN"
      echo "Running aws sts get-caller-identity"
      aws sts get-caller-identity