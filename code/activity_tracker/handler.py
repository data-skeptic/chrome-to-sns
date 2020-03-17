import json
import sys
sys.path.insert(0, 'package/')

from utils import inject_terraform_vars
inject_terraform_vars()

from snsService import SnsService
import requests

def lambda_handler(event, context):
    try:
        snsService = SnsService()

        if not 'body' in event:
            raise AttributeError('Input object should have <body> attribute')
        try:
            message = json.loads(event['body'])
        except:
            raise AttributeError(
                'Input object attribute <body> is not valid JSON')

        print(f'sending message: ${message}')
        messageId = snsService.post_message_in_topic(message)

        # below is test invocation to demo dependency packages work in Lmbda
        my_ip = requests.get('http://api.ipify.org?format=json').json()
        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Content-Type': 'application/json'
            },
            'body': json.dumps({'messageId': messageId, 'publicIp': my_ip['ip']})
        }
    except Exception as err:
        print('err in catch scope 2', err)
        return {
            'statusCode': 500,
            'body': json.dumps({
                'Scope': 'Lambda global catch',
                'Error': str(err)
            })
        }
