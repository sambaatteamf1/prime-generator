math = require("mathjs")
BigNumber = require("bignumber.js")


# @function isPrime
#
# This function checks if a number is a prime using trail division
# Trail division can be used for not very large numbers. See https://en.wikipedia.org/wiki/Primality_test
# All prime numbers are of the form 30k + i for i = 1, 7, 11, 13, 17, 19, 23, 29
# 
# @param n
# @returns {Boolean} : true or false 


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


# @function isPrimeUsingBigNum
#
# This function checks if a big number is a prime using trail division
# Trail division can be used for not very large numbers. 
# See https://en.wikipedia.org/wiki/Primality_test
#
# All prime numbers are of the form 
#
# 30k + i for i = 1, 7, 11, 13, 17, 19, 23, 29
#
# @param n
# @returns {Boolean} : true or false 

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

# @function init
#
# This function initializes the primality tester
# 
# @param :
#
# @returns  : 

init = () ->


module.exports = {
    isPrime :  isPrime
    isPrimeUsingBigNum :  isPrimeUsingBigNum
    init : init
}