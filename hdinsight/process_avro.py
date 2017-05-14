#Includes
from pyspark.sql import SparkSession
from pyspark.sql.functions import regexp_replace, col, input_file_name
import datetime
from pyspark.sql.types import *
import json
import uuid
import string
import os



spark = SparkSession \
.builder \
.config("spark.hadoop.mapred.output.compress", "true") \
.config("spark.hadoop.mapred.output.compression.codec", "true") \
.config("spark.hadoop.mapred.output.compression.codec", "org.apache.hadoop.io.compress.GzipCodec") \
.config("spark.hadoop.mapred.output.compression.type", "BLOCK") \
.config("mapreduce.fileoutputcommitter.marksuccessfuljobs", "false") \
.config("spark.shuffle.consolidateFiles","true") \
.config("spark.serializer","org.apache.spark.serializer.KryoSerializer") \
.config("spark.ui.showConsoleProgress","false") \
.config("spark.locality.wait","1s") \
.config("spark.kryoserializer.buffer.max","500m") \
.appName("spark-avro-json-sample") \
.getOrCreate()




# Other Definitions
safetyMinutes=20
inputStorageAccount='eventhubsstorageaccount'
inputContainer='eventhubsarchive'
outputStorageAccount='catalinsparkstorage11'
outputContainer='joboutput'
ehName='catalintesteh1'
ehNamespace='catalintestns1'

print 'Define ParaseMessage ' + str(datetime.datetime.now())

try:
	start_time =  datetime.datetime.strptime(str(spark.sql("select update_date from Checkpoint limit 1").select(["update_date"]).collect()[0]["update_date"]), '%Y-%m-%d %H:%M:%S')
except:
	start_time = datetime.datetime.now().replace(minute=0,second=0, microsecond=0) + datetime.timedelta(hours=-2)
	
print "start_time: " + str(start_time)

curr_time =  datetime.datetime.now().replace(second=0, microsecond=0)

process_time = start_time + datetime.timedelta(hours=1)

try:
	while ((process_time.replace(minute=safetyMinutes) + datetime.timedelta(hours=1)) <=  curr_time.replace(second=0, microsecond=0)) :
		#Dates Setup
		print process_time
		#year
		p_yr = process_time.strftime('%Y') 
		#week number
		p_wn =  process_time.strftime('%W') 
		#Week day       
		p_wd = str(int(process_time.strftime('%w')) + 1)       
		#month		
		p_mon = process_time.strftime('%m') 
		#day of month
		p_dom = process_time.strftime('%d') 
		#hour 24 hrs format
		p_hr = process_time.strftime('%H') 
		try:
			print 'Config paths ' + str(datetime.datetime.now())
			path ="wasbs://" + inputContainer + "@" + inputStorageAccount + ".blob.core.windows.net/" + ehNamespace + "/" + ehName + "/*/"+p_yr+"/"+p_mon+"/"+p_dom+"/"+p_hr+"/*/*"    
			outputPath = "wasbs://" + outputContainer + "@" + outputStorageAccount + ".blob.core.windows.net/aggregateddata/Y_" +p_yr + "/MON_" +p_mon + "/D_" + p_dom + "/H_" +p_hr
			
			print 'READ AVRO ' + str(datetime.datetime.now())
			avro_df = spark.read.format("com.databricks.spark.avro").load(path)
			
			print 'Extract JSON' + str(datetime.datetime.now())
			jsonRdd = avro_df.select(avro_df.Body.cast("string")).rdd.map(lambda x: x[0])
			
			print 'Read as JSON ' + str(datetime.datetime.now())
			data = spark.read.json(jsonRdd)
			
			print 'WRITE PARQUET ' + str(datetime.datetime.now())
			data.coalesce(1).write.mode("overwrite").parquet(outputPath)
			
		except Exception as e:
			print "ERROR AT " + str(process_time)
			print str(e)
		chckpnt = spark.sql("select '"+ str(process_time) +"' as update_date")
		chckpnt.write.mode("Overwrite").saveAsTable("Checkpoint")
		process_time = process_time + datetime.timedelta(hours=1)
		curr_time =  datetime.datetime.now().replace(second=0, microsecond=0)
except Exception as e:
	print "ERROR AT " + str(process_time)
	print str(e)
