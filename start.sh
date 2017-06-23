#!/bin/sh
## Entry point for the Jenkins container.
##

debugging=false

jenkins_user_name="${jenkins_user_name:-jenkins}"
jenkins_group_name="${jenkins_group_name:-jenkins}"

jenkins_home_root="${jenkins_home_root:-/var/jenkins_home}"
jenkins_home_ref_root="${jenkins_home_ref_root:-/usr/share/jenkins/ref}"

jenkins_docker_image_setup_root="${jenkins_docker_image_setup_root:-/var/local/workspaces/jenkins/setup}"

jenkins_docker_image_ssh_key_type="${jenkins_docker_image_ssh_key_type:-rsa}"

##

# set ownership & permissions on files managed by jenkins:
for d1 in \
	"${jenkins_home_root}" \
	"${jenkins_home_ref_root}" \
	"${jenkins_docker_image_setup_root}" \
;do
	(set -x ; : ; chown -R "${jenkins_user_name}:${jenkins_group_name}" "$d1")

	(set -x ; : ; ls -al "$d1")
done

(set -x ; : ; chmod go-rwx "${jenkins_home_root}"/.ssh)
for f1 in \
	"${jenkins_home_root}"/.ssh/*.pub \
;do
	(set -x ; chmod a+r "$f1")
done

# generate an ssh key for user jenkins on demand:
for k1 in \
	"${jenkins_home_root}/.ssh/id_${jenkins_docker_image_ssh_key_type}" \
;do
	! [ -s "$k1" -a -s "$k1".pub ] || continue

	su -c "set -x ; : ; ssh-keygen -t '${jenkins_docker_image_ssh_key_type}' -f '${k1}' -N ''" "${jenkins_user_name}"
done

(set -x ; : ; ls -al "${jenkins_home_root}"/.ssh)

##

export TINI_SUBREAPER=
#^-- mere existence indicates 'true'

echo
echo "==== Environment variables:"
echo
printenv | LC_ALL=C sort
echo
echo "===="
echo

##

if ${debugging} ; then
	echo "Launching a shell..."
	echo
	exec bash -l
else
	echo "Launching Jenkins..."
	echo
	exec su -c "exec /bin/tini -- /usr/local/bin/jenkins.sh $@" "${jenkins_user_name}"
fi

##

