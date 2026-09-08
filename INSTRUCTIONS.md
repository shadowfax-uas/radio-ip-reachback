# After following the README, continue with these steps

## Set network MTU size to 1300

`curl -X POST -H "Authorization: token ${TOKEN}" -d '{"config": {"mtu": 1300}}' "https://my.zerotier.com/api/v1/network/${NETWORK_ID}"`

## Configure GStreamer to push to COMPASS

Run the following GStreamer script with the correct variables:

```bash
gst-launch-1.0 udpsrc port=15004 buffer-size=200000 caps="video/mpegts" ! \
  tsparse parse-private-sections=false ! \
  queue max-size-buffers=10000 max-size-bytes=0 max-size-time=0 leaky=downstream ! \
  tsdemux ! h264parse ! queue ! \
  rtspclientsink protocols=tcp location=rtsp://compass.mchmr.us:554/k1000-test/group/AFCENT
```
