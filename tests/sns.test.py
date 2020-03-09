import os
import random
import time
import boto3
import json
from datetime import datetime
from code.activity_tracker.utils import inject_terraform_vars
inject_terraform_vars()

from code.activity_tracker.snsService import SnsService

sqs = boto3.resource('sqs', os.getenv('REGION'))
sns = boto3.resource('sns', os.getenv('REGION'))

sqs_arn = None
sqs_url = None
sns_subscription = None


def integration_test():
    try:
        print('Çreating SQS entry...')
        create_sqs()
        print('Subscribing SQS to SNS topic...')
        subscribe_sqs_to_topic()
        time.sleep(1)
        print('Sending test message to SNS topic...')
        place_message_into_sns_topic()
        print('Sleeping for 3 secs...')
        time.sleep(3)
        print('Reading message from SQS...')
        read_message_from_sqs()
    finally:
        print('AWS resources cleaning up...')
        remove_topic_subscription()
        remove_sqs()
        pass


def read_message_from_sqs():
    queue = sqs.Queue(sqs_url)
    message = queue.receive_messages(
        AttributeNames=['All'],
        MessageAttributeNames=['All'],
        WaitTimeSeconds=1
    )
    if len(message) != 1:
        raise Error('Failed to get expected one message from SQS')
    body = json.loads(message[0].body)
    message = json.loads(body['Message'])
    print(f'receiving message: ${message}')


def remove_topic_subscription():
    if sns_subscription is None:
        return
    sns_subscription.delete()


def subscribe_sqs_to_topic():
    snsService = SnsService()
    topic = sns.Topic(snsService.arn)
    global sns_subscription
    sns_subscription = topic.subscribe(
        Protocol='sqs',
        Endpoint=sqs_arn,
        ReturnSubscriptionArn=True
    )


def create_sqs():
    random.seed()
    q_name = f'test-subscription-{str(int(random.random()*1000))}'

    queue = sqs.create_queue(
        QueueName=q_name,
        tags={
            'lifetime': 'should be automatically removed'
        }
    )
    queue.set_attributes(
        Attributes={
            'Policy': json.dumps({
                "Version": "2012-10-17",
                "Id": "Queue_Policy",
                "Statement":
                    {
                        "Sid": "Queue_AnonymousAccess",
                        "Effect": "Allow",
                        "Principal": "*",
                        "Action": "sqs:*",
                        "Resource": "arn:aws:sqs:*"
                    }
            })
        }
    )
    global sqs_arn
    sqs_arn = queue.attributes['QueueArn']
    global sqs_url
    sqs_url = queue.url


def remove_sqs():
    if sqs_url is None:
        return
    queue = sqs.Queue(sqs_url)
    response = queue.delete()


def place_message_into_sns_topic():
    snsService = SnsService()
    message = json.dumps(
        {
            "name": "John",
            "age": 30,
            "city": "New York",
            "current_time": datetime.now().strftime('%H:%M:%S')
        }
    )
    print(f'sending message: ${message}')
    snsService.post_message_in_topic(message)


if __name__ == "__main__":
    # place_message_into_sns_topic()
    integration_test()
