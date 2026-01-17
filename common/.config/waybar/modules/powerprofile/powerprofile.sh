#!/bin/bash

profile=$(powerprofilesctl get)
printf '{"text":"%s","alt":"%s","tooltip":"Power profile: %s","class":["power-profile","%s"]}\n' "$profile" "$profile" "$profile" "$profile"
