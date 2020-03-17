import boto3
import json
import os

sns = boto3.resource('sns', os.getenv('REGION'))


class SnsService:
    def __init__(self):
        self.arn = None
        self.fetch_topic_arn()
  
    def fetch_topic_arn(self):
        wanted_topic_name = f'{os.getenv("TOPIC_NAME")}-{os.getenv("STAGE")}'
        topic = next((it for it in sns.topics.all()
                     if it.arn.endswith(wanted_topic_name)), None)
        if topic is None:
            raise Exception('failed to find SNS Topic')
        self.arn = topic.arn

    def post_message_in_topic(self, body):
        try:
            topic = sns.Topic(self.arn)
            response = topic.publish(
                Message=json.dumps({'default': json.dumps(body)}),
                Subject='test message',
                MessageStructure='json'
                )
            print('new message id:', response['MessageId'])
            return response['MessageId']
        except:
            error_message = f'failed to post message to SNS Topic {os.getenv("TOPIC_NAME")}'
            print (error_message)
            raise Exception(error_message)

