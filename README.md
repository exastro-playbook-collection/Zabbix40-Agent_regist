# Zabbix Agent 4.0 for RHEL6/RHEL7

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
本プロジェクトのリポジトリで統合監視ソフトウェアであるZabbix-agentのインストール、セットアップRoleを公開しています。  
OSSの対象バージョンは以下のバージョンとなります。  
・Zabbix 4.0  
  
対応OSは以下となります。  
・RHEL6,RHEL7  

各ロールの説明はREADME_role.mdをご参照ください。

## Supports

- 管理マシン(Ansibleサーバ)
  * Linux系OS（RHEL/CentOS）
  * Ansible バージョン 2.5 以上 (動作確認済みバージョン：2.5、2.6)
  * Python バージョン 2.6 または2.7


- 管理対象マシン(構築対象マシン)
  * Red Hat Enterprise Linux 6
  * Red Hat Enterprise Linux 7

## roles

  - Zabbix40-Agent_install  
     Zabbix Agent 4.0関連のパッケージのインストールを行うroleです。  
     提供している機能は以下です。

    * Zabbixリポジトリパッケージのインストール
    * ZabbixAgent4.0関連パッケージのインストール


  - Zabbix40-Agent_setup  
     Zabbix Agent 4.0、及び関連コンポーネントのconfigファイルへの設定を行うroleです。  
     提供している機能は以下です。

     * Zabbix Agentのconfigファイルの設定
     　　-　zabbix_agentd.conf
     * Zabbix Agentのログファイルのlogrotateの設定
     * Zabbix Agentのサービスの自動起動設定の変更
     * Zabbix Agentの再起動


  - Zabbix40-Agent_regist  
     ZabbixAgentをZabbixServerへ監視対象として登録を行うroleです。  
     提供している機能は以下です。

    * 指定されたZabbixServerへホスト登録する
    * ホスト登録時に以下の情報の登録も可能
       - Hostgroup（指定されたgroupがなければ作成）
       - 適用するTemplate（複数指定可能）


## Evidence

本ロールは、gatheringに公開されているエビデンス取得対応をしています。
各ロールにエビデンスを定義してありますので、エビデンス取得ロールを利用して設定内容のエビデンスを取得することができます。
詳しい利用方法については、gathering ロールのREADME.md等をご参照ください。

 - 定義されているエビデンス

      * roles/Zabbix40-Agent_install/vars/gathering_definition.yml  
        ・ Zabbixに関連するインストールパッケージ環境の取得  
        ・ 関連情報の取得  

   ~~~
   ---
   command:
     - cat /etc/redhat-release
     - cat /etc/selinux/config
     - getenforce
   # for RHEL6
     - service iptables status
   # for RHEL7
     - systemctl status firewalld
     - rpm -qa
     - yum repolist
     - ls -l /etc/yum.repos.d/*.repo
     - cat /etc/yum.repos.d/*.repo
     - cat /mnt/media.repo
     - ls -l /etc/zabbix/zabbix_agentd.conf
     - ls -l /etc/logrotate.d/zabbix-agent
     - ls -l /var/run/zabbix/*agent*
     - ls -l /var/log/zabbix/*agent*
     - tail -n 100 /var/log/zabbix/zabbix_agentd.log
     - ls -l /tmp
     - ls -l /root
   ~~~

      * roles/Zabbix40-Agent_setup/vars/gathering_definition.yml
        ・ 設定されるconfファイルの取得
        ・ 設定したサービスの状態

   ~~~
   ---
   command:
     - cat /etc/zabbix/zabbix_agentd.conf
     - cat /etc/logrotate.d/zabbix-agent
     - ls -l /var/log/zabbix/*agent*
     - ls -l /tmp
   # for RHEL6
     - service zabbix-agent status
     - chkconfig --list | grep zabbix
   # for RHEL7
     - systemctl status zabbix-agent
     - systemctl list-unit-files | grep zabbix
   file:
     - /var/log/zabbix/zabbix_agentd.log
   ~~~

      * roles/Zabbix40-Agent_regist/vars/gathering_definition.yml
         ・ 登録後のZabbix Agentのログ

   ~~~
   ---
   command:
     - ls -l /var/log/zabbix/*agent*
     - ls -l /tmp
   file:
     - /var/log/zabbix/zabbix_agentd.log
   ~~~


 - エビデンス取得のためのマスタPlaybook(gathering_definition.yml)の例

   ~~~
   ###  install master playbook for Evidence

   ---
    - name: evidence Zabbix40-Agent_install
      hosts: all
      become: yes
      roles:
       - role: gathering
         VAR_gathering_definition_role_path: "{{ inventory_dir }}/roles/Zabbix40-Agent_install"

    - name: evidence Zabbix40-Agent_setup
      hosts: all
      become: yes
      roles:
       - role: gathering
         VAR_gathering_definition_role_path: "{{ inventory_dir }}/roles/Zabbix40-Agent_setup"

    - name: evidence Zabbix40-Agent_regist
      hosts: all
      become: yes
      roles:
       - role: gathering
         VAR_gathering_definition_role_path: "{{ inventory_dir }}/roles/Zabbix40-Agent_regist"

   ~~~

## 備考
本プロジェクトのリポジトリで公開しているRoleにはZabbix Agentをインストールするためのリポジトリパッケージが含まれていますがZabbix Agent自身のrpmファイルは含まれません。   

# Copyright
Copyright (c) 2018 NEC Corporation

# Author Information
NEC Corporation
