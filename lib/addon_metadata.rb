require 'json'
require 'digest'

class AddonMetadata
  def initialize(addon_file_s3_parent:, metadata_full_s3_path:, version:, prefix:)
    @addon_file_s3_parent  = addon_file_s3_parent
    @metadata_full_s3_path = metadata_full_s3_path
    @version               = version
    @prefix                = prefix
  end

  def create(addon_file_local_path)
    new_addon_metadata = {
      version: @version,
      major_version: @version,
      introduced_on: DateTime.now.iso8601,
      location: "#{@addon_file_s3_parent}/#{File.basename(addon_file_local_path)}",
      checksums: {
        'md5'    => Digest::MD5.file(addon_file_local_path),
        'sha1'   => Digest::SHA1.file(addon_file_local_path),
        'sha256' => Digest::SHA256.file(addon_file_local_path),
        'sha512' => Digest::SHA512.file(addon_file_local_path)
      }
    }

    File.join(File.dirname(addon_file_local_path), "#{@prefix}_metadata.json").tap do |path|
      File.open(path, 'w+') do |f|
        f.write(JSON.pretty_generate(new_addon_metadata))
      end
    end
  end

  def append_to_existing(new_addon_metadata)
    existing_data = fetch_existing_metadata
    existing_version = existing_data.find { |datum| datum['version'] == @version }
    raise "Version already exists: #{@version} - #{existing_version}" unless existing_version.nil?

    create_combined_metadata_file
    File.open(@combined_metadata_file_location.path, 'w+') do |new_json|
      puts "Adding this information to #{@metadata_full_s3_path}:\n#{JSON.pretty_generate(new_addon_metadata).gsub(/^/, '  ')}"
      new_json.write(JSON.pretty_generate(existing_data << new_addon_metadata))
    end
  end

  def remove_version(version)
    existing_data = fetch_existing_metadata
    new_metadata_without_version = existing_data.reject { |datum| datum['version'] == version }

    create_combined_metadata_file
    File.open(@combined_metadata_file_location.path, 'w+') do |new_json|
      puts "Removing version #{version} from #{@metadata_full_s3_path}"
      new_json.write(JSON.pretty_generate(new_metadata_without_version))
    end
  end

  def upload_combined_metadata_file
    raise 'You need to create the combined metadata file first' if @combined_metadata_file_location.nil?
    sh("AWS_PROFILE=extensions aws s3 cp #{@combined_metadata_file_location.path} #{@metadata_full_s3_path}")
  end

  private

  def create_combined_metadata_file
    @combined_metadata_file_location = Tempfile.new(["#{@prefix}_combined_metadata", '.json'])
  end

  def fetch_existing_metadata
    Tempfile.open(['existing-metadata', '.json']) do |old_json|
      sh("AWS_PROFILE=extensions aws s3 cp #{@metadata_full_s3_path} #{old_json.path}")
      JSON.parse(File.read(old_json.path))
    end
  end

  def sh(command)
    puts(command)
    system(command)
  end
end
