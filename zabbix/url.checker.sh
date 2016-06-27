#!/bin/bash
#Check url with curl, cache result to file

URL=${1:-}
PARAM=${2:-}
POST=${3:-}
CURL=$(which curl 2>/dev/null)
MD5SUM=$(which md5sum 2>/dev/null)
TMPDIR="/var/tmp"
TIMEOUT=19
LOG="/tmp/curl.log"
DEBUG=false
_LOG=""

function log() {
	if ${DEBUG} ; then
		_LOG+="$(date +%F' '%k':'%M':'%S): ($$) ${URL}: $*\n"
	fi
}

log "${PARAM} ${POST}"

[ -z "${URL}" ] && exit 255
[ -z "${PARAM}" ] && exit 255
[ -z "${CURL}" ] && exit 255
[ -z "${MD5SUM}" ] && exit 255

FILE="${TMPDIR}/url_$(echo "${URL}" | ${MD5SUM} | cut -d" " -f 1)"
CURTIME=$(date +%s)
log "${FILE}"

(
	if flock -xn -w10 200; then
		[ -f $FILE ] && STATTIME=$(stat -c %Z ${FILE}) || STATTIME=0
		if (( $((${CURTIME} - ${STATTIME})) > 60 )); then
			log "Start check"
			if [ -n "${POST}" ]; then
				POST="-XPOST -d '${POST}'"
				echo $POST
			fi
			echo -e "url ${URL}\ncheck_time ${CURTIME}" > "${FILE}.tmp"
			LANG= curl -L ${POST} -s -A "Zabbix URL Checker" -k "${URL}" --connect-timeout ${TIMEOUT} -m ${TIMEOUT} -w "http_code %{http_code}\ntime_total %{time_total}\nhttp_connect %{http_connect}\ntime_namelookup %{time_namelookup}\ntime_connect %{time_connect}\ntime_appconnect %{time_appconnect}\ntime_pretransfer %{time_pretransfer}\ntime_redirect %{time_redirect}\ntime_starttransfer %{time_starttransfer}\nsize_download %{size_download}\nsize_upload %{size_upload}\nsize_header %{size_header}\nsize_request ${size_request}\nspeed_download %{speed_download}\nspeed_upload %{speed_upload}\ncontent_type %{content_type}\nnum_connects ${num_connects}\nnum_redirects %{num_redirects}\nredirect_url %{redirect_url}\nftp_entry_path %{ftp_entry_path}\nssl_verify_result %{ssl_verify_result}\n" -o /dev/null >> "${FILE}.tmp"
			rt=$?
			log "Return Code - ${rt}"
			echo "curl_code ${rt}" >> "${FILE}.tmp"
			mv "${FILE}.tmp" ${FILE}
			log "Stop check"
		fi
	fi
) 200>${FILE}.lock

ZRT=$(tac ${FILE} | grep -Po -m 1 "${PARAM} \K.*?(?=$)" || echo "ZBX_NOTSUPPORTED")
log "ZRT - ${ZRT}"
echo -en ${_LOG} >> ${LOG}
echo ${ZRT}
