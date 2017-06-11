log4js = require("log4js")


initialized = false

init = () ->
	logConfigFile = process.env.LOG4JS_CONFIG or "./log4js.json"
	log4js.configure(logConfigFile)
	initialized = true
	return

getLogger = (category) ->
	unless initialized then init()
	logger = log4js.getLogger(category)	
	return logger
	
module.exports = {
	getLogger : getLogger
}