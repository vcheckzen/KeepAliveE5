#!/usr/bin/env bash

set -e

APP_NAME='E5_ALIVE'
PERMISSIONS_FILE='./required-resource-accesses.json'
CONFIG_PATH='../config'

jq() {
    echo -n "$1" | python3 -c "import sys,json; print(json.load(sys.stdin)$2)"
}

es() {
    echo -n "$1" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read()))"
}

register_app() {
    config_file="$CONFIG_PATH/app$1.json"
    reply_uri="http://localhost:1000$1/"
    username="$2"
    password="$3"

    # separate multiple accounts
    export AZURE_CONFIG_DIR="/tmp/az-cli/$1"
    mkdir -p "$AZURE_CONFIG_DIR"
    # clear account if exists
    # az account clear

    # login
    # ret="$(az login \
    #     --allow-no-subscriptions \
    #     -u "$username" \
    #     -p "$password" 2>/dev/null)"
    # tenant_id="$(jq "$ret" "[0]['tenantId']")"
    az login \
        --allow-no-subscriptions \
        -u "$username" \
        -p "$password" || {
            echo "登录失败，账号或密码错误，或未关闭多因素认证（安全默认值），请进一步阅读英文日志"
            exit 1
        }

    # delete the existing app
    ret=$(az ad app list --display-name "$APP_NAME")
    [ "$ret" != "[]" ] && {
        az ad app delete --id "$(jq "$ret" "[0]['appId']")"
    }

    # create a new app
    # --identifier-uris api://e5.app \
    ret="$(az ad app create \
        --display-name "$APP_NAME" \
        --reply-urls "$reply_uri" \
        --available-to-other-tenants true \
        --required-resource-accesses "@$PERMISSIONS_FILE")"

    app_id="$(jq "$ret" "['appId']")"
    user_id="$(jq "$(az ad user list)" "[0]['objectId']")"

    # wait azure system to refresh
    sleep 20

    # set owner
    az ad app owner add \
        --id "$app_id" \
        --owner-object-id "$user_id"

    # grant admin consent
    az ad app permission admin-consent --id "$app_id"

    # generate client secret
    ret="$(az ad app credential reset \
        --id "$app_id" \
        --years 100)"
    client_secret="$(jq "$ret" "['password']")"

    # wait azure system to refresh
    sleep 60

    # save app details
    cat >"$config_file" <<EOF
{
    "username": "$username",
    "password": $(es $password),
    "client_id": "$app_id",
    "client_secret": "$client_secret",
    "redirect_uri": "$reply_uri"
}
EOF

    node server.js "$config_file" &
    node client.js "$config_file"
}

[ "$USER" ] && [ "$PASSWD" ] && {
    # install cli
    [ "$(command -v az)" ] && sudo apt remove azure-cli -y && sudo apt autoremove -y
    pip3 install azure-cli==2.30.0
    
    rm -rf "$CONFIG_PATH"
    mkdir -p "$CONFIG_PATH"

    mapfile -t users < <(echo -e "$USER")
    mapfile -t passwords < <(echo -e "$PASSWD")

    for ((i = 0; i < "${#users[@]}"; i++)); do
        register_app "$i" "${users[$i]}" "${passwords[$i]}" &
    done

    wait
    exit
}

echo "未设置账号密码，无法执行应用注册"
exit 1
