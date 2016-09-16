#!/usr/bin/env ruby

require 'rubygems'
require 'rake'
%w(rake rake/file_utils).each do |f|
  begin
    require f
  rescue LoadError => e
    puts "Unable to require #{f}, continuing"
  end
end

include FileUtils

current_core_commit=''
pipeline_counter=''
stage_counter=''

cd("../gocd/core") do
  current_core_commit=%x[git log -1 --format=%H].strip
  puts "current core commit:#{current_core_commit}"
end

cd("../gocd_build_map") do
  commit_to_build_mapping_cmd="grep '#{current_core_commit}' commit_build_map | tail -n 1"
  puts "Get mapping : [#{commit_to_build_mapping_cmd}]"
  commit_to_build_mapping=%x[#{commit_to_build_mapping_cmd}].strip
  if commit_to_build_mapping.nil? || commit_to_build_mapping.empty?
    puts "Did not find mapping build for #{current_core_commit}"
    exit 1
  end
  puts "Mapping found: [#{commit_to_build_mapping}]"
  pipeline_counter = commit_to_build_mapping.split(':')[1].split('/')[0]
  stage_counter = commit_to_build_mapping.split(':')[1].split('/')[1]
  puts "pipeline counter:#{pipeline_counter} stage counter:#{stage_counter}"
end

rm_rf 'zip'
mkdir_p 'zip'

require 'open-uri'
require 'json'

urls = JSON.parse(open("#{ENV['GOCD_BUILD_PACKAGE']}/#{pipeline_counter}/dist/#{stage_counter}/dist/dist/zip.json", 'r', http_basic_authentication: [ENV['GOCD_USER'], ENV['GOCD_PASSWORD']]).read).collect {|f| f['url']}

cd 'zip' do
  urls.each do |url|
    sh("curl --silent --fail --user #{ENV['GOCD_USER']}:#{ENV['GOCD_PASSWORD']} #{url} -O")
  end
end
