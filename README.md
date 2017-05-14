# AzureLambda
Lambda Architecture Using Azure PaaS Services


<img src="https://github.com/CatalinEsanu/AzureLambda/blob/master/Desc/overview.png" width="100">

This process create an ACS cluster that has several containers on it writing to Event Hubs.
From there the flow forks to:
Batch Layer – Event Hubs writes to Storage Account with Event Hubs Archive feature, then an hourly spark jobs runs over the avro files produced during that hour and consolidates them into parquet files.
These files can be used for offline reporting, data exploration, hive tables, etc.

Speed Layer – Stream Analytics reads from Event Hubs and writes the data to CosmosDB (using the native API).
There data can be read and used for online process.

The script automates all aspects of the deployment and creates a functional data pipeline in less than 1 hour (mostly the time it takes to provision the HDI cluster and the ACS cluster).
