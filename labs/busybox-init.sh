#!/bin/sh
export PATH=/bin:/sbin
mkdir -p /proc /sys /dev /tmp
mount -t proc proc /proc || echo 'proc mount failed'
mount -t sysfs sysfs /sys || echo 'sysfs mount failed'
mount -t devtmpfs devtmpfs /dev || echo 'devtmpfs mount failed'
exec </dev/console >/dev/console 2>&1
echo 'BusyBox early init PID' $$
# Teaching init: supervise a foreground shell; not a general service manager.
while :; do
    setsid cttyhack sh
    echo 'Shell exited; restarting'
    sleep 1
done
