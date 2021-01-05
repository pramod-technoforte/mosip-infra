#!/bin/python3

import sys
import argparse
from api import *
import csv
import json
import config as conf
sys.path.insert(0, '../')
from utils import *

def add_machine_type(csv_file):
    session = MosipSession(conf.server, conf.superadmin_user, conf.superadmin_pwd)
    reader = csv.DictReader(open(csv_file, 'rt')) 
    for row in reader:
        myprint('Adding machine type %s' % row['name'])
        r = session.add_machine_type(row['code'], row['name'], row['description'], row['language'])
        r = response_to_json(r)
        myprint(r)
        if r['errors'] is not None:
            if r['errors'][0]['errorCode'] == 'KER-MSD-994' or \
               r['errors'][0]['errorCode'] == 'KER-MSD-061':
                myprint('Updating machine type for "%s"' % row['name'])
                r = session.update_machine_type(row['code'], row['name'], row['description'], row['language'])
                r = response_to_json(r)
                myprint(r)

def add_machine_spec(csv_file):
    session = MosipSession(conf.server, conf.superadmin_user, conf.superadmin_pwd)
    reader = csv.DictReader(open(csv_file, 'rt')) 
    spec_id = 'any' # Just a placeholder
    for row in reader:
            myprint('Adding machine spec (%s,%s)' % (row['name'], row['language']))
            r = session.add_machine_spec(spec_id, row['name'], row['type_code'], row['brand'], row['model'],
                                         row['description'], row['language'], row['min_driver_ver'])
            r = response_to_json(r)
            myprint(r)
            if r['errors'] is not None:
                myprint('ABORTING')
                break
            
            if row['language'] == conf.primary_lang:
                spec_id = r['response']['id']  # Spec id is generated by mosip, so use that in the next step
            else:
                spec_id = 'any'
                
def get_machine_spec_id(spec_name, language):
    session = MosipSession(conf.server, conf.superadmin_user, conf.superadmin_pwd)
    r = session.get_machine_specs()
    r = response_to_json(r)
    spec_id = None
    if r['errors'] is None:
        for spec in r['response']['data']: 
            if spec['name'] == spec_name and spec['langCode'] == language:
                spec_id = spec['id']  
                break
    return spec_id

#    def add_machine(self, machine_id, name, spec_id, public_key, reg_center_id, serial_num, sign_pub_key, validity,
#                    zone, language):
def add_machine(csv_file):
    session = MosipSession(conf.server, conf.superadmin_user, conf.superadmin_pwd)
    reader = csv.DictReader(open(csv_file, 'rt')) 
    for row in reader:
        myprint('Adding machine (%s,%s)' % (row['name'], row['language']))
        spec_id = get_machine_spec_id(row['spec_name'], row['language'])
        if spec_id is None:
            myprint('ABORTING: spec id for (%s,%s) not found' % (row['name'], row['language']))
            break
        pub_key = open(row['pub_key_path'], 'rt').read().strip()
        sign_pub_key = open(row['sign_pub_key_path'], 'rt').read().strip()
        r = session.add_machine(row['machine_id'], row['name'], spec_id, pub_key, row['reg_center_id'], 
                                row['serial_num'], sign_pub_key, row['validity'], row['zone'], row['language'])
        r = response_to_json(r)
        myprint(r)

def args_parse(): 
   parser = argparse.ArgumentParser()
   parser.add_argument('action', help='type|spec|machine|all')
   args = parser.parse_args()
   return args

def main():

    init_logger('full', 'a', './out.log', level=logging.INFO)  # Append mode
    init_logger('last', 'w', './last.log', level=logging.INFO, stdout=False)  # Just record log of last run

    args = args_parse()

    if args.action == 'type' or args.action == 'all':
        add_machine_type(conf.csv_machine_type)
    if args.action == 'spec' or args.action == 'all':
        add_machine_spec(conf.csv_machine_spec)
    if args.action == 'machine' or args.action == 'all':
        add_machine(conf.csv_machine)

if __name__=="__main__":
    main()
