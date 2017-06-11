# Prime Number App

## Summary

Generates all prime numbers between 1 to X where X is a command line argument to the application

The prime numbers are stored in a local Redis instance. Once the prime numbers are generated the 
application repeatedly asks the user for a lower and upper bounds (inclusive) 
on the prime numbers to return along with their sum and mean

Example flow:

`
$ node app.js 100

Enter a lower bound: 3
Enter an upper bound: 9
Result:
Prime numbers: [3, 5, 7]
Sum: 15
Mean: 5

`

## Build & install

The steps below lists the steps to get ready to run the application

### Pre-requsites
1. Install node (v4.6.2)
`
$ curl -sL https://deb.nodesource.com/setup_4.x | sudo -E bash -
$ sudo apt-get install -y nodejs
`

2. Install npm (v2.5.11)
`
$ sudo apt-get install -y npm
`
3. The application uses redis by default to persist prime numbers. Make sure you have and installation of redis available
`
   $ sudo apt-get install redis-server
`  

### Build

1. Clone repo or download tarball.
`
   $ git clone https://github.com/sambaatteamf1/prime-generator.git
`

2. Build

`
$ cd SOURCE_DIRECTORY
$ ./build.sh
`

### Test
`
$ cd SOURCE_DIRECTORY
$ ./test.sh
`