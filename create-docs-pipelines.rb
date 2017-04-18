#!/usr/bin/env ruby

if File.basename($PROGRAM_NAME) != 'rake'
  require 'shellwords'
  puts "bundle exec rake -f #{Shellwords.escape($PROGRAM_NAME)} #{Shellwords.shelljoin(ARGV)}"
  exec "bundle exec rake -f #{Shellwords.escape($PROGRAM_NAME)} #{Shellwords.shelljoin(ARGV)}"
end

require 'representable/json'
require 'rest-client'
require_relative 'helpers/pipeline_representers'
require 'base64'

def validate(key)
  value = ENV[key].to_s.strip
  fail "Please specify #{key}" if value == ''
  value
end

version_to_release = validate('VERSION_TO_RELEASE')
template = validate('TEMPLATE')
gocd_group = validate('GROUP')
repo = validate('REPO')
username = validate('USERNAME')
password = validate('PASSWORD')

task :default do

  include Representers
  Attributes = Struct.new(:url, :destination, :filter, :invert_filter, :name, :auto_update, :branch, :submodule_folder, :shallow_clone)
  Materials = Struct.new(:type, :attributes)
  Pipeline = Struct.new(:label_template, :name, :template, :enable_pipeline_locking, :parameters, :environment_variables, :materials, :stages, :tracking_tool, :timer)
  Group = Struct.new(:group, :pipeline)

  attributes = Attributes.new("https://mirrors.gocd.io/git/gocd/#{repo}", nil, nil, false, nil, true, "#{version_to_release}", nil, true)
  materials = Materials.new('git', attributes)
  pipeline = Pipeline.new("${COUNT}", "#{repo}-#{version_to_release}", template, false, [], [], [materials], nil, nil, nil)
  pipeline_obj = Group.new(gocd_group, pipeline)
  url = 'https://build.go.cd/go/api/admin/pipelines'
  payload = PipelineRepresenter.new(pipeline_obj).to_json
  $auth = 'Basic ' + Base64.encode64( "#{username}:#{password}").chomp
  RestClient.post(url, payload, headers = {:accept => 'application/vnd.go.cd.v4+json', :content_type => 'application/json', :authorization => $auth})

end
