package org.mozilla.loginsapi.rust
import com.sun.jna.Library
import com.sun.jna.Native
import com.sun.jna.Pointer
import com.sun.jna.PointerType


@Suppress("FunctionNaming", "TooManyFunctions", "TooGenericExceptionThrown")
internal interface PasswordSyncAdapter : Library {
    companion object {
        private const val JNA_LIBRARY_NAME = "loginsapi_ffi"
        internal var INSTANCE: PasswordSyncAdapter

        init {
            System.loadLibrary("crypto")
            System.loadLibrary("ssl")
            System.loadLibrary("sqlcipher")
            System.loadLibrary("loginsapi_ffi")
            INSTANCE = Native.loadLibrary(JNA_LIBRARY_NAME, PasswordSyncAdapter::class.java) as PasswordSyncAdapter
        }
    }

    fun sync15_passwords_state_new(
            mentat_db_path: String,
            encryption_key: String,

            key_id: String,
            access_token: String,
            sync_key: String,
            token_server_base_url: String,

            error: RustError.ByReference
    ): RawLoginSyncState

    fun sync15_passwords_state_destroy(p: RawLoginSyncState)

    // Important: strings returned from rust as *char must be Pointers on this end, returning a
    // String will work but either force us to leak them, or cause us to corrupt the heap (when we
    // free them).

    // Returns null if the id does not exist, otherwise json
    fun sync15_passwords_get_by_id(state: RawLoginSyncState, id: String, error: RustError.ByReference): Pointer

    // return json array
    fun sync15_passwords_get_all(state: RawLoginSyncState, error: RustError.ByReference): Pointer

    fun sync15_passwords_sync(state: RawLoginSyncState, error: RustError.ByReference)

    fun sync15_passwords_wipe(state: RawLoginSyncState, error: RustError.ByReference)
    fun sync15_passwords_reset(state: RawLoginSyncState, error: RustError.ByReference)

    fun sync15_passwords_touch(state: RawLoginSyncState, id: String, error: RustError.ByReference)
    fun sync15_passwords_delete(state: RawLoginSyncState, id: String, error: RustError.ByReference)

    fun destroy_c_char(p: Pointer)
}

class RawLoginSyncState : PointerType()