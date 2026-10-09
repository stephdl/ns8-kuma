*** Settings ***
Library    SSHLibrary
Resource    api.resource

*** Variables ***
${ADMIN_USER}        admin
${ADMIN_PASSWORD}    Nethesis,1234
${kuma_host}         kuma.dom.test
${kuma_password}     Kuma,Test-1234

*** Keywords ***
Login to cluster-admin
    New Page    https://${NODE_ADDR}/cluster-admin/
    Fill Text    text="Username"    ${ADMIN_USER}
    Click    button >> text="Continue"
    Fill Text    text="Password"    ${ADMIN_PASSWORD}
    Click    button >> text="Log in"
    Wait For Elements State    css=#main-content    visible    timeout=10s

SQL
    [Arguments]    ${query}    ${module}=${module_id}
    # The query goes through stdin, so its quotes need no shell escaping
    ${out}    ${err}    ${rc} =    Execute Command
    ...    echo "${query}" | runagent -m ${module} podman exec -i kuma-mariadb sh -c 'MYSQL_PWD="\${MARIADB_ROOT_PASSWORD}" exec mariadb -N -B -uroot "\${MARIADB_DATABASE}"'
    ...    return_stderr=True    return_rc=True
    Should Be Equal As Integers    ${rc}    0    ${err}
    RETURN    ${out}

HTTP code
    [Arguments]    ${url}    ${options}=${EMPTY}
    ${code} =    Execute Command    curl -sk ${options} -o /dev/null -w "\%{http_code}" -H "Host: ${kuma_host}" ${url}
    RETURN    ${code}

Uptime Kuma answers
    ${code} =    HTTP code    https://127.0.0.1/    -L
    Should Be Equal    ${code}    200

*** Test Cases ***
Check if kuma is installed correctly
    ${output}  ${rc} =    Execute Command    add-module ${IMAGE_URL} 1
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}  0
    &{output} =    Evaluate    ${output}
    Set Suite Variable    ${module_id}    ${output.module_id}
    ${mode} =    Execute Command    runagent -m ${module_id} stat -c %a database.env
    Should Be Equal    ${mode}    600

Check the fresh configuration
    ${config} =    Run task    module/${module_id}/get-configuration    {}
    Should Be Equal    ${config['admin_username']}    ${EMPTY}
    Should Not Be True    ${config['smtp_enabled']}
    Set Suite Variable    ${smarthost_available}    ${config['smarthost_available']}

Check a weak admin password is rejected
    ${output} =    Run task    module/${module_id}/configure-module
    ...    {"host":"${kuma_host}","lets_encrypt":false,"admin_username":"admin","admin_password":"abcdefgh"}
    ...    decode_json=${FALSE}    rc_expected=2
    Should Contain    ${output}    admin_password_too_weak

Check if kuma can be configured
    Run task    module/${module_id}/configure-module
    ...    {"host":"${kuma_host}","lets_encrypt":false,"admin_username":"admin","admin_password":"${kuma_password}"}
    ${config} =    Run task    module/${module_id}/get-configuration    {}
    Should Be Equal    ${config['host']}    ${kuma_host}
    Should Be Equal    ${config['admin_username']}    admin

Check services run on MariaDB
    ${status} =    Run task    module/${module_id}/get-status    null
    FOR    ${service}    IN    @{status['services']}
        Should Be True    ${service['active']}    ${service['name']} is not active
    END
    ${users} =    SQL    select username from user
    Should Be Equal    ${users}    admin
    ${rc} =    Execute Command    journalctl _UID=$(id -u ${module_id}) | grep -q "Database Type: mariadb"
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0

Check if kuma works as expected
    Wait Until Keyword Succeeds    30 times    5 seconds    Uptime Kuma answers
    # HTTP to HTTPS redirection is always on
    ${code} =    HTTP code    http://127.0.0.1/
    Should Match Regexp    ${code}    ^30[178]$

Check the admin is created only once
    Run task    module/${module_id}/configure-module
    ...    {"host":"${kuma_host}","lets_encrypt":false,"admin_username":"other","admin_password":"Other,Pass-1234"}
    ${users} =    SQL    select username from user
    Should Be Equal    ${users}    admin

Check the smarthost notification follows the cluster smarthost
    Run task    module/${module_id}/configure-module
    ...    {"host":"${kuma_host}","lets_encrypt":false,"smtp_enabled":true,"notification_emails":["alerts@dom.test"]}
    ${count} =    SQL    select count(*) from notification where name='NethServer smarthost'
    ${expected} =    Set Variable If    ${smarthost_available}    1    0
    Should Be Equal    ${count}    ${expected}

Check a partial configuration keeps the SMTP settings
    Run task    module/${module_id}/configure-module    {"host":"${kuma_host}"}
    ${config} =    Run task    module/${module_id}/get-configuration    {}
    Should Be True    ${config['smtp_enabled']}
    Should Be Equal    ${config['notification_emails']}    ${{ ["alerts@dom.test"] }}

Check the backup dump
    ${rc} =    Execute Command    runagent -m ${module_id} module-dump-state
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0
    ${mode} =    Execute Command    runagent -m ${module_id} stat -c %a kuma.sql
    Should Be Equal    ${mode}    600
    ${rc} =    Execute Command    runagent -m ${module_id} grep -q "CREATE TABLE \\`user\\`" kuma.sql
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0
    Execute Command    runagent -m ${module_id} module-cleanup-state
    ${rc} =    Execute Command    runagent -m ${module_id} test -e kuma.sql
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  1

Check if kuma can be cloned
    ${output} =    Run task    cluster/clone-module    {"module":"${module_id}","node":1,"replace":false}
    ${clone_id} =    Set Variable    ${output['module_id']}
    ${config} =    Run task    module/${clone_id}/get-configuration    {}
    Should Be Equal    ${config['host']}    ${kuma_host}
    Should Be Equal    ${config['admin_username']}    admin
    ${users} =    SQL    select count(*) from user    module=${clone_id}
    Should Be Equal    ${users}    1
    ${rc} =    Execute Command    remove-module --no-preserve ${clone_id}
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0

Take screenshots
    [Tags]    ui
    Import Library    Browser
    New Browser    chromium    headless=True
    New Context    ignoreHTTPSErrors=True
    Login to cluster-admin
    Go To    https://${NODE_ADDR}/cluster-admin/#/apps/${module_id}
    Wait For Elements State    iframe >>> h2 >> text="Status"    visible    timeout=10s
    Sleep    5s
    Take Screenshot    filename=${OUTPUT DIR}/browser/screenshot/1._Status.png
    Go To    https://${NODE_ADDR}/cluster-admin/#/apps/${module_id}?page=settings
    Wait For Elements State    iframe >>> h2 >> text="Settings"    visible    timeout=10s
    Sleep    5s
    Take Screenshot    filename=${OUTPUT DIR}/browser/screenshot/2._Settings.png
    Close Browser

Check if kuma is removed correctly
    ${rc} =    Execute Command    remove-module --no-preserve ${module_id}
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0
