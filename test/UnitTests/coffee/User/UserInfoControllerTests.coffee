sinon = require('sinon')
chai = require('chai')
should = chai.should()
expect = chai.expect
modulePath = "../../../../app/js/Features/User/UserInfoController.js"
SandboxedModule = require('sandboxed-module')
events = require "events"
MockResponse = require "../helpers/MockResponse"
MockRequest = require "../helpers/MockRequest"
ObjectId = require("mongojs").ObjectId

describe "UserInfoController", ->
	beforeEach ->
		@UserDeleter = 
			deleteUser: sinon.stub().callsArgWith(1)
		@UserInfoController = SandboxedModule.require modulePath, requires:
			"./UserGetter": @UserGetter = {}
			"./UserDeleter": @UserDeleter

		@req = new MockRequest()
		@res = new MockResponse()
		@next = sinon.stub()

	describe "getLoggedInUsersPersonalInfo", ->
		beforeEach ->
			@user =
				_id: ObjectId()
			@req.user = @user
			@UserInfoController.sendFormattedPersonalInfo = sinon.stub()
			@UserInfoController.getLoggedInUsersPersonalInfo(@req, @res, @next)

		it "should call sendFormattedPersonalInfo", ->
			@UserInfoController.sendFormattedPersonalInfo
				.calledWith(@user, @res, @next)
				.should.equal true

	describe "getPersonalInfo", ->
		beforeEach ->
			@user_id = ObjectId().toString()
			@user =
				_id: ObjectId(@user_id)
			@req.params = user_id: @user_id

		describe "when the user exists", ->
			beforeEach ->
				@UserGetter.getUser = sinon.stub().callsArgWith(2, null, @user)
				@UserInfoController.sendFormattedPersonalInfo = sinon.stub()
				@UserInfoController.getPersonalInfo(@req, @res, @next)

			it "should look up the user in the database", ->
				@UserGetter.getUser
					.calledWith(@user_id, { _id: true, first_name: true, last_name: true, email: true })
					.should.equal true
				
			it "should send the formatted details back to the client", ->
				@UserInfoController.sendFormattedPersonalInfo
					.calledWith(@user, @res, @next)
					.should.equal true

		describe "when the user does not exist", ->
			beforeEach ->
				@UserGetter.getUser = sinon.stub().callsArgWith(2, null, null)
				@UserInfoController.sendFormattedPersonalInfo = sinon.stub()
				@UserInfoController.getPersonalInfo(@req, @res, @next)

			it "should return 404 to the client", ->
				@res.statusCode.should.equal 404

	describe "sendFormattedPersonalInfo", ->
		beforeEach ->
			@user =
				_id: ObjectId()
				first_name: "Douglas"
				last_name: "Adams"
				email: "doug@sharelatex.com"
			@formattedInfo =
				id: @user._id.toString()
				first_name: @user.first_name
				last_name: @user.last_name
				email: @user.email
			@UserInfoController._formatPersonalInfo = sinon.stub().callsArgWith(1, null, @formattedInfo)
			@UserInfoController.sendFormattedPersonalInfo @user, @res

		it "should format the user details for the response", ->
			@UserInfoController._formatPersonalInfo
				.calledWith(@user)
				.should.equal true

		it "should send the formatted details back to the client", ->
			@res.body.should.equal JSON.stringify(@formattedInfo)

	describe "_formatPersonalInfo", ->
		it "should return the correctly formatted data", ->
			@user =
				_id: ObjectId()
				first_name: "Douglas"
				last_name: "Adams"
				email: "doug@sharelatex.com"
				password: "should-not-get-included"
				signUpDate: new Date()
			@UserInfoController._formatPersonalInfo @user, (error, info) =>
				expect(info).to.deep.equal {
					id: @user._id.toString()
					first_name: @user.first_name
					last_name: @user.last_name
					email: @user.email
					signUpDate: @user.signUpDate
				}


