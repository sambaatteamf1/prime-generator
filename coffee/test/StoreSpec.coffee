
chai = require("chai")
assert = chai.assert
expect = chai.expect 
_ = require("lodash")
Q = require("q")

TableStore = require("../lib/js/Store")

tableName = "testPrimeTable"
Store = null


primeNumbers = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97]

describe("StoreSpec - ", ->

    before((done)->
        Store = new TableStore()
        done()
    )

    it("Set a key/value in store", (done)->
        Store.qSet(tableName, 0, primeNumbers)
        .then(()->
            Store.qGet(tableName, 0)
            .then((numArr)->
                expect(numArr).to.eql(primeNumbers)
                done()
            )
        )
        .fail((err)->
            done(err)
        )
    )

    it("Scan entries in a store", (done)->
        promiseArr = []

        _.each([0..12], (index)->
            promiseArr.push(Store.qSet(tableName, index, primeNumbers))
        )

        Q.allSettled(promiseArr)
        .then(()->
            Store.qScan(tableName, 0, 5)
            .then((scanResults)->
                cursor = scanResults.cursor
                records = scanResults.records

                size = _.size(records)

                expect(size).to.be.at.least(5)

                _.each(records, (numArr, key)->
                    expect(numArr).to.eql(primeNumbers)
                )
                done()
            )
        )
        .fail((err)->
            done(err)
        )
    )

    it("Get multiple entries from the store in the same order", (done)->
        promiseArr = []
        prime1To200 = [ 101, 103, 107, 109, 113, 127, 131, 137, 139, 149, 151, 157, 163, 167, 173, 179, 181, 191, 193, 197, 199 ]

        promiseArr.push(Store.qSet(tableName, 0, primeNumbers))
        promiseArr.push(Store.qSet(tableName, 1, prime1To200))

        Q.allSettled(promiseArr)
        .then(()->
            fieldArr = [0..1]

            Store.qMGet(tableName, fieldArr)
            .then((numArr)->
                expect(_.size(numArr)).to.be.eql(_.size(fieldArr))
                expect(numArr[0]).to.eql(primeNumbers)
                expect(numArr[1]).to.eql(prime1To200)
                done()
            )
        )
        .fail((err)->
            done(err)
        )
    )

    after((done)->
        Store.qDeleteTable(tableName)
        .finally(()->
            done()
        )
    )
)