#!/bin/bash

ZBX_TARGET_IP="$1"
ZBX_SERVER_ADDR="$2"
ZBX_API_TEMP="$3"
ZBX_TEMP_CNT="$4"

RETVAL=
parse_json() {
    RETVAL=`echo $1 | \
                sed -e 's/[{}]/''/g' -e 's/\[/','/g' -e 's/]/','/g' | \
                awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}'`
}

I_RETVAL=
parse_json_get_element_internal() {
    I_RETVAL=`echo $1 | \
                sed -e 's/[{}]/''/g' -e 's/\[/','/g' -e 's/]/','/g' | \
                awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | \
                grep $2 | \
                cut -d '"' -f$3`
}

E_RETVAL=
parse_json_get_element_error() {
    E_RETVAL=`echo $1 | \
                sed -e 's/[{}]/''/g' -e 's/\[/','/g' -e 's/]/','/g' | \
                awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | \
                grep $2 | \
                cut -d ':' -f$3`
}

parse_json_get_element() {
    parse_json_get_element_internal "$1" "$2" 4
    RETVAL="$I_RETVAL"
}

ERROR_RETVAL=
check_error() {
    if [ -z "$1" ]; then
        echo "Failed to get response from Zabbix"
        exit 1
    fi

    parse_json_get_element_internal "$1" "error" 5
    ERROR_RETVAL="$I_RETVAL"

    if [ -n "$ERROR_RETVAL" ]; then
        parse_json "$1"
        parse_json_get_element_error "$1" "data" 2
        ERROR_RETVAL="$E_RETVAL"
    fi
}

ZBX_AUTH_TOKEN=
get_zbx_auth_token() {
    ZBX_AUTH_JSON="`cat "$ZBX_API_TEMP"/login.$ZBX_TARGET_IP.json`"

    ZBX_AUTH_RET=`curl -v -s -H "Content-Type: application/json-rpc" \
                  -d "$ZBX_AUTH_JSON" \
                  "$ZBX_SERVER_ADDR"/api_jsonrpc.php 2> /dev/null`

    check_error "$ZBX_AUTH_RET"
    if [ -n "$ERROR_RETVAL" ]; then
        echo "$ERROR_RETVAL"
        exit 1
    fi

    parse_json_get_element "$ZBX_AUTH_RET" "result"
    ZBX_AUTH_TOKEN="$RETVAL"
}

ZBX_ADD_GROUP_ID=
get_zbx_add_group() {
    ZBX_ADD_GROUP_ID=

    files=""$ZBX_API_TEMP"/create_hostgroup.*.$ZBX_TARGET_IP.json"
    for f in $files; do
        if [ ! -e "$f" ]; then
            sleep 1
            break
        fi

        ZBX_ADD_GROUP_JSON="`cat "$f"`"
        ZBX_ADD_GROUP_JSON=`echo "$ZBX_ADD_GROUP_JSON" | sed -e "s/ZBX_AUTH_TOKEN/$ZBX_AUTH_TOKEN/g"`

        ZBX_ADD_GROUP_RET=`curl -v -s -H "Content-Type: application/json-rpc" \
                           -d "$ZBX_ADD_GROUP_JSON" \
                           "$ZBX_SERVER_ADDR"/api_jsonrpc.php 2> /dev/null`

        check_error "$ZBX_ADD_GROUP_RET"
        if [ -n "$ERROR_RETVAL" ]; then
            # Error handling with "already exists" error as exception
            local TMP=`echo "$ERROR_RETVAL" | grep -vE "^\"Host group .+ already exists\.\"$"`
            if [ -n "$TMP" ]; then
                echo "$ERROR_RETVAL"
                zbx_logout
                exit 1
            fi
        fi

        parse_json_get_element "$ZBX_GROUP_RET" "groupid"
        ZBX_ADD_GROUP_ID="$ZBX_ADD_GROUP_ID $RETVAL"
    done
}

ZBX_GROUP_ID=
get_zbx_group_id() {
    ZBX_GROUP_JSON="`cat "$ZBX_API_TEMP"/hostgroup.$ZBX_TARGET_IP.json`"
    ZBX_GROUP_JSON=`echo "$ZBX_GROUP_JSON" | sed -e "s/ZBX_AUTH_TOKEN/$ZBX_AUTH_TOKEN/g"`

#    echo "$ZBX_GROUP_JSON" >/tmp/a
    ZBX_GROUP_RET=`curl -v -s -H "Content-Type: application/json-rpc" \
                   -d "$ZBX_GROUP_JSON" \
                   "$ZBX_SERVER_ADDR"/api_jsonrpc.php 2> /dev/null`

    check_error "$ZBX_GROUP_RET"
    if [ -n "$ERROR_RETVAL" ]; then
        echo "$ERROR_RETVAL"
        zbx_logout
        exit 1
    fi

    parse_json_get_element "$ZBX_GROUP_RET" "groupid"
    ZBX_GROUP_ID="$RETVAL"
}

ZBX_TEMPLATE_ID=
get_zbx_template_id() {
    ZBX_TID_CNT=0
    if [ ! $ZBX_TEMP_CNT -eq 0 ]; then
        ZBX_TEMPLATE_JSON="`cat "$ZBX_API_TEMP"/template.$ZBX_TARGET_IP.json`"
        ZBX_TEMPLATE_JSON=`echo "$ZBX_TEMPLATE_JSON" | sed -e "s/ZBX_AUTH_TOKEN/$ZBX_AUTH_TOKEN/g"`

        ZBX_TEMPLATE_RET=`curl -v -s -H "Content-Type: application/json-rpc" \
                          -d "$ZBX_TEMPLATE_JSON" \
                          "$ZBX_SERVER_ADDR"/api_jsonrpc.php 2> /dev/null`

        check_error "$ZBX_TEMPLATE_RET"
        if [ -n "$ERROR_RETVAL" ]; then
            echo "$ERROR_RETVAL"
            zbx_logout
            exit 1
        fi

        parse_json_get_element "$ZBX_TEMPLATE_RET" "templateid"
        ZBX_TEMPLATE_ID="$RETVAL"
        ZBX_TID_CNT=`echo "$ZBX_TEMPLATE_ID" | wc -l`
    fi

    if [ ! "$ZBX_TID_CNT" -eq "$ZBX_TEMP_CNT" ]; then
        echo "One or more designated template is either duplicated or not registered."
        exit 1
    fi
}

ZBX_HOST_ID=
add_zbx_host() {
    ZBX_ADD_HOST_JSON="`cat "$ZBX_API_TEMP"/add_host.$ZBX_TARGET_IP.json`"
    ZBX_ADD_HOST_JSON=`echo "$ZBX_ADD_HOST_JSON" | sed -e "s/ZBX_AUTH_TOKEN/$ZBX_AUTH_TOKEN/g"`

    LAST_GID=
    GID_CNT=0
    for GID in `echo $ZBX_GROUP_ID`
    do
        ZBX_ADD_HOST_JSON=`echo "$ZBX_ADD_HOST_JSON" | sed -e "s/GROUP_ID_$GID_CNT/$GID/g"`
        GID_CNT="$((GID_CNT+1))"
        LAST_GID="$GID"
    done
    # fix against double registration of same group name.
    ZBX_ADD_HOST_JSON=`echo "$ZBX_ADD_HOST_JSON" | sed -e "s/GROUP_ID_[0-9]*/$LAST_GID/g"`

    LAST_TID=
    TID_CNT=0
    for TID in `echo $ZBX_TEMPLATE_ID`
    do
        ZBX_ADD_HOST_JSON=`echo "$ZBX_ADD_HOST_JSON" | sed -e "s/TEMPLATE_ID_$TID_CNT/$TID/g"`
        TID_CNT="$((TID_CNT+1))"
        LAST_TID="$TID"
    done
    # fix against double registration of same template name.
    ZBX_ADD_HOST_JSON=`echo "$ZBX_ADD_HOST_JSON" | sed -e "s/TEMPLATE_ID_[0-9]*/$LAST_TID/g"`

    #echo "$ZBX_ADD_HOST_JSON"

    ZBX_ADD_HOST_RET=`curl -v -s -H "Content-Type: application/json-rpc" \
                      -d "$ZBX_ADD_HOST_JSON" \
                      "$ZBX_SERVER_ADDR"/api_jsonrpc.php 2> /dev/null`

    check_error "$ZBX_ADD_HOST_RET"
    if [ -n "$ERROR_RETVAL" ]; then
        # Error handling with "already exists" error as exception
        local TMP=`echo "$ERROR_RETVAL" | grep -vE "^\"Host with the same name .+ already exists\.\"$"`
        if [ -n "$TMP" ]; then
            echo "$ERROR_RETVAL"
            zbx_logout
            exit 1
        fi
    fi

    parse_json "$ZBX_ADD_HOST_RET"
    ZBX_HOST_ID="$RETVAL"
}

# Logging out auth token
zbx_logout() {
    ZBX_LOGOUT_JSON="`cat "$ZBX_API_TEMP"/logout.$ZBX_TARGET_IP.json`"
    ZBX_LOGOUT_JSON=`echo "$ZBX_LOGOUT_JSON" | sed -e "s/ZBX_AUTH_TOKEN/$ZBX_AUTH_TOKEN/g"`

    ZBX_LOGOUT_RET=`curl -v -s -H "Content-Type: application/json-rpc" \
                    -d "$ZBX_LOGOUT_JSON" \
                    "$ZBX_SERVER_ADDR"/api_jsonrpc.php 2> /dev/null`

    check_error "$ZBX_LOGOUT_RET"
    if [ -n "$ERROR_RETVAL" ]; then
        echo "$ERROR_RETVAL"
        exit 1
    fi
}

get_zbx_group() {
    get_zbx_add_group

    local GID_TIMES=0
    if [ "$GID_TIMES" -lt 5 ]; then
        get_zbx_group_id
        GID_TIMES="$((GID_TIMES+1))"

        if [ -n "$ZBX_GROUP_ID" ]; then
            return
        else
            sleep $GID_TIMES
        fi
    fi
}

get_zbx_auth_token
get_zbx_group
get_zbx_template_id
add_zbx_host
zbx_logout

