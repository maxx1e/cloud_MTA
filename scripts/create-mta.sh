#!/bin/bash
set -eo pipefail
filename="mta.yaml"
touch $filename
echo "ID:${PRJ_PATH%.*}" >> $filename
echo "_schema-version: '3.1'" >> $filename
echo "version: '0.0.1'" >> $filename
echo >> $filename
echo "modules:" >> $filename
echo " - name: ${PRJ_PATH%.*}" >> $filename
echo "   type: com.sap.hcp.html5" >> $filename
echo "   path: ./${PRJ_PATH%.*}" >> $filename
echo "   parameters:" >> $filename
echo "    name: ${PRJ_PATH%.*}" >> $filename
echo "    version: 0.0.1" >> $filename
echo "   build-parameters:" >> $filename
echo "     info: "Executing build with Node builder"" >> $filename
echo "     builder: npm" >> $filename
echo "     supported-platforms: [NEO]" >> $filename
echo "     build-artifact-name: mta_${PRJ_PATH%.*}" >> $filename
