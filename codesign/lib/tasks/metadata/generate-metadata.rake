require 'open-uri'
require 'json'
require 'base64'
require 'pathname'
require 'digest'
require 'openssl'

require_relative '../../requirements.rb'

namespace :meta do
  # Takes in following directory structure
  # └── binaries
  #   ├── deb
  #   │   └── signed
  #   │       ├── go-agent_18.10.0-7496_all.deb
  #   │       └── go-server_18.10.0-7496_all.deb
  #   ├── meta
  #   │   ├── release-notes.html
  #   │   ├── release-notes.md
  #   │   └── version.json
  #   ├── rpm
  #   │   └── signed
  #   │       ├── go-agent-18.10.0-7496.noarch.rpm
  #   │       └── go-server-18.10.0-7496.noarch.rpm
  #   └── zip
  #     └── signed
  #         ├── go-agent-18.10.0-7496.zip
  #         ├── go-agent-18.10.0-7496.zip.asc
  #         ├── go-server-18.10.0-7496.zip
  #         └── go-server-18.10.0-7496.zip.asc
  #


  allowed_os = {
      "zip" => ".zip",
      "deb" => ".deb",
      "rpm" => ".rpm",
      "win" => ".exe",
      "osx" => ".zip"
  }

  task :metadata do

    # Generates following
    #
    # └── binaries
    #   ├── ...
    #   ├── metadata.json

    require 'time'

    bin_dir = binariesSourceDir

    version_info = JSON.parse(open("#{bin_dir.join('meta', 'version.json')}", 'r').read)

    release_time = Time.now.utc

    metadata = {
        go_version:            version_info.delete('go_version'),
        go_build_number:       version_info.delete('go_build_number'),
        go_full_version:       version_info.delete('go_full_version'),
        release_time_readable: release_time.xmlschema,
        release_time:          release_time.to_i,
        git_sha:               version_info.delete('git_sha'),
        pipeline_name:         version_info.delete('pipeline_name'),
        pipeline_counter:      version_info.delete('pipeline_counter'),
        pipeline_label:        version_info.delete('pipeline_label'),
        stage_name:            version_info.delete('stage_name'),
        stage_counter:         version_info.delete('stage_counter')
    }

    bin_dir
        .children.select {|path| allowed_os.keys.include? path.basename.to_s}
        .each do |dir|
      os = dir.basename.to_s

      metadata[os] ||= {}

      os_signed_files = dir.join("signed").children

      os_signed_files.each do |each_file|
        next unless each_file.basename.extname == allowed_os[os]
        file_name = each_file.basename.to_s
        component = file_name =~ /go-server/ ? 'server' : 'agent'
        component = component + "32bit" if(file_name =~ /32bit/)

        file_contents = File.read("#{each_file}")
        checksums = {
            md5sum:    Digest::MD5.hexdigest(file_contents),
            sha1sum:   Digest::SHA1.hexdigest(file_contents),
            sha256sum: Digest::SHA256.hexdigest(file_contents),
            sha512sum: Digest::SHA512.hexdigest(file_contents)
        }

        checksums.each do |k, v|
          open("#{each_file}.#{k}", 'w') {|f| f.puts([v, file_name].join('  '))}
        end

        metadata[os][component] = checksums.merge(
            {file: "#{os}/#{each_file.basename}"})
      end
    end

    open(bin_dir.join('metadata.json'), 'w') do |f|
      f.puts(JSON.generate(metadata))
    end
  end

  task :latest_json do

    # Generates following
    #
    # └── binaries
    #   ├── ...
    #   ├── latest.json

    require 'time'

    bin_dir = binariesSourceDir
    key_dir = keyDir

    version_info = JSON.parse(open("#{bin_dir.join('meta', 'version.json')}", 'r').read)
    full_version = version_info['go_full_version']
    message = JSON.generate({
                                'latest-version' => full_version,
                                'release-time'   => Time.now.utc.xmlschema
                            })

    sub_private_key    = "#{key_dir.join('subordinate-private-key.pem')}"
    sub_private_phrase = "#{key_dir.join('subordinate-private-key-passphrase')}"
    sub_public_key     = "#{key_dir.join('subordinate-public-key.pem')}"
    sub_public_key_digest = "#{key_dir.join('subordinate-public-key-digest')}"

    digest            = OpenSSL::Digest::SHA512.new
    private_key       = OpenSSL::PKey::RSA.new(File.read(sub_private_key), File.read(sub_private_phrase))
    message_signature = Base64.encode64(private_key.sign(digest, message))

    open(bin_dir.join('latest.json'), 'w') do |f|
      f.puts(JSON.generate({
                               message:                      message,
                               message_signature:            message_signature,
                               signing_public_key:           File.read(sub_public_key),
                               signing_public_key_signature: File.read(sub_public_key_digest)
                           }))
    end
  end

  task :prepare_for_upload => [:metadata, :latest_json] do

    # Generates following
    #
    # └── target
    #   ├── upload
    #   │   └── binaries
    #   │       └── win
    #   │       └── deb
    #   │       └── rpm
    #   │       └── osx
    #   │       └── latest.json
    #   │       └── metadata.json
    #   ├── update-check
    #   │   └── latest.json

    bin_dir     = binariesSourceDir
    target_dir  = targetUploadDir

    rm_rf target_dir.join('upload', 'binaries')
    rm_rf target_dir.join('upload', 'update-check')

    mkdir_p target_dir.join('upload', 'binaries')
    mkdir_p target_dir.join('upload', 'update-check')

    bin_dir
        .children.select {|path| allowed_os.keys.include? path.basename.to_s}
        .each do |dir|
      os = dir.basename.to_s
      cp_r bin_dir.join(os, 'signed', '.'), target_dir.join('upload', 'binaries', os)
    end

    cp_r bin_dir.join('latest.json'), target_dir.join('upload', 'binaries')
    cp_r bin_dir.join('metadata.json'), target_dir.join('upload', 'binaries')

    cp_r bin_dir.join('latest.json'), target_dir.join('upload', 'update-check')
  end
end

