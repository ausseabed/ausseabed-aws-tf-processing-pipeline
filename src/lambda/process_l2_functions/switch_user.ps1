##### Switch to caris user
$secretjson = (aws secretsmanager get-secret-value --region ap-southeast-2 --secret-id ga-sb-caris-user-credentials)
$secretjson_extract = $secretjson | ConvertFrom-Json
$secrets = $secretjson_extract.SecretString | ConvertFrom-Json
$usertext = $secrets.user
$passtext = $secrets.password

$hostname=(hostname)

$Password = ConvertTo-SecureString $passtext -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential $hostname\$usertext, $Password

## Then run something like this
# New-PSSession -Credential $credential | Enter-PSSession
# carisbatch --version

$session = New-PSSession -Credential $credential
