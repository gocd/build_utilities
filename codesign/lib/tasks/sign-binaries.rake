require 'open-uri'
require 'json'
require 'base64'
require 'pathname'

require_relative '../requirements.rb'

namespace :sign do
  unsigned_bin_dir   = ""
  signed_bin_dir     = ""
  gpg_signing_key_id = ""

  include Requirements

  task :checkConfig do
    unsigned_bin_dir   = sourceDir
    signed_bin_dir     = destDir
    gpg_signing_key_id = gpgSigningKey
    gnupg_home         = gnupgHome
  end

  task :clean => [:checkConfig] do
    rm_rf "#{signed_bin_dir}"
    mkdir_p "#{signed_bin_dir}"
  end

  task :centos => [:clean] do
    cp_r "#{unsigned_bin_dir}/.", "#{signed_bin_dir}"

    sh("rpm --addsign --define \"_gpg_name #{gpg_signing_key_id}\" #{signed_bin_dir.join('*.rpm')}")
    sh("gpg --armor --output /tmp/GPG-KEY-GOCD --export #{gpg_signing_key_id}")
    sh("rpm --import /tmp/GPG-KEY-GOCD")
    sh("rpm --checksig #{signed_bin_dir.join('*.rpm')}")
  end

  task :ubuntu => [:clean] do
    cp_r "#{unsigned_bin_dir}/.", "#{signed_bin_dir}"

    sh("dpkg-sig --verbose --sign builder -k #{gpg_signing_key_id} #{signed_bin_dir}/*.deb")
    sh("gpg --armor --output /tmp/GPG-KEY-GOCD --export #{gpg_signing_key_id}")
    sh("apt-key add /tmp/GPG-KEY-GOCD")
    sh("dpkg-sig --verbose --verify #{signed_bin_dir}/*.deb")
  end

  task :zip => [:clean] do
    cp_r "#{unsigned_bin_dir}/.", "#{signed_bin_dir}"

    signed_bin_dir
        .children.select {|path| path.basename.extname == '.zip'}
        .each do |file|
      sig = "#{file}.asc"
      sh("gpg --default-key #{gpg_signing_key_id} --armor --detach-sign --sign --output #{sig} #{file}")
      sh("gpg --default-key #{gpg_signing_key_id} --verify #{sig}")
    end
  end

  task :win do
    unsigned_bin_dir   = sourceDir
    signed_bin_dir     = destDir
    cert_file          = p12CertificateFile
    cert_password      = p12CertificatePassword
    cert_name          = p12CertificateName
    signtool           = envOrDefault('SIGNTOOL', "\"C:\\Program Files (x86)\\Windows Kits\\8.1\\bin\\x64\\signtool\"")
        ENV['SIGNTOOL'] || "\"C:\\Program Files (x86)\\Windows Kits\\8.1\\bin\\x64\\signtool\""

    cp_r "#{unsigned_bin_dir}/.", "#{signed_bin_dir}"

    signed_bin_dir
        .children.select {|path| path.basename.extname == '.exe'}
        .each do |file|
      sh("#{signtool} sign /debug /v /sm /s My /n #{cert_name} /t http://timestamp.digicert.com /a #{file}")
      sh("#{signtool} sign /debug /v /sm /s My /n #{cert_name} /tr http://timestamp.digicert.com /a /fd sha256 /td sha256 /as #{file}")
      sh("#{signtool} verify /debug /v /a /pa /hash sha1 #{file}")
      sh("#{signtool} verify /debug /v /a /pa /hash sha256 #{file}")
    end
  end

  task :osx do
    unsigned_bin_dir   = sourceDir
    signed_bin_dir     = destDir
    code_sign_identity = codeSigningIdentity
    keychain_file      = keychainFile
    keychain_password  = keychainPassword

    staging_dir  = "stage/bins"

    rm_rf "#{signed_bin_dir}"
    mkdir_p "#{signed_bin_dir}"

    unsigned_bin_dir
        .children.select {|path| path.basename.extname == '.zip'}
        .each do |file|

      rm_rf staging_dir
      mkdir_p staging_dir

      sh("unzip -q #{file} -d #{staging_dir}")

      sh(%{security unlock-keychain -p #{keychain_password} #{keychain_file} && codesign --force --verify --verbose --sign "#{code_sign_identity}" #{staging_dir}/*.app}) do |ok, _res|
        puts 'Locking keychain again'
        sh("security lock-keychain #{keychain_file}")
        fail 'There was an error performing code OSX signing' unless ok
      end
      sh("cd #{staging_dir} && zip -r #{signed_bin_dir.join(file.basename)} .")
      rm_rf "#{staging_dir}"
    end
  end


  task :test => [:clean] do
    puts "GPG signing key: #{gpg_signing_key_id}"
    puts "Unsigned binaries directory: #{unsigned_bin_dir}"
    puts "Signed binaries directory: #{signed_bin_dir}"
    puts ".gnupg set to: #{ENV['GNUPGHOME']}"
    cp_r "#{unsigned_bin_dir}/.", "#{signed_bin_dir}"
  end
end