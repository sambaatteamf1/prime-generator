### Status
[![Build Status](https://travis-ci.org/sambaatteamf1/prime-generator.svg?branch=master)](https://travis-ci.org/sambaatteamf1/prime-generator)

# Prime Number App

Generates all prime numbers between 1 to X where X is a command line argument to the application

The prime numbers are stored in a local Redis instance. Once the prime numbers are generated the 
application repeatedly asks the user for a lower and upper bounds (inclusive) 
on the prime numbers to return along with their sum and mean

X can take values in the range  (1 - pow(2, 25)]. 

Example flow:

```
$ node app.js 100

Enter a lower bound: 3
Enter an upper bound: 9
Result:
Prime numbers: [3, 5, 7]
Sum: 15
Mean: 5

```
This application has been tested with node 4.x 


## Build & install

The section lists the steps to install and build the application

### Pre-requsites
1. Install node
```
$ curl -sL https://deb.nodesource.com/setup_4.x | sudo -E bash -
$ sudo apt-get install -y nodejs
```

2. Install npm
```
$ sudo apt-get install -y npm
```
3. The application uses redis by default to persist prime numbers. Make sure you have and installation of redis available
```
   $ sudo apt-get install redis-server
```

### Build

1. Clone repo or download tarball.
```
   $ git clone https://github.com/sambaatteamf1/prime-generator.git
```

2. Build

```
$ cd SOURCE_DIRECTORY
$ ./build.sh
```

### Test
```
$ cd SOURCE_DIRECTORY
$ ./test.sh
```
### Improvements

The following impovements can further be done 

* The primality testing with tail division in not computationally efficient.
  It can be improved by using - prime number sieves or probabilistic algos like rabin-miller

* Limit printing of prime numbers in the console.

* The prime sum table is currently being cached in memory. It can also be saved in redis

* To make the implementation more generic for bigger prime numbers (and avoid overflows), 
  big numbers must be used. In javascript, pow(2, 53) - 1 is the max safe integer

* Add more command line options for - store type, primality checking method, max limit
 
* Add benchmarking test suite for various primality generation methods

* All data stored in redis is being serialized using strings (JSON.stringify) 
  Performance can be improved using binary buffers.
  
* As the max primes limit is increased, the entire primes table can no longer be
  stored in memory during prime number generation.

