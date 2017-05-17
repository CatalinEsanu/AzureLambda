# AzureLambda
Lambda Architecture Using Azure PaaS Services


<img src="https://github.com/CatalinEsanu/AzureLambda/blob/master/Desc/overview.png" width="800">

This process creates an ACS cluster that has several containers on it writing to Event Hubs.
From there the flow forks to:


Batch Layer – Event Hubs writes to Storage Account with Event Hubs Archive feature, then an hourly spark jobs runs over the avro files produced during that hour and consolidates them into parquet files.
These files can be used for offline reporting, data exploration, hive tables, etc.

Speed Layer – Stream Analytics reads from Event Hubs and writes the data to CosmosDB (using the native API).
There data can be read and used for online process.

Serving Layer - This layer is not included yet.

The script automates all aspects of the deployment and creates a functional data pipeline in less than 1 hour (mostly the time it takes to provision the HDI cluster and the ACS cluster).

It is possible to change the (JSON) data schema written to Event Hubs, without having to change any of the existing components - this was planned to be absolutely  schema agnostic.

## General Parameters
```
$geoLocation="West Europe"
```

*Not all features are available on all regions.

# Usage 

```
PS > <directory>\invokeLambda.ps1
```

# Component Overview

## Azure Container Services (ACS)
https://docs.microsoft.com/en-us/azure/container-service/container-service-intro


### Parameters
```
$dcosAgentCount = 1 # Number of agents
$dcosAgentVMSize = "Standard_A3"
$dcosLinuxAdminUsername = "azureuser"
$dcosMasterCount = 1 # Use 3 for production
$dcosSshRSAPublicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAlwUbj59tAoinx6BqJXID4Ej2Xa5m3tsI3jQpVDOiyniR6hvIS+quuTayc2cyB6w3vyLXdFBwWvdPOuxxNoGpzA+N0k9uBym216oa4uLbxiCmuo6rbTiseYBjS/7Y/NCwLsAPbqyRdbyGVgp7gmRusVS3gEXt8mRGEszSAOYYKXq8vsOvzoq0BgpOypLQojKmkw7+YXleMwYJ8ac9EM6R8w3sECJpPR7dyOQJn6ZA+eHvMft87lo/Q0xu1yS1UB4RDoNwF3E3e4ej+37pAacRr+IHHPrFW8UKV9lmpruDEf/4k8njmatE8Mhwk31v/OGCri2gDAMVE+hQlm1cFjum1Q== rsa-key-20170430" # BE SURE TO CHANGE THIS IF YOU ARE GOING TO USE ANY KIND OF PRODUCTION DATA ON THIS CLUSTER
```


## Azure Event Hubs 
https://docs.microsoft.com/en-us/azure/event-hubs/event-hubs-what-is-event-hubs

This is currently created with 1 Throughput Unit.


### Parameters
```
$ehArchiveTime = 300 # Time in seconds
$ehArchiveSize = 314572800 # Size in bytes
```

## Azure Blob Storage
https://docs.microsoft.com/en-us/azure/storage/storage-introduction#blob-storage


## Spark on Azure HDInsight
https://docs.microsoft.com/en-us/azure/hdinsight/hdinsight-apache-spark-overview

### Parameters
```
$hdiSparkVersion = "2.0" # Spark Version
$hdiClusterLoginUserName = "azureuser" # Ambari login user name
$hdiClusterLoginPassword = "Ab12345678!1" # Cluster password for all accounts
$hdiSshUserName = "azureuserssh" # SSH User
```

## Azure Stream Analytics
https://docs.microsoft.com/en-us/azure/stream-analytics/stream-analytics-introduction

### Parameters
```
$saNumberOfStreamingUnits = 12
```

## Azure CosmosDB
This is Azure's global scale NoSQL database. 

Since its native Powershell cmdlets don't support all the operations required by this automation script, I used the following project as a baseline to what is used here:
https://github.com/savjani/Azure-DocumentDB-Powershell-Cmdlets

The collection is created with the SQL API (which is the Native DocumentDB API)
The partitionKey is hardcoded as "id"

### Parameters
```
$docdbConsistencyLevel = "BoundedStaleness" # Strong | BoundedStaleness | Session | ConsistentPrefix | Eventual
$docdbMaxStalenessPrefix= 100 # When used with Bounded Staleness consistency, this value represents the number of stale requests tolerated. Accepted range for this value is 1 – 2,147,483,647.
$docdbMaxIntervalInSeconds = 5 # When used with Bounded Staleness consistency, this value represents the time amount of staleness (in seconds) tolerated. Accepted range for this value is 1 - 100.
$docdbDBName="DB1" # Database name
$docdbCollName="coll1" # Collection name
```

## TODOs
- Automate Event Hubs Throughput Units scaling.
- Streamline script outputs
- Add error handling
- Add "Deployment Size" parameter and scale services accordingly.
- Set CosmosDB partitionKey and RU/s as parameters.