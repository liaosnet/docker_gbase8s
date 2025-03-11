## 使用方式  
自行构建镜像  
docker build -t liaosnet/gbase8s:v8.8_3513x25_csdk_x64 .

指定标签
docker tag liaosnet/gbase8s:v8.8_3513x25_csdk_x64 gbase8sv8.8:3513x25_csdk_x64

运行镜像，-p参数绑定主机端口19088到docker的9088端口上
docker run -d -p 19088:9088 \
  --network mynetwork --ip 172.20.0.21 \
  --name node11 --hostname node11 \
  --mac-address F0-F0-69-F0-F0-01 \
  --privileged=true \
  -v /data/gbase_std:/opt/gbase/data \
  -e SERVERNAME=gbase01 \
  -e USERPASS=GBase123$% \
  -e CPUS=1 \
  -e MEMS=2048 \
  -e ADTS=0 \
  liaosnet/gbase8s:v8.8_3513x25_csdk_x64

以上参数中：  
端口9088为数据库使用的内部端口，需要在容器中映射，如使用19088端口    
SERVERNAME对应的是默认服务名称：gbase01  
USERPASS对应的是默认gbasedbt用户密码：GBase123$%  
CPUS对应的是限制容器中使用的cpu数量：1  
MEMS对应的是限制容器中使用的内存总量： 2048 MB  
ADTS对应的是数据库是否开启审计：0 表示不开启（默认）,  1 开启  

其它参数：  
MODE数据库主备集群节点的角色，standard|primary|secondary   
LOCALIP本节点使用的IP地址，用于集群时指定IP或者地址  
PAIRENAME集群对端数据库实例名称，默认gbase02  
PAIREIP集群对端节点的IP地址，用于集群时指定IP或者地址  

docker参数:  
-p 指定端口映射  
--name 指定容器名称  
--hostname 指定容器主机名称  
--mac-address 指定容器使用的网卡使用的mac地址（这里使用私有）  
--network 指定使用的自定义网络名称  
--ip 指定使用的自定义网络IP地址  
--privileged 指定容器是否允许使用特权模式（映射目录需要）  
-v 映射目录  

## 数据库连接(JDBC)  
JDBC JAR：
类名：com.gbasedbt.jdbc.Driver
默认URL：jdbc:gbasedbt-sqli://IPADDR:19088/testdb:GBASEDBTSERVER=gbase01;DB_LOCALE=zh_CN.utf8;CLIENT_LOCALE=zh_CN.utf8;IFX_LOCK_MODE_WAIT=30;
用户：gbasedbt
默认密码：GBase123$%
其中：IPADDR为docker所在机器的IP地址，同时需要放通19088端口。

<dependency>
    <groupId>com.gbasedbt</groupId>
    <artifactId>jdbc</artifactId>
    <version>3.5.1.32</version>
</dependency>
