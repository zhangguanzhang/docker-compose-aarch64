## 说明

git 上搜索了很多 docker-compose 的 arm64 的编译基本都是使用 `qemu-user-static` 之类的设置下后编译的，也看到过用特权容器启动 qemu-user-static 或者 `binfmt` 之类的，但是我自己机器上试了无效，貌似是因为我操作系统是低版本内核的 centos ，github 上搜了下，其他很多人的编译感觉太啰嗦了。就在 action 上整了下，测试是可用的，而且非常简单。


编译过程看 compose 仓库的 makefile，是运行的 https://github.com/docker/compose/blob/master/script/build/linux 这个脚本。所以克隆 compose 仓库后进目录里，然后 checkout 指定 tag。官方的编译过程都是在 docker build 产生的容器里去编译的。最后有个 build --output就是直接把文件给整出来。我这里是用的 buildx 去替代 build 编译。我仓库整个自动化同步官方 tag checkout 去编译。

## 测试 

### 环境信息

银河麒麟 v10 系统，架构 arm64

```
$ arch
aarch64
$ cat /etc/os-release 
NAME="Kylin Linux Advanced Server"
VERSION="V10 (Tercel)"
ID="kylin"
VERSION_ID="V10"
PRETTY_NAME="Kylin Linux Advanced Server V10 (Tercel)"
ANSI_COLOR="0;31"
------------------
$ cat /etc/os-release 
NAME="Kylin"
VERSION="4.0.2 (juniper)"
ID=kylin
ID_LIKE=debian
PRETTY_NAME="Kylin 4.0.2"
VERSION_ID="4.0.2"
HOME_URL="http://www.kylinos.cn/"
SUPPORT_URL="http://www.kylinos.cn/content/service/service.html"
BUG_REPORT_URL="http://www.kylinos.cn/"
UBUNTU_CODENAME=juniper
```

docker 版本信息

```
$ docker info
Containers: 63
 Running: 44
 Paused: 0
 Stopped: 19
Images: 24
Server Version: 18.09.9
Storage Driver: overlay2
 Backing Filesystem: xfs
 Supports d_type: true
 Native Overlay Diff: true
Logging Driver: json-file
Cgroup Driver: cgroupfs
Plugins:
 Volume: local
 Network: bridge host macvlan null overlay
 Log: awslogs fluentd gcplogs gelf journald json-file local logentries splunk syslog
Swarm: inactive
Runtimes: runc
Default Runtime: runc
Init Binary: docker-init
containerd version: 894b81a4b802e4eb2a91d1ce216b8817763c29fb
runc version: 425e105d5a03fabd737a126ad93d62a9eeede87f
init version: fec3683
Security Options:
 seccomp
  Profile: default
Kernel Version: 4.19.90-17.ky10.aarch64
Operating System: Kylin Linux Advanced Server V10 (Tercel)
OSType: linux
Architecture: aarch64
CPUs: 64
Total Memory: 62.76GiB
Name: reg.xxx.lan
ID: RI24:C6CM:WELZ:MQEJ:N5OY:IR74:OQPG:XV72:SFRI:NUSK:DS44:OQNQ
Docker Root Dir: /data/kube/docker
Debug Mode (client): false
Debug Mode (server): false
Registry: https://index.docker.io/v1/
Labels:
Experimental: false
Insecure Registries:
 reg.xxx.lan:5000
 treg.yun.xxx.cn
 127.0.0.0/8
Registry Mirrors:
 https://registry.docker-cn.com/
 https://docker.mirrors.ustc.edu.cn/
Live Restore Enabled: false
Product License: Community Engine
```

### 测试运行

```
$ ldd ./docker-compose-linux-arm64 
	linux-vdso.so.1 (0x0000fffd72210000)
	libdl.so.2 => /lib64/libdl.so.2 (0x0000fffd721a0000)
	libz.so.1 => /lib64/libz.so.1 (0x0000fffd72160000)
	libc.so.6 => /lib64/libc.so.6 (0x0000fffd71fd0000)
	/lib/ld-linux-aarch64.so.1 (0x0000fffd72220000)
$ ll
总用量 10504
drwxr-xr-x 2 root root       26  3月 13 11:11 conf.d
-rwxr-xr-x 1 root root 10750256  3月 12 13:15 docker-compose-linux-arm64
-rw-r--r-- 1 root root      389  3月 13 11:11 docker-compose.yml
drwxr-xr-x 2 root root        6  3月 13 11:11 down
$ mkdir -p conf.d down
$ cat > conf.d/default.conf << EOF
server {
    listen       81;
    server_name  localhost;
    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
        autoindex    on;
    }
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }
}
EOF
$ cat docker-compose.yml 
version: '3.4'
services:
  nginx:
    image: nginx:alpine
    container_name: install-nginx
    hostname: install-nginx
    volumes:
      - /usr/share/zoneinfo/Asia/Shanghai:/etc/localtime:ro
      - ./down:/usr/share/nginx/html
      - ./conf.d/:/etc/nginx/conf.d/
    network_mode: "host"
    logging:
      driver: json-file
      options:
        max-file: '3'
        max-size: 100m

$ ./docker-compose-linux-arm64 up -d
Pulling nginx (nginx:alpine)...
alpine: Pulling from library/nginx
Digest: sha256:c2ce58e024275728b00a554ac25628af25c54782865b3487b11c21cafb7fabda
Status: Downloaded newer image for nginx:alpine
Creating install-nginx ... done
$./docker-compose-linux-arm64 ps -a
    Name                   Command               State   Ports
--------------------------------------------------------------
install-nginx   /docker-entrypoint.sh ngin ...   Up           
$ netstat -nlptu | grep -E ':81\s'
tcp        0      0 0.0.0.0:81              0.0.0.0:*               LISTEN      4093364/nginx: mast 
```

页面访问了下正常，清理

```
$ ./docker-compose-linux-arm64 down
Stopping install-nginx ... done
Removing install-nginx ... done
```


## 参考资料

- https://github.com/ubiquiti/docker-compose-aarch64
- https://github.com/RogerLaw/docker-compose-aarch64
