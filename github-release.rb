#!/usr/bin/env ruby

if File.basename($PROGRAM_NAME) != 'rake'
  require 'shellwords'
  puts "bundle exec rake -f #{Shellwords.escape($PROGRAM_NAME)} #{Shellwords.shelljoin(ARGV)}"
  exec "bundle exec rake -f #{Shellwords.escape($PROGRAM_NAME)} #{Shellwords.shelljoin(ARGV)}"
end

require 'rest-client'
require 'json'

task :release do
  version_to_release = ENV['VERSION_TO_RELEASE']
  commit = ENV["COMMIT"]
  token = ENV["TOKEN"]

  hash = {
      tag_name: version_to_release,
      target_commitish: commit,
      name: "GoCD #{version_to_release}",
      body: "Checkout the release notes at https://www.gocd.org/releases",
      draft: false,
      prerelease: false
  }
  release = RestClient.post("https://api.github.com/repos/gocd/gocd/releases", hash.to_json, {:accept => 'application/vnd.github.v3+json', :Authorization => "token #{token}"})
  p JSON.parse(release)
end

task :bump_plugins do
  released_version = ENV['VERSION_TO_RELEASE']
  next_version = ENV['NEXT_VERSION']
  repo_url = ENV['PLUGINS_REPO_URL']
  rm_rf "go-plugins"
  sh("git clone #{repo_url} go-plugins --branch master --depth 1 --quiet")
  cd 'go-plugins' do
    xml_file = File.read('pom.xml')
    updated_xml = xml_file.gsub(/#{released_version}/, "#{next_version}")
    File.write('pom.xml', updated_xml)
    sh('git add pom.xml')
    sh("git commit -m 'Bump version to #{next_version}'")
    sh("git push #{repo_url} master")
  end
end

task :bump_gocd do
  released_version = ENV['VERSION_TO_RELEASE']

  next_version = ENV['NEXT_VERSION']
  segments_of_next_version = Gem::Version.new(next_version).segments
  repo_url = ENV['GOCD_REPO_URL']

  rm_rf "gocd"
  sh("git clone #{repo_url} gocd --branch master --depth 1")
  cd 'gocd' do
    gradle_file = File.read("build.gradle")
    updated_gradle = gradle_file.gsub(/def GO_VERSION_PREVIOUS = .*/, "def GO_VERSION_PREVIOUS = '#{released_version}'")
    updated_gradle = updated_gradle.gsub(/year.*:.*/, "year: #{segments_of_next_version[0]},")
    updated_gradle = updated_gradle.gsub(/releaseInYear.*:.*/, "releaseInYear: #{segments_of_next_version[1]},")
    updated_gradle = updated_gradle.gsub(/patch.*:.*/, "patch: #{segments_of_next_version[2]}")
    File.write("build.gradle", updated_gradle)

    sh('git add build.gradle')
    sh("git commit -m 'Bump version to #{next_version}'")
    sh("git push #{repo_url} master")
  end
end

task default: [:release, :bump_gocd, :bump_plugins]