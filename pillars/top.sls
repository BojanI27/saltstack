base:
  'role:monitoring':
    - match: grain
    - credentials
    - openstack
  'role:directory':
    - match: grain
    - credentials
  'role:owncloud':
    - match: grain
    - credentials
  'role:lamp':
    - match: grain
    - lamp
  'role:backup':
    - match: grain
    - credentials
  'role:fileshare':
    - match: grain
    - credentials
  'role:email':
    - match: grain
    - credentials
  'role:va-master':
    - match: grain
    - openvpn
  '*':
    - base
