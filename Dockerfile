FROM jenkins/jenkins:lts

VOLUME ["/var/jenkins_home", "/usr/share/jenkins/ref"]
#^-- these locations are determined by the base image

ENV jenkins_docker_image_setup_root=/var/local/workspaces/jenkins/setup

ENV jenkins_docker_image_ssh_key_type=rsa

##

USER    root
WORKDIR "${jenkins_docker_image_setup_root}"

COPY packages.needed.01.txt .
RUN  egrep -v '^\s*#' packages.needed.01.txt > packages.needed.01.filtered.txt

ARG docker_install_sandbox=docker.install.gist.d
ARG docker_install=${docker_install_sandbox}/docker.install.sh
ARG docker_install_sha1sum=c8dd6b35545e7ea5d7c4eecfe4eb6025c0ae844c
ARG docker_install_gist_url=https://gist.github.com/f66848f75de00612bedbce26395c5a93.git
RUN git clone "${docker_install_gist_url}" "${docker_install_sandbox}"

RUN apt-get update && apt-get install -y apt-utils && \
	apt-get install -y $(cat packages.needed.01.filtered.txt) && \
	(echo "${docker_install_sha1sum}  ${docker_install}" | shasum -a 1 -c - || :) && \
	bash "${docker_install}" && \
	rm -rf /var/lib/apt/lists/*

##

USER    root
WORKDIR "${jenkins_docker_image_setup_root}"

COPY start.sh .

ENTRYPOINT ["sh", "start.sh"]

##

