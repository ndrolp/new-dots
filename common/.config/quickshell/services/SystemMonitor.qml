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
    property int uptimeSeconds: 0
    property string batteryHealth: ""
    property string batteryTimeToEmpty: ""
    property string batteryTimeToFull: ""
    property int batteryCycles: -1
    property string batteryChargeThreshold: ""
    property real batteryTemperature: 0
    property real diskUsedGiB: 0
    property real diskTotalGiB: 0
    property real networkDownloadRate: 0
    property real networkUploadRate: 0
    property real gpuUsage: -1
    property real gpuTemperature: 0
    property real previousCpuTotal: 0
    property real previousCpuIdle: 0
    property real previousNetworkReceived: 0
    property real previousNetworkTransmitted: 0
    property real previousNetworkTimestamp: 0

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

    function formatUptime() {
        const days = Math.floor(uptimeSeconds / 86400);
        const hours = Math.floor((uptimeSeconds % 86400) / 3600);
        const minutes = Math.floor((uptimeSeconds % 3600) / 60);
        const parts = [];

        if (days > 0)
            parts.push(days + "d");
        if (hours > 0 || days > 0)
            parts.push(hours + "h");
        parts.push(minutes + "m");
        return parts.join(" ");
    }

    function formatRate(bytesPerSecond) {
        if (bytesPerSecond < 1024)
            return Math.round(bytesPerSecond) + " B/s";
        if (bytesPerSecond < 1048576)
            return (bytesPerSecond / 1024).toFixed(1) + " KiB/s";
        return (bytesPerSecond / 1048576).toFixed(1) + " MiB/s";
    }

    function updateNetwork(received, transmitted) {
        const timestamp = Date.now();

        if (previousNetworkTimestamp > 0) {
            const elapsed = (timestamp - previousNetworkTimestamp) / 1000;

            if (elapsed > 0) {
                networkDownloadRate = Math.max(0, (received - previousNetworkReceived) / elapsed);
                networkUploadRate = Math.max(0, (transmitted - previousNetworkTransmitted) / elapsed);
            }
        }

        previousNetworkReceived = received;
        previousNetworkTransmitted = transmitted;
        previousNetworkTimestamp = timestamp;
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
            + "awk '{ print \"load\", $1, $2, $3 }' /proc/loadavg; "
            + "awk '{ print \"uptime\", int($1) }' /proc/uptime; "
            + "df -Pk \"$HOME\" | awk 'NR == 2 { print \"disk\", $3, $2 }'; "
            + "awk 'NR > 2 { split($0, pair, \":\"); interface=pair[1]; gsub(/^[[:space:]]+|[[:space:]]+$/, \"\", interface); "
            + "if (interface != \"lo\") { gsub(/^[[:space:]]+/, \"\", pair[2]); split(pair[2], values, /[[:space:]]+/); received += values[1]; transmitted += values[9] } } "
            + "END { print \"network\", received, transmitted }' /proc/net/dev; "
            + "command -v nvidia-smi >/dev/null && nvidia-smi --query-gpu=utilization.gpu,temperature.gpu --format=csv,noheader,nounits "
            + "| awk -F, 'NR == 1 { gsub(/[[:space:]]/, \"\", $1); gsub(/[[:space:]]/, \"\", $2); print \"gpu\", $1, $2 }'; "
            + "battery=$(upower -e 2>/dev/null | awk '/battery_/ { print; exit }'); "
            + "[ -z \"$battery\" ] || upower -i \"$battery\" | awk -F: '"
            + "/^[[:space:]]+capacity:/ { value=$2; gsub(/^[[:space:]]+|[[:space:]]+$/, \"\", value); print \"battery-health\", value } "
            + "/^[[:space:]]+time to empty:/ { value=$2; gsub(/^[[:space:]]+|[[:space:]]+$/, \"\", value); print \"battery-empty\", value } "
            + "/^[[:space:]]+time to full:/ { value=$2; gsub(/^[[:space:]]+|[[:space:]]+$/, \"\", value); print \"battery-full\", value } "
            + "/^[[:space:]]+charge-cycles:/ { value=$2; gsub(/^[[:space:]]+|[[:space:]]+$/, \"\", value); print \"battery-cycles\", value } "
            + "/^[[:space:]]+temperature:/ { value=$2; gsub(/^[[:space:]]+|[[:space:]]+$/, \"\", value); print \"battery-temperature\", value } "
            + "/^[[:space:]]+charge-start-threshold:/ { value=$2; gsub(/^[[:space:]]+|[[:space:]]+$/, \"\", value); start=value } "
            + "/^[[:space:]]+charge-end-threshold:/ { value=$2; gsub(/^[[:space:]]+|[[:space:]]+$/, \"\", value); print \"battery-threshold\", start \"-\" value }'"
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
                else if (fields[0] === "uptime")
                    root.uptimeSeconds = Number(fields[1]);
                else if (fields[0] === "battery-health")
                    root.batteryHealth = fields.slice(1).join(" ");
                else if (fields[0] === "battery-empty")
                    root.batteryTimeToEmpty = fields.slice(1).join(" ");
                else if (fields[0] === "battery-full")
                    root.batteryTimeToFull = fields.slice(1).join(" ");
                else if (fields[0] === "battery-cycles")
                    root.batteryCycles = Number(fields[1]);
                else if (fields[0] === "battery-temperature")
                    root.batteryTemperature = Number(fields[1]);
                else if (fields[0] === "battery-threshold")
                    root.batteryChargeThreshold = fields.slice(1).join(" ");
                else if (fields[0] === "disk") {
                    root.diskUsedGiB = Number(fields[1]) / 1048576;
                    root.diskTotalGiB = Number(fields[2]) / 1048576;
                } else if (fields[0] === "network")
                    root.updateNetwork(Number(fields[1]), Number(fields[2]));
                else if (fields[0] === "gpu") {
                    root.gpuUsage = Number(fields[1]);
                    root.gpuTemperature = Number(fields[2]);
                }
            }
        }
    }
}
