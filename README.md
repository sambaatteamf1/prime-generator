### Status
[![Build Status](https://travis-ci.org/sambaatteamf1/prime-generator.svg?branch=master)](https://travis-ci.org/sambaatteamf1/prime-generator)

# Prime Number App

Generates all prime numbers between 1 to X where X is a command line argument to the application

The prime numbers are stored in a local Redis instance. Once the prime numbers are generated the 
application repeatedly asks the user for a lower and upper bounds (inclusive) 
on the prime numbers to return along with their sum and mean

```
$ node app.js --h

Usage: nodejs app.js [-s <redis,memory>]  [-c <chunkSize>] [-P <parallel>] [ -m <method> ] X

   -s  --store : store for prime numbers. 'redis' or 'memory'. Default = redis
   -c  --chunk : number of prime numbers to store in one row. Default = 1024
   -P  --parallel : number of rows to fetch from store in parallel'. Default = 5
   -m  --method : primality check method 'division' or 'sieve' '. Default = sieve

X can take values in the range  (1 - pow(2, 25)]. 
```

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
### Code Organization
This section shows the code organization in this project.

```
prime-generator
    |           +--test 
    |           | (unit test files) 
    + coffee----+
    | (source files)
    |              
    |
    + lib (compiled js files)
    |
    + node_modules (external dependencies)
    |
    + test (compiled test files) 
    |
   app.js 
 (starter js file)
 
```
The implementation is done in coffeescript. The code is compiled into javascript using grunt. <br>
node_modules, lib and test directories are created after running the build.sh script.

### Improvements

The following impovements can further be done 

* The primality testing with deterministic algos is slower (trial divison, sieve).
  The seive algorithm consumes memory proportional to the max number of the sieve. 
  Primality testing can be improved using probabilistic algos like rabin-miller

* Limit printing of prime numbers in the console.

* The prime sum table is currently being cached in memory. It can also be saved in redis

* To make the implementation more generic for bigger prime numbers (and avoid overflows), 
  big numbers must be used. In javascript, pow(2, 53) - 1 is the max safe integer

* Add more command line options for - max limit
 
* Add benchmarking test suite for various primality generation methods

* All data stored in redis is being serialized using strings (JSON.stringify) 
  Performance can be improved using binary buffers.
  
* As the max primes limit is increased, the entire primes table can no longer be
  stored in memory during prime number generation.

