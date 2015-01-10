salt-minion:
    # Remove apt package so we don't upgrade automatically.
    pkg.removed: []
    service.running:
        - enable: yes
        - watch:
            - pip: salt

remove-old-salt-install-dir:
    cmd.run:
        - name: 'rm -rf /tmp/pip-build-root/salt'

# This preliminary step is required so we don't upgrade recursively unless
# necessary. pip: salt will take care of really necessary dependent installs
# or upgrades.  See
# http://www.pip-installer.org/en/latest/cookbook.html#non-recursive-upgrades
salt-nodeps:
    pip.installed:
        - name: salt=={{ pillar['salt_version'] }}
        - upgrade: yes
        - no_deps: yes
        - require:
            - cmd: remove-old-salt-install-dir

salt:
    # Use pip package so we maintain control over installed versions.
    pip.installed:
        # Not as tautological as it looks.  bin/update.py may change this on
        # the cloudmaster, and then a subsequent state.highstate applies the
        # upgrade.
        - name: salt=={{ pillar['salt_version'] }}
        - require:
            - pip: salt-nodeps
            - pkg: salt-prereqs

# In theory this is only required for salt-cloud, but now that salt-cloud is
# a part of the salt project this requirement seems to apply even if you don't
# use any salt-cloud functionality.
#apache-libcloud:
#    pip.installed:
#        - upgrade: yes

salt-prereqs:
    pkg.installed:
        - names:
            - swig
            - libssl-dev
            - python-dev
            - libzmq3-dev
            # For some reason this was required in cloudmaster1-2, but not in
            # my test cloudmaster.  -aranhoide
            - python-libcloud

