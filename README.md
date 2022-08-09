# Twitch Archiver
A docker container to automatically download the latest vod of your favourite twitch streamer.
It uses streamlink as the interface to connect to twitch and download the vods, which are passed to ffmpeg for saving to /vods/

To get started, fill out the docker-compose.yml file, and simply run: `docker-compose up -d`

Required Environment Vars:
- STR_APPID: Check https://dev.twitch.tv/docs/authentication for how to register an app to obtain the ID and Secret needed for communicating with the API endpoint
- STR_APPSECRET: See APPID
- JSON_CONFIG: json formatted configuration
  - name: (required) name of twitch channel
  - dir: (defaults to: value of name) different directory to download the files to. eg. "." would mean the directory under /vods/./
  - quality: (defaults to: "720p,480p,best") quality string to pass to streamlink. note that 720p is different than 720p50, these are set by twitch
  - ffmpeg: (defaults to: "-c:v copy -c:a copy -movflags +faststart") ffmpeg output flags, currently it's mostly to filter out the data stream and make the file more stream-able by moving the mp4 info to the front.
  - extension: (defaults to: "mp4") output file extension, usually infers a certain container format

Optional Environment Vars:
- STR_LOOPTIME: defaults to 1 hour wait time between download sessions. 0 means it will do one download session then exit.
- FORCEDOWNLOAD: if set, the first download session will download everything, useful in case you want to force downloading different formats.
