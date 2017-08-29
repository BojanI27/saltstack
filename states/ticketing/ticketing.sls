install_ticketing:
  pkg.installed:
    - pkgs:
      - imagemagick
      - libopenssl-ruby1.8.
      - wget
      - postgresql

# based on http://www.redmine.org/projects/redmine/wiki/redmineinstall

{% set domain = salt['pillar.get']('domain') %}
{% set host_name = grains['id'] %}
{% set dcip = salt['mine.get'](tgt='role:directory',fun='inventory',expr_form='grain')['va-directory']['ip4_interfaces']['eth0'][0] %}

/root/redmine.tar.gz:
  file.managed:
    - source: salt://ticketing/files/redmine-3.4.2.tar.gz
    - user: root
    - group: root
    - mode: 755

# UNPACK
    

#instrall POSTGRESQL

#sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" >> /etc/apt/sources.list.d/pgdg.list'
#wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | sudo apt-key add -
#sudo apt-get update
#sudo apt-get install postgresql postgresql-contrib


# prepare database


#CREATE ROLE redmine LOGIN ENCRYPTED PASSWORD 'my_password' NOINHERIT VALID UNTIL 'infinity';

user:
  postgres_user.present:
    - name: "redmine"
    - password: "{{ salt['grains.get_or_set_hash']('redmine_db_pass') }}"
#    - password: test
    - createdb: True
    - login: True
    - encrypted: True
    - createroles: True
    - createuser: "redmine"
    - inherit: False
    
#CREATE DATABASE redmine WITH ENCODING='UTF8' OWNER=redmine;
create_db:
  postgres_database.present:
    - name: "redmine"
    - db_user: "redmine"
    - db_password: "{{ salt['grains.get_or_set_hash']('redmine_db_pass') }}"
#    - db_password: test
    - db_host: 127.0.0.1
    - encoding: "UTF8"
    - owner: "redmine"

# ??
ALTER DATABASE "redmine_db" SET datestyle="ISO,MDY";


# copy config/database.ym
/usr/additional_environment.rb:
  file.managed:
    - source: salt://ticketing/files/additional_environment.rb
    - user: root
    - group: root
    - mode: 644

/usr/configuration.yml:
  file.managed:
    - source: salt://ticketing/files/configuration.yml
    - user: root
    - group: root
    - mode: 644

/usr/database.yml:
  file.managed:
    - source: salt://ticketing/files/database.yml
    - user: root
    - group: root
    - mode: 644



# Dependencies installation

gem install bundler
bundle install --without development test

# session store secret generation

bundle exec rake generate_secret_token


# Database schema objects creation

# Create the database structure, by running the following command under the application root directory:
#cert_lhttps:
 # cmd.run:
 #  - name: openssl req -new -x509 -keyout /etc/lighttpd/certs/lighttpd.pem -out /etc/lighttpd/certs/lighttpd.pem -days 3650 -nodes -sha256 -subj '/CN={{ host_name }}.{% filter lower %}{{ domain }}{% endfilter %}/O=VA-Proxy/C=US'


RAILS_ENV=production bundle exec rake db:migrate



# Database default data set
#Insert default configuration data in database, by running the following command:

RAILS_ENV=production REDMINE_LANG=en bundle exec rake redmine:load_default_data


#  File system permissions

mkdir -p tmp tmp/pdf public/plugin_assets
sudo chown -R redmine:redmine files log tmp public/plugin_assets
sudo chmod -R 755 files log tmp public/plugin_assets


/etc/lighttpd/certs/:
  file.directory:
    - makedirs: True

    
# cron backups
# Database
#/usr/bin/mysqldump -u <username> -p<password> <redmine_database> | gzip > /path/to/backup/db/redmine_`date +%y_%m_%d`.gz

# Attachments
#rsync -a /path/to/redmine/files /path/to/backup/files





#### functionality script
/usr/lib/nagios/plugins/:
  file.directory:
    - makedirs: True

check_functionality_ticketing:
  file.managed:
    - name: /usr/lib/nagios/plugins/check_functionality.sh
    - source: salt://ticketing/files/check_functionality.sh
    - user: root
    - group: root
    - mode: 755

