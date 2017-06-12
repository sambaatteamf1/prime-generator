
math = require("mathjs")
_ = require("lodash")

sieve = null
sieveLength = 0

NumberType = {
    PRIME  : 1
    COMPOSITE : 0
}


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

# See https://en.wikipedia.org/wiki/Sieve_of_Eratosthenes

# Input: an integer n > 1.

# Let A be an array of Boolean values, indexed by integers 2 to n,
# initially all set to true.

# for i = 2, 3, 4, ..., not exceeding √n:
#   if A[i] is true:
#     for j = i2, i2+i, i2+2i, i2+3i, ..., not exceeding n:
#       A[j] := false.


init = (max)->

    sieveLength = max + 1

    sieve = new Int8Array(sieveLength)

    # initially all set to true.
    sieve[index] = NumberType.PRIME for index in [0..max] by 1

    # set all even as false
    sieve[index] = NumberType.COMPOSITE for index in [0..max] by 2

    # 0,1 are not primes
    sieve[0] = NumberType.COMPOSITE
    sieve[1] = NumberType.COMPOSITE
    sieve[2] = NumberType.PRIME

    n = math.sqrt(max)

    for index in [2..n] by 1

        if sieve[index] is NumberType.PRIME

            isquared = index * index 

            for j in [isquared..max] by index
                sieve[j] = NumberType.COMPOSITE

    return

isPrime = (n)-> 

    if n > sieveLength - 1
        return false

    type = sieve[n]

    if type is NumberType.COMPOSITE
        return false

    return true        

module.exports = {
    init : init
    isPrime : isPrime
}