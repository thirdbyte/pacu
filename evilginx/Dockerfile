FROM ubuntu:20.04

RUN apt-get -y update && apt-get -y dist-upgrade && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y make nano git golang && \
	cd /root && git clone https://github.com/kgretzky/evilginx2.git && \
	cd evilginx2 && \
	sed -i /'req.Header.Set(string(hg),\ egg2)'/d ./core/http_proxy.go && \
	sed -i /'egg2\ :=\ req.Host'/d ./core/http_proxy.go && \
	sed -i 's/req.RemoteAddr/req.Header.Get("X-Real-IP")/g' ./core/http_proxy.go && \
	make && \
	apt-get -y autoremove && apt-get -y clean && rm -rf /var/lib/apt/lists/* && \
	ln -s /root/evilginx2 /opt/evilginx

WORKDIR /opt/evilginx

CMD ["/bin/bash"]
