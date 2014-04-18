#!/usr/bin/env python
"""To use this, set config.controller to some fake ID that no real controller
shares."""

import sys

import boto
import boto.sqs
from boto.sqs.jsonmessage import JSONMessage

import config
import util
import json


def launch(email,
           serial,
           pillars):
    send_message({'launch-fp-as': email,
                  'launch-refrtok': 'bogus',
                  'launch-serial': serial,
                  'launch-pillars': json.loads(pillars)})

def kill(email, serial):
    send_message({'shutdown-fp': name_prefix(email, serial)})

def send_message(d):
    aws_id, aws_key = util.read_aws_credential()
    aws_creds = {'aws_access_key_id': aws_id,
                 'aws_secret_access_key': aws_key}
    sqs = boto.sqs.connect_to_region(config.aws_region, **aws_creds)
    req_q = sqs.get_queue("%s_request" % config.controller)
    req_q.set_message_class(JSONMessage)
    msg = JSONMessage()
    msg.set_body(d)
    print "Sending request..."
    req_q.write(msg)
    print "Sent."

#DRY: Logic copied and pasted from ../salt/cloudmaster/cloudmaster.py
def name_prefix(email, serialno):
    sanitized_email = email.replace('@', '-at-').replace('.', '-dot-')
    # Since '-' is legal in e-mail usernames and domain names, and although
    # I don't imagine we'd approve problematic e-mails, let's be somewhat
    # paranoid and add some hash of the unsanitized e-mail to avoid clashes.
    sanitized_email += "-" + hex(hash(email))[-4:]
    return "fp-%s-%s-" % (sanitized_email, serialno)

def print_usage():
    print "Usage: %s (launch|kill) <email> <serial> [{pillar_key: pillar_value[, pillar_key: pillar_value]...}]" % sys.argv[0]

if __name__ == '__main__':
    try:
        cmd, email, serial = sys.argv[1:4]
        serial = int(serial)
        if cmd == 'launch':
            pillars = '{}'
            if len(sys.argv) > 4:
                pillars = sys.argv[4]
            launch(email, serial, pillars)
        elif cmd == 'kill':
            kill(email, serial)
        else:
            print_usage()
    except ValueError:
        print_usage()
