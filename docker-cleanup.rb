require 'rest-client'
require 'json'

username = ENV['USERNAME']
password = ENV['PASSWORD']
org = ENV['ORG']

if org == 'gocd'
  fail "ORG can't be `gocd`! We can't delete the official stable images."
end

login = RestClient.post('https://hub.docker.com/v2/users/login/', {username: username, password: password}, {:accept => 'application/json', :content_type => 'application/json'})
token = JSON.parse(login)['token']

response = RestClient.get("https://hub.docker.com/v2/repositories/#{org}/?page_size=50", {:accept => 'application/json', :Authorization => "JWT #{token}"})
all_repos = JSON.parse(response)

agents = all_repos['results'].map do |repo|
  repo['name'] if (repo['name'].start_with?('gocd-agent-') && repo['name'] != 'gocd-agent-deprecated') || repo['name'] == 'gocd-server'
end

agents.compact.each do |repo|
  list_all_tags = RestClient.get("https://hub.docker.com/v2/repositories/#{org}/#{repo}/tags?page_size=50", {:accept => 'application/json', :Authorization => "JWT #{token}"})
  tags = JSON.parse(list_all_tags)['results'].map() {|result| result['name']}
  p tags

  tags.each do |tag|
    delete_tag = RestClient.delete("https://hub.docker.com/v2/repositories/#{org}/#{repo}/tags/#{tag}/", {:accpet => 'application/json', :Authorization => "JWT #{token}"})
    p delete_tag
  end
end
logout = RestClient.post('https://hub.docker.com/v2/logout/', {}, {:accpet => 'application/json', :Authorization => "JWT #{token}"})
