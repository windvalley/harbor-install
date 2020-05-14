# Name

一键部署企业级Docker私有镜像仓库.

# Depolyment

## 环境准备

- CentOS7+
- Docker CE
- Docker Compose

请提前安装好Docker, 并启动Docker服务, 提前安装好`docker-compose`命令.

确保root用户能找到docker和docker-compose命令:
```bash
which docker
which docker-compose
```


## 执行安装脚本

提前设置好`harbor_install.sh`脚本中的前3个变量:

- `HARBOR_FQDN`, harbor服务的域名, 比如`reg.sre.im`, 解析到你部署harbor的服务器ip上.
- `CERT_PUB`, harbor服务域名的证书公钥**全路径**名称.
- `CERT_KEY`, harbor服务域名的证书私钥**全路径**名称.

> 如果`CERT_PUB`和`CERT_KEY`只要有一个为空, 将使用自签证书.

使用`root`用户或`sudo`来执行`harbor_install.sh`脚本进行自动安装:
```bash
sudo bash harbor_install.sh
```

# Test

### 安装目录

harbor被默认安装在`/usr/local/harbor/harbor`目录,
可以切换到该目录执行`docker-compose`命令操作harbor服务.

`docker-compose`详细配置文件:
`/usr/local/harbor/harbor/docker-compose.yml`

### 宿主机上的数据存储目录

`/data/`

### 宿主机上的服务日志目录

`/var/log/harbor/`

### 管理harbor服务

已设置systemd的harbor服务, 可通过如下命令管理harbor服务.
```bash
sudo systemctl stop harbor
sudo systemctl start harbor
sudo systemctl status harbor
```
### 命令行登录harbor

```bash
docker login -u admin -p Harbor12345 $HARBOR_FQDN
```

### 上传镜像到harbor

```bash
docker image tag python:3.8 $HARBOR_FQDN/library/python:3.8
docker image push $_
```

### Web UI

浏览器访问`https://$HARBOR_FQDN`, 管理员用户名密码: `admin/Harbor12345`


### 其他

#### 修改默认服务端口

如果想使用其他端口代替默认的`80`和`443`, 请手动修改如下文件:

`/usr/local/harbor/harbor/docker-compose.yml`

比如想使用8080和8443代替默认的`80`和`443`, 只需:

```
    ports:
      - 80:8080
      - 443:8443
```
修改为:
```
    ports:
      - 8080:8080
      - 8443:8443
```
