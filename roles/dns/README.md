Role Name
=========

Map the internal IP addresses to the external hostname in the /etc/hosts files.

This way traffic doesn't leave the VPN and the security rules don't need to ingess from outside mostly.

Requirements
------------

N/A

Role Variables
--------------

N/A

Dependencies
------------

N/A

Example Playbook
----------------

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

    - hosts: servers
      roles:
         - { role: username.rolename, x: 42 }
