import json
import sys
sys.path.insert(0, 'package/')

from utils import inject_terraform_vars
inject_terraform_vars()


import requests
from snsService import SnsService

def lambda_handler(event, context):
    try:
        snsService = SnsService()
        message = json.dumps(event['body'])
        if message.find('raiseError') >= 0:
            raise Error('Synthetic error')
        print(f'sending message: ${message}')
        snsService.post_message_in_topic(message)

        #below is test invocation to demo dependency packages work in Lmbda
        my_ip = requests.get('http://api.ipify.org?format=json').json()
        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Origin' : '*',
                'Content-Type': 'application/json'
            },
            'body': json.dumps({'Public_IP': my_ip['ip']})
        }
    except:
        return {
            'statusCode': 500,
            'body': json.dumps({'ErrorMessage': 'Lambda global catch'})
        }
