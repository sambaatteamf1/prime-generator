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
#     - max       : max prime number in the store
#     - chunkSize : size of the chunk 
#     - ntables   : number of tables  
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

# count and sum of all the primes in a chunk is stored in a separate table
#
#- primeSumTbl
#     - 0  : [25,  1060]
#  
# The sum table and prime table use the same index (field value) to store related 
# chunks. All indexes are numbers

PRIME_INDEX_TBL="primeIndexTbl"
# PRIME_SUM_TBL="primeSumTbl"
PRIME_TBL = "primeTbl"

primeIndexTbl = {}
# primeSumTbl = {}
primeTbl = {}

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
        return q.resolve(primeIndexTbl)
    )
    .fail((err)->
        return q.reject(err)
    )
    return q.promise

qLoadSumTbl = () ->
    return Q()

# qLoadSumTbl = (self) ->
#     q = Q.defer()
#     # load primeSumTbl from persistent store
#     self.store.qGetTable(PRIME_SUM_TBL)
#     .then((info)->
#         _.each(info, (value, index)->
#             index = Number(index)
#             primeSumTbl[index] = value
#         )
#         return q.resolve(primeSumTbl)
#     )
#     .fail((err)->
#         return q.reject(err)
#     )
#     return q.promise


#
# Make a list of all the primes between
# start - end. While we are at it
# Also calculate the sum

findPrimesInRange = (self, start, end) ->
    primes = []
    sum = 0

    debug('finding primes in range: [%s-%s]', start, end)

    _.each([start..end], (value, index) ->

        if self.primalityTester.isPrime(value) isnt true
            return

        debug(" %d ", value)
        primes.push(value)

        sum = sum + value            
        
    )

    chunkPrimeTbl =  {
        start : start 
        end : end
        
        primes : primes
        sum : sum
    }

    return chunkPrimeTbl

qUpdatePrimeTables = (self, chunkPrimeTbl) ->
    q = Q.defer()    

    debug('primes:%s', JSON.stringify(chunkPrimeTbl))

    chunkIndex = _.floor(chunkPrimeTbl.start / self.chunkSize) 
    if chunkIndex < 0
        q.reject(ErrorTypes.PrimeGenIntrnalError)
        return q.promise

    debug('chunk index:%d', chunkIndex)
        
    # primeSumTbl[chunkIndex] = [ chunkPrimeTbl.primes.length ,  chunkPrimeTbl.sum ]    
    primeTbl[chunkIndex] = _.uniq(_.concat(primeTbl[chunkIndex] or [], chunkPrimeTbl.primes or []))

    # store the primes
    self.store.qSet(PRIME_TBL, chunkIndex, chunkPrimeTbl.primes)
    .then(()->
        # # store the metadata
        # self.store.qSet(PRIME_SUM_TBL, chunkIndex, primeSumTbl[chunkIndex])
        # .then(()->
        #     return q.resolve()
        # )
        return q.resolve()
    )
    .fail((err)->
        debug('error updating prime tables:%s', err)
        return q.reject(err)
    )
    return q.promise

qUpdateIndex = (self, maxBound) ->
    q = Q.defer()

    if primeIndexTbl.maxBound >= maxBound
        debug("skip index update currentMax:#{primeIndexTbl.maxBound} maxBound:#{maxBound}")
        q.resolve()
        return q.promise

    primeIndexTbl.maxBound = maxBound        
    debug("index update %s", JSON.stringify(primeIndexTbl))
    self.store.qSetTable(PRIME_INDEX_TBL, primeIndexTbl)        
    .then(()->
        return q.resolve()
    )
    .fail((err)->
        return q.reject(err)
    )
    return q.promise


class PrimeNumberStore

    constructor: (config, @store, @primalityTester) ->
        @chunkSize = config.chunkSize or 1024
        @numParallelRows = config.numParallelRows or 5
        return

    qInit : () ->
        self = this
        q = Q.defer()
        # Load index table
        qLoadIndexTbl(self)
        .then(()->
            # Load sum table
            qLoadSumTbl(self)
            .then(()->
                return q.resolve()
            )
        )
        .fail((err)->
            return q.reject(err)
        )
        return q.promise         

    qGetPrimes : (min, max) ->
        self = this 
        primes = []
        sum = 0
        mean = 0
        indexesToFetch = []

        if ((_.inRange(min, 0, primeIndexTbl.maxBound+1) isnt true) or  
            (_.inRange(max, 0, primeIndexTbl.maxBound+1) isnt true)) 
           return Q({ sum : sum , mean : mean, primes : primes })

        debug("Getting primes [%s-%s]", min, max)

        minIndex = _.floor(min / self.chunkSize)
        maxIndex = _.ceil(max / self.chunkSize)  

        qGetPrimesAtGivenIndexes = (fieldArr) ->
            promise = self.store.qMGet(PRIME_TBL, fieldArr)

            promise.then((primeRecords)->
                _.each(fieldArr, (value, index)->

                    unless primeRecords[index]? or primeRecords[index].length > 0
                        return

                    debug('caching primes %s for index : %d', JSON.stringify(primeRecords[index]), value)
                    primeTbl[value] = primeRecords[index]
                )
            )
            return promise

        debug("retrieve primes in range:[%s-%s]", minIndex, maxIndex)
            
        # Do we have primes in memory ??    
        _.each([minIndex..maxIndex], (index)->

            if primeTbl[index]? 
                debug("skip index:%d Already in memory. primes:%s", index, JSON.stringify(primeTbl[index]))
                return

            debug("add #{index} to fetch list")    
            indexesToFetch.push(index)
        )

        if indexesToFetch.length > 0 
            debug("fetching #{indexesToFetch.length} chunks from store")

        fieldArrArr = _.chunk(indexesToFetch, self.numParallelRows)

        q = Q.defer()

        # Get all the primes
        chain = Q()

        _.each(fieldArrArr or [], (fieldArr)->
            chain = chain.then(()-> 
                return qGetPrimesAtGivenIndexes(fieldArr)
            )
        )

        chain.then(()->
            _.each([minIndex..maxIndex], (index)->

                debug("index:%d min:%d max:%d", index, min, max)
                filtered = _.filter(primeTbl[index] or [], (prime)->

                        if prime < min  or prime > max 
                            return false

                        # debug("%d", prime)
                            
                        sum = sum + prime 
                        return true    
                )

                debug("filtered: %s:%d", filtered, filtered.length)
                if _.isArray(filtered) and filtered.length > 0 then primes = _.concat(primes, filtered)
            )

            if primes.length > 0 then mean = sum / primes.length

            result = {
                sum : sum
                mean : mean
                primes : primes
            }
            return q.resolve(result)
        ).fail((err)->
            debug("failed to fetch primes:%s", err)
            return q.reject(err)
        )
        return q.promise

    qGenerate : (maxBound) ->
        self = this

        q = Q.defer()

        # skip the range, if we already have them 
        # in the store
        currentMax = primeIndexTbl.maxBound or 0

        debug("current max bound:%d", currentMax)

        if currentMax >= maxBound
            q.resolve()
            return q.promise

        range = maxBound - currentMax

        # split range into chunk size
        nchunks = _.ceil(range / primeIndexTbl.chunkSize)

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

                chunkPrimeTbl = findPrimesInRange(self, start+1, end)
                return qUpdatePrimeTables(self, chunkPrimeTbl)
            )
        )

        chain = chain.then(()->
            return qUpdateIndex(self, maxBound)
        )

        chain.then(()->
            return q.resolve()
        )
        .fail((err)->
            return q.reject(err)
        )
        return q.promise

    getMaxBound: () ->
        self = this

        unless primeIndexTbl.maxBound?
            return 0

        return primeIndexTbl.maxBound

module.exports = PrimeNumberStore