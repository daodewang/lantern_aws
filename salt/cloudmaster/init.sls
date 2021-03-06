include:
    - salt_cloud
    - lockfile
{% if grains['controller'] == grains['production_controller'] %}
    - lantern
{% endif %}

{% set config_folder_path = "/home/lantern/allfallbacks_config_folder.txt" %}

/etc/ufw/applications.d/salt:
    file.managed:
        - source: salt://cloudmaster/ufw-rules
        - user: root
        - group: root
        - mode: 644

'ufw app update Salt ; ufw allow salt':
    cmd.run:
        - require:
            - file: /etc/ufw/applications.d/salt

{% set scripts = [('cloudmaster', '1')] %}

{% if grains['controller'] == grains['production_controller'] %}

/home/lantern/alert_fallbacks_failing_to_proxy.py:
    file.managed:
        - source: salt://cloudmaster/alert_fallbacks_failing_to_proxy.py
        - template: jinja
        - user: lantern
        - group: lantern
        - mode: 700

{{ config_folder_path }}:
    file.managed:
        - source: salt://cloudmaster/allfallbacks_config_folder.txt
        - user: lantern
        - group: lantern
        - mode: 600

check-fallbacks-proxying:
    cron.present:
        - name: "rm -rf /home/lantern/.lantern /home/lantern/.littleshoot ; /home/lantern/lantern-repo/quickRun.bash --force-get --check-fallbacks={{ config_folder_path }}"
        - user: lantern
        - minute: "*/30"
        - require:
            - cmd: install-lantern

{% endif %}

{% for script_name, minutes in scripts %}
/home/lantern/{{ script_name }}.py:
    file.managed:
        - source: salt://cloudmaster/{{ script_name }}.py
        - template: jinja
        - user: root
        - group: root
        - mode: 700
    cron.present:
        - user: root
        - minute: "*/{{ minutes }}"
        - require:
            - pip: lockfile
{% endfor %}

/home/lantern/check_unresponsive_fallbacks.py:
    cron.absent

/usr/bin/regenerate-fallbacks-list:
    file.managed:
        - source: salt://cloudmaster/regenerate_fallbacks_list.py
        - user: root
        - group: root
        - mode: 700

/usr/bin/accept-minions:
    file.managed:
        - source: salt://cloudmaster/accept_minions.py
        - user: root
        - group: root
        - mode: 700
