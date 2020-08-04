#! /bin/sh

PLEX_AUTOSCAN_CONFIG=${PLEX_AUTOSCAN_CONFIG}
PAGE=$(cat ${PLEX_AUTOSCAN_CONFIG} | grep '"PLEX_LOCAL_URL":' | awk -F\" '{print $4}')
TOKEN=$(cat ${PLEX_AUTOSCAN_CONFIG} | grep '"PLEX_TOKEN":' | awk -F: '{print $2}' | awk -F\" '{print $2}')
PGSELFTEST=$(curl -LI "${PAGE}/system?X-Plex-Token=${TOKEN}" -o /dev/null -w '%{http_code}\n' -s)

######## FUNCTIONS ##########
if [ -f ${PLEX_AUTOSCAN_CONFIG} ]
   then
   if [[ ${PGSELFTEST} -le 200 && ${PGSELFTEST} -gt 299 ]]
      then
      echo " -> PLEX down or Token missmatched "
      echo " -> next check for accesible in 5 seconds"
      sleep 5
        if [[ ${PGSELFTEST} -le 200 && ${PGSELFTEST} -gt 299 ]]; then
        echo " second check also failed "
        echo " exit now "
        exit 1
        fi
   fi
fi
