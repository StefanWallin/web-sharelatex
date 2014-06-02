logger = require('logger-sharelatex')
metrics = require('../../infrastructure/Metrics')
Settings = require('settings-sharelatex')
metrics = require("../../infrastructure/Metrics")
nodemailer = require("nodemailer")

if Settings.email? and Settings.email.fromAddress?
	defaultFromAddress = Settings.email.fromAddress
else
	defaultFromAddress = ""

# provide dummy mailer unless we have a better one configured.
client =
	sendMail: (options, callback = (err,status) ->) ->
		logger.log options:options, "Would send email if enabled."
		callback()

if Settings.email?
	if Settings.email.transport? and Settings.email.parameters?
		nm_client = nodemailer.createTransport( Settings.email.transport, Settings.email.parameters )
		if nm_client
			client = nm_client
		else
			logger.warn "Failed to create email transport. Please check your settings. No email will be sent."
	else
		logger.warn "Email transport and/or parameters not defined. No emails will be sent."

module.exports =
	sendEmail : (options, callback = (error) ->)->
		logger.log receiver:options.to, subject:options.subject, "sending email"
		metrics.inc "email"
		options =
			to: options.to
			from: defaultFromAddress
			subject: options.subject
			html: options.html
			replyTo: options.replyTo || Settings.email.replyToAddress
		client.sendMail options, (err, res)->
			if err?
				logger.err err:err, "error sending message"
			else
				logger.log "Message sent to #{options.to}"
			callback(err)

