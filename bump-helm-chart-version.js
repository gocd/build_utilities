const fs           = require('fs');
const childProcess = require('child_process');
const assert       = require('assert');
const request      = require('request');

const CLONE_TO_PATH                   = './tmp-charts';
const UPSTREAM_HELM_CHART_GITHUB_REPO = 'https://github.com/helm/charts';

const GIT_USERNAME            = process.env.GIT_USERNAME || bomb('GIT_USERNAME');
const GIT_PASSWORD            = process.env.GIT_PASSWORD || bomb('GIT_PASSWORD');
const GOCD_CURRENT_VERSION    = process.env.GOCD_CURRENT_VERSION || bomb('GOCD_CURRENT_VERSION');
const GOCD_VERSION_TO_RELEASE = process.env.GOCD_VERSION_TO_RELEASE || bomb('GOCD_VERSION_TO_RELEASE');

const options = {'cwd': CLONE_TO_PATH};

console.log(`Start cloning git repository into '${CLONE_TO_PATH}'...`);
childProcess.execSync(`git clone https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com/gocd/charts ${CLONE_TO_PATH}`);
console.log(`Done cloning repository...\n`);

console.log(`Adding '${UPSTREAM_HELM_CHART_GITHUB_REPO}' upstream...`);
childProcess.execSync(`git remote add upstream ${UPSTREAM_HELM_CHART_GITHUB_REPO}`, options);
console.log("Done adding upstream...\n");

console.log(`Listing all git remotes..`);
console.log(childProcess.execSync(`git remote -v`, options).toString());
console.log('-----');

console.log('Verifying current branch being master..');
const currentBranch = childProcess.execSync('git branch | grep \\* | cut -d \' \' -f2', options).toString();
assert.equal(currentBranch.trim(), 'master', `Expected current branch to be master, but was ${currentBranch}`);
console.log('Done verifying master branch..');


console.log('Pulling latest code from upstream..');
console.log(childProcess.execSync('git pull upstream master', options).toString());
console.log('Done pulling code..');

console.log('Pushing latest code from upstream to origin..');
console.log(childProcess.execSync('git push origin master', options).toString());
console.log('Done pushing code..');


const branchName = `bump-gocd-version-to-${GOCD_VERSION_TO_RELEASE}`;
console.log(`Checking out new branch '${branchName}'..`);
console.log(childProcess.execSync(`git checkout -b ${branchName}`, options).toString());
const checkedOutBranch = childProcess.execSync('git branch | grep \\* | cut -d \' \' -f2', options).toString();
assert.equal(checkedOutBranch.trim(), branchName, `Expected current branch to be ${branchName}, but was ${checkedOutBranch}`);
console.log('Done checking out new branch..');

const chartYamlFilePath = `${CLONE_TO_PATH}/stable/gocd/Chart.yaml`;
let chartYamlContent    = fs.readFileSync(chartYamlFilePath, 'utf8');

console.log(`Updating appVersion from '${GOCD_CURRENT_VERSION}' to '${GOCD_VERSION_TO_RELEASE}' in Chart.yaml...`);
chartYamlContent = chartYamlContent.replace(`appVersion: ${GOCD_CURRENT_VERSION}`, `appVersion: ${GOCD_VERSION_TO_RELEASE}`);
fs.writeFileSync(chartYamlFilePath, chartYamlContent);
console.log(`Done updating appVersion.`);

const versionString     = chartYamlContent.match('version: [0-9].[0-9].[0-9]')[0];
const currentAppVersion = versionString.split(':')[1].trim();
const splitAppVersions  = currentAppVersion.split('.');
splitAppVersions[2]     = (+splitAppVersions[2]) + 1;
const newAppVersion     = splitAppVersions.join('.');

console.log(`Updating Chart version from '${currentAppVersion}' to '${newAppVersion}' in Chart.yaml...`);
chartYamlContent = chartYamlContent.replace(`version: ${currentAppVersion}`, `version: ${newAppVersion}`);
fs.writeFileSync(chartYamlFilePath, chartYamlContent);
console.log(`Done updating appVersion..`);

console.log('Performing git diff..');
console.log(childProcess.execSync(`git diff`, options).toString());
console.log('-----');

const commitMessage = `Bump up GoCD Version to ${GOCD_VERSION_TO_RELEASE}`;
console.log('Committing Chart.yaml changes...');
console.log(childProcess.execSync(`git add stable/gocd/Chart.yaml`, options).toString());
console.log(childProcess.execSync(`git commit --signoff -m "${commitMessage}"`, options).toString());
console.log('Done committing changes...');


console.log('Updating Changelog...');
const latestCommitShortSHA = childProcess.execSync(`git rev-parse --short HEAD`, options).toString().trim();

const changelog = `### ${newAppVersion}

* [${latestCommitShortSHA}](https://github.com/kubernetes/charts/commit/${latestCommitShortSHA}):

- ${commitMessage}

`;

const changelogFilePath = `${CLONE_TO_PATH}/stable/gocd/CHANGELOG.md`;
const existingChangelog = fs.readFileSync(changelogFilePath, 'utf8');
const newChangelog      = changelog + existingChangelog;
fs.writeFileSync(changelogFilePath, newChangelog);
console.log('Done updating Changelog...');

console.log('Performing git diff..');
console.log(childProcess.execSync(`git diff`, options).toString());
console.log('-----');

const changelogCommitMessage = 'Updated Changelog.';
console.log('Committing CHANGELOG.md changes...');
console.log(childProcess.execSync(`git add stable/gocd/CHANGELOG.md`, options).toString());
console.log(childProcess.execSync(`git commit --signoff -m "${changelogCommitMessage}"`, options).toString());
console.log('Done committing changes...');

console.log('Pushing branch to origin..');
console.log(childProcess.execSync(`git push origin ${branchName}`, options).toString());
console.log('Done Pushing branch to origin..');

console.log('------------');


console.log('Creating Pull Request..');

const requestConfig = {
  'url':    `https://api.github.com/repos/helm/charts/pulls`,
  'method': 'POST',
  'auth':   {
    'username': GIT_USERNAME,
    'password': GIT_PASSWORD
  },
  body:     {
    title:                 `[stable/gocd] ${commitMessage}`,
    head:                  `${GIT_USERNAME}:${branchName}`,
    base:                  `master`,
    maintainer_can_modify: true
  },
  json:     true,
  headers:  {
    'User-Agent': GIT_USERNAME,
    'Accept':     'application/vnd.github.v3+json'
  }
};

request(requestConfig, (err, res) => {
  if (err) {
    return reject(err);
  }

  console.log('Done creating pull request..');
  console.log(`Visit: ${res.body.html_url} to see your pull request.`);
});

//--- private method
function bomb(argument) {
  throw new Error(`Please provide ${argument} environment variable.`);
}
