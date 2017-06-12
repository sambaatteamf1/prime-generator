
prompt = require('prompt')
async = require("async")
Util = require("./Util")
_ = require("lodash")
PrimeNumberStore = require("./PrimeNumberStore")
PrimalityTester = require("./TrailDivPrimality")
Store = require("./Store")
# Store = require("../../test/MockStore")
logger = require("./Log").getLogger("PrimeNumberApp")
Q = require("q")

# Description
# ===========
# Create a NodeJS, Scala, or Golang (pick one) application that accomplishes the following:
 
# It should generate all the prime numbers between 1 to X where X is a command line argument to the application
# Example for NodeJS: node app.js 100
 
# The prime numbers should be stored in a local Redis instance
# Once the prime numbers are generated the application should repeatedly ask the user for a lower and upper bounds (inclusive) on the prime numbers to return along with their sum and mean
# Example flow:
 
# $ Enter a lower bound: 3
# $ Enter an upper bound: 9
# $ Result:
# $ Prime numbers: [3, 5, 7]
# $ Sum: 15
# $ Mean: 5
# Include basic unit testing around the core functionality
# All code (excluding any external dependencies) should be committed to a GitHub repository.



maxBound = undefined

hasStartedExit = false
sessionCounter = 0

process.on('SIGINT', () => 
    console.log('Received SIGINT.  Press Control-D to exit.');
)
  
process.on('SIGTERM', () =>
    console.log('Received SIGTERM. Exiting');
)

printResult = (min, max, primes, count, sum, mean) ->
    unless count  > 0
        logger.info("No primes in range. Let's try again.")
        return

    logger.info("Result:")

    logger.info("Prime numbers in [#{min}-#{max}] : #{count} ")

    _.each(primes, (arr, index)->
        arrarr = _.chunk(arr, 32)

        _.each(arrarr, (obj) ->
            logger.info(obj)
        )
    )

    
    logger.info("Sum: ", sum)
    logger.info("Mean: ", mean)
    return

qGetMaxBound = () ->

    if maxBound? then return Q(Number(maxBound))

    q = Q.defer()

    qGetUserInput(['maxBound'], "Enter a max bound for generating primes")
    .then((userInput)->
        maxBound = Number(userInput.maxBound)

        return q.resolve(maxBound)
    )
    .fail((err)->
        return q.reject(err)
    )
    return q.promise

qGetUserInput = (labelArr, message) ->
    q = Q.defer()
    logger.info("#{message}:")
    prompt.get(labelArr, (err, userInput)->

        if err?
            logger.error(err)
            return q.reject(err)

        return q.resolve(userInput)    
    )
    return q.promise

primeNumberProvider = (done) ->
    lower = 0
    upper = 0

    if hasStartedExit is true
        return done("APP_SHUTDOWN")

    doneWrapper = () ->
        logger.info("")
        logger.info("--------------------------------------")
        logger.info("")
        return done()

    ++sessionCounter    
    logger.info("--------  Session #{sessionCounter} -----------")
    logger.info("")    

    qGetUserInput(['lower'], "Enter a lower bound")
    .then((userInput)->
        lower = Number(userInput.lower)

        unless lower?
            logger.error("missing input. lower:#{lower}")
            return doneWrapper()

        if lower > maxBound 
            logger.error("invalid lower bound provided. lower bound must be < #{maxBound}")
            return doneWrapper()

        # check if number is valid
        unless Util.isNumberValid(lower) is true
            logger.error("invalid lower bound provided. lower:#{lower}")
            return doneWrapper()

        qGetUserInput(['upper'], "Enter a upper bound")
        .then((userInput)->
            upper =  Number(userInput.upper)

            # get primes 
            primes = {}

            # number of primes
            count = 0

            # calculate sum
            sum = 0

            # calculate mean
            mean = 0

            unless upper?
                logger.error("missing input. upper:#{upper}")
                return doneWrapper()

            # check if number is valid
            unless Util.isNumberValid(upper) is true and upper > 0
                logger.error("invalid upper bound provided. upper:#{upper}")
                return doneWrapper()

            if upper > maxBound 
                logger.error("invalid upper bound provided. upper bound must be < #{maxBound}")
                return doneWrapper()

            range = upper - lower
            if range < 0 
                logger.error("upper-lower range is invalid. upper must be greater than lower")     
                return doneWrapper()

            logger.info("Getting primes from [ #{lower} - #{upper} ]")    
            if range > 0 
                PrimeNumberGetter.qGetPrimes(lower, upper)
                .then((result)->
                    printResult(lower, upper, result.primes, result.count,  result.sum, result.mean)
                )
                .fail((err)->
                    logger.error("failed to get primes. Error:", err)
                    return
                )
                .finally(()->
                    doneWrapper()
                )
                return
            else if range is 0 and PrimalityTester.isPrime(lower) is true   
                primes[0] = [lower]
                ++count
                sum = mean = lower

            printResult(lower, upper, primes, count, sum, mean)
            doneWrapper()    
        )
    )
    .fail((err)->
        doneWrapper(err)
    )
    return

handleError = (err) ->
    logger.error("prime number provider exited with error:", err)
    return

loopForEver = () ->
    async.forever(primeNumberProvider, handleError)

decodeError = (err) ->

    unless err? and err.message?
        return err

    msg = "Internal Error. code:#{err.message}"

    maxLimit = PrimeNumberGetter.getLookupLimit()

    switch err.message
        when "PRIME_GEN_ERR_ELIMIT"
            msg = "invalid max bound provided. can only generate primes 1-#{maxLimit}"
            break

        when "STORE_CONN_LOST"    
            msg = "Connection to store lost."
            break

    return msg            

###
App initialization
###

maxBound = process.argv[2]

Store = new Store()

config = {
    chunkSize : 1024
    numParallelRows : 5
}

PrimeNumberGetter = new PrimeNumberStore(config, Store, PrimalityTester) 

prompt.start()

qGetMaxBound()
.then((max)->

    # check if the number is acceptable
    if Util.isNumberValid(max) is false
        return

    PrimeNumberGetter.qInit()
    .then(()->
        # Generate prime numbers
        PrimeNumberGetter.qGenerate(max)
    )
    .then(()->
        loopForEver()
    )
)
.fail((err)->
    logger.error("exiting with error:", decodeError(err))
    process.exit(1)
)
