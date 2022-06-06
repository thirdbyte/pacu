FROM ubuntu:20.04

RUN apt-get -y update && apt-get -y dist-upgrade && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y golang nano git && \
	cd /root && go get github.com/gophish/gophish && \
	cd go/src/github.com/gophish/gophish && \
	sed -i 's/rid/id/g' models/campaign.go && sed -i 's/gophish//g' models/smtp_test.go && \
	sed -i 's/const\ ServerName\ =\ "gophish"/const\ ServerName\ =\ ""/g' config/config.go && \
	sed -i /'msg.SetHeader("X-Mailer",\ config.ServerName)'/d models/maillog.go && \
        sed -i /'msg.SetHeader("X-Mailer",\ config.ServerName)'/d models/email_request.go && \
        sed -i /'github.com\/gophish\/gophish\/config'/d models/maillog.go && \
        sed -i /'github.com\/gophish\/gophish\/config'/d models/email_request.go && \
	go build && \
	apt-get -y autoremove && apt-get -y clean && rm -rf /var/lib/apt/lists/* && \
	ln -s /root/go/src/github.com/gophish/gophish /opt/gophish

WORKDIR /opt/gophish
RUN sed -i 's/127.0.0.1/0.0.0.0/g' config.json && sed -i 's/false/true/g' config.json

CMD ["./gophish"]
