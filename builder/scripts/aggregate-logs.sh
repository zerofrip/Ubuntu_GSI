#!/bin/bash
# =============================================================================
# scripts/aggregate-logs.sh (Master Multi-Format Telemetry Compiler)
# =============================================================================
# Outputs: HTML, JSON, and CSV
# Tracks Device, Firmware, and explicitly counts FAIL/WARN/SUCCESS occurrences.
# =============================================================================

LOG_DIR="/data/uhl_overlay"
REPORT_HTML="$LOG_DIR/MASTER_QA_REPORT.html"
REPORT_JSON="$LOG_DIR/MASTER_QA_REPORT.json"
REPORT_CSV="$LOG_DIR/MASTER_QA_REPORT.csv"

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
DEVICE=$(getprop ro.product.device || echo "Unknown_Device")
FINGERPRINT=$(getprop ro.vendor.build.fingerprint || echo "Unknown_VINTF")
ANDROID_VER=$(getprop ro.build.version.release || echo "Unknown_Version")

echo "[QA Compiler] Generating HTML, JSON, and CSV Reports -> $LOG_DIR"

# =============================================================================
# CSV Header Initialization
# =============================================================================
echo "Timestamp,Device,Android Version,Log Component,Status,Success Count,Fatal Count,Warn Count" > "$REPORT_CSV"

# =============================================================================
# HTML Header Initialization
# =============================================================================
cat << EOF > "$REPORT_HTML"
<!DOCTYPE html>
<html>
<head>
    <title>Final Master GSI - QA Diagnostic Report</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background-color: #1e1e1e; color: #d4d4d4; margin: 0; padding: 20px; }
        h1 { color: #569cd6; border-bottom: 2px solid #569cd6; padding-bottom: 10px; }
        .meta { color: #808080; font-family: monospace; margin-bottom: 30px; }
        .log-section { background-color: #252526; border: 1px solid #3c3c3c; border-radius: 5px; padding: 15px; margin-bottom: 25px; box-shadow: 0 4px 6px rgba(0,0,0,0.3); }
        h2 { color: #4ec9b0; margin-top: 0; }
        pre { background-color: #000; color: #ce9178; padding: 15px; border-radius: 4px; overflow-x: auto; font-family: Consolas, "Courier New", monospace; line-height: 1.4; }
        .success { color: #8fc152 !important; font-weight: bold; }
        .fatal { color: #f44336 !important; font-weight: bold; }
        .warn { color: #ffca28 !important; }
        .missing { color: #f44336; font-style: italic; }
    </style>
</head>
<body>
    <h1>Universal Hardware Framework QA Diagnostics</h1>
    <div class='meta'>
        Compiled: $TIMESTAMP<br>
        Device: $DEVICE<br>
        Android Version: $ANDROID_VER<br>
        Vendor Fingerprint: $FINGERPRINT
    </div>
EOF

# =============================================================================
# JSON JSON Initialization
# =============================================================================
cat << EOF > "$REPORT_JSON"
{
  "qa_metadata": {
    "timestamp": "$TIMESTAMP",
    "device": "$DEVICE",
    "android_version": "$ANDROID_VER",
    "fingerprint": "$FINGERPRINT"
  },
  "subsystem_logs": [
EOF

FIRST_JSON=true

process_log() {
    local log_file=$1
    local title=$2
    local s_count=0
    local f_count=0
    local w_count=0
    local log_content=""
    
    # HTML start
    echo "    <div class='log-section'>" >> "$REPORT_HTML"
    echo "        <h2>$title ($log_file)</h2>" >> "$REPORT_HTML"
    
    if [ -f "$LOG_DIR/$log_file" ]; then
        echo "        <pre>" >> "$REPORT_HTML"
        while IFS= read -r line; do
            if echo "$line" | grep -iq "SUCCESS"; then
                echo "<span class='success'>$line</span>" >> "$REPORT_HTML"
                s_count=$((s_count + 1))
            elif echo "$line" | grep -Eiq "FATAL|ERROR|CRASH"; then
                echo "<span class='fatal'>$line</span>" >> "$REPORT_HTML"
                f_count=$((f_count + 1))
            elif echo "$line" | grep -Eiq "WARN|WARNING|Timeout"; then
                echo "<span class='warn'>$line</span>" >> "$REPORT_HTML"
                w_count=$((w_count + 1))
            else
                echo "$line" >> "$REPORT_HTML"
            fi
        done < "$LOG_DIR/$log_file"
        echo "        </pre>" >> "$REPORT_HTML"
        
        # Read raw content for JSON escaping natively via pure bash string replacement
        log_content=$(cat "$LOG_DIR/$log_file" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | awk '{printf "%s\\n", $0}')
    else
        echo "        <p class='missing'>Log file missing or uninitialized.</p>" >> "$REPORT_HTML"
        f_count=1 # Flag fatal if target log missing natively
        log_content="[FILE MISSING]"
    fi
    echo "    </div>" >> "$REPORT_HTML"
    
    # CSV Appending
    local csv_status="OK"
    [ $f_count -gt 0 ] && csv_status="FAIL"
    echo "$TIMESTAMP,$DEVICE,$ANDROID_VER,$log_file,$csv_status,$s_count,$f_count,$w_count" >> "$REPORT_CSV"

    # JSON Appending (Handling Comma Logic)
    if [ "$FIRST_JSON" = true ]; then
        FIRST_JSON=false
    else
        echo "    ," >> "$REPORT_JSON"
    fi

cat << EOF >> "$REPORT_JSON"
    {
      "component": "$title",
      "file": "$log_file",
      "metrics": {
        "success": $s_count,
        "warnings": $w_count,
        "fatals": $f_count
      },
      "raw_dump": "$log_content"
    }
EOF
}

# Process each bounds expressly matching exact file limits!
process_log "gpu_success.cache" "Active GPU Configurations"
process_log "snapshot_rotation.log" "Dynamic RootFS & Pivot Rotations"
process_log "rollback.log" "Recovery & Rollback Checkpoint Bounds"
process_log "hal.log" "Vendor IPC & Hardware Discovery Latency"
process_log "daemon.log" "Universal HAL Layer Mock Translations"
process_log "gpu_stage.log" "Watchdog Pipeline Discoveries"
process_log "gpu_stats.log" "GPU Final Crash Metrics Tracking"

# Explicitly process multiple dynamic Waydroid container sessions mapping gracefully
WAYDROID_LOGS=$(find "$LOG_DIR" -maxdepth 1 -name "waydroid_*.log" -type f 2>/dev/null || true)
if [ -n "$WAYDROID_LOGS" ]; then
    for w_log in $WAYDROID_LOGS; do
        bname=$(basename "$w_log")
        process_log "$bname" "LXC Dynamic Network & Sandbox Bindings ($bname)"
    done
else
    process_log "waydroid_container0.log" "LXC Dynamic Network & Sandbox Bindings (Default)"
fi

# Finalize HTML
echo "</body></html>" >> "$REPORT_HTML"

# Finalize JSON
echo "  ]" >> "$REPORT_JSON"
echo "}" >> "$REPORT_JSON"

echo "[QA Compiler] All Matrices Rendered successfully: HTML, JSON, CSV generated natively."
exit 0
