async = require("async")
_ = require("underscore")
UserCreator = require("../User/UserCreator")
SubscriptionUpdater = require("./SubscriptionUpdater")
SubscriptionLocator = require("./SubscriptionLocator")
UserLocator = require("../User/UserLocator")
LimitationsManager = require("./LimitationsManager")


module.exports = 

	addUserToGroup: (adminUser_id, newEmail, callback)->
		UserCreator.getUserOrCreateHoldingAccount newEmail, (err, user)->
			LimitationsManager.hasGroupMembersLimitReached adminUser_id, (err, limitReached)->
				if limitReached
					return callback(limitReached:limitReached)
				SubscriptionUpdater.addUserToGroup adminUser_id, user._id, (err)->
					userViewModel = buildUserViewModel(user)
					callback(err, userViewModel)

	removeUserFromGroup: (adminUser_id, userToRemove_id, callback)->
		SubscriptionUpdater.removeUserFromGroup adminUser_id, userToRemove_id, callback


	getPopulatedListOfMembers: (adminUser_id, callback)->
		SubscriptionLocator.getUsersSubscription adminUser_id, (err, subscription)-> 
			users = []
			jobs = _.map subscription.member_ids, (user_id)->
				return (cb)->
					UserLocator.findById user_id, (err, user)->
						if err? or !user?
							users.push _id:user_id
							return cb()
						userViewModel = buildUserViewModel(user)
						users.push(userViewModel)
						cb()
			async.series jobs, (err)->
				callback(err, users)


buildUserViewModel = (user)->
	u = 
		email: user.email
		first_name: user.first_name
		last_name: user.last_name
		holdingAccount: user.holdingAccount
		_id: user._id
	return u
