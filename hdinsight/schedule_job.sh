export PREFIX=`hostname | cut -c 1-3`
if [ "$PREFIX" = "hn0" ]; then
	sudo crontab -l > cronfile
	echo 30 \* \* \* \* /usr/hdp/current/spark2-client/bin/spark-submit --master yarn --deploy-mode cluster --name PARSE_AVRO --num-executors 2 --executor-cores 2 --conf spark.executor.memory=2G  --conf spark.yarn.executor.memoryOverhead=1024 --conf spark.yarn.driver.memoryOverhead=4072 --conf spark.driver.memory=1G --conf spark.driver.cores=2  --conf spark.jars.packages='com.databricks:spark-avro_2.11:3.1.0' wasbs://hdiscripts@catalinsparkstorage11.blob.core.windows.net/process_avro.py >> cronfile
	sudo crontab cronfile
fi	
