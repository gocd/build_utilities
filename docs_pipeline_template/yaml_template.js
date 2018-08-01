module.exports = function (templateName, groupName, pipelineName, gitUrl, gitBranch) {
	return `format_version: 2
pipelines:
  ${pipelineName}:
    group: ${groupName}
    label_template: "\${COUNT}"
    lock_behavior: none
    materials:
      ${pipelineName}:
        git: ${gitUrl}
        branch: ${gitBranch}
    template: ${templateName}
`
};
