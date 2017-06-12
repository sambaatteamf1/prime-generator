
redis = require("redis")
Q = require("q")
_ = require("lodash")
debug = require('debug')('Store')
ErrorTypes = require("./ErrorTypes")

# 
#
# Store/cache objects
# 

REDIS_SERVER = process.env.REDIS_SERVER or "localhost"
REDIS_PORT = process.env.REDIS_PORT or 6379

class RedisStore 

    constuctor: (@port, @host)->
        @client = null
        unless @port?
            @port = REDIS_PORT

        unless @host?
            @host = REDIS_SERVER

    qGetClient = (self)->
        if self.client? then return Q(self.client)

        q = Q.defer()

        options = {
            socket_keepalive : true
            detect_buffers : true
        }

        self.client = redis.createClient(self.port, self.host, options)
        self.client.on("error", (err)->
            return q.reject(err)
        )

        self.client.on("ready", ()->
            return q.resolve(self.client)
        )

        self.client.on("end", ()->
            self.client = null
        )
        return q.promise

    # Deletes the table        
    qDeleteTable: (key) ->
        self = this
        q = Q.defer()

        unless key?
            q.reject(ErrorTypes.StoreTableDelInvalidArgError)
            return q.promise

        qGetClient(self)
        .then((client)->
            qDel = Q.nbind(client.del, client)
            qDel(key)
            .then(()->
                return q.resolve()
            )
        )
        .fail((err)->
            return q.reject(err)
        )
        return q.promise

    # Delete a field in the table     
    qDeleteField: (key, field) ->
        self = this
        q = Q.defer()

        unless key?
            q.reject(ErrorTypes.StoreFieldDelInvalidArgError)
            return q.promise

        qGetClient(self)
        .then((client)->
            qDel = Q.nbind(client.hdel, client)
            qDel(key, field)
            .then(()->
                return q.resolve()
            )
        )
        .fail((err)->
            return q.reject(err)
        )
        return q.promise

    qMGet : (key, fieldArr) ->
        self = this
        q = Q.defer()

        debug('getting key=%s fieldArr=%s', key, fieldArr);

        unless key? or fieldArr?
            q.reject(ErrorTypes.StoreGetInvalidArgError)
            return q.promise

        qGetClient(self)
        .then((client)->
            unless client?
                return q.reject(ErrorTypes.StoreConnLostError)

            qGetter = Q.nbind(client.hmget, client)
            qGetter(key, fieldArr)
            .then((valueArr)->
                records = []

                _.each(valueArr, (value, index)->

                    try
                        records[index] = JSON.parse(value)
                    catch e
                        return q.reject(ErrorTypes.StoreGetInvalidObjError)
                )

                debug('getting key=%s done', key);
                return q.resolve(records)
            )
        )
        .fail((err)->
            debug('getting failed with error:', err)
            return q.reject(err)
        )
        return q.promise        

    qGet:(key, field) ->        
        self = this
        q = Q.defer()

        debug('getting key=%s field=%s', key, field);

        unless key? or field?
            q.reject(ErrorTypes.StoreGetInvalidArgError)
            return q.promise

        qGetClient(self)
        .then((client)->
            unless client?
                return q.reject(ErrorTypes.StoreConnLostError)

            qGetter = Q.nbind(client.hget, client)
            qGetter(key, field)
            .then((value)->
                try
                    obj = JSON.parse(value)
                catch e
                    return q.reject(ErrorTypes.StoreGetInvalidObjError)
                
                debug('getting key=%s done', key);
                return q.resolve(obj)
            )
        )
        .fail((err)->
            debug('getting failed with error:', err)
            return q.reject(err)
        )
        return q.promise

    qSetTable : (key, records) ->
        self = this
        q = Q.defer()

        debug('setting key=%s ', key);

        unless key? or records?
            q.reject(ErrorTypes.StoreGetInvalidArgError)
            return q.promise

        kvpairs = [key]            
        _.each(records, (v, k)->
            kvpairs.push(k)
            kvpairs.push(v)
        )
            
        qGetClient(self)
        .then((client)->
            unless client?
                return q.reject(ErrorTypes.StoreConnLostError)

            qSetter = Q.nbind(client.hmset, client)
            qSetter(kvpairs)
            .then((valueArr)->
                debug('setting key=%s done', key);
                return q.resolve()
            )
        )
        .fail((err)->
            debug('getting failed with error:', err)
            return q.reject(err)
        )
        return q.promise

    qGetTable : (key) ->
        self = this
        q = Q.defer()

        debug('getting table=%s ', key);

        unless key?
            q.reject(ErrorTypes.StoreGetInvalidArgError)
            return q.promise

        qGetClient(self)
        .then((client)->
            unless client?
                return q.reject(ErrorTypes.StoreConnLostError)

            qGetter = Q.nbind(client.hgetall, client)
            qGetter(key)
            .then((records)->
                debug('getting table=%s done', key);
                return q.resolve(records)
            )
        )
        .fail((err)->
            debug('getting failed with error:', err)
            return q.reject(err)
        )
        return q.promise

    qSet : (key, field, obj) ->        
        self = this
        q = Q.defer()


        unless key? or field? or obj?
            q.reject(ErrorTypes.StoreSetInvalidArgError)
            return q.promise

        debug('setting key=%s field=%s', key, field);
            
        qGetClient(self)
        .then((client)->

            unless client?
                return q.reject(ErrorTypes.StoreConnLostError)

            try
                value = JSON.stringify(obj)
            catch e
                return q.reject(ErrorTypes.StoreSetInvalidObjError)
            
            qSetter = Q.nbind(client.hset, client)
            qSetter(key, field, value)
            .then(()->
                debug('setting key=%s done', key);
                return q.resolve()
            )
        )
        .fail((err)->
            debug('setting failed with error:', err)
            return q.reject(err)
        )
        return q.promise


    qScan : (key, cursor=0, count=10) ->        
        self = this
        q = Q.defer()

        unless key?
            q.reject(ErrorTypes.StoreScanInvalidArgError)
            return q.promise

        debug('scanning key=%s ', key);

        qGetClient(self)
        .then((client)->

            unless client?
                return q.reject(ErrorTypes.StoreConnLostError)

            qScanner = Q.nbind(client.hscan, client)
            promise = qScanner(key, cursor, "count", count)

            promise.then((results)->
                cursor = Number(results[0])

                flatTable = results[1] or []
                records = {}

                id = ""
                _.each(flatTable, (obj, index)->

                    if index % 2 is 0
                        id = obj
                        return

                    records[id] = JSON.parse(obj)
                    return
                )
                debug('scanning of key=%s done', key);
                return q.resolve({cursor : cursor, records : records })
            )

            return promise    
        )
        .fail((err)->
            debug('scanning of key=%s failed with error:%s', key, err);
            return q.reject(err)
        )
        return q.promise



# Every prime number can be expressed as 30k±1, 30k±7, 30k±11, or 30k±13 for some k. 
# That means we can use eight bits per thirty numbers to store all the primes; 
# a million primes can be compressed to 33,334 bytes, plus a small program to 
# load the compressed primes from disk and to manipulate the compressed data structure

###
# Naively, one may expect that the number of primes in an interval (x,y](x,y], 
# for large xx is about (y−x)/logx(y−x)/log⁡x, and in a heuristic formula, 
# See https://math.stackexchange.com/questions/288747/how-to-find-number-of-prime-numbers-between-two-integers
###

module.exports = RedisStore