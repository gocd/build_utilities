#!/usr/bin/env ruby

require 'aws-sdk'

s3_client = Aws::S3::Client.new(region: 'us-east-1')
last_key = nil
objects = []

begin
  new_objects = s3_client.list_objects_v2(bucket:ENV["S3_BUCKET"], continuation_token: last_key)
  objects_to_be_deleted = new_objects.to_h[:contents].map do |object|
    if !object[:key].include?("robots") && object[:last_modified].strftime('%Y-%m-%d') <= (Date.today() - 30).strftime('%Y-%m-%d')
      {key: object[:key]}
    end
  end
  objects << objects_to_be_deleted.compact
  last_key = new_objects.to_h[:next_continuation_token]
end while !new_objects.to_h[:next_continuation_token].nil?
p "Empyting bucket now"
objects.each do |list_of_objects_to_be_deleted|
  unless list_of_objects_to_be_deleted.empty?
    s3_client.delete_objects(bucket: ENV["S3_BUCKET"], delete: { objects: list_of_objects_to_be_deleted })
  end
end
p "Done."
