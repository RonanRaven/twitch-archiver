#!/bin/bash

# Streamlink helper script for downloading vods automatically.
# You will need to create a Twitch API key for this to work since it relies on the API.
# Version 1.0
# Author theneedyguy
# LICENSE: MIT

# Set variables
APP_ID=$STR_APPID
APP_SECRET=$STR_APPSECRET
CHANNEL=$STR_CHANNEL
DESIRED_RES=$STR_RES

token=$(curl -s -X POST "https://id.twitch.tv/oauth2/token?client_id=$APP_ID&client_secret=$APP_SECRET&grant_type=client_credentials" | jq -r '.access_token')

if [[ "${token}" == "" ]]; then
	echo "Error fetching auth token!"; exit 1
fi

# To avoid downloading the current stream that might not even be finished we download the second latest vod of the streamer.
# This will have problems if the streamer has never streamed before but who really cares. This is just a little script.
stream_status=$(curl -s -H "Authorization: Bearer ${token}" -H "Client-ID: ${APP_ID}" -X GET "https://api.twitch.tv/helix/streams?user_login=${CHANNEL}" | jq -r .data[].type)

if [[ "${stream_status}" == "live" ]]; then
    echo "Streamer is live."; vod_offset=1
else
    echo "Streamer is offline."; vod_offset=0
fi

stream_id=$(curl -s -H "Authorization: Bearer ${token}" -H "Client-ID: ${APP_ID}" -X GET "https://api.twitch.tv/helix/users?login=${CHANNEL}" | jq -r .data[].id)
if [[ "${stream_id}" == "" ]]; then
    echo "Error fetching stream id from channel name!"; exit 1
fi


vod_list=$(curl -s -H "Authorization: Bearer ${token}" -H "Client-ID: $APP_ID" -X GET "https://api.twitch.tv/helix/videos?user_id=${stream_id}?type=archive" | jq -c ".data[${vod_offset}:]" | jq -c '.[] | {created_at: .created_at, url: .url }')
vod_dir="/vods/"

for vod in $vod_list; do
    vod_time=$(echo "${vod}" | jq -r .created_at)
    vod_url=$(echo "${vod}" | jq -r .url)
    vod_file=$(echo "${vod_dir}vod-${vod_time}.mp4" | sed 's!:!-!g')
    if [ -f "${vod_file}" ]; then
        continue
    fi
    echo "Downloading ${vod_file}"
    streamlink "${vod_url}" "${DESIRED_RES}" -o "${vod_file}" --hls-segment-threads 2 --ffmpeg-video-transcode h265 --ffmpeg-audio-transcode aac
done

