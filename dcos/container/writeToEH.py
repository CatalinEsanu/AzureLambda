import uuid
import datetime
import random
import json
from azure.servicebus import ServiceBusService
import argparse
import os

parser = argparse.ArgumentParser(description='This will send demo events to an Event Hub of your choosing')
parser.add_argument('-n','--namespace', help='Namespace Name',required=False)
parser.add_argument('-e','--eventhub',help='Event Hub Name', required=False)
parser.add_argument('-s','--keyname',help='Shared Access Key Name', required=False)
parser.add_argument('-k','--keyvalue',help='Shared Access Key Value', required=False)
args = parser.parse_args()

if args.namespace is not None:
    ehNamespace=args.namespace #catalintestns1
else:
    ehNamespace=os.environ['EH_NAMESPACE']

if args.eventhub is not None:
    ehName=args.eventhub #catalintesteh1
else:
    ehName=os.environ['EH_NAME']

if args.keyname is not None:
    ehSharedAccessKeyName=args.keyname #RootManageSharedAccessKey
else:
    ehSharedAccessKeyName=os.environ['EH_SHARED_ACCESS_KEY_NAME']

if args.keyvalue is not None:
    ehSharedAccessKeyValue=args.keyvalue #IdKZBJi4NXFkyCkPm2X2U3t6zJOPivMAm7WuQJCVGUw=
else:
    ehSharedAccessKeyValue=os.environ['EH_SHARED_ACCESS_KEY_VALUE']


sbs = ServiceBusService(service_namespace=ehNamespace, shared_access_key_name=ehSharedAccessKeyName, shared_access_key_value=ehSharedAccessKeyValue)
while (1>-1):
    devices = []
    for x in range(0, 10):
        devices.append(str(uuid.uuid4()))

    for y in range(0,20):
    #while (1>-1):
        for dev in devices:
            reading = {'id': str(uuid.uuid4()), 'timestamp': str(datetime.datetime.utcnow()), 'uv': random.random(), 'temperature': random.randint(70, 100), 'humidity': random.randint(70, 100)}
            s = json.dumps(reading)
            sbs.send_event(ehName, s)
    #    print y