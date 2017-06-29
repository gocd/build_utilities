#!/usr/bin/env ruby

require 'net/http'
require 'uri'
require 'base64'
require 'json'
require 'tempfile'

def validate(key)
  value = ENV[key].to_s.strip
  raise "Please specify #{key}" if value == ''
  value
end

version_to_release = validate('VERSION_TO_RELEASE')
template = validate('TEMPLATE')
gocd_group = validate('GROUP')
repo = validate('REPO')
username = validate('USERNAME')
password = validate('PASSWORD')

task :default do
  repo_url = "https://mirrors.gocd.org/git/gocd/#{repo}"
  pipeline_name = "#{repo}-release-#{version_to_release}"

  payload = {
    group: gocd_group,
    pipeline: {
      label_template: '${COUNT}',
      name: pipeline_name,
      template: template,
      enable_pipeline_locking: false,
      materials: [
        {
          type: 'git',
          attributes: {
            url: repo_url,
            branch: "release-#{version_to_release}",
            shallow_clone: true
          }
        }
      ]
    }
  }
  sh("curl -u'#{username}:#{password}' -H 'Content-Type: application/json' -H 'Accept: application/vnd.go.cd.v4+json' 'https://build.gocd.org/go/api/admin/pipelines' -d '#{payload.to_json}'")
  sh("curl -u'#{username}:#{password}' -H 'Confirm: true' 'https://build.gocd.org/go/api/pipelines/#{pipeline_name}/unpause' -X POST")
end
