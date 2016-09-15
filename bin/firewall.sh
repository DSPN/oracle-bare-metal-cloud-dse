#!/usr/bin/env bash

# Turn off the firewall
service firewalld stop
chkconfig firewalld off
