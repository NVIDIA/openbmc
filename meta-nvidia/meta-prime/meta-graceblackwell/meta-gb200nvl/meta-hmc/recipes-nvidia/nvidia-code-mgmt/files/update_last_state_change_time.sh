#!/bin/sh

nowTS=$(printf "%.0f" "$(echo "$EPOCHREALTIME * 1000" | bc)")
busctl set-property xyz.openbmc_project.State.Chassis /xyz/openbmc_project/state/chassis0 xyz.openbmc_project.State.Chassis LastStateChangeTime t "$nowTS"
