package org.mozilla.loginsapi

import org.mozilla.loginsapi.rust.JNA
import android.util.Log
import com.beust.klaxon.Klaxon

class Api {
    companion object {
        fun createLoginsStore(): LoginsStore {
            Log.d("API", "in the module")
            return LoginsStore()
        }
    }
}

class LoginsStore {
    fun prepare() {

    }

    fun list() {

    }

    fun get(id: String): ServerPassword {
        val json = JNA.INSTANCE.get(id)
        val serverPassword = Klaxon().parse<ServerPassword>(json)!!
        JNA.INSTANCE.destroy_c_char(json)
        return serverPassword
    }
}

// TODO: better types (eg, uuid for id? Time-specific fields? etc)
class ServerPassword (
    val id: String,

    val hostname: String,
    val username: String?,
    val password: String,

    // either one of httpReal or formSubmitURL will be non-null, but not both.
    val httpRealm: String? = null,
    val formSubmitURL: String? = null,

    val timesUsed: Int,

    val timeCreated: Long,

    val timeLastUsed: Long,

    val timePasswordChanged: Long,

    val usernameField: String? = null,
    val passwordField: String? = null
)
