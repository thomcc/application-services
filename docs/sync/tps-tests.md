---
id: tps-tests
title: TPS Tests
sidebar_label: TPS Tests
---

TPS is an end to end test for Sync. Its name stands for Testing and
Profiling tool for Sync (which is a misnomer, since it doesn't do any
profiling), and it should not be confused with the [similarly named
tests in Talos](https://wiki.mozilla.org/Buildbot/Talos/Tests#tps).

TPS consists of a Firefox extension of the same name, along with a
Python test runner, both of which live inside `mozilla-central`. The
Python test runner will read a test file (in JavaScript format), setup
one or more Firefox profiles with the necessary extensions and
preferences, then launch Firefox and pass the test file to the
extension. The extension will read the test file and perform a series of
actions specified therein, such as populating a set of bookmarks,
syncing to the Sync server, making bookmark modifications, etc.

A test file may contain an arbitrary number of sections, each involving
the same or different profiles, so that one test file may be used to
test the effect of syncing and modifying a common set of data (from a
single Sync account) over a series of different events and clients.

Set up an environment and run a test
------------------------------------

To run TPS, you should [create a new firefox
account](https://accounts.firefox.com/) using a
[restmail.net](http://restmail.net/) email address (Strictly speaking,
restmail isn't required, but it will allow TPS to automatically do
account confirmation steps for you. Even if you opt not to use restmail,
**do not** use your personal firefox account, as TPS will delete and
replace the data in it many times, not to mention the first run is very
likely to fail, since it expects a clean start).

Note: Be prepared not to use your computer for 15 or so minutes after
starting a full run of TPS, as it will open and close a fairly large
number of Firefox windows.

### Steps

1.  Get the source code

    Clone mozilla-central (choose your flavor):

        hg clone hg.mozilla.org/mozilla-central

    or

        git clone github.com/mozilla/gecko-dev

2.  cd into the tps folder

        cd testing/tps

3.  Create the environment

    I suggest the path to be outside of the mc source tree:

        Python create_venv.py --username=%EMAIL% --password=%PASSWORD% %PATH%

4.  Activate the environment

        source %PATH%/bin/activate

5.  Run some tests

  Note that the `testfile` is NOT a path, it should only be the filename
  from `services/sync/tests/tps/`

    runtps --debug --testfile %TEST_FILE_NAME% --binary %FIREFOX_BINARY_PATH%

  1.  Additionally, omitting a `--testfile` parameter will cause it to
      run all TPS tests listed in
      `services/sync/tests/tps/all_tests.json`
  2.  You can also prefix with `MOZ_HEADLESS=1` to run in [headless
      mode](/en-US/docs/Mozilla/Firefox/Headless_mode) (recommended)

An example on OSX, for headlessly running just the `test_sync.js`
testfile against a locally built firefox (where the mozconfig set the
objdir to `obj-ff-artifact`):

    MOZ_HEADLESS=1 runtps --debug --testfile test_sync.js --binary obj-ff-artifact/dist/Nightly.app/Contents/MacOS/firefox

Running TPS against stage, or dev FxA
-------------------------------------

TPS can be configured using the `$TPS_VENV_PATH/config.json` file. In
particular, it will set preferences from the `"preferences"` property,
and so you can set the `"identity.fxaccounts.autoconfig.uri"` preference
to point to any FxA server you want. For example, a (partial) tps config
for testing against stage might look like:

```json
{
  // ...
  "fx_account": {
    "username": "foobar@restmail.net",
    "password": "hunter2"
  },
  "preferences": {
    // use "https://stable.dev.lcip.org" for dev instead of stage
    "identity.fxaccounts.autoconfig.uri": "https://accounts.stage.mozaws.net"
    // possibly more preferences...
  },
  // ...
}
```

Note that in this example, the `foobar@restmail.net` account must be
registered on stage, otherwise authentication will fail (and the whole
test will fail as well.  You can sign up for an FxA account on stage or
dev by creating an FxA account after adding
the `identity.fxaccounts.autoconfig.uri` preference (with the
appropriate value) to `about:config`. Additionally, note that the config
file must parse as valid JSON, and so you can't have comments in it
(sorry, I know this is annoying). One alternative is to put underscores
before the "disabled" preferences, e.g.
`"_identity.fxaccounts.autoconfig.uri": "..."`.

Writing TPS tests.
------------------

Each TPS test is run as a series of "phases". A phase runs in some
firefox profile, and contains some set of actions to perform or check on
that profile. Phases have an N to M relationship with profiles, where N
\>= M (there can never be more phases than profiles). Typically there
are two profiles used, but any number of profiles could be used in
theory (other than 0).

After the phases run, two additional "cleanup" phases are run, to
unregister the devices with FxA. This is an implementation detail, but
if you work with TPS for any amount of time you will almost certainly
see `cleanup-profile1` or similar in the logs. That's what that phase is
doing, it does any necessary cleanup for the phase, primarially
unregistering the device associated with that profile.

TPS tests tend to be broken down into three sections, in the following
order (we'll cover these out of order, for the sake of simplicity)

1.  Phase declarations (mandatory).
2.  Data definitions/asset list (optional, but all current tests have
    them).
3.  Phase implementation (mandatory)

It's worth noting that some parts of TPS assume that it can read the
number off the end of the phase or profile to get to the next one, so
try to stick to the convention established in the other tests. Yes, this
is cludgey, but it's effective enough and nobody has changed it.

### Phase Declarations

These map the phases to profiles. Both Python and JavaScript read them
in. They ***must*** look like:

```js
 var phases = { "phase1": "profile1", "phase2": "profile2", "phase3": "profile1" };
```

Between `{` and `}` it must be ***strict JSON***. e.g. quoted keys, no
trailing parentheses, etc. The Python testrunner will be parsing it with
an unforgiving call to `json.loads`, so anything other than strict JSON
will fail.

You can use as many profiles or phases as you need, but every phase you
define later must be declared here, or it will not be run by the Python
test runner. Any phases declared here but not implemented later will
cause the test to fail when it hits that phase.

### Asset lists

A test file will contain one or more asset lists, which are lists of
bookmarks, passwords, or other types of browser data that are relevant
to Sync. The format of these asset lists vary somwhat depending on asset
type.

-   [Bookmarks](https://developer.mozilla.org/en-US/docs/Mozilla/Projects/TPS/TPS_Bookmark_Lists)
-   [Passwords](https://developer.mozilla.org/en-US/docs/Mozilla/Projects/TPS/TPS_Password_Lists)
-   [History](https://developer.mozilla.org/en-US/docs/Mozilla/Projects/TPS/TPS_History_Lists)
-   [Tabs](https://developer.mozilla.org/en-US/docs/Mozilla/Projects/TPS/TPS_Tab_Lists)
-   [Form Data](https://developer.mozilla.org/en-US/docs/Mozilla/Projects/TPS/TPS_Formdata_Lists)
-   [Prefs](https://developer.mozilla.org/en-US/docs/Mozilla/Projects/TPS/TPS_Pref_Lists)

### Test Phases

The phase blocks are where the action happens! They tell TPS what to do.
Each phase block contains the name of a phase, and a list of actions.
TPS iterates through the phase blocks in alphanumeric order, and for
each phase, it does the following:

1.  Launches Firefox with the profile from the `phases` object that
    corresponds to this test phase.
2.  Performs the specified actions in sequence.
3.  Determines if the phase passed or failed; if it passed, it continues
    to the next phase block and repeats the process.

A phase is defined by calling the `Phase` function with the name of the
phase and a list of actions to perform:

```js
Phase('phase1', [
  [Bookmarks.add, bookmarks_initial],
  [Passwords.add, passwords_initial],
  [History.add, history_initial],
  [Sync, SYNC_WIPE_SERVER],
]);
```

Each action is an array, the first member of which is a function
reference to call, the other members of which are parameters to pass to
the function.  Each type of asset list has a number of built-in
functions you can call, described in the section on Asset lists; there
are also some additional built-in functions.

### Built-in functions

**`Sync(options)`**

Initiates a Sync operation.  If no options are passed, a default sync
operation is performed.  Otherwise, a special sync can be performed if
one of the following are passed:  `SYNC_WIPE_SERVER`,
`SYNC_WIPE_CLIENT`, `SYNC_RESET_CLIENT`. This will cause TPS to set the
firstSync pref to the relevant value before syncing, so that the
described action will take place

**`Logger.logInfo(msg)`**

Logs the given message to the TPS log.

**`Logger.AssertTrue(condition, msg)`**

Asserts that condition is true, otherwise an exception is thrown and the
test fails.

**`Logger.AssertEqual(val1, val2, msg)`**

Asserts that val1 is equal to val2, otherwise an exception is thrown and
the test fails.

### Custom functions

You can also write your own functions to be called as actions.  For
example, consider the first action in the phase above:

```js
[Bookmarks.add, bookmarks_initial]
```

You could rewrite this as a custom function so as to add some custom
logging:

```js
[async () => {
  Logger.logInfo("adding bookmarks_initial");
  await Bookmarks.add(bookmarks_initial);
}]
```

Note that this is probably best used for debugging, and new tests that
want custom behavior should add it to the TPS addon so that other tests
can use it.

### Example Test

Here's an example TPS test to tie it all together.

```js
// Phase declarations
var phases = { "phase1": "profile1",
               "phase2": "profile2",
               "phase3": "profile1" };

// Asset list

// the initial list of bookmarks to be added to the browser
var bookmarks_initial = {
  "menu": [
    { uri: "http://www.google.com",
      title "google.com",
      changes: {
        // These properties are ignored by calls other than Bookmarks.modify
        title: "Google"
      }
    },
    { folder: "foldera" },
    { folder: "folderb" }
  ],
  "menu/foldera": [
    { uri: "http://www.yahoo.com",
      title: "testing Yahoo",
      changes: {
        location: "menu/folderb"
      }
    }
  ]
};

// The state of bookmarks after the first 'modify' action has been performed
// on them. Note that it's equivalent to what you get after applying the properties
// from "changes"
var bookmarks_after_first_modify = {
  "menu": [
    { uri: "http://www.google.com",
      title "Google"
    },
    { folder: "foldera" },
    { folder: "folderb" }
  ],
  "menu/folderb": [
    { uri: "http://www.yahoo.com",
      title: "testing Yahoo"
    }
  ]
};

// Phase implementation

Phase('phase1', [
  [Bookmarks.add, bookmarks_initial],
  [Sync, SYNC_WIPE_SERVER]
]);

Phase('phase2', [
  [Sync],
  [Bookmarks.verify, bookmarks_initial],
  [Bookmarks.modify, bookmarks_initial],
  [Bookmarks.verify, bookmarks_after_first_modify],
  [Sync]
]);

Phase('phase3', [
  [Sync],
  [Bookmarks.verify, bookmarks_after_first_modify]
]);
```

The effects of this test file will be:

1.  Firefox is launched with profile1, the TPS extension adds the two
    bookmarks specified in the `bookmarks_initial` array, then they are
    synced to the Sync server. The `SYNC_WIPE_SERVER` argument causes
    TPS to set the `firstSync="wipeServer"` pref before syncing, in case
    the Sync account already contains data (this is typically
    unnecessary, and done largely as an example). Firefox closes.
2.  Firefox is launched with profile2, and all data is synced from the
    Sync server. The TPS extension verifies that all bookmarks in the
    `bookmarks_initial` list are present. Then it modifies those
    bookmarks by applying the "changes" property to each of them. E.g.,
    the title of the first bookmark is changed from "google.com" to
    "Google". Next, the changes are synced to the Sync server. Finally,
    Firefox closes.
3.  Firefox is launched with profile1 again, and data is synced from the
    Sync server. The TPS extension verifies that the bookmarks in
    `bookmarks_after_first_modify` list are present; i.e., all the
    changes performed in profile2 have successfully been synced to
    profile1. Lastly, Firefox closes and the tests ends.
4.  (Implementation detail) Two final cleanup phases are run to wipe the
    server state and unregister devices.

Troubleshooting and debugging tips for writing and running TPS tests
--------------------------------------------------------------------

1.  TPS evaluates the whole file in every phase, so any syntax error(s)
    in the file will get reported in phase 1, even though the error may
    not be in phase 1 itself.
2.  Inspect tps.log. When a tps test fails, the log is dumped to tps.log
    in the virtualenv.
3.  Inspect about:sync-log. Every sync should have a log and every item
    synced should have a record.
4.  Run `runtps` with `--debug`. This will enable much more verbose
    logging in all engines.
5.  Check the `tps.log` file written out after TPS runs. It will include
    log output written by the Python driver, which includes information
    about where the temporary profiles it uses are stored.
6.  run test\_sync.js. This test generally validates your tps setup and
    does a light test of a few engines.
7.  Comment out the goQuitApplication() calls in
    services/sync/tps/extensions/tps/modules/tps.jsm (remember to undo
    this later!).
    1.  You will have to manually quit the browser at each phase, but
        you will be able to inspect the browser state manually.
    2.  Using this technique in conjunction with
        [aboutsync](https://addons.mozilla.org/en-US/firefox/addon/about-sync/)
        is helpful. (Note that the Python testrunner will generally
        still kill firefox after a TPS test runs for 5 or so minutes, so
        it's often helpful to kill the Python testrunner outright, and
        then use aboutsync in a different instance of the browser).

8.  A TPS failure may not point directly to the problem. For example,
    1.  Most errors involving bookmarks look like "Places Item not found
        in expected index", which could mean a number of issues. The
        other engines are similarly unhelpful, and will likely fail if
        there's any problem, without really indicating what the problem
        is.
    2.  It's common for the phase after the problem to be the one
        reporting errors (e.g. if one phase doesn't upload what it
        should, we won't notice until the next phase).

9.  TPS runs one "cleanup" phase for each profile (even for failed
    tests), which means most tests have two cleanup phases. This has a
    couple side effects
    1.  You usually need to scroll up a bit in the log past the end of
        the test to find the actual failure.
    2.  When one of the cleanup phases fails (often possible if firefox
        crashes or TPS hangs), there's no guarantee that the data was
        properly cleaned up, and so the next TPS test you run may fail
        due to the leftover data. This means **you may want to run a TPS
        test twice** to see if it really failed, or it just started with
        garbage.

10. Feel free to ask for help with setting up and running TPS in the
    `#sync` IRC channel!
