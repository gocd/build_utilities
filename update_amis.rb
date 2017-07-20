#!/usr/bin/env ruby

if File.basename($0) != "rake"
  require 'shellwords'
  puts "bundle exec rake -f #{Shellwords.escape($0)} #{Shellwords.shelljoin(ARGV)}"
  exec "bundle exec rake -f #{Shellwords.escape($0)} #{Shellwords.shelljoin(ARGV)}"
end

$stdout.sync = true
$stderr.sync = true

require 'aws-sdk'
require 'json'

def env(key)
  value = ENV[key].to_s.strip
  fail "Please specify #{key}" if value == ''
  value
end

s3_bucket = env('S3_BUCKET')
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

def upload_to_s3(s3_bucket, s3_client)
  s3_client.put_object({acl: "public-read",
                        body: File.read('amis.json'),
                        bucket: s3_bucket,
                        cache_control: "max-age=600",
                        content_type: 'application/json',
                        content_md5: Digest::MD5.file('amis.json').base64digest,
                        key: 'amis.json'
                       })
end

task :default do
  all_amis = {'go_version' => version, 'server_amis' => server_amis(version), 'demo_amis' => demo_ami(version)}
  s3_client = Aws::S3::Client.new(region: 'us-east-1')
  begin
  response = s3_client.get_object(bucket: s3_bucket, key: 'amis.json')
  rescue Aws::S3::Errors::NoSuchKey
    File.open('amis.json', 'w'){|f| f.write([all_amis].to_json)}
    puts "Creating #{s3_bucket}/amis.json"
    upload_to_s3(s3_bucket, s3_client)
  end
  unless response.nil?
    amis_from_bucket = JSON.parse(response.body.string)
    amis_from_bucket.delete_if {|hash| hash['go_version'] == version}
    amis_from_bucket << all_amis
    to_be_uploaded = amis_from_bucket.sort_by { |hash| hash['go_version']}
    File.open('amis.json', 'w'){|f| f.write(to_be_uploaded.to_json)}
    puts "Uploading amis.json to #{s3_bucket}/amis.json"
    upload_to_s3(s3_bucket, s3_client)
  end
end
