
chai = require("chai")
assert = chai.assert
expect = chai.expect 
_ = require("lodash")

Primality = require("../lib/js/TrailDivPrimality")

primeNumbers = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97]
primeTable = []

describe("TrailDivision PrimalityTest - ", ->

    before((done)->
        _.each(primeNumbers, (value, index)->
            primeTable[value] = true
        )
        done()
    )

    it("check if negative number is a prime", (done)->
        isPrime = Primality.isPrime(-7)
        expect(isPrime).to.equal(false)
        done()
    )

    it("check if 0,1 is a prime", (done)->
        isPrime = Primality.isPrime(0)
        expect(isPrime).to.equal(false)

        isPrime = Primality.isPrime(1)
        expect(isPrime).to.equal(false)
        done()
    )

    it("test primes between 1-100", (done)->
        count = 0
        max = 100
        _.each([1..max], (n)->
            isPrime = Primality.isPrime(n)
            if isPrime is true
                ++count

            # if isPrime is true then console.log("#{n} is prime")

            if primeTable[n] is true and isPrime isnt true 
                expect(n).to.equal(!isPrime)
        )
        done()
    )

    it("count primes 1 - 1024", (done)->
        count = 0
        pow = 10
        max = Math.pow(2, pow)
        _.each([1..max], (n)->
            isPrime = Primality.isPrime(n)
            if isPrime is true
                ++count
        )
        expect(count).to.equal(172)
        done()
    )

    it("count primes (1-1024) using big number", (done)->
        count = 0
        pow = 10
        max = Math.pow(2, pow)
        _.each([1..max], (n)->
            isPrime = Primality.isPrimeUsingBigNum(n)
            if isPrime is true
                ++count
        )
        expect(count).to.equal(172)
        done()
    )
)
