let dockerHubAPI = require('docker-hub-api');

var shortDescription, fullDescription;

const allImages = [
  'gocd-server',
  'gocd-agent-alpine-3.5',
  'gocd-agent-alpine-3.6',
  'gocd-agent-centos-6',
  'gocd-agent-centos-7',
  'gocd-agent-debian-7',
  'gocd-agent-debian-8',
  'gocd-agent-ubuntu-12.04',
  'gocd-agent-ubuntu-14.04',
  'gocd-agent-ubuntu-16.04'
];

const ORGANIZATION_NAME = 'gocd';

const GO_FULL_VERSION_CURRENT = process.env.GO_FULL_VERSION_CURRENT;
const GO_FULL_VERSION_TO_RELEASE = process.env.GO_FULL_VERSION_TO_RELEASE;

if(!GO_FULL_VERSION_CURRENT || !GO_FULL_VERSION_TO_RELEASE) {
  throw new Error("Please provide GO_FULL_VERSION_CURRENT and GO_FULL_VERSION_TO_RELEASE environment variables");
};

const GO_VERSION_CURRENT = GO_FULL_VERSION_CURRENT.split('-')[0];
const GO_VERSION_TO_RELEASE = GO_FULL_VERSION_TO_RELEASE.split('-')[0];

console.log(`Bumping up GoCD Version from ${GO_FULL_VERSION_CURRENT} to ${GO_FULL_VERSION_TO_RELEASE}`);

dockerHubAPI.login(process.env.DOCKER_HUB_USERNAME, process.env.DOCKER_HUB_PASSWORD).then(function(info) {
  dockerHubAPI.loggedInUser().then(function(_data) {
    allImages.forEach(function(dockerhubRepo) {
      dockerHubAPI.repository(ORGANIZATION_NAME, dockerhubRepo).then(function(data) {

        json = {
          full: data.full_description.replace(new RegExp(GO_FULL_VERSION_CURRENT, 'g'), GO_FULL_VERSION_TO_RELEASE).replace(new RegExp(GO_VERSION_CURRENT, 'g'), GO_VERSION_TO_RELEASE)
        }

        dockerHubAPI.setRepositoryDescription('gocd', dockerhubRepo, json).then(function(data) {
          console.log(data.full_description);
        });
      });
    });
  });
});
