#!/bin/bash

hyprctl getoption general:layout | grep -q 'dwindle' && hyprctl keyword general:layout master || hyprctl keyword general:layout dwindle
