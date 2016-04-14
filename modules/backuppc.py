import salt, os.path

default_paths = {
    'va-monitoring' : ['/etc/icinga2', '/root/.va/backup', '/var/lib/pnp4nagios/perfdata/'], 
    'va-directory' : ['/root/.va/backup', '/etc/openvpn'], 
    'va-backup' : ['/etc/backuppc'], 
    'va-fileshare' : ['/home', '/etc/samba'], 
    'va-email' : ['/etc/postfix', '/root/.va/backup', '/var/vmail/'],
    'va-owncloud' : ['/root/.va/backup', '/var/www/owncloud'],
}

def add_default_paths(hosts = []):
    for host in hosts: 
        paths = [default_paths[x] for x in default_paths if __salt__['mine.get'](x, 'inventory')[x]['fqdn'] == host][0]
        for path in paths: 
            result = add_folder(host, path)
    return True

def hosts_file_add(hostname):
    address = __salt__['mine.get']('fqdn:'+hostname,'address',expr_form='grain')
    address = address[address.keys()[0]][0]
    __salt__['file.append']('/etc/hosts',address+'\t'+hostname)

def add_host(hostname):
    hosts_file_add(hostname)
    __salt__['file.touch']('/etc/backuppc/pc/'+hostname+'.pl')
    __salt__['file.append']('/etc/backuppc/pc/'+hostname+'.pl', '$Conf{XferMethod} = \'rsync\';\n$Conf{RsyncShareName} = [\n];')
    __salt__['file.chown']('/etc/backuppc/pc/'+hostname+'.pl', 'backuppc', 'www-data')
    __salt__['file.append']('/etc/backuppc/hosts', hostname+'       0       backuppc')
    return True

def rm_host(hostname):
    __salt__['file.remove']('/etc/backuppc/pc/'+hostname+'.pl')
    __salt__['file.line'](path='/etc/backuppc/hosts',content=hostname+'       0       backuppc', mode='delete')
    __salt__['file.chown']('/etc/backuppc/hosts', 'backuppc', 'www-data')
    return __salt__['service.reload']('backuppc')

def add_folder(hostname, folder, ip=''):
	sshcmd='ssh -oStrictHostKeyChecking=no root@'+hostname+' '
	if not __salt__['file.file_exists']('/etc/backuppc/pc/'+hostname+'.pl'):
		add_host(hostname)
        	__salt__['event.send']('backuppc/copykey', fqdn=hostname)
                __salt__['cmd.retcode'](cmd=sshcmd+'exit', runas='backuppc', shell='/bin/bash',cwd='/var/lib/backuppc')
	if __salt__['file.search']('/etc/backuppc/pc/'+hostname+'.pl','\''+folder+'\','):
		return False
	elif __salt__['cmd.retcode'](cmd=sshcmd+'test ! -d '+folder, runas='backuppc', shell='/bin/bash',cwd='/var/lib/backuppc'):
		__salt__['file.replace']('/etc/backuppc/pc/'+hostname+'.pl', pattern="\$Conf\{RsyncShareName\} \= \[", repl="$Conf{RsyncShareName} = [\n  '"+folder+'\',')
		__salt__['service.reload']('backuppc')
		return True
	else:
		return False
 
def rm_folder(hostname, folder):
	if os.path.exists('/etc/backuppc/'+hostname+'.pl') and __salt__['file.line'](path='/etc/backuppc/pc/'+hostname+'.pl',content='\''+folder,mode='delete'):
		__salt__['file.chown']('/etc/backuppc/pc/'+hostname+'.pl', 'backuppc', 'www-data')
		if list_folders([hostname])[hostname] == []:
			rm_host(hostname)
		return 'Folder '+folder+' has been deleted from backup list'
	else:
		return 'Folder not in backup list'

#def backup_count():
	

def list_folders(hostnames):
	folders_list = dict()
	for hostname in hostnames:
		folders = []
		if os.path.exists('/etc/backuppc/'+hostname+'.pl'):
			config_file = open('/etc/backuppc/'+hostname+'.pl', 'r').read().splitlines()
			for folder in config_file[config_file.index('$Conf{RsyncShareName} = [')+1:config_file.index('];')]:
				folders.append(folder.split('\'')[1])
		folders_list[hostname] = folders
	return folders_list
