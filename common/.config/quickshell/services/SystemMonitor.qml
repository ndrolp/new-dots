import Quickshell.Io
import QtQuick

QtObject {
    id: root

    property real cpuUsage: 0
    property real memoryUsage: 0
    property real memoryUsedGiB: 0
    property real memoryTotalGiB: 0
    property real temperature: 0
    property string loadAverage: "0.00 / 0.00 / 0.00"
    property real previousCpuTotal: 0
    property real previousCpuIdle: 0

    function updateCpu(total, idle) {
        if (previousCpuTotal > 0) {
            const totalDelta = total - previousCpuTotal;
            const idleDelta = idle - previousCpuIdle;

            if (totalDelta > 0)
                cpuUsage = Math.max(0, Math.min(100, (1 - idleDelta / totalDelta) * 100));
        }

        previousCpuTotal = total;
        previousCpuIdle = idle;
    }

    function updateMemory(totalKiB, availableKiB) {
        memoryTotalGiB = totalKiB / 1048576;
        memoryUsedGiB = (totalKiB - availableKiB) / 1048576;
        memoryUsage = totalKiB > 0 ? memoryUsedGiB / memoryTotalGiB * 100 : 0;
    }

    property var pollTimer: Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!metricsQuery.running)
                metricsQuery.running = true;
        }
    }

    property var metricsQuery: Process {
        id: metricsQuery

        command: ["sh", "-c",
            "awk '/^cpu / { total=0; for (i=2; i<=NF; i++) total+=$i; print \"cpu\", total, $5+$6; exit }' /proc/stat; "
            + "awk '/MemTotal:/ { total=$2 } /MemAvailable:/ { print \"mem\", total, $2 }' /proc/meminfo; "
            + "sensors 2>/dev/null | awk '/Package id 0:/ { value=$4; gsub(/[+°C]/, \"\", value); print \"temp\", value; exit }'; "
            + "awk '{ print \"load\", $1, $2, $3 }' /proc/loadavg"
        ]

        stdout: SplitParser {
            onRead: data => {
                const fields = data.trim().split(/\s+/);

                if (fields[0] === "cpu")
                    root.updateCpu(Number(fields[1]), Number(fields[2]));
                else if (fields[0] === "mem")
                    root.updateMemory(Number(fields[1]), Number(fields[2]));
                else if (fields[0] === "temp")
                    root.temperature = Number(fields[1]);
                else if (fields[0] === "load")
                    root.loadAverage = fields.slice(1).join(" / ");
            }
        }
    }
}
