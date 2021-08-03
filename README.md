# Twitch Archiver
A docker container to automatically download the latest vod of your favourite twitch streamer.
It uses streamlink as the interface to connect to twitch and download the vods.

The container expects the following environment variables:
- STR_APPID (Check https://dev.twitch.tv/docs/authentication for how to register an app to obtain the ID and Secret needed for communicating with the API endpoint)
- STR_APPSECRET
- STR_CHANNEL (The name of the twitch channel you want to auto download)
- STR_RES (The default resolution of the vod)
The container will save all the vods under /vods

## Resolutions
Valid resolutions may vary since streamers are free to set it and what framerates they use. Streamlink is the program that finds out the available quality of the archived stream. STR_RES will be passed to streamlink.
Example stream quality:
- worst
- 160p
- 360p
- 480p
- 720p
- 720p60
- 1080p60
- best

If you set one of these resolutions as the value for STR_RES the container should download the vod. If the resoluton does not exist it will automatically download the best available resolution.

