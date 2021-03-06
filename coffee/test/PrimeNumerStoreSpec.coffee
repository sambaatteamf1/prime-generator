
chai = require("chai")
assert = chai.assert
expect = chai.expect 
_ = require("lodash")

PrimeNumberStore = require("../lib/js/PrimeNumberStore")

DivisionPrimalityTester = require("../lib/js/TrailDivPrimality")
SievePrimalityTester = require("../lib/js/SieveOfEratosthenes")

MockStore = require("./MockStore")
RedisStore = require("../lib/js/Store")

refPrimes = require("./RefPrimeTbl")

MAX_BOUND = Math.pow(2, 25)
# Math.pow(2, 20) = 82000  primes
# Math.pow(2, 21) = 155586 primes
# Math.pow(2, 22) = 295922 primes
# Math.pow(2, 23) = 
# Math.pow(2, 25) = 2063689 primes (22 s)
# Math.pow(2, 26) = 3957809 primes (60 s)
# Math.pow(2, 27) = 7603553 primes (121 s)

PrimeNumberGetter = null
Store = null 

primeNumbers = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97]

describe("PrimeNumberStoreTest - ", ->

    before(()->
        Store = new MockStore()

        config = {
            chunkSize : 1024
            numParallelRows : 5
        }

        PrimeNumberGetter = new PrimeNumberStore(config, Store, DivisionPrimalityTester)
        # PrimeNumberGetter = new PrimeNumberStore(config, Store, SievePrimalityTester)
        return PrimeNumberGetter.qInit()
    )

    it("should be able to generate primes", ()->
        PrimeNumberGetter.qGenerate(100)
        .then(()->
            PrimeNumberGetter.qGetPrimes(0,100)
            .then((result)->
                expect(result.primes[0]).to.eql(primeNumbers)
            )
        )
    )

    it("should calculate sum of primes correctly", ()->
        PrimeNumberGetter.qGetPrimes(0,100)
        .then((result)->
            expect(result.sum).to.eql(1060)
        )
    )

    it("should be able to generate primes for a subset", ()->
        PrimeNumberGetter.qGetPrimes(0,30)
        .then((result)->
            subPrime =  [2, 3, 5, 7, 11, 13, 17, 19, 23, 29]
            expect(result.primes[0]).to.eql(subPrime)
        )
    )

    it("should be able handle out-of-range query", ()->
        PrimeNumberGetter.qGetPrimes(200, 300)
        .then((result)->
            expect(result.count).to.eql(0)
        )
    )

    it("should persist the primes", ()->
        Store.qMGet("primeTbl", [0])
        .then((result)->
            expect(result[0]).to.have.lengthOf.above(0)
        )
    )

    it("should correctly generate primes", ()->
        PrimeNumberGetter.qGenerate(2000)
        .then(()->
            PrimeNumberGetter.qGetPrimes(0, 2000)
            .then((result)->
                primes = []

                _.each(result.primes, (chunk, index)->
                    primes = _.concat(primes, chunk)
                )

                filtered = _.filter(refPrimes, (prime, index)->
                    if prime > 2000
                        return false

                    return true    
                )

                if _.isEqual(filtered, primes) is false
                    expect(true).to.eql(false)           
            )
        )
    )

    it.skip("should be able to generate primes until #{MAX_BOUND}", ()->
        PrimeNumberGetter.qGenerate(MAX_BOUND)
        .then(()->
            PrimeNumberGetter.qGetPrimes(0, MAX_BOUND)
            .then((result)->
                expect(result.count).to.equal(2063689)
            )
        )
    )    
)
