Q = require("q")
_ = require("lodash")
debug = require('debug')('PrimeNumberStore')
ErrorTypes = require("./ErrorTypes")

# 
# This class streams prime numbers upto maxBound
#
# During initialization, it checks if the store already has pre-computed 
# prime numbers, if yes then it pipes them out  
#
# If more of them has to be generated then, it does so and
# persists them back to the store
#
# primeIndexTbl
#     - maxBound       : max prime number in the store
#     - ceiledMaxBound : ceiled max bound
#     - chunkSize      : size of the chunk 
#     - ntables        : number of tables  
#                  (if primes are stored in more than one table)
# 
# The prime numbers are stored as following - primeTable
#
# it is stored as an array of hashes. Each array contains all the primes
# in a given chunk. example: if the chunk size is 100, then each hash
# entry will contain 172 elements. The chunk number is used as 
# a the key of the hash table
#
#  primeTbl
#     - 0  : [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97]
#

PRIME_INDEX_TBL="primeIndexTbl"
PRIME_TBL = "primeTbl"

primeIndexTbl = {}
primeTbl = {}

# MAX Seachable limit
PRIME_NUMBER_LOOKUP_LIMIT = Math.pow(2, 25)

# cache sum in memory
primeSumTbl = {}

###
# Load index table from store
###
qLoadIndexTbl = (self) ->
    q = Q.defer()
    # load primeIndexTbl
    self.store.qGetTable(PRIME_INDEX_TBL)
    .then((info)->
        defaults = {
            chunkSize : self.chunkSize
            ntables : 1
            maxBound : 0
        }

        primeIndexTbl = _.extend({}, defaults , info)
        _.each(primeIndexTbl, (value, key) ->
            primeIndexTbl[key] = Number(value)
        )
        return q.resolve(primeIndexTbl)
    )
    .fail((err)->
        return q.reject(err)
    )
    return q.promise

###
# Make a list of all the primes between
# start - end. While we are at it,
# also calculate the sum of primes 
# in this chunk
###
findPrimesInRange = (self, start, end) ->
    primes = []
    sum = 0

    debug('finding primes in range: [%s-%s]', start, end)

    _.each([start..end], (value, index) ->

        if self.primalityTester.isPrime(value) isnt true
            return

        primes.push(value)
        sum = sum + value            
    )

    chunkPrimeTbl =  {
        start : start 
        end : end
        
        primes : primes
        sum : sum
    }

    debug('found %d primes in range: [%s-%s]',  primes.length, start, end)

    # memUsage = process.memoryUsage()
    # debug("memory usage:" +  Math.round(memUsage.heapUsed / 1024 / 1024) + " MB")
    return chunkPrimeTbl

###
# This function persists the prime numbers of
# a given chunk in store
###
qUpdatePrimeTables = (self, chunkPrimeTbl) ->
    q = Q.defer()    

    chunkIndex = Math.floor(chunkPrimeTbl.start / self.chunkSize) 
    if chunkIndex < 0
        q.reject(ErrorTypes.PrimeGenInternalError)
        return q.promise

    debug('setting primes at index:%d', chunkIndex)
    primeSumTbl[chunkIndex] = chunkPrimeTbl.sum
    primeTbl[chunkIndex] = _.uniq(_.concat(primeTbl[chunkIndex] or [], chunkPrimeTbl.primes or []))

    # store the primes
    self.store.qSet(PRIME_TBL, chunkIndex, chunkPrimeTbl.primes)
    .then(()->
        return q.resolve()
    )
    .fail((err)->
        debug('error updating prime tables:%s', err)
        return q.reject(err)
    )
    return q.promise

###
# This function persists the prime numbers of
# a given chunk in store
###
qUpdateIndex = (self, maxBound, ceiledMaxBound) ->
    q = Q.defer()

    if primeIndexTbl.maxBound >= maxBound
        debug("skip index update currentMax:#{primeIndexTbl.maxBound} maxBound:#{maxBound}")
        q.resolve()
        return q.promise

    primeIndexTbl.maxBound = maxBound        
    primeIndexTbl.ceiledMaxBound = ceiledMaxBound
    
    debug("index update %s", JSON.stringify(primeIndexTbl))
    self.store.qSetTable(PRIME_INDEX_TBL, primeIndexTbl)        
    .then(()->
        return q.resolve()
    )
    .fail((err)->
        return q.reject(err)
    )
    return q.promise

###
# This function gets the primes from the 
# store at the give indexes
###
qGetPrimesAtGivenIndexes = (self, indexesToFetch) ->

    debug("fetching #{indexesToFetch.length} chunks from store")

    fieldArrArr = _.chunk(indexesToFetch, self.numParallelRows) or []

    q = Q.defer()

    chain = Q()

    _.each(fieldArrArr, (fieldArr)->
        chain = chain.then(()-> 
            promise = self.store.qMGet(PRIME_TBL, fieldArr)
            promise.then((primeRecords)->

                _.each(fieldArr, (value, index)->

                    unless _.isArray(primeRecords[index]) and primeRecords[index].length > 0
                        return

                    debug('caching %d primes for index : %d', primeRecords[index].length, value)
                    primeSumTbl[value] = primeRecords[index].reduce(getSum, 0)
                    primeTbl[value] = primeRecords[index]
                )
            )
            return promise            
        )
    )

    chain.then(()->
        debug("fetching #{indexesToFetch.length} chunks from store done")
        return q.resolve()
    )
    .fail((err)->
        return q.reject(err)
    )
    return q.promise    

# Accumulator for calculating sum
getSum = (acc, num)-> return acc + num

class PrimeNumberStore

    constructor: (config, @store, @primalityTester) ->
        @chunkSize = config.chunkSize or 1024
        @numParallelRows = config.numParallelRows or 5
        return

    # qInit
    #        
    # Loads the index table from store
    #
    qInit : () ->
        self = this
        q = Q.defer()
        # Load index table
        qLoadIndexTbl(self)
        .then(()->
            return q.resolve()
        )
        .fail((err)->
            return q.reject(err)
        )
        return q.promise         

    # qGetPrimes
    #   
    # Get all from primes from min - max
    # It first looks up the tables in memory, else
    # gets them from the persistent store
    #
    # Returns {Object} :
    #    - count   Number
    #    - primes  Object (key=Number, value: Array of primes)
    #    - sum     Number
    #    - mean    Number 

    qGetPrimes : (min, max) ->
        self = this 
        primes = {}
        nprimes = 0
        sum = 0
        mean = 0
        indexesToFetch = []

        if ((_.inRange(min, 0, primeIndexTbl.maxBound+1) isnt true) or  
            (_.inRange(max, 0, primeIndexTbl.maxBound+1) isnt true)) 
           return Q({ sum : sum , count : 0,  mean : mean, primes : primes })

        debug("Getting primes [%s-%s]", min, max)

        minIndex = Math.floor(min / self.chunkSize) 
        maxIndex = Math.floor(max / self.chunkSize)  

        debug("retrieve primes in indexes:[%s-%s]", minIndex, maxIndex)
        
        # Do we have primes in memory ??    
        _.each([minIndex..maxIndex], (index)->

            if _.isArray(primeTbl[index])
                debug("skip index:%d Already in memory. primes:%d", index, primeTbl[index].length)
                return

            debug("add #{index} to fetch list")    
            indexesToFetch.push(index)
        )

        q = Q.defer()

        # Get all the primes
        chain = Q()

        chain = chain.then(()->
            unless indexesToFetch.length > 0
                return

            return qGetPrimesAtGivenIndexes(self, indexesToFetch)    
        )            

        chain.then(()->

            _.each([minIndex..maxIndex], (index)->

                arr = primeTbl[index]

                unless _.isArray(arr)
                    return

                arrLen = arr.length
                unless arrLen > 0
                    return

                # return if no primes in the index are in (min - max) range                    
                if min > arr[arrLen-1] or max < arr[0]
                    return

                # Include all the primes in this index
                unless _.inRange(min, arr[0], arr[arrLen-1]) or _.inRange(max, arr[0], arr[arrLen-1])
                    debug("processed index:%d added %d primes", index, arrLen)
                    primes[index] = arr
                    nprimes += arrLen
                    sum += primeSumTbl[index]
                    return

                filtered = _.filter(arr, (prime)->

                        if prime < min  or prime > max 
                            return false
                            
                        sum = sum + prime 
                        return true    
                )

                debug("processed index #{index} add filtered #{filtered.length} primes")

                if _.isArray(filtered) and filtered.length > 0 
                    primes[index] = filtered
                    nprimes += filtered.length
            )

            # if primes.length > 0 then mean = sum / primes.length
            if nprimes > 0 then mean = sum / nprimes

            result = {
                sum : sum
                mean : mean
                primes : primes
                count : nprimes
            }
            return q.resolve(result)
        ).fail((err)->
            debug("failed to fetch primes:%s", err)
            return q.reject(err)
        )
        return q.promise

    #
    # qGenerate
    #        
    # Generate primes until maxBound.
    #
    qGenerate : (maxBound) ->
        self = this

        q = Q.defer()

        if maxBound <=0 or maxBound > PRIME_NUMBER_LOOKUP_LIMIT
            q.reject(ErrorTypes.PrimeGenLimitError)
            return q.promise

        # skip the range, if we already have them 
        # in the store
        currentMax = primeIndexTbl.maxBound or 0

        debug("current max bound:%d", currentMax)

        if currentMax >= maxBound
            q.resolve()
            return q.promise

        # 
        # Round up to the nearest chunk size
        # Example : if chunkSize = 1024, maxBound = 10,000 
        # 
        # we search for primes until 10240
        # 
        ceiledMaxBound = Math.ceil(maxBound / primeIndexTbl.chunkSize) * primeIndexTbl.chunkSize

        range = ceiledMaxBound - currentMax

        # split range into chunk size
        nchunks = Math.ceil(range / primeIndexTbl.chunkSize)

        if nchunks <= 0 
            q.resolve()
            return q.promise

        debug("number of chunks:%d", nchunks)

        chain = Q()

        # Process each chunk serially..
        _.each([0..nchunks-1], (chunkNum)->

            chain = chain.then(()->

                start = currentMax + primeIndexTbl.chunkSize * chunkNum
                end  = start + primeIndexTbl.chunkSize

                # find primes
                chunkPrimeTbl = findPrimesInRange(self, start+1, end)

                # store them
                return qUpdatePrimeTables(self, chunkPrimeTbl)
            )
        )

        chain = chain.then(()->
            # update the index
            return qUpdateIndex(self, maxBound, ceiledMaxBound)
        )

        chain.then(()->
            return q.resolve()
        )
        .fail((err)->
            return q.reject(err)
        )
        return q.promise

    #
    # getMaxBound
    #        
    # returns the max searchable limit of prime numbers
    #
    getLookupLimit: () ->
        return PRIME_NUMBER_LOOKUP_LIMIT

module.exports = PrimeNumberStore