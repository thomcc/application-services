package org.mozilla.logins_example

import android.Manifest
import android.os.Bundle
import android.os.Environment
import android.support.design.widget.Snackbar
import android.support.v7.app.AppCompatActivity
import android.util.Log
import android.view.Menu
import android.view.MenuItem

import org.mozilla.loginsapi.Api

import kotlinx.android.synthetic.main.activity_main.*
import kotlinx.android.synthetic.main.content_main.*
//import jdk.nashorn.internal.runtime.ScriptingFunctions.readLine
import android.os.Environment.getExternalStorageDirectory
import android.view.View
import com.beust.klaxon.JsonObject
import com.beust.klaxon.Klaxon
import com.beust.klaxon.Parser
import org.mozilla.loginsapi.LoginsStore
import org.mozilla.loginsapi.RustException
import org.mozilla.loginsapi.ServerPassword
import android.content.pm.PackageManager
import android.Manifest.permission
import android.Manifest.permission.WRITE_EXTERNAL_STORAGE
import android.annotation.SuppressLint
import android.content.Context
import android.support.v4.content.ContextCompat
import java.io.*


class MainActivity : AppCompatActivity() {
    var store: LoginsStore? = null;

    fun dumpError(tag: String, e: RustException) {
        val sw = StringWriter();
        val pw = PrintWriter(sw);
        e.printStackTrace(pw);
        val stack = sw.toString();
        Log.e(tag, e.message);
        Log.e(tag, stack);
        this.editText.setText("rust error (${tag}): : ${e.message}\n\n${stack}\n");
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        setSupportActionBar(toolbar)
        checkPermissions();
        fab.setOnClickListener(fun(view: View?) { // apparently we need to use `fun` to early return...
            Log.d("TEST", "Clicked!")
            Snackbar.make(view!!, "Loading logins...", Snackbar.LENGTH_LONG)
                    .setAction("Action", null).show()
            if (this.store == null) {
                try {
                    this.store = initFromCredentials();
                } catch (e: RustException) {
                    dumpError("LoginInit: ", e);
                    return
                }
            }
            try {
                this.store!!.sync()
            } catch (e: RustException) {
                dumpError("LoginSync: ", e);
                return;
            }
            val logins: List<ServerPassword>;
            try {
                logins = this.store!!.list();
            } catch (e: RustException) {
                dumpError("LoginList: ", e);
                return;
            }
            val b = StringBuffer();
            b.append("Got ${logins.count()} logins\n\n");
            for (login in logins) {
                b.append("${login.hostname} (${login.username}/${login.password})")
                b.append('\n')
            }

            this.editText.setText(b.toString())
        })

    }

    override fun onCreateOptionsMenu(menu: Menu): Boolean {
        // Inflate the menu; this adds items to the action bar if it is present.
        menuInflater.inflate(R.menu.menu_main, menu)
        return true
    }

    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        // Handle action bar item clicks here. The action bar will
        // automatically handle clicks on the Home/Up button, so long
        // as you specify a parent activity in AndroidManifest.xml.
        return when (item.itemId) {
            R.id.action_settings -> true
            else -> super.onOptionsItemSelected(item)
        }
    }

    fun checkPermissions() {
        val permissionCheck = ContextCompat.checkSelfPermission(this, Manifest.permission.WRITE_EXTERNAL_STORAGE);

        if (permissionCheck == PackageManager.PERMISSION_GRANTED) {
            Log.d("LoginsSampleApp", "Got Permission!");
        } else {
            requestPermissions(arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE), 1);
        }
    }

    // We expect you to put credentials.json right in the sdcard root so...
    @SuppressLint("SdCardPath")
    fun initFromCredentials(): LoginsStore {
        val file = File("/sdcard/credentials.json")
        // The format is a bit weird so I'm not sure if I can map this make klaxon do the
        // deserializing for us...
        val o = Parser().parse(file.inputStream()) as JsonObject
        val info = o.obj("keys")!!.obj("https://identity.mozilla.com/apps/oldsync")!!
        val appFiles = this.applicationContext.getExternalFilesDir(null)
        val store = Api.createLoginsStore(
                databasePath   = appFiles.absolutePath + "/logins.mentatdb",
                metadataPath   = appFiles.absolutePath + "/login-metadata.json",
                databaseKey    = "my_secret_key",
                kid            = info.string("kid")!!,
                accessToken    = o.string("access_token")!!,
                syncKey        = info.string("k")!!,
                tokenserverURL = "https://oauth-sync.dev.lcip.org/syncserver/token"
        )
        return store
    }
}
