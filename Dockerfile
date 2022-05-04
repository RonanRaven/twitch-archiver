FROM alpine:3.15

#all prerequisites, packages, and setup for python
RUN apk add --no-cache bash jq curl build-base ffmpeg python3 py3-pip cython libxml2 libxslt

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

ENTRYPOINT ["bash","-c", "while true; do './app.sh'; sleep 3600; done"]
