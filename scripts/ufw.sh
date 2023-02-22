#!/bin/bash

ufw enable
ufw default deny outgoing
ufw default deny incoming
reboot
