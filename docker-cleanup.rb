require 'rest-client'
require 'json'

username = ENV['USER_NAME']
password = ENV['PASSWORD']
org = ENV['ORG']

login = RestClient.post('https://hub.docker.com/v2/users/login/', {username: username, password: password}, {:accept => 'application/json', :content_type => 'application/json'})
token = JSON.parse(login)['token']

%w(gocd-server gocd-agent-centos-6 gocd-agent-centos-7 gocd-agent-debian-7 gocd-agent-debian-8 gocd-agent-ubuntu-12.04 gocd-agent-ubuntu-14.04 gocd-agent-ubuntu-16.04 gocd-agent-alpine-3.5).each do |repo|
  list_all_tags = RestClient.get("https://hub.docker.com/v2/repositories/#{org}/#{repo}/tags?page_size=50", {:accept => 'application/json', :Authorization => "JWT #{token}"})
  tags = JSON.parse(list_all_tags)['results'].map() {|result| result['name']}
  p tags

  tags.each do |tag|
    delete_tag = RestClient.delete("https://hub.docker.com/v2/repositories/#{org}/#{repo}/tags/#{tag}/", {:accpet => 'application/json', :Authorization => "JWT #{token}"})
    p delete_tag
  end
end
logout = RestClient.post('https://hub.docker.com/v2/logout/', {}, {:accpet => 'application/json', :Authorization => "JWT #{token}"})
