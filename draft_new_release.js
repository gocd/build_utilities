var GitHub = require('github-base');
const VERSION = require('./version.json');

const OWNER = 'gocd';

const GITHUB_TOKEN = process.env.GITHUB_TOKEN;

if(!GITHUB_TOKEN) {
  throw new Error('Please provide GITHUB_TOKEN');
}

const GOCD_VERSION = VERSION.go_version;
const RELEASE_GIT_SHA = VERSION.git_sha;

var github = new GitHub({ token: GITHUB_TOKEN });

console.log(`Creating github release for version ${GOCD_VERSION} with commit ${RELEASE_GIT_SHA}`);

github.post(`/repos/${OWNER}/gocd/releases`, {
  tag_name: GOCD_VERSION,
  target_commitish: RELEASE_GIT_SHA,
  name: `GoCD ${GOCD_VERSION}`,
  body: 'Check release notes at https://www.gocd.org/releases/'
}, function(err, res) {
  if(err){
    console.error(`Error: ${JSON.stringify(err, null, 2)}`);
    process.exit(1);
  }else {
    console.log(`Done creating a new release: ${JSON.stringify(res, null, 2)}`);
  }
});
