module Requirements
  def requiresEnvVariable(envVariables)
    envVariables.each do |env_var|
      ENV[env_var] || (raise "Environment variable '#{env_var}' is not set") if env_var
    end
  end

  def env(varName, errorMsg='')
    errorMsg = errorMsg || "Environment variable '#{varName}' is not set"
    ENV["#{varName}"] || (raise errorMsg)
  end

  def envOrDefault(varName, defaultValue)
    ENV[varName] || defaultValue
  end

  def path(path)
    Pathname.new("#{path}").expand_path
  end

  def sourceDir
    path(env('UNSIGNED_BIN_DIRECTORY', 'UNSIGNED_BIN_DIRECTORY is not set. e.g.'))
  end

  def destDir
    path(env('SIGNED_BIN_DIRECTORY', 'SIGNED_BIN_DIRECTORY is not set. e.g. /mydir/signed'))
  end

  def gpgSigningKey
    env('GPG_SIGNING_KEY_ID', 'GPG_SIGNING_KEY_ID is not set. e.g. 7722C545')
  end

  def gnupgHome
    path(env('GNUPGHOME', 'GNUPGHOME is not set, this must be set to path of `.gnupg` directory e.g. /pipeline1/.gnupg'))
  end

  def p12CertificateName
    env('P12_CERTIFICATE_NAME', 'P12 CERTIFICATE certificate name is not set')
  end

  def p12CertificateFile
    path(env('P12_CERTIFICATE_FILE', 'P12_CERTIFICATE_FILE must be set with certificate file path'))
  end

  def p12CertificatePassword
    env('P12_CERTIFICATE_PASSWORD', 'GO_P12_CERTIFICATE_PASSWORD is not set, should be cleartext password for p12 cert')
  end

  def keychainFile
    path(env('KEYCHAIN_FILE', 'Path to .keychain file containing code signing certificate'))
  end

  def keychainPassword
    env('KEYCHAIN_PASSWORD', 'Password of keychain file')
  end

  def codeSigningIdentity
    env('CODE_SIGNING_IDENTITY', 'Name of the certificate you imported into keychain e.g. `Developer ID Application: ThoughtWorks (LL62P32G5C)`')
  end

  def binariesSourceDir
    path(env('BIN_DIRECTORY', 'BIN_DIRECTORY is not set, should contain `meta/` directory with version.json e.g. /local/meta'))
  end

  def targetUploadDir
    path(env('TARGET_DIRECTORY','TARGET_DIRECTORY is not set, should contain binaries to be uploaded'))
  end

  def s3Bucket
    env('S3_BUCKET', 'S3_BUCKET is not set')
  end

  def s3UpdateCheckBucket
    env('S3_UPDATE_CHECK_BUCKET', 'S3_UPDATE_CHECK_BUCKET is not set')
  end

  def keyDir
    _msg = <<-_EOS_
      'KEY_DIRECTORY' is not set. e.g. /local/meta
      contains following things from update_check keys
      - subordinate-private-key.pem
      - subordinate-private-key-passphrase
      - subordinate-public-key.pem
      - subordinate-public-key-digest
    _EOS_

    path(env('KEY_DIRECTORY', _msg))
  end
end
