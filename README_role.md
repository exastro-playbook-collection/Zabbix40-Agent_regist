# Ansible Role: Zabbix40-Agent_regist for RHEL6/RHEL7

# Trademarks
-----------
* Linuxは、Linus Torvalds氏の米国およびその他の国における登録商標または商標です。
* RedHat、RHEL、CentOSは、Red Hat, Inc.の米国およびその他の国における登録商標または商標です。
* Windows、PowerShellは、Microsoft Corporation の米国およびその他の国における登録商標または商標です。
* Ansibleは、Red Hat, Inc.の米国およびその他の国における登録商標または商標です。
* pythonは、Python Software Foundationの登録商標または商標です。
* Zabbixは、ラトビア共和国にあるZabbix LLCの商標です。
* Oracleは、Oracle International Corporation の米国およびその他の国における登録商標または商標です。
* NECは、日本電気株式会社の登録商標または商標です。
* その他、本ロールのコード、ファイルに記載されている会社名および製品名は、各社の登録商標または商標です。

## Description
本Roleは統合監視ソフトウェア"Zabbix"において、ZabbixサーバにZabbixエージェントホストの登録を行います。<br/>
対象バージョンは以下のバージョンです。
- Zabbix 4.0


## Supports
- 管理マシン(Ansibleサーバ)
  - Linux系OS（RHEL/CentOS）
  - Ansible バージョン2.5 以上 (動作確認済み：2.5、2.6)
  - Python バージョン2.6 または 2.7

- 管理対象マシン(インストール対象マシン)
  - RHEL6 または RHEL7
  - Python 2.6以上  

## Requirements
- 管理マシン(Ansibleサーバ)
  - 管理対象マシンへroot権限でSSH接続できること
  - curlコマンドが利用可能なこと
  - ZabbixServerマシンへHTTP接続できること
- 管理対象マシン(設定対象マシン)
  - Zabbix Agentがインストールされていること
  - SELinuxが無効に設定されていること
  - iptables, firewalldが適切に設定されていること
- ZabbiServerマシン
  - Zabbix Server 4.0 がインストールされ、サービスが起動していること
  - 管理マシン(Ansibleサーバ)からZabbix APIへのHTTPアクセスを受け付けられること


## Role Variables
### Mandatory variables
実行時には、以下の変数を必ず指定します。

- ホスト登録
  * ''VAR_Zabbix40AG_serverregist'': Zabbix Serverへの登録実行 (yes|no)
    + yes の場合は、Zabbixサーバに、Zabbixエージェントのホストを登録する
    + no の場合は、登録しない
  * ''VAR_Zabbix40AG_Server''： ZabbixサーバのIPアドレス(string)


### Optional variables
以下の変数は任意で指定します。

- ホスト登録
  * ''VAR_Zabbix40AG_Hostname''： ホスト名(string, default: "{{ ansible_hostname }}")
    - デフォルト値は、Ansible設定のホスト名が設定される
  * ''VAR_Zabbix40AG_DisplayName''： ホスト表示名(string, default: "")
  * ''VAR_Zabbix40AG_HostIP''： ホストIPアドレス(string, default: "{{ ansible_host }}")
    - デフォルト値は、Ansible設定のホストアドレスが設定される
  * ''VAR_Zabbix40AG_AgentPort''： エージェントポート番号(string, default: "10050")
  * ''VAR_Zabbix40AG_SnmpPort''： SNMPポート番号(string, default: "161")
  * ''VAR_Zabbix40AG_HostGroups''： ホストが属するホストグループ(string[], default: "Linux servers")
    - 配列形式で設定可能
  * ''VAR_Zabbix40AG_Templates''： ホストへリンクするTemplate名(string[], default: "")
    - 配列形式で設定可能
  * ''VAR_Zabbix40AG_APITempPath''： Ansibleサーバ上の一次ファイル配置パス(string, default: "/tmp/zbx_api")


- Zabbixサーバ接続情報
  * ''VAR_Zabbix40AG_Username''： Zabbixサーバへのログイン名(string, default: "Admin")
  * ''VAR_Zabbix40AG_Password''： Zabbixサーバへのログインパスワード(string, default: "zabbix")
  * ''VAR_Zabbix40AG_ServerAddress''： ZabbixサーバAPIのアドレス(string, default: "http://192.168.1.1:80/zabbix/")


## Usage
1. 本Roleを用いたPlaybookを作成します。
2. 必須変数を指定します。
3. 任意変数を必要に応じて指定します。
4. Playbookを実行します。

## Example Playbook

インストールとすべての設定を行う場合は、提供した以下のRoleを"roles"ディレクトリに配置した上で、以下のようなPlaybookを作成してください。

- フォルダ構成
~~~
  - group_vars/
    ・ server1
    ・ server2
  - host_vars/
    ・ host1
    ・ host2
  - roles/
    ・ Zabbix40-Agent_install/
    ・ Zabbix40-Agent_regist/
    ・ Zabbix40-Agent_setup/
  - Zabbix40-Agent_install.yml
  - Zabbix40-Agent_regist.yml
  - Zabbix40-Agent_setup.yml
  - conf.yml
  - hosts
  - site.yml
~~~


- マスターPlaybookサンプル 「Zabbix40-Agent_regist.yml」
~~~
# Zabbix40-Agent_regist.yml
 - name: Registration to Zabbix40 Server
   hosts: all
   gather_facts: yes
   become: yes
   tags:
    - regist
   roles:
     - Zabbix40-Agent_regist
~~~


## Running Playbook
- extra-vars を利用する場合の実行例
> ansible-playbook site.yml -k -i hosts --extra-vars="@conf.yml"

- group_vars を利用する場合の実行例  
group_vars で指定したグループ名が webserver1 の場合
> ansible-playbook site.yml -k -i hosts -l webserver1

- host_vars を利用する場合の実行例  
host_vars で指定したグループ名が server1 の場合
> ansible-playbook site.yml -k -i hosts -l server1

- 本Roleのみを実行する場合は、 --tags "regist" を付け加える
> ansible-playbook site.yml -k -i hosts --extra-vars="@conf.yml" --tags "regist"

# Copyright
Copyright (c) 2018 NEC Corporation

# Author Information
NEC Corporation
