require "unifi/api/version"
require "httparty"

module Unifi
  module Api
    class APIError < Exception
    end

    class Controller
      attr_accessor :host, :username, :password, :port, :version, :site_id, :cookies, :is_unifi_os

      def initialize(host, username, password, port=8443, version='v2', site_id='default', is_unifi_os=false)
        @host = host
        @port = port
        @version = version
        @username = username
        @password = password
        @site_id = site_id
        login
      end

      def url
        "https://#{host}:#{port}/"
      end

      def api_url
        v2_path = 'api/'
        v3_path = "api/s/#{@site_id}/"
        api_path = %w(v3 v4).include?(@version) ? v3_path : v2_path
        "#{url}#{api_path}"
      end

      def login_url
        if is_unifi_os
          "#{url}api/auth/login"
        else
          if @version == 'v4'
            "#{url}api/login"
          else
            "#{url}login"
          end
        end
      end

      def get_alerts
        read "#{api_url}list/alarm"
      end

      def get_alerts_unarchived
        params ={'json': {'_sort': '-time', 'archived': false}}
        read "#{api_url}list/alarm", params
      end

      def get_statistics_last_24h
        get_statistics_24h(Time.now)
      end

      def get_statistics_24h(endtime)
        params = {
          'attrs': ["wlan_bytes", "wlan-num_sta", "time"],
          'start': "#{(endtime - 1.day).to_i * 1000}",
          'end': "#{(endtime - 1.hour).to_i * 1000}"
        }
        return read "#{api_url}stat/report/hourly.site", params, :post
      end

      def get_events
        read "#{api_url}stat/event"
      end

      def get_aps
        params = {'_depth': 2, 'test': 0}
        read "#{api_url}stat/device", params
      end

      def get_clients
        read "#{api_url}stat/sta"
      end

      def get_users
        read "#{api_url}list/user"
      end

      def get_user(user_mac)
        read "#{api_url}stat/user/#{user_mac}"
      end

      def get_guests(within=24)
        params = {'within': within}
        read "#{api_url}stat/guest", params
      end

      def get_user_groups
        read "#{api_url}list/usergroup"
      end

      def get_wlan_conf
        read "#{api_url}list/wlanconf"
      end

      def block_client(mac)
        mac_cmd mac, 'block-sta'
      end

      def unblock_client(mac)
        mac_cmd mac, 'unblock-sta'
      end

      def disconnect_client(mac)
        mac_cmd mac, 'kick-sta'
      end

      def restart_ap(mac)
        mac_cmd mac, 'restart', 'devmgr'
      end

      def restart_ap_name(name=nil)
        if name.nil?
          raise APIError("#{name} is not valid name")
        end
        get_aps.each do |ap|
          if ap['state'] == 1 and ap['name'] == name
            restart_ap(ap['mac'])
          end
        end
      end

      def archive_all_alerts
        params = {'cmd': 'archive-all-alarms'}
        read "#{api_url}cmd/evtmgr", params, :post
      end

      def create_backup
        params = {'cmd': 'backup'}
        result = read "#{api_url}cmd/system", params, :post
        result[0]['url']
      end

      def get_backup(target_file='unifi-backup.unf')
        download_path = create_backup

        unifi_archive = read("#{url}#{download_path}", nil, :post)
        File.open(target_file, "wb") do |f|
          f.write(unifi_archive)
        end
      end

      def authorize_guest(guest_mac, minutes, up_bandwidth=nil, down_bandwidth=nil, byte_quota=nil, ap_mac=nil)
        cmd = 'authorize-guest'
        params = {'mac': guest_mac, 'minutes': minutes}

        if up_bandwidth
           params['up'] = up_bandwidth
        end
        if down_bandwidth
           params['down'] = down_bandwidth
        end
        if byte_quota
           params['bytes'] = byte_quota
        end
        if ap_mac && @version != 'v2'
           params['ap_mac'] = ap_mac
        end

        run_command cmd, params
      end

      def unauthorize_guest(guest_mac)
        cmd = 'unauthorize-guest'
        params = {'mac': guest_mac}
        run_command(cmd, params)
      end

      def login
        params = {'username': @username, 'password': @password}
        params['login'] = 'login' unless version == 'v4'

        options = {
          verify: false,
          body: params.to_json,
          headers: {'Content-Type': 'application/json','Accept': 'application/json'}
        }

        res = HTTParty.post(login_url, options)
        if res.code == 404
          is_unifi_os = true
          res = HTTParty.post(login_url, options)
        end

        @cookies = res.headers['set-cookie']
        get_data res
      end

      def logout
        @cookies = nil
      end

      private

      def read(url, params=nil, method=:get)
        options = {
          verify: false,
          body: params.to_json,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Cookie': @cookies || ''
          }
        }

        if method == :get
          get_data HTTParty.get(url, options)
        elsif method == :post
          get_data HTTParty.post(url, options)
        end
      end

      def get_data(res)
        obj = res.parsed_response
        if obj && obj['meta'] && obj['meta']['rc'] != 'ok'
          raise APIError, obj['meta']['msg']
        end
        if obj && obj['data']
          return obj['data']
        end
        obj
      end

      def run_command(command, params={}, mgr='stamgr')
          params['cmd'] =  command
          read "#{api_url}cmd/#{mgr}", params, :post
      end

      def mac_cmd(target_mac, command, mgr='stamgr')
          params = {'mac': target_mac}
          run_command(command, params, mgr)
      end

    end
  end
end
