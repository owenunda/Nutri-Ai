#!/usr/bin/env bash
# Script para mapear el puerto 3000 del dispositivo al host (usado para pruebas con dispositivo físico)
set -e
echo "Devices attached:"
adb devices

echo "Applying adb reverse tcp:3000 -> tcp:3000"
adb reverse tcp:3000 tcp:3000

echo "Done. From the device, the app can reach host:3000 via http://127.0.0.1:3000"

