#!/usr/bin/env ruby

if File.basename($0) != "rake"
  require 'shellwords'
  puts "bundle exec rake -f #{Shellwords.escape($0)} #{Shellwords.shelljoin(ARGV)}"
  exec "bundle exec rake -f #{Shellwords.escape($0)} #{Shellwords.shelljoin(ARGV)}"
end

$stdout.sync = true
$stderr.sync = true

require 'aws-sdk'
require 'yaml'

def env(key)
  value = ENV[key].to_s.strip
  fail "Please specify #{key}" if value == ''
  value
end

repo_url = env('REPO_URL')
version = env('VERSION')

def image_list(ec2_client, region, type, version)
  ec2_client.describe_images({owners: ["self"],
                              filters: [
                                  {
                                      name: "tag:GoCD-Version",
                                      values: ["#{version}"]
                                  },
                                  {
                                      name: "tag:Name",
                                      values: ["GoCD #{type} #{version}"]
                                  },
                                  {
                                      name: "state",
                                      values: ["available"]
                                  }
                              ]})
end

def extract_details(image, region)
  {
      region: region,
      ami_id: image.image_id,
      image_name: image.name,
      href: "https://console.aws.amazon.com/ec2/home?region=#{region}#launchAmi=#{image.image_id}"
  }
end

def populate_amis(all_amis, region, self_owned_images)
  self_owned_images.images.each do |image|
    all_amis << extract_details(image, region)
  end
end

def server_amis(version)
  amis_server = []
  regions = Aws.partition('aws').regions.map { |region| region.name }
  p regions
  regions.each do |region|
    ec2_client = Aws::EC2::Client.new(region: region)
    self_owned_images = image_list(ec2_client, region, 'Server', version)
    populate_amis(amis_server, region, self_owned_images)
  end
  amis_server
end

def demo_ami(version)
  amis_demo = []
  region = 'us-east-1'
  ec2_client = Aws::EC2::Client.new(region: region)
  self_owned_images = image_list(ec2_client, region, 'Demo', version)
  populate_amis(amis_demo, region, self_owned_images)
  amis_demo
end

task :default do
  all_amis = {"#{version}": {"server": server_amis(version), "demo": demo_ami(version)}}
  all_amis_yaml = all_amis.to_yaml
  yaml_file = all_amis_yaml.gsub("---\n", '')
  p "Cloning www.go.cd"
  sh("git clone #{repo_url} website --depth 1")
  File.open("website/data/amis.yml", 'a') {|f| f.write(yaml_file) }
  cd 'website' do
    sh("git add data/amis.yml")
    sh("git commit -m 'Updated amis.yml with version #{version}'")
    sh("git push #{repo_url} master")
  end
  rm_rf 'website'
end
