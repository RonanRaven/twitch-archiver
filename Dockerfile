FROM linuxserver/ffmpeg:version-4.4-cli

#all prerequisites, packages, and setup for python
RUN apt-get update && apt-get install -y jq curl python3 python3-pip && rm -rf /var/lib/apt/lists/*

#python requirements install
COPY ./requirements.txt /tmp/
RUN pip install -r /tmp/requirements.txt

#script setup
RUN mkdir -p /vods /app
COPY ./fix-permissions /usr/bin/fix-permissions
COPY ./app.sh /app/
RUN /usr/bin/fix-permissions /vods/ && /usr/bin/fix-permissions /app/
WORKDIR /app/
VOLUME ["/vods/"]

ENTRYPOINT [""]
CMD ["/bin/bash", "-c", "./app.sh"]
