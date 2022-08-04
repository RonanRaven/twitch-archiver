# Twitch Archiver
A docker container to automatically download the latest vod of your favourite twitch streamer.
It uses streamlink as the interface to connect to twitch and download the vods, which are passed to ffmpeg for saving to /vods/

Environment Vars:
- STR_APPID: Check https://dev.twitch.tv/docs/authentication for how to register an app to obtain the ID and Secret needed for communicating with the API endpoint
- STR_APPSECRET: See APPID
- STR_CHANNEL: The name of the twitch channel you want to auto download

Optional Environment Vars:
- STR_FFMPEG: arguments to pass to ffmpeg. Default: 2Mbits/s VBR video to go with the webm extension
- STR_EXTENSION: the output file extension. Default: webm
- STR_LOOPTIME: defaults to 1 hour wait time between download sessions. 0 means it will do one download session then exit.

