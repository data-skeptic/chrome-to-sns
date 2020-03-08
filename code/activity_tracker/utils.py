import os
import configparser

def inject_terraform_vars():
    with open('setup.tfvars', 'r') as f:
        config_string = '[DEFAULT]\n' + f.read()
    config = configparser.ConfigParser()
    config.optionxform = str
    config.read_string(config_string)
    for (key, value) in config.items('DEFAULT'):
        os.environ[key] = str(value).strip('\"')
        