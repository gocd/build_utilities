require 'open-uri'
require 'json'
require 'base64'
require 'pathname'
require 'digest'

require_relative '../../requirements.rb'

namespace :meta do
  task :verify_not_already_uploaded do
    bin_dir           = binariesSourceDir
    upload_bucket     = s3Bucket

    version_info = JSON.parse(open("#{bin_dir.join('meta', 'version.json')}", 'r').read)
    full_version = version_info['go_full_version']

    sh("aws s3 ls s3://#{upload_bucket}/binaries/#{full_version}/") do |ok, _res|
      if ok
        fail 'It appears that the version already exists on the s3 bucket node!'
      end
    end
  end
  task :upload => [:verify_not_already_uploaded] do
    upload_bucket = s3Bucket
    update_bucket = s3UpdateCheckBucket
    bin_dir       = binariesSourceDir

    target_dir       = Pathname.new(ENV['TARGET_DIRECTORY']).expand_path
    version_info     = JSON.parse(open("#{bin_dir.join('meta', 'version.json')}", 'r').read)
    full_version     = version_info['go_full_version']

    # copy the binaries
    sh("aws s3 sync #{target_dir.join('upload', 'binaries')} s3://#{upload_bucket}/binaries/#{full_version} --acl public-read --cache-control 'max-age=31536000'")

    # copy the latest-version in a specific dir
    sh("AWS_PROFILE=update aws s3 cp #{target_dir.join('upload', 'update-check', 'latest.json')} s3://#{update_bucket}/channels/experimental/latest-#{full_version}.json --cache-control 'max-age=600' --acl public-read")

    # copy the top level latest-version in a specific dir
    sh("AWS_PROFILE=update aws s3 cp #{target_dir.join('upload', 'update-check', 'latest.json')} s3://#{update_bucket}/channels/experimental/latest.json --cache-control 'max-age=300' --acl public-read")
  end
end