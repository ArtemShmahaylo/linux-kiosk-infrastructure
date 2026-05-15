#!/bin/bash

sudo systemctl daemon-reload

sudo systemctl enable monitor-off.timer
sudo systemctl enable monitor-on.timer

sudo systemctl start monitor-off.timer
sudo systemctl start monitor-on.timer