import json
import sys
sys.path.insert(0, 'package/')

from utils import inject_terraform_vars
inject_terraform_vars()


import requests
from snsService import SnsService

def lambda_handler(event, context):

    snsService = SnsService()
    message = json.dumps(event)
    print(f'sending message: ${message}')
    snsService.post_message_in_topic(message)

    #below is test invocation to demo dependency packages work in Lmbda
    my_ip = requests.get('http://api.ipify.org?format=json').json()
    return {'Public IP': my_ip['ip']}
