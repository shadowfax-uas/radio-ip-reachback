gst-launch-1.0 udpsrc port=15004 buffer-size=200000 caps="video/mpegts" ! \
  tsparse parse-private-sections=false ! \
  queue max-size-buffers=10000 max-size-bytes=0 max-size-time=0 leaky=downstream ! \
  tsdemux ! h264parse ! queue ! \
  rtspclientsink protocols=tcp location=rtsp://compass.mchmr.us:554/k1000-test/group/AFCENT
