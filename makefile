IP=143.198.76.122

all:
	rsync -ar --del . root@$(IP):/var/www/html/deadsfu
	scp Caddyfile root@$(IP):/etc/caddy
	scp deadsfu.caddy root@$(IP):/etc/caddy
	ssh root@$(IP) chmod 755 /etc/caddy/\*
	ssh root@$(IP) systemctl reload caddy
