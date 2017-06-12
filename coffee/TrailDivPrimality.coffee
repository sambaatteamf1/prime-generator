math = require("mathjs")
BigNumber = require("bignumber.js")


# Trail division (Not for very large numbers) 
# See https://en.wikipedia.org/wiki/Primality_test
# Summary: All prime numbers are of the form 30k + i for i = 1, 7, 11, 13, 17, 19, 23, 29
# Returns : true or false 
isPrime = (n) ->
    if n <= 1
        return false
    else if n <=3
        return true
    else if n % 2 is 0 or n % 3 is 0
        return false
    
    index = 5

    # For very big, i*i will overflow
    max = math.sqrt(n)

    while index <= max

        if n % index is 0 or n % (index + 2) is 0
            return false

        index = index + 6

    return true                                         


isPrimeUsingBigNum = (n) ->
    n = new BigNumber(n)
    
    if n.lte(1)
        return false
    else if n.lte(3)
        return true
    else if n.mod(2).equals(0) or n.mod(3).equals(0)
        return false
    
    index = new BigNumber(5)
    
    max = n.sqrt()
    while index.lte(max)

        nextIndex = index.plus(2)
        
        if n.mod(index).equals(0) or n.mod(nextIndex).equals(0)
            return false

        index = index.plus(6)

    return true

init = () ->

# Our method is to pre-compute a large number of primes and store them on disk. 
# If n is within the bounds of the pre-computed list, it is easy to find the next prime. 
# But if n is too large, we revert to checking individual candidates for primality.

# The sieve of Eratosthenes is a popular way to benchmark computer performance.
# As can be seen from the above by removing all constant offsets and constant 
# factors and ignoring terms that tend to zero as n approaches infinity, the time 
# complexity of calculating all primes below n in the random access machine model 
# is O(n log log n) operations, a direct consequence of the fact that the prime 
# harmonic series asymptotically approaches log log n. 
# It has an exponential time complexity with regard to input size, though, 
# which makes it a pseudo-polynomial algorithm. 
# The basic algorithm requires O(n) of memory.


module.exports = {
    isPrime :  isPrime
    isPrimeUsingBigNum :  isPrimeUsingBigNum
    init : init
}