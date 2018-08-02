const fs = require('fs');
const path = require('path');
const childProcess = require('child_process');
const JSONPipeline = require('./docs_pipeline_template/json_template');
const YAMLPipeline = require('./docs_pipeline_template/yaml_template');

const GIT_USERNAME = process.env.GIT_USERNAME || bomb('GIT_USERNAME');
const GIT_PASSWORD = process.env.GIT_PASSWORD || bomb('GIT_PASSWORD');
const GO_VERSION = process.env.GO_VERSION || bomb('GO_VERSION');
const TEMPLATE_NAME = process.env.TEMPLATE_NAME || bomb('TEMPLATE_NAME');
const PIPELINE_GROUP_NAME = process.env.PIPELINE_GROUP_NAME || bomb('PIPELINE_GROUP_NAME');
const GITHUB_REPO_NAME = process.env.GITHUB_REPO_NAME || bomb('GITHUB_REPO_NAME');
const PIPELINE_CONFIG_FORMAT = process.env.PIPELINE_CONFIG_FORMAT ? validateFormat(process.env.PIPELINE_CONFIG_FORMAT) : bomb('PIPELINE_CONFIG_FORMAT');

const pipelineName = `${GITHUB_REPO_NAME}-release-${GO_VERSION}`;
const gitUrl = `https://git.gocd.io/git/gocd/${GITHUB_REPO_NAME}`;
const gitBranch = `release-${GO_VERSION}`;

let pipelineContent, pipelineFileName;
if (isJSONFormat(PIPELINE_CONFIG_FORMAT)) {
	pipelineContent = JSONPipeline(TEMPLATE_NAME, PIPELINE_GROUP_NAME, pipelineName, gitUrl, gitBranch);
	pipelineFileName = `${GO_VERSION}.gopipeline.json`;
} else {
	pipelineContent = YAMLPipeline(TEMPLATE_NAME, PIPELINE_GROUP_NAME, pipelineName, gitUrl, gitBranch);
	pipelineFileName = `${GO_VERSION}.gocd.yaml`;
}

const githubRepoUrl = `https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com/gocd/${GITHUB_REPO_NAME}`;
const folderToStorePipelineConfig = 'build_gocd_pipelines';

gitClone(githubRepoUrl, GITHUB_REPO_NAME);
const pipelineConfigFolderPath = path.join('./', GITHUB_REPO_NAME, folderToStorePipelineConfig);
createPipelinesFolderIfDoesntExist(pipelineConfigFolderPath);
createPipelineConfig(pipelineConfigFolderPath, pipelineFileName, pipelineContent);
changeDirectoryTo(GITHUB_REPO_NAME);
gitCommitAndPush([`./${folderToStorePipelineConfig}/${pipelineFileName}`], pipelineName);
changeDirectoryTo('../');
tearDown(GITHUB_REPO_NAME);


//Private method..
function bomb(argument) {
	throw new Error(`Please provide ${argument} environment variable.`);
}

function validateFormat(format) {
	if (format.toLowerCase() === 'json' || format.toLowerCase() === 'yaml') return format;
	throw new Error(`Invalid PIPELINE_CONFIG_FORMAT ${format} specified. Valid formats are: YAML or JSON.`);
}

function gitClone(url, repoName) {
	console.log(`Start cloning Github Repository ${url} into ${repoName}.`);
	childProcess.execSync(`git clone ${url} ${repoName}`);
	console.log(`Done cloning Github Repository.....`);
}

function createPipelinesFolderIfDoesntExist(folderPath) {
	const doesExist = fs.existsSync(folderPath);
	if (!doesExist) {
		console.log(`Creating '${folderPath}' folder to store pipeline configurations.'`);
		fs.mkdirSync(folderPath);
		console.log(`Done creating folder.....`);
	} else {
		console.log(`Skipping '${folderPath}' folder creation as it already exists.....`);
	}
}

function createPipelineConfig(folder, fileName, content) {
	console.log(`Creating pipeline config file with name '${fileName}' inside '${folder}' folder`);
	fs.writeFileSync(path.join(folder, fileName), content);
	console.log(`Done creating pipeline config file.`);
}

function changeDirectoryTo(dirPath) {
	console.log(`cd ${dirPath}`);
	process.chdir(dirPath);
}

function gitCommitAndPush(filesToAdd, pipelineName) {
	console.log(`Adding files ${filesToAdd.join(', ')} to git`);
	childProcess.execSync(`git add ${filesToAdd.join(' ')}`);
	console.log(`Done Adding file to git.....`);

	console.log(`Start committing files`);
	childProcess.execSync(`git commit -m "Add config repo pipeline named '${pipelineName}' in files '${filesToAdd.join(' ')}'"`);
	console.log(`Done committing files.`);

	console.log(`Start pushing code`);
	childProcess.execSync(`git push origin master`);
	console.log(`Done pushing code.`);
}

function tearDown(dirName) {
	console.log(`Start deleting ${dirName}`);
	childProcess.execSync(`rm -rf ${dirName}`);
	console.log(`Done deleting ${dirName}`);
}

function isJSONFormat(format) {
	return format.toLowerCase() === 'json';
}
