
.PHONY: rsync watch-rsync

REMOTE_DIR='/tmp/flight-manage'

rsync:
	rsync \
		--rsh='sshpass -p ${PASSWORD} ssh -l root' \
		-r \
		--delete \
		--exclude=vendor/ \
		--exclude='Gemfile.lock'\
		--exclude='var/'\
		--exclude='etc/'\
		--copy-links \
		--perms \
		. ${IP}:${REMOTE_DIR}

watch-rsync:
	rerun \
		--name 'Flight Appliance CLI' \
		--pattern '**/*' \
		--exit \
		--no-notify \
	  make rsync IP=${IP}
