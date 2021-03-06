#!/bin/bash

# This script sends an email alert when the load average exceeds 70% of the
# number of cores. It also logs the load average to statshub.
# 
# This script is based upon the one here -
# https://www.digitalocean.com/community/questions/email-notifications-for-server-resources
#
# See also http://stackoverflow.com/questions/11735211/get-last-five-minutes-load-average-using-ksh-with-uptime
# for a more reliable way to get the load average.
#

function die() {
  echo $*
  exit 1
}

service=$1
mail="fallback-alarms@getlantern.org"
hn=`hostname`
statshub="https://pure-journey-3547.herokuapp.com/stats/$hn"
country="sp" # TODO - make this templatized
maxloadpercent="70" # Note - this is given as percentage, not decimal
maxload=$(echo "$maxloadpercent * `nproc`" | bc -l)
restartload="90"
load=`uptime | sed 's/.*load average: //' | awk -F\, '{print $3}'`
loadscaled=$(echo "$load * 100" | bc -l)
loadint=$(printf "%.0f" $loadscaled)

if [ "$loadint" -gt "$maxload" ]; then
    echo "System load $loadint% is higher than $maxload%, alerting $mail"
    echo "15 minute load average is $loadint%" | mail -s "$hn - High $service Server Load" -- $mail || die "Unable to email alert"
    if [ "$loadint" -gt "$restartload" ]; then
        echo "System load is higher than $restartload%, restarting $service"
        # Stop/start instead of restart to make sure profiling info is saved.
        sudo service $service stop
        sudo service $service start
    fi
fi

if [ "$service" = "flashlight" ]; then
    # Report data to statshub
    curl --data-binary "{\"dims\": {\"flserver\": \"$hn\", \"country\": \"$country\"}, \"gauges\": { \"loadavg_15min\": $loadint } }" $statshub || die "Unable to post stats"
fi

echo ""
