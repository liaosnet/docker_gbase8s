FROM scratch
ADD base_sys.tar.gz /
ADD docker_entrypoint.sh /usr/local/bin/
RUN groupadd -g 1000 gbasedbt && useradd -u 1000 -g gbasedbt -d /home/gbase -m -s /bin/bash gbasedbt
ADD v8.8_3633x31_csdk_x64.tar.gz /
EXPOSE 9088
ENTRYPOINT ["docker_entrypoint.sh"]
