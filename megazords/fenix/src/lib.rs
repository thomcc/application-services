/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#![allow(unknown_lints)]
#![warn(rust_2018_idioms)]

pub use fxaclient_ffi;
pub use places_ffi;
pub use push_ffi;
pub use rc_log_ffi;
pub use viaduct;

#[no_mangle]
pub unsafe extern "C" fn fenix_workaround_rust_issue_50007() -> Vec<usize> {
    // return a vec of the addresses of every method we need to ensure is
    // getting compiled in. this function (which shouldn't ever be called)
    // prevents something (rustc? the android linker? who knows) from preventing
    // us from re-exporting the ffi functions from the above crates when not
    // compiled with LTO.
    //
    // ideally we could autogenerate this. it's actually kind of tricky though.
    // parsing it from rust isn't reliable since we build these with macros
    // sometimes. parsing them out of a LTO-compiled .so almost could work, but
    // we don't know the crate/module each function comes from, so that probably
    // would only work to validate that they're present...

    let mut value = vec![];

    value.push(rc_log_ffi::rc_log_adapter_create as usize);
    value.push(rc_log_ffi::rc_log_adapter_set_max_level as usize);
    value.push(rc_log_ffi::rc_log_adapter_destroy as usize);
    value.push(rc_log_ffi::rc_log_adapter_test__log_msg as usize);

    value.push(places_ffi::places_enable_logcat_logging as usize);
    value.push(places_ffi::places_api_new as usize);
    value.push(places_ffi::places_new_sync_conn_interrupt_handle as usize);
    value.push(places_ffi::places_connection_new as usize);
    value.push(places_ffi::places_bookmarks_import_from_ios as usize);
    value.push(places_ffi::places_api_return_write_conn as usize);
    value.push(places_ffi::places_api_reset_bookmarks as usize);
    value.push(places_ffi::places_new_interrupt_handle as usize);
    value.push(places_ffi::places_interrupt as usize);
    value.push(places_ffi::places_note_observation as usize);
    value.push(places_ffi::places_query_autocomplete as usize);
    value.push(places_ffi::places_match_url as usize);
    value.push(places_ffi::places_get_visited as usize);
    value.push(places_ffi::places_get_visited_urls_in_range as usize);
    value.push(places_ffi::places_delete_place as usize);
    value.push(places_ffi::places_delete_visits_between as usize);
    value.push(places_ffi::places_delete_visit as usize);
    value.push(places_ffi::places_wipe_local as usize);
    value.push(places_ffi::places_run_maintenance as usize);
    value.push(places_ffi::places_prune_destructively as usize);
    value.push(places_ffi::places_delete_everything as usize);
    value.push(places_ffi::places_get_visit_infos as usize);
    value.push(places_ffi::places_get_visit_count as usize);
    value.push(places_ffi::places_get_visit_page as usize);
    value.push(places_ffi::sync15_history_sync as usize);
    value.push(places_ffi::sync15_bookmarks_sync as usize);
    value.push(places_ffi::bookmarks_get_tree as usize);
    value.push(places_ffi::bookmarks_get_by_guid as usize);
    value.push(places_ffi::bookmarks_insert as usize);
    value.push(places_ffi::bookmarks_update as usize);
    value.push(places_ffi::bookmarks_delete as usize);
    value.push(places_ffi::bookmarks_get_all_with_url as usize);
    value.push(places_ffi::bookmarks_search as usize);
    value.push(places_ffi::bookmarks_get_recent as usize);
    value.push(places_ffi::places_destroy_string as usize);
    value.push(places_ffi::places_destroy_bytebuffer as usize);
    value.push(places_ffi::places_api_destroy as usize);
    value.push(places_ffi::places_connection_destroy as usize);
    value.push(places_ffi::places_interrupt_handle_destroy as usize);

    value.push(viaduct::ffi::viaduct_alloc_bytebuffer as usize);
    value.push(viaduct::ffi::viaduct_log_error as usize);
    value.push(viaduct::ffi::viaduct_initialize as usize);
    value.push(viaduct::ffi::viaduct_force_enable_ffi_backend as usize);

    value.push(push_ffi::push_enable_logcat_logging as usize);
    value.push(push_ffi::push_connection_new as usize);
    value.push(push_ffi::push_subscribe as usize);
    value.push(push_ffi::push_unsubscribe as usize);
    value.push(push_ffi::push_unsubscribe_all as usize);
    value.push(push_ffi::push_update as usize);
    value.push(push_ffi::push_verify_connection as usize);
    value.push(push_ffi::push_decrypt as usize);
    value.push(push_ffi::push_dispatch_for_chid as usize);
    value.push(push_ffi::push_destroy_string as usize);
    value.push(push_ffi::push_destroy_buffer as usize);
    value.push(push_ffi::push_connection_destroy as usize);

    value.push(fxaclient_ffi::fxa_enable_logcat_logging as usize);
    value.push(fxaclient_ffi::fxa_new as usize);
    value.push(fxaclient_ffi::fxa_from_json as usize);
    value.push(fxaclient_ffi::fxa_to_json as usize);
    value.push(fxaclient_ffi::fxa_profile as usize);
    value.push(fxaclient_ffi::fxa_get_token_server_endpoint_url as usize);
    value.push(fxaclient_ffi::fxa_get_connection_success_url as usize);
    value.push(fxaclient_ffi::fxa_get_manage_account_url as usize);
    value.push(fxaclient_ffi::fxa_get_manage_devices_url as usize);
    value.push(fxaclient_ffi::fxa_begin_pairing_flow as usize);
    value.push(fxaclient_ffi::fxa_begin_oauth_flow as usize);
    value.push(fxaclient_ffi::fxa_complete_oauth_flow as usize);
    value.push(fxaclient_ffi::fxa_migrate_from_session_token as usize);
    value.push(fxaclient_ffi::fxa_get_access_token as usize);
    value.push(fxaclient_ffi::fxa_clear_access_token_cache as usize);
    value.push(fxaclient_ffi::fxa_set_push_subscription as usize);
    value.push(fxaclient_ffi::fxa_set_device_name as usize);
    value.push(fxaclient_ffi::fxa_get_devices as usize);
    value.push(fxaclient_ffi::fxa_poll_device_commands as usize);
    value.push(fxaclient_ffi::fxa_destroy_device as usize);
    value.push(fxaclient_ffi::fxa_handle_push_message as usize);
    value.push(fxaclient_ffi::fxa_initialize_device as usize);
    value.push(fxaclient_ffi::fxa_ensure_capabilities as usize);
    value.push(fxaclient_ffi::fxa_send_tab as usize);
    value.push(fxaclient_ffi::fxa_free as usize);
    value.push(fxaclient_ffi::fxa_str_free as usize);
    value.push(fxaclient_ffi::fxa_bytebuffer_free as usize);

    value
}

