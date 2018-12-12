#!/usr/bin/env ruby

# Usage:
# VERSION=x.x.x AWS_ACCESS_KEY_ID=access-key-id AWS_SECRET_ACCESS_KEY=secret-access-key \
#   S3_ACCESS_KEY_ID=s3-access-key-id S3_SECRET_ACCESS_KEY=s3_secret-access-key S3_BUCKET=foo \
#   DOCKERHUB_USERNAME=username DOCKERHUB_PASSWORD=password DOCKERHUB_ORG=org bundle exec rake -f update_cloud_images.rb

if File.basename($0) != "rake"
  require 'shellwords'
  puts "bundle exec rake -f #{Shellwords.escape($0)} #{Shellwords.shelljoin(ARGV)}"
  exec "bundle exec rake -f #{Shellwords.escape($0)} #{Shellwords.shelljoin(ARGV)}"
end

$stdout.sync = true
$stderr.sync = true

require 'aws-sdk'
require 'json'
require 'rest-client'

def env(key)
  value = ENV[key].to_s.strip
  fail "Please specify #{key}" if value == ''
  value
end

s3_bucket = env('S3_BUCKET')
s3_access_key_id = env('S3_ACCESS_KEY_ID')
s3_secret_access_key = env('S3_SECRET_ACCESS_KEY')
dockerhub_username = env('DOCKERHUB_USERNAME')
dockerhub_password = env('DOCKERHUB_PASSWORD')
org = env('DOCKERHUB_ORG')

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
  regions.each do |region|
    ec2_client = Aws::EC2::Client.new(region: region)
    self_owned_images = image_list(ec2_client, region, 'Server', version)
    populate_amis(amis_server, region, self_owned_images)
  end
  amis_server
end

def demo_amis(version)
  amis_demo = []
  regions = Aws.partition('aws').regions.map { |region| region.name }
  regions.each do |region|
    ec2_client = Aws::EC2::Client.new(region: region)
    self_owned_images = image_list(ec2_client, region, 'Demo', version)
    populate_amis(amis_demo, region, self_owned_images)
  end
  amis_demo
end

def upload_to_s3(s3_bucket, s3_client)
  s3_client.put_object({acl: "public-read",
                        body: File.read('cloud.json'),
                        bucket: s3_bucket,
                        cache_control: "max-age=600",
                        content_type: 'application/json',
                        content_md5: Digest::MD5.file('cloud.json').base64digest,
                        key: 'cloud.json'
                       })
end

def docker_agents(dockerhub_username, dockerhub_password, org)
  login = RestClient.post('https://hub.docker.com/v2/users/login/', {username: dockerhub_username, password: dockerhub_password}.to_json, {:accept => 'application/json', :content_type => 'application/json'})
  token = JSON.parse(login)['token']

  response = RestClient.get("https://hub.docker.com/v2/repositories/#{org}/?page_size=50", {:accept => 'application/json', :Authorization => "JWT #{token}"})
  all_repos = JSON.parse(response)

  agents = all_repos['results'].map do |repo|
    {image_name: repo['name']} if (repo['name'].start_with?('gocd-agent-') && repo['name'] != 'gocd-agent-deprecated')
  end
  agents.compact
end

task :default do
  release_time = Time.now.utc
  cloud_images_for_version = {
    'go_version'            => version,
    'release_time_readable' => release_time.xmlschema,
    'release_time'          => release_time.to_i,
    'server_amis'           => server_amis(version),
    'demo_amis'             => demo_amis(version),
    'server_docker'         => [{'image_name' => 'gocd-server'}],
    'agents_docker'         => docker_agents(dockerhub_username, dockerhub_password, org)
  }

  s3_client = Aws::S3::Client.new(region: 'us-east-1', credentials: Aws::Credentials.new(s3_access_key_id, s3_secret_access_key))
  begin
  response = s3_client.get_object(bucket: s3_bucket, key: 'cloud.json')
  rescue Aws::S3::Errors::NoSuchKey
    File.open('cloud.json', 'w'){|f| f.write([cloud_images_for_version].to_json)}
    puts "Creating #{s3_bucket}/cloud.json"
    upload_to_s3(s3_bucket, s3_client)
  end
  unless response.nil?
    cloud_images_from_bucket = JSON.parse(response.body.string)
    cloud_images_from_bucket.delete_if {|hash| hash['go_version'] == version}
    cloud_images_from_bucket << cloud_images_for_version
    to_be_uploaded = cloud_images_from_bucket.sort_by { |hash| hash['go_version']}
    File.open('cloud.json', 'w'){|f| f.write(to_be_uploaded.to_json)}
    puts "Uploading cloud.json to #{s3_bucket}/cloud.json"
    upload_to_s3(s3_bucket, s3_client)
  end
end
