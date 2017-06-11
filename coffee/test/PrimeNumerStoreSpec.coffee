
chai = require("chai")
assert = chai.assert
expect = chai.expect 
_ = require("lodash")

PrimeNumberStore = require("../lib/js/PrimeNumberStore")
PrimalityTester = require("../lib/js/TrailDivPrimality")
MockStore = require("./MockStore")
RedisStore = require("../lib/js/Store")

MAX_BOUND = Math.pow(2, 10)

# Math.pow(2, 20) = 82000  primes
# Math.pow(2, 21) = 155586 primes
# Math.pow(2, 22) = 295922 primes
# Math.pow(2, 23) = 564138 primes (60 s)

PrimeNumberGetter = null
Store = null 

primeNumbers = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97]

describe("PrimeNumberStoreTest - ", ->

    before((done)->
        # Store = new MockStore()
        Store = new RedisStore()

        config = {
            chunkSize : 1024
            numParallelRows : 5
        }

        PrimeNumberGetter = new PrimeNumberStore(config, Store, PrimalityTester)
        PrimeNumberGetter.qInit()
        .then(()->
            done()
        )
        .fail((err)->
            done(err)
        )
    )

    it("should be able to generate primes", (done)->
        PrimeNumberGetter.qGenerate(100)
        .then(()->
            PrimeNumberGetter.qGetPrimes(0,100)
            .then((result)->
                expect(result.primes).to.eql(primeNumbers)
                done()
            )
        )
        .fail((err)->
            done(err)
        )
    )

    it("should be able to generate primes for a subset", (done)->
        PrimeNumberGetter.qGetPrimes(0,30)
        .then((result)->
            subPrime =  [2, 3, 5, 7, 11, 13, 17, 19, 23, 29]
            expect(result.primes).to.eql(subPrime)
            done()
        )
    )

    # it("should be able handle out-of-range query", (done)->
    #     PrimeNumberGetter.qGetPrimes(200,300)
    #     .then((result)->
    #         expect(result.primes.length).to.eql(0)
    #         done()
    #     )
    #     .fail((err)->
    #         done(err)
    #     )
    # )

    it("should persist the primes", (done)->
        Store.qMGet("primeTbl", [0])
        .then((result)->
            expect(result[0]).to.have.lengthOf.above(0)
            done()
        )
        .fail((err)->
            done(err)
        )
    )

    it.skip("should be able to generate primes until #{MAX_BOUND}", (done)->
        PrimeNumberGetter.qGenerate(MAX_BOUND)
        .then(()->
            PrimeNumberGetter.qGetPrimes(0, MAX_BOUND)
            .then((result)->
                expect(result.primes).to.have.lengthOf.above(0)
                done()
            )
        )
        .fail((err)->
            done(err)
        )
    )    
)
