Q = require("q")
_ = require("lodash")
ErrorTypes = require("../lib/js/ErrorTypes")

class MockStore

    constructor: () ->
        @db = {}
        return

    qGet: (tableName, rowid) ->
        self = this 
        q = Q.defer()

        unless rowid?
            q.reject(ErrorTypes.StoreGetInvalidArgError)
            return q.promise

        htable = self.db[tableName]
        unless htable?
            q.reject(ErrorTypes.StoreGetInvalidArgError)
            return q.promise

        q.resolve(htable[rowid])
        return q.promise

    qMGet: (tableName, rowArr) ->
        self = this 
        q = Q.defer()

        unless rowArr?
            q.reject(ErrorTypes.StoreGetInvalidArgError)
            return q.promise

        htable = self.db[tableName]
        unless htable?
            q.reject(ErrorTypes.StoreGetInvalidArgError)
            return q.promise

        records = {}

        _.each(rowArr, (index, value)->
            records[index] = htable[value] or []
        )

        q.resolve(records)
        return q.promise

    qSet: (tableName, rowid, obj) ->
        self = this 
        q = Q.defer()
        
        unless rowid?
            q.reject(ErrorTypes.StoreSetInvalidArgError)
            return q.promise

        htable = self.db[tableName]
        unless htable?
            self.db[tableName] = {}
            htable = self.db[tableName]            
            
        htable[rowid] = obj
        q.resolve()
        return q.promise    

    qGetTable : (tableName) ->
        self = this 
        q = Q.defer()

        htable = self.db[tableName]
        unless htable?
            q.resolve({})
            return q.promise

        q.resolve(htable)     

        return q.promise

    qSetTable : (tableName, records) ->
        self = this 
        q = Q.defer()

        htable = self.db[tableName]
        unless htable?
            self.db[tableName] = {}
            htable = self.db[tableName]

        _.each(records, (key, value)->
            htable[key] = value
        )

        q.resolve()
        return q.promise

    qDeleteTable : (tableName) ->
        self = this 
        q = Q.defer()

        htable = self.db[tableName]
        unless htable?
            q.reject(ErrorTypes.StoreSetInvalidArgError)
            return q.promise

        delete self.db[tableName]

        q.resolve()
        return q.promise

    qScan: (tableName, cursor, count=10) ->
        self = this 
        q = Q.defer()

        unless tableName?
            q.reject(ErrorTypes.StoreScanInvalidArgError)
            return q.promise

        records = {}

        htable = self.db[tableName]

        size = _.size(htable)

        if cursor? and cursor >= size
            q.resolve({cursor : 0, records : records })
            return q.promise
       
        newcursor = cursor
        _.each(htable, (obj, index)->
            if index <= cursor
                return

            if count is 0
                return false

            --count
            records[index] = obj
            newcursor = index
        )

        q.resolve({ cursor : newcursor, records : records})
        return q.promise


module.exports = MockStore        