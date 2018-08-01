module.exports = function (templateName, groupName, pipelineName, gitUrl, gitBranch) {
	return `{
  "format_version": 1,
  "group": "${groupName}",
  "name": "${pipelineName}",
  "label_template": "\${COUNT}",
  "lock_behavior": "none",
  "template": "${templateName}",
  "materials": [
    {
      "type": "git",
      "url": "${gitUrl}",
      "destination": null,
      "filter": null,
      "invert_filter": false,
      "name": null,
      "auto_update": true,
      "branch": "${gitBranch}",
      "submodule_folder": null,
      "shallow_clone": true
    }
  ]
}
`
};
