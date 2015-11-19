install_nrpe:
  pkg.installed:
    - pkgs:
      - nagios-nrpe-server
      - libsys-statistics-linux-perl

/usr/lib/nagios/plugins/check_linux_stats.pl:
  file.managed:
    - source:
      - salt://nrpe/check_linux_stats.pl
    - user: root
    - group: root
    - mode: 755

/etc/nagios/nrpe.d/va.cfg:
  file.managed:
    - source:
      - salt://nrpe/va.cfg
    - user: root
    - group: root
    - mode: 644

/etc/nagios/nrpe.cfg:
  file.replace:
    - pattern: 'allowed_hosts=127.0.0.1'
    - repl: 'allowed_hosts={{ salt['grains.get']('master') }}'

nagios-nrpe-server:
  service.running:
  - watch:
    - file: /etc/nagios/nrpe.cfg
