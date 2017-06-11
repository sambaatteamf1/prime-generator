_ = require("lodash")
BigNumber = require("bignumber.js")

logger = require("./Log").getLogger("PrimeNumberApp")

isBigNumberValid = (x) ->
    x = new BigNumber(x)

    if x.isNaN(x) is true
        logger.error("#{x} is not a number")
        return false

    if x.isFinite() is false
        logger.error("#{x} is not a finite")
        return false 

    if  x.isNegative() < 0 
        logger.error("#{x} must be gt 0.")
        return false
    
    return true        


isNumberValid = (x) ->

    if _.isNaN(x) is true
        logger.error("#{x} is not a number")
        return false

    if _.isFinite(x) is false
        logger.error("#{x} is not a finite number")
        return false

    if _.isInteger(x) is false
        logger.error("#{x} is not a number")
        return false

    if  x < 0 
        logger.error("#{x} must be gt 0.")
        return false
    
    return true        

module.exports = {
    isNumberValid : isNumberValid
    isBigNumberValid : isBigNumberValid
}
