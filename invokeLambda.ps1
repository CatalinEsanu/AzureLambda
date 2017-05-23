###############################################
# Install Prerequisites
###############################################

if ( -Not ( ( Get-Module -ListAvailable AzureRM.Compute) -and
( Get-Module -ListAvailable AzureRM.EventHub) -and
( Get-Module -ListAvailable AzureRM.HDInsight) -and
( Get-Module -ListAvailable AzureRM.IotHub) -and
( Get-Module -ListAvailable AzureRM.Network) -and
( Get-Module -ListAvailable AzureRM.Profile) -and
( Get-Module -ListAvailable AzureRM.Resources) -and
( Get-Module -ListAvailable AzureRM.ServiceBus) -and
( Get-Module -ListAvailable AzureRM.Storage) -and
( Get-Module -ListAvailable AzureRM.StreamAnalytics)
 ))
{
    Write-Output 'I am missing some prereqs - installing'
    Install-Module AzureRM -Force
    Install-AzureRM -AllowClobber
    Import-Module AzureRM

}

$title = "LOADER Environment"
$message = "Do you want me to create a load environemnt that will push data into the system?"

$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
    "Creates DC/OS cluster."

$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
    "Does not create DC/OS cluster."

$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

$isCreateLoader = $host.ui.PromptForChoice($title, $message, $options, 0) 

switch ($isCreateLoader)
    {
        0 {"You selected Yes."}
        1 {"You selected No."}
    }



###############################################
# Login
###############################################

Login-AzureRmAccount

$subscriptionSelected=0

while ($subscriptionSelected -eq 0) {
    
    Write-Output "Please choose a relevant and valid subscription id"

    Get-AzureRmSubscription
        
    $subscriptionId = read-host -prompt "Your selection " 

        Set-AzureRmContext -SubscriptionId $subscriptionId
    if ( $? -eq $true)
    {
        $subscriptionSelected=1
    } else
    {
        $subscriptionSelected=0
    }
}

Get-AzureRmContext 
###############################################
# Global variables
###############################################


$runDir=split-path -parent $MyInvocation.MyCommand.Definition # "C:\Users\cesanu\OneDrive for Business\DOCS\Templates\Lambda"
#$runDir="C:\Users\xxx\Desktop\AzureLambda-master\AzureLambda-master"
cd $runDir
$uniqueId = Get-Random -minimum 10000 -maximum 99999
$resourceGroupName="Lambda" + $uniqueId + "-RG"
$loaderResourceGroupName="Load"+$resourceGroupName
$deploymentName="Lambda" + $uniqueId
$loaderDeploymentName="Loader" + $uniqueId
$geoLocation="West Europe"
$templateFile=$runDir + "\ARMTemplates\ARMTemplateDeployLambda.json" # Do not change
$paramsFile=$runDir + "\ARMTemplateDeployLambda.params.json" # Do not change

New-Item -ItemType Directory -Force -Path .\runtime

# Stream Analytics
$saStreamAnalyticsJobName = "SAJob" + $uniqueId
$saNumberOfStreamingUnits = 12
$saInputTemplateFile = ".\StreamAnalytics\Template\TemplateStreamAnalyticsInput.json" # Do not change
$saInputFile = ".\runtime\StreamAnalyticsInput.json" # Do not change
$saOutputTemplateFile = ".\StreamAnalytics\Template\TemplateStreamAnalyticsOutput.json" # Do not change
$saOutputFile = ".\runtime\StreamAnalyticsOutput.json" # Do not change

# Event Hubs
$ehArchDeployment="ehArch" + $uniqueId
$ehNamespaceName =  "lambdans" + $uniqueId
$ehEventHubName = "lambdaeh" + $uniqueId
$ehConsumerGroupName = "lambdacg" + $uniqueId
$ehArchiveStorageAcc = "ehacc" + $uniqueId
$ehArchiveTime = 300
$ehArchiveSize = 314572800
$ehArchiveEnabled = "true" # Do not change
$ehArchiveEncodingFormat = "Avro" # Do not change
$ehArchiveStorageContainer = "eventhubsarchive" # Do not change
$ehSharedAccessPolicyName="RootManageSharedAccessKey" # Do not change

$ehArchTemplateFile=$runDir +"\ARMTemplates\ARMTemplateDeployEHArchive.json" # Do not change
$ehArchParamsFile=$runDir+".\ARMTemplateDeployEHArchive.params.json" # Do not change

# CosmosDB
$docdbDatabaseAccountName = "lambdadoc" + $uniqueId
$docdbConsistencyLevel = "BoundedStaleness"
$docdbMaxStalenessPrefix= 100
$docdbMaxIntervalInSeconds = 5
$docdbDBName="DB1" 
$docdbCollName="coll1"
$docdbExecutables = ".\cosmos-cmdlets\" # Do not change

# HDInsight 
$hdiClusterName = "lambdahdi" + $uniqueId
$hdiSparkVersion = "2.1"
$hdiClusterVersion = "3.6"
$hdiSparkStorageAccount = "hdiacc" + $uniqueId
$hdiClusterLoginUserName = "azureuser"
$hdiClusterLoginPassword = "Ab12345678!1"
$hdiSshUserName = "azureuserssh"
$hdiJobOutputContainer = "joboutput" # Do not change
$hdiScriptsContainer = "hdiscripts" # Do not change
$hdiFilesLoc = $runDir+"\HDInsight" # Do not change
$hdiAvroScriptTemplate = $hdiFilesLoc + "\process_avro_template.py" # Do not change
$hdiAvroScriptShortName = "process_avro.py" # Do not change
$hdiAvroScript = ".\runtime\" + $hdiAvroScriptShortName # Do not change
$hdiScriptActionShortName = "schedule_job.sh" # Do not change
$hdiScriptAction = ".\runtime\" + $hdiScriptActionShortName # Do not change
$hdiScriptActionTemplate = $hdiFilesLoc + "\schedule_job_template.sh" # Do not change

# DCOS
$dcosDnsNamePrefix = "ehloader" + $uniqueId
$dcosAgentCount = 1
$dcosAgentVMSize = "Standard_A3"
$dcosLinuxAdminUsername = "azureuser"
$dcosOrchestratorType = "DCOS" # Do not change
$dcosMasterCount = 1
$dcosSshRSAPublicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAlwUbj59tAoinx6BqJXID4Ej2Xa5m3tsI3jQpVDOiyniR6hvIS+quuTayc2cyB6w3vyLXdFBwWvdPOuxxNoGpzA+N0k9uBym216oa4uLbxiCmuo6rbTiseYBjS/7Y/NCwLsAPbqyRdbyGVgp7gmRusVS3gEXt8mRGEszSAOYYKXq8vsOvzoq0BgpOypLQojKmkw7+YXleMwYJ8ac9EM6R8w3sECJpPR7dyOQJn6ZA+eHvMft87lo/Q0xu1yS1UB4RDoNwF3E3e4ej+37pAacRr+IHHPrFW8UKV9lmpruDEf/4k8njmatE8Mhwk31v/OGCri2gDAMVE+hQlm1cFjum1Q== rsa-key-20170430"
$dcosNATRuleName = "HTTPNATRULE"    
$dcosDeploymentTemplateURI = "https://raw.githubusercontent.com/azure/azure-quickstart-templates/master/101-acs-dcos/azuredeploy.json " # Do not change
$dcosFilesLoc = $runDir + "\dcos" # Do not change
$dcosDeploymentTemplateParams = ".\ARMTemplateDCOS.params.json" # Do not change
$dcosInstanceTemplateFile = $dcosFilesLoc + "\Template\deployInstanceToDCOSTemplate.json" # Do not change
$dcosInstanceFile = ".\runtime\deployInstanceToDCOS.json" # Do not change


cp $docdbExecutables\Azrdocdb.dll $PSHome\Modules


###############################################
# Initial Template Deployment
###############################################

New-AzureRmResourceGroup -Name $resourceGroupName -Location $geoLocation



#Deploy the template
Write-Output "Deploying initial template - this can take about 20 minutes (or more)"

#$initialTemplateResult=(New-AzureRmResourceGroupDeployment -Name $deploymentName -ResourceGroupName $resourceGroupName -TemplateFile $templateFile -TemplateParameterFile $paramsFile)
$initialTemplateResult=(New-AzureRmResourceGroupDeployment -Name $deploymentName -ResourceGroupName $resourceGroupName -TemplateFile $templateFile `
    -namespaceName $ehNamespaceName `
    -eventHubName $ehEventHubName `
    -consumerGroupName $ehConsumerGroupName `
    -archiveStorageAcc $ehArchiveStorageAcc `
    -databaseAccountName $docdbDatabaseAccountName `
    -consistencyLevel $docdbConsistencyLevel `
    -maxStalenessPrefix $docdbMaxStalenessPrefix `
    -maxIntervalInSeconds $docdbMaxIntervalInSeconds `
    -streamAnalyticsJobName $saStreamAnalyticsJobName `
    -numberOfStreamingUnits $saNumberOfStreamingUnits `
    -clusterName $hdiClusterName `
    -sparkVersion $hdiSparkVersion `
    -sparkStorageAccount $hdiSparkStorageAccount `
    -clusterLoginUserName $hdiClusterLoginUserName `
    -clusterLoginPassword (ConvertTo-SecureString $hdiClusterLoginPassword -AsPlainText -Force) `
    -sshUserName $hdiSshUserName `
    -sshPassword (ConvertTo-SecureString $hdiClusterLoginPassword -AsPlainText -Force) `
    -clusterVersion $hdiClusterVersion `
)




Write-Output $initialTemplateResult.ProvisioningState

###############################################
# DocumentDB
###############################################

#Create DocumentDB Collection
Write-Output "Running CosmosDB configs"

Import-Module $docdbExecutables\Azrdocdb.dll


$dbkey = (Invoke-AzureRmResourceAction -Action listKeys -ResourceType "Microsoft.DocumentDb/databaseAccounts" -ApiVersion "2015-04-08" -ResourceGroupName $resourceGroupName -ResourceName $docdbDatabaseAccountName -Force).primaryMasterKey
$dburi = "https://" + $docdbDatabaseAccountName + ".documents.azure.com:443/"
$ctx = New-Context -Uri $dburi -Key $dbkey
$db = Add-Database -Context $ctx -Name $docdbDBName
$coll = Add-DocumentCollection -Context $ctx -DatabaseLink $db.SelfLink -Name $docdbCollName 



###############################################
# Stream Analytics
###############################################

Write-Output "Running Stream Analytics configs"

#Make sure the job is stopped in order to allow changes
Stop-AzureRmStreamAnalyticsJob -ResourceGroupName $resourceGroupName -Name $saStreamAnalyticsJobName

# Define stream Analytics Input - Paramaeters: "ConsumerGroupName": "<ConsumerGroupName>","EventHubName": "<EventHubName>","ServiceBusNamespace": "<ServiceBusNamespace>","SharedAccessPolicyKey": "<SharedAccessPolicyKey>","SharedAccessPolicyName": "<SharedAccessPolicyName>"
$ehSharedAccessPolicyKey =  (Get-AzureRmEventHubNamespaceKey -ResourceGroupName $resourceGroupName -NamespaceName $ehNamespaceName -AuthorizationRuleName $ehSharedAccessPolicyName).PrimaryKey



cp $saInputTemplateFile $saInputFile
(Get-Content $saInputFile).replace('<EventHubName>', $ehEventHubName) | Set-Content $saInputFile
(Get-Content $saInputFile).replace('<ConsumerGroupName>', $ehConsumerGroupName) | Set-Content $saInputFile
(Get-Content $saInputFile).replace('<ServiceBusNamespace>', $ehNamespaceName) | Set-Content $saInputFile
(Get-Content $saInputFile).replace('<SharedAccessPolicyKey>', $ehSharedAccessPolicyKey) | Set-Content $saInputFile
(Get-Content $saInputFile).replace('<SharedAccessPolicyName>', $ehSharedAccessPolicyName) | Set-Content $saInputFile


New-AzureRMStreamAnalyticsInput -ResourceGroupName $resourceGroupName -JobName $saStreamAnalyticsJobName –File $saInputFile –Name InputEH -Force


# Define stream Analytics Output - Parameters:  "AccountId": "<AccountId>","AccountKey": "<AccountKey>","CollectionNamePattern": "<CollectionNamePattern>","Database": "<Database>",
cp $saOutputTemplateFile $saOutputFile
(Get-Content $saOutputFile).replace('<AccountId>', $docdbDatabaseAccountName) | Set-Content $saOutputFile
(Get-Content $saOutputFile).replace('<AccountKey>', $dbkey) | Set-Content $saOutputFile
(Get-Content $saOutputFile).replace('<Database>', $docdbDBName) | Set-Content $saOutputFile
(Get-Content $saOutputFile).replace('<CollectionNamePattern>', $docdbCollName) | Set-Content $saOutputFile


New-AzureRMStreamAnalyticsOutput -ResourceGroupName $resourceGroupName –File $saOutputFile –JobName $saStreamAnalyticsJobName –Name OutputDB -Force


# Start the job
Start-AzureRMStreamAnalyticsJob -ResourceGroupName $resourceGroupName -Name $saStreamAnalyticsJobName -OutputStartMode   JobStartTime


###############################################
# Configure Storage Accounts
###############################################

Write-Output "Configuring storage accounts"

# Create container for Event Hubs Archive feature
$eventHubArchiveStorageAccountKeys = Get-AzureRmStorageAccountKey -ResourceGroupName $resourceGroupName -Name $ehArchiveStorageAcc;
$ehStorageContext = New-AzureStorageContext -StorageAccountName $ehArchiveStorageAcc -StorageAccountKey $eventHubArchiveStorageAccountKeys[0].Value;
New-AzureStorageContainer -Context $ehStorageContext -Name $ehArchiveStorageContainer;


# Create containers for HDI scripts and output files
$hdiStorageAccountKeys = Get-AzureRmStorageAccountKey -ResourceGroupName $resourceGroupName -Name $hdiSparkStorageAccount;
$hdiStorageContext = New-AzureStorageContext -StorageAccountName $hdiSparkStorageAccount -StorageAccountKey $hdiStorageAccountKeys[0].Value;
New-AzureStorageContainer -Context $hdiStorageContext -Name $hdiJobOutputContainer;
New-AzureStorageContainer -Context $hdiStorageContext -Name $hdiScriptsContainer -Permission container;




###############################################
# Configure Event Hubs Archive
###############################################
Write-Output "Deploying Event Hubs Archive"

#$ehArchiveTemplateResult=New-AzureRmResourceGroupDeployment -Name $ehArchDeployment -ResourceGroupName $resourceGroupName -TemplateFile $ehArchTemplateFile -TemplateParameterFile $ehArchParamsFile
$ehArchiveTemplateResult=(New-AzureRmResourceGroupDeployment -Name $ehArchDeployment -ResourceGroupName $resourceGroupName -TemplateFile $ehArchTemplateFile `
    -namespaceName $ehNamespaceName `
    -eventHubName $ehEventHubName `
    -consumerGroupName $ehConsumerGroupName `
    -archiveEnabled $ehArchiveEnabled `
    -archiveEncodingFormat $ehArchiveEncodingFormat `
    -archiveTime $ehArchiveTime  `
    -archiveSize $ehArchiveSize  `
    -archiveStorageAcc $ehArchiveStorageAcc `
    -archiveStorageContainer $ehArchiveStorageContainer `
)


Write-Output $ehArchiveTemplateResult.ProvisioningState


###############################################
# Configure HDInsight Spark 
###############################################

cp $hdiAvroScriptTemplate $hdiAvroScript
(Get-Content $hdiAvroScript).replace('<<ehNamespace>>', $ehNamespaceName) | Set-Content $hdiAvroScript
(Get-Content $hdiAvroScript).replace('<<ehName>>', $ehEventHubName) | Set-Content $hdiAvroScript
(Get-Content $hdiAvroScript).replace('<<inputStorageAccount>>', $ehArchiveStorageAcc) | Set-Content $hdiAvroScript
(Get-Content $hdiAvroScript).replace('<<inputContainer>>', $ehArchiveStorageContainer) | Set-Content $hdiAvroScript
(Get-Content $hdiAvroScript).replace('<<outputStorageAccount>>', $hdiSparkStorageAccount) | Set-Content $hdiAvroScript
(Get-Content $hdiAvroScript).replace('<<outputContainer>>', $hdiJobOutputContainer) | Set-Content $hdiAvroScript

cp $hdiScriptActionTemplate $hdiScriptAction
(Get-Content $hdiScriptAction).replace('<<hdiScriptsContainer>>', $hdiScriptsContainer) | Set-Content $hdiScriptAction
(Get-Content $hdiScriptAction).replace('<<hdiStorageAccount>>', $hdiSparkStorageAccount) | Set-Content $hdiScriptAction
(Get-Content $hdiScriptAction).replace('<<hdiAvroScriptShortName>>', $hdiAvroScriptShortName) | Set-Content $hdiScriptAction


$hdiStorageContext = New-AzureStorageContext -StorageAccountName $hdiSparkStorageAccount -StorageAccountKey $hdiStorageAccountKeys[0].Value;
Set-AzureStorageBlobContent -File $hdiAvroScript -Container $hdiScriptsContainer -Blob $hdiAvroScriptShortName -Context $hdiStorageContext -Force
Set-AzureStorageBlobContent -File $hdiScriptAction -Container $hdiScriptsContainer -Blob $hdiScriptActionShortName -Context $hdiStorageContext -Force


$hdiScriptActionURI = "https://"+ $hdiSparkStorageAccount +".blob.core.windows.net/"+ $hdiScriptsContainer +"/" + $hdiScriptActionShortName

Write-Output "Deploying HDInsight Script Action"

# Deploy script Action
$hdiScriptActionResult=Submit-AzureRmHDInsightScriptAction `
            -ClusterName $hdiClusterName `
            -Name "config crontab" `
            -Uri $hdiScriptActionURI `
            -NodeTypes HeadNode 

write-output $hdiScriptActionResult.OperationState



###############################################
# Configure Loading Environment
###############################################

if ($isCreateLoader -eq 0)
{
    Write-Output "Deploying Load environment - this can take 20 minutes (or more)"

    cp $dcosInstanceTemplateFile $dcosInstanceFile
    (Get-Content $dcosInstanceFile).replace('<<EH_NAMESPACE>>', $ehNamespaceName) | Set-Content $dcosInstanceFile
    (Get-Content $dcosInstanceFile).replace('<<EH_NAME>>', $ehEventHubName) | Set-Content $dcosInstanceFile
    (Get-Content $dcosInstanceFile).replace('<<EH_SHARED_ACCESS_KEY_NAME>>', $ehSharedAccessPolicyName) | Set-Content $dcosInstanceFile
    (Get-Content $dcosInstanceFile).replace('<<EH_SHARED_ACCESS_KEY_VALUE>>', $ehSharedAccessPolicyKey) | Set-Content $dcosInstanceFile

    New-AzureRmResourceGroup -Name $loaderResourceGroupName -Location $geoLocation


    #$dcosClusterOutput=(New-AzureRmResourceGroupDeployment -Name $loaderDeploymentName -ResourceGroupName $loaderResourceGroupName -TemplateUri $dcosDeploymentTemplateURI -TemplateParameterFile $dcosDeploymentTemplateParams).Outputs
    $dcosClusterOutput=(New-AzureRmResourceGroupDeployment -Name $loaderDeploymentName -ResourceGroupName $loaderResourceGroupName -TemplateUri $dcosDeploymentTemplateURI `
        -dnsNamePrefix $dcosDnsNamePrefix `
        -agentCount $dcosAgentCount `
        -agentVMSize $dcosAgentVMSize `
        -linuxAdminUsername $dcosLinuxAdminUsername `
        -orchestratorType $dcosOrchestratorType `
        -masterCount $dcosMasterCount `
        -sshRSAPublicKey $dcosSshRSAPublicKey `
    )
  


    $masterURL= $dcosClusterOutput.Outputs.masterFQDN.Value

    $masterNSGName=(Get-AzureRmNetworkSecurityGroup -ResourceGroupName $loaderResourceGroupName).Name | sls "master"
    $masterNSG= Get-AzureRmNetworkSecurityGroup -ResourceGroupName $loaderResourceGroupName -Name $masterNSGName

    Add-AzureRmNetworkSecurityRuleConfig -NetworkSecurityGroup $masterNSG `
        -Name all-rule `
        -Description "Allow any" `
        -Access Allow `
        -Protocol Tcp `
        -Direction Inbound `
        -Priority 100 `
        -SourceAddressPrefix * `
        -SourcePortRange * `
        -DestinationAddressPrefix * `
        -DestinationPortRange *


    Set-AzureRmNetworkSecurityGroup -NetworkSecurityGroup $masterNSG


    $masterLBName=(get-AzureRmLoadBalancer -ResourceGroupName $loaderResourceGroupName).Name | sls "master"
    $masterLB=get-AzureRmLoadBalancer -ResourceGroupName $loaderResourceGroupName -Name $masterLBName
    $masterLB | Add-AzureRmLoadBalancerInboundNatRuleConfig -Name $dcosNATRuleName -FrontendIPConfiguration $masterLB.FrontendIpConfigurations[0] -Protocol "Tcp" -FrontendPort 80 -BackendPort 80  | Set-AzureRmLoadBalancer 

    $masterNICName=((Get-AzureRmNetworkInterface -ResourceGroupName $loaderResourceGroupName ).name | sls "master")[0]
    $masterNIC=Get-AzureRmNetworkInterface -ResourceGroupName $loaderResourceGroupName -Name $masterNICName
    $masterNIC.IpConfigurations[0].LoadBalancerInboundNatRules.Add((Get-AzureRmLoadBalancerInboundNatRuleConfig -LoadBalancer $masterLB -Name $dcosNATRuleName)) 
    Set-AzureRmNetworkInterface -NetworkInterface $masterNIC

    $dcosSubmitURI= "http://"+$masterURL+"/marathon/v2/apps/"

    Invoke-WebRequest -Method post -Uri $dcosSubmitURI -ContentType application/json -InFile $dcosInstanceFile # '.\dcos\deployment.json'

}
else 
{
    Write-Output "Loading environment will not be created"
}

###############################################
# Done 
###############################################


write-output "Done successfully"