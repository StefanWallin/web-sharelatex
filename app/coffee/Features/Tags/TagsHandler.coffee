_ = require('underscore')
settings = require("settings-sharelatex")
request = require("request")
logger = require("logger-sharelatex")

oneSecond = 1000
module.exports = 


	deleteTag: (user_id, project_id, tag, callback)->
		uri = buildUri(user_id, project_id)
		opts =
			uri:uri
			json:
				name:tag
			timeout:oneSecond
		logger.log user_id:user_id, project_id:project_id, tag:tag, "send delete tag to tags api"
		request.del opts, callback

	addTag: (user_id, project_id, tag, callback)->
		uri = buildUri(user_id, project_id)
		opts =
			uri:uri
			json:
				name:tag
			timeout:oneSecond
		logger.log user_id:user_id, project_id:project_id, tag:tag, "send add tag to tags api"
		request.post opts, callback

	requestTags: (user_id, callback)->
		opts = 
			uri: "#{settings.apis.tags.url}/user/#{user_id}/tag"
			json: true
			timeout: 2000
		request.get opts, (err, res, body)->
			statusCode =  if res? then res.statusCode else 500
			if err? or statusCode != 200
				e = new Error("something went wrong getting tags, #{err}, #{statusCode}")
				logger.err err:err
				callback(e, [])
			else
				callback(null, body)

	getAllTags: (user_id, callback)->
		@requestTags user_id, (err, allTags)=>
			if !allTags?
				allTags = []
			@groupTagsByProject allTags, (err, groupedByProject)->
				logger.log allTags:allTags, user_id:user_id, groupedByProject:groupedByProject, "getting all tags from tags api"
				callback err, allTags, groupedByProject

	removeProjectFromAllTags: (user_id, project_id, callback)->
		uri = buildUri(user_id, project_id)
		opts =
			uri:"#{settings.apis.tags.url}/user/#{user_id}/project/#{project_id}"
			timeout:oneSecond
		logger.log user_id:user_id, project_id:project_id, "removing project_id from tags"
		request.del opts, callback

	groupTagsByProject: (tags, callback)->
		result = {}
		_.each tags, (tag)->
			_.each tag.project_ids, (project_id)->
				result[project_id] = []

		_.each tags, (tag)->
			_.each tag.project_ids, (project_id)->
				clonedTag = _.clone(tag)
				delete clonedTag.project_ids
				result[project_id].push(clonedTag)
		callback null, result


buildUri = (user_id, project_id)->
	uri = "#{settings.apis.tags.url}/user/#{user_id}/project/#{project_id}/tag"
