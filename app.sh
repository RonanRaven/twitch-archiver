#!/bin/bash

# Streamlink helper script for downloading vods automatically.
# You will need to create a Twitch API key for this to work since it relies on the API.
# Version 1.0
# Author theneedyguy
# LICENSE: MIT



# Set variables
APP_ID=${STR_APPID}
APP_SECRET=${STR_APPSECRET}
LOOPTIME=${STR_LOOPTIME}
FORCEDOWNLOAD=${STR_FORCEDOWNLOAD}

# Variable defaults
LOOP_RUNNING=true
if [[ "${LOOPTIME}" == "" ]]; then
  LOOPTIME=3600 #default to 1 hour sleep interval
elif [[ "${LOOPTIME}" == "0" ]]; then
  LOOP_RUNNING=false
fi

#CONFIG defaults
STREAMLINK_DEFAULT="720p,480p,best"
FFMPEG_DEFAULT="-c:v copy -c:a copy -movflags +faststart"
EXTENSION_DEFAULT="mp4"

CONFIG=${JSON_CONFIG}
NUM_CHANNELS=$(jq -s -r '.|length' <<< ${CONFIG})
if [[ $? != 0 ]] || [[ "$CONFIG" == "" ]]; then
  echo "CRIT: Cannot parse config. exiting."
  sleep 5
  exit 1
fi

function time_to_seconds() {
  #accept as a pipe, and as a param.
  if (( $# == 0 )); then
    timestring=$(cat /dev/stdin)
  else
    timestring=$1
  fi
  #string manip to cut out only the digits and quantifier
  days=$(echo $timestring | grep -o '[[:digit:]]*d' | sed 's/d//')
  hours=$(echo $timestring | grep -o '[[:digit:]]*h' | sed 's/h//')
  minutes=$(echo $timestring | grep -o '[[:digit:]]*m' | sed 's/m//')
  seconds=$(echo $timestring | grep -o '[[:digit:]]*s' | sed 's/s//')
  #default on empty values
  if [[ "$days" == "" ]]; then days=0; fi
  if [[ "$hours" == "" ]]; then hours=0; fi
  if [[ "$minutes" == "" ]]; then minutes=0; fi
  if [[ "$seconds" == "" ]]; then seconds=0; fi
  echo $(( ($days*86400)+($hours*3600)+($minutes*60)+($seconds) ))
}


function download_session() {
  echo "Starting a download session!"
  token=$(curl -s -X POST "https://id.twitch.tv/oauth2/token?client_id=${APP_ID}&client_secret=${APP_SECRET}&grant_type=client_credentials" | jq -r '.access_token')
  if [[ "${token}" == "" ]]; then
    echo "Error fetching auth token!"; return 1
  fi

  #iterate through the config
  for channelnum in $(seq 0 $(expr $NUM_CHANNELS - 1)); do
    # read in all vals from config
    name=$(jq -s -r .[${channelnum}].name <<< $CONFIG)
    dir=$(jq -s -r .[${channelnum}].dir <<< $CONFIG)
    quality=$(jq -s -r .[${channelnum}].quality <<< $CONFIG)
    ffmpeg=$(jq -s -r .[${channelnum}].ffmpeg <<< $CONFIG)
    extension=$(jq -s -r .[${channelnum}].extension <<< $CONFIG)

    # if empty, set defaults
    if [[ "${name}" == "" ]] || [[ "${name}" == "null" ]]; then echo "WARNING: check json config, ${channelnum} doesn't have a valid name"; continue; fi
    if [[ "${dir}" == "" ]] || [[ "${dir}" == "null" ]]; then dir="${name}"; fi
    if [[ "${quality}" == "" ]] || [[ "${quality}" == "null" ]]; then quality="${STREAMLINK_DEFAULT}"; fi
    if [[ "${ffmpeg}" == "" ]] || [[ "${ffmpeg}" == "null" ]]; then ffmpeg="${FFMPEG_DEFAULT}"; fi
    if [[ "${extension}" == "" ]] || [[ "${extension}" == "null" ]]; then extension="${EXTENSION_DEFAULT}"; fi

    # To avoid downloading the current stream that might not even be finished we download the second latest vod of the streamer.
    # This will have problems if the streamer has never streamed before but who really cares. This is just a little script.
    stream_status=$(curl -s -H "Authorization: Bearer ${token}" -H "Client-ID: ${APP_ID}" -X GET "https://api.twitch.tv/helix/streams?user_login=${name}" | jq -r .data[].type)
    if [[ "${stream_status}" == "live" ]]; then
      echo "${name} is live."; vod_offset=1
    else
      echo "${name} is offline."; vod_offset=0
    fi
    stream_id=$(curl -s -H "Authorization: Bearer ${token}" -H "Client-ID: ${APP_ID}" -X GET "https://api.twitch.tv/helix/users?login=${name}" | jq -r .data[].id)
    if [[ "${stream_id}" == "" ]]; then
      echo "Error fetching stream id from channel name!"; continue
    fi
    vod_list=$(curl -s -H "Authorization: Bearer ${token}" -H "Client-ID: $APP_ID" -X GET "https://api.twitch.tv/helix/videos?user_id=${stream_id}?type=archive" | jq -c ".data[${vod_offset}:]" | jq '.[] | {created_at: .created_at, url: .url, duration: .duration }' )
    num_vods=$(jq -s -r '.|length' <<< ${vod_list})

    vod_dir="/vods/${dir}"
    mkdir -p "${vod_dir}"
    for curvod in $(seq 0 $(expr ${num_vods} - 1)); do
      echo " checking vod $(( ${curvod} + 1 )) of ${num_vods}"
      vod_file="${vod_dir}/vod-"$(jq -s -r ".[${curvod}].created_at" <<< ${vod_list} | sed 's!:!-!g')
      vod_url=$(jq -s -r ".[${curvod}].url" <<< ${vod_list})
      vod_duration=$(jq -s -r ".[${curvod}].duration" <<< ${vod_list} | time_to_seconds)
      file_duration=$(ffprobe -v quiet -show_format -of flat=s=_ -i ${vod_file}.${extension} | grep "format_duration" | cut -d '"' -f 2 | cut -d '.' -f 1)
      if [[ "$file_duration" == "" ]]; then file_duration=0; fi

      if [ "${FORCEDOWNLOAD}" == "" ] && [ -f ${vod_file}* ] && \
      [[ $(( ${vod_duration} - ${file_duration} )) -le 2 ]] && \
      [[ $(( ${vod_duration} - ${file_duration} )) -ge -2 ]]; then
        echo "Skipping ${vod_file}.${extension}"
        continue
      fi
      echo "Downloading ${vod_file}.${extension}"
      streamlink --stdout "${vod_url}" "${quality}" | ffmpeg -hide_banner -loglevel error -y -i pipe:0 ${ffmpeg} "${vod_file}.${extension}"
    done
    [[ "${FORCEDOWNLOAD}" != "" ]] && FORCEDOWNLOAD=""
  done
  echo "Download session completed"
}


function main() {
  #do while loop
  while true; do
    download_session
    [[ ! ${LOOP_RUNNING} ]] && break
    sleep $LOOPTIME
    [[ ! ${LOOP_RUNNING} ]] && break
  done
}

main
