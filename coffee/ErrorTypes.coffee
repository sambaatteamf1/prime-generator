module.exports = {
    StoreConnLostError : new Error("STORE_CONN_LOST")

    StoreGetInvalidArgError: new Error("STORE_GET_INVALID_ARG")
    StoreGetInvalidObjError: new Error("STORE_GET_INVALID_OBJ")
    
    StoreSetInvalidArgError: new Error("STORE_SET_INVALID_ARG")
    StoreSetInvalidObjError: new Error("STORE_SET_INVALID_OBJ")

    StoreScanInvalidArgError: new Error("STORE_SCAN_INVALID_ARG")

    StoreTableDelInvalidArgError : new Error("STORE_TABLE_DEL_INVALID_ARG")
    StoreFieldDelInvalidArgError : new Error("STORE_FIELD_DEL_INVALID_ARG")

    PrimeGenIntrnalError : new Error("PRIME_GEN_ERR_INTERNAL")
}