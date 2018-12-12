#!/usr/local/bin/python3
# Not terribly useful here on it's own, but this is a script I wrote to run in
# conjunction with docker-compose; this sets up everything my docker-compose file
# needs to spin up properly.
#
# it's also in my DevOps repository under docker/nginx-atlassian-jenkins

import re
import shutil
import os
import sys

composefile = "docker-compose.yml"
root_host = "testdomain.com"
volume_list = []
host_list = []


def get_volumes (filename) :
    # Processes the passed file and looks for the 'volumes:' section, returning
    # a list of its contents
    file = open(filename, "r").read().split('\n')
    mylist = []
    secondlist = []
    vol_section = False
    for line in file :
        if "hostname: " in line.lower() :
            if root_host in line.lower() :
                line = re.search(': (.*)', line).group(1)
                secondlist.append(line)
        elif line.lower() == "volumes:" :     # Start of relevant section
            vol_section = True
        elif line[:1] != " " :              # Start of irrelevant section
            vol_section = False
        elif vol_section :                  # Relevant line for processing
            line = re.search('  (.*):', line).group(1)
            mylist.append(line)
    return mylist, secondlist

def mk_volumes(list) :
    # Takes a list of names and creates subdirectories for each
    for name in list :
        try :
            os.mkdir(name)
            print("Created DIR ", name)
        except OSError as e :
            print("Error: %s - %s." % (e.filename, e.strerror))
#            print("ERROR: DIR ", name, " already exists")

def rm_volumes(list) :
    # Takes a list of subdirectories and removes them
    for name in list :
        try :
            shutil.rmtree(name)
            print("Removed DIR ", name)
        except OSError as e :
            print("Error: %s - %s." % (e.filename, e.strerror))

def add_hosts(list) :
    # Scans our /etc/hosts file and appends any FQDNs that were found in
    # our docker-compose file. It then writes the new file to a temporary
    # location before using it to overwrite /etc/hosts
    file = open("/etc/hosts", "r").read().split('\n')
    newfile = open("newhosts", "w")
    for line in file :
        if len(line) > 0 :
            newfile.write(line + "\n")
            print(line)
    for name in list :
        newfile.write("127.0.0.1\t" + name + "\n")
        print("127.0.0.1\t" + name)
    newfile.close()
    print("Moving generated hosts file to proper location ..")
    os.system('sudo mv newhosts /etc/hosts')

def rm_hosts(list) :
    # Scans /etc/hosts and removes any hostnames that were found in our
    # docker-compose.yml file; it writes everything else to a new file,
    # which it then uses to overwrite /etc/hosts
    file = open("/etc/hosts", "r").read().split('\n')
    newfile = open("newhosts", "w")
    for line in file :
        line_needed = True
        for name in list :
            if name in line :
                print("REMOVING ", line, " : matches ", name)
                line_needed = False
        if line_needed :
            if len(line) > 0 :
                newfile.write(line + "\n")
                print(line)
                print("Writing: ", line)
    newfile.close()
    print("Moving generated hosts file to proper location ..")
    os.system('sudo mv newhosts /etc/hosts')

command = ""
if len(sys.argv) > 1 :
    command = sys.argv[1]
volume_list, host_list = get_volumes(composefile)
if command == "UP" :
    print("Setting up environment ...")
    mk_volumes(volume_list)
    add_hosts(host_list)
    print("Running docker-compose ...")
    os.system("docker-compose up -d")
elif command == "DOWN" :
    print("Stopping docker-compose ...")
    os.system("docker-compose down")
    print("Cleaning up environment ...")
    rm_volumes(volume_list)
    rm_hosts(host_list)
else :
    print("Invalid argument: use UP or DOWN")
