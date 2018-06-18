/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

public class FxAConfig: MovableRustOpaquePointer {
    /// Convenience method over `custom(...)` which provides an `FxAConfig` that
    /// points to the production FxA servers.
    open class func release() throws -> FxAConfig {
        let pointer = try fxa_get_release_config().pointee.unwrap()
        return FxAConfig(raw: pointer)
    }

    /// Fetches an `FxAConfig` by making a request to `<content_base>/.well-known/fxa-client-configuration`
    /// and parsing the newly fetched configuration object.
    ///
    /// Note: `content_base` shall not have a trailing slash.
    open class func custom(content_base: String) throws -> FxAConfig {
        let pointer = try fxa_get_custom_config(content_base).pointee.unwrap()
        return FxAConfig(raw: pointer)
    }

    override func cleanup(pointer: OpaquePointer) {
        fxa_config_free(pointer)
    }
}

public class FirefoxAccount: RustOpaquePointer {
    /// Creates a `FirefoxAccount` instance from credentials obtained with the onepw FxA login flow.
    /// This is typically used by the legacy Sync clients: new clients mainly use OAuth flows and
    /// therefore should use `init`.
    /// Please note that the `FxAConfig` provided will be consumed and therefore
    /// should not be re-used.
    open class func from(config: FxAConfig, clientId: String, webChannelResponse: String) throws -> FirefoxAccount {
        let pointer = try fxa_from_credentials(config.validPointer(), clientId, webChannelResponse).pointee.unwrap()
        config.raw = nil
        return FirefoxAccount(raw: pointer)
    }

    /// Restore a previous instance of `FirefoxAccount` from a serialized state (obtained with `toJSON(...)`).
    open class func fromJSON(state: String) throws -> FirefoxAccount {
        let pointer = try fxa_from_json(state).pointee.unwrap()
        return FirefoxAccount(raw: pointer)
    }

    /// Create a `FirefoxAccount` from scratch. This is suitable for callers using the
    /// OAuth Flow.
    /// Please note that the `FxAConfig` provided will be consumed and therefore
    /// should not be re-used.
    public convenience init(config: FxAConfig, clientId: String) throws {
        let pointer = try fxa_new(config.validPointer(), clientId).pointee.unwrap()
        config.raw = nil
        self.init(raw: pointer)
    }

    override func cleanup(pointer: OpaquePointer) {
        fxa_free(pointer)
    }

    /// Serializes the state of a `FirefoxAccount` instance. It can be restored later with `fromJSON(...)`.
    /// It is the responsability of the caller to persist that serialized state regularly (after operations that mutate `FirefoxAccount`) in a **secure** location.
    public func toJSON() throws -> String {
        return copy_and_free_str(try fxa_to_json(self.raw).pointee.unwrap())
    }

    /// Gets the logged-in user profile.
    /// Throws FxAError.Unauthorized we couldn't find any suitable access token
    /// to make that call. The caller should then start the OAuth Flow again with
    /// the "profile" scope.
    public func getProfile() throws -> Profile {
        return Profile(raw: try fxa_profile(self.raw, false).pointee.unwrap())
    }

    public func getSyncKeys() throws -> SyncKeys {
        return SyncKeys(raw: try fxa_get_sync_keys(self.raw).pointee.unwrap())
    }

    public func getTokenServerEndpointURL() throws -> URL {
        return URL(string: copy_and_free_str(try fxa_get_token_server_endpoint_url(self.raw).pointee.unwrap()))!
    }

    /// Request a OAuth token by starting a new OAuth flow.
    ///
    /// This function returns a URL string that the caller should open in a webview.
    ///
    /// Once the user has confirmed the authorization grant, they will get redirected to `redirect_url`:
    /// the caller must intercept that redirection, extract the `code` and `state` query parameters and call
    /// `completeOAuthFlow(...)` to complete the flow.
    ///
    /// It is possible also to request keys (e.g. sync keys) during that flow by setting `wants_keys` to true.
    public func beginOAuthFlow(redirectURI: String, scopes: [String], wantsKeys: Bool) throws -> URL {
        let scope = scopes.joined(separator: " ");
        return URL(string: copy_and_free_str(try fxa_begin_oauth_flow(raw, redirectURI, scope, wantsKeys).pointee.unwrap()))!
    }

    /// Finish an OAuth flow initiated by `beginOAuthFlow(...)` and returns token/keys.
    ///
    /// This resulting token might not have all the `scopes` the caller have requested (e.g. the user
    /// might have denied some of them): it is the responsibility of the caller to accomodate that.
    public func completeOAuthFlow(code: String, state: String) throws -> OAuthInfo {
        return OAuthInfo(raw: try fxa_complete_oauth_flow(raw, code, state).pointee.unwrap())
    }

    /// Try to get a previously obtained cached token.
    ///
    /// If the token is expired, the system will try to refresh it automatically using
    /// a `refresh_token` or `session_token`.
    ///
    /// If the system can't find a suitable token but has a `session_token`, it will generate a new one on the go.
    ///
    /// If not, the caller must start an OAuth flow with `beginOAuthFlow(...)`.
    public func getOAuthToken(scopes: [String]) throws -> OAuthInfo? {
        let scope = scopes.joined(separator: " ")
        guard let ptr: UnsafeMutablePointer<OAuthInfoC> = try fxa_get_oauth_token(raw, scope).pointee.tryUnwrap() else {
            return nil
        }
        return OAuthInfo(raw: ptr)
    }

    public func generateAssertion(audience: String) throws -> String {
        return copy_and_free_str(try fxa_assertion_new(raw, audience).pointee.unwrap())
    }
}

public class OAuthInfo: RustStructPointer<OAuthInfoC> {
    public var scopes: [String] {
        get {
            return String(cString: raw.pointee.scope).components(separatedBy: " ")
        }
    }

    public var accessToken: String {
        get {
            return String(cString: raw.pointee.access_token)
        }
    }

    public var keys: String? {
        get {
            guard let pointer = raw.pointee.keys else {
                return nil
            }
            return String(cString: pointer)
        }
    }

    override func cleanup(pointer: UnsafeMutablePointer<OAuthInfoC>) {
        fxa_oauth_info_free(self.raw)
    }
}

public class Profile: RustStructPointer<ProfileC> {
    public var uid: String {
        get {
            return String(cString: raw.pointee.uid)
        }
    }

    public var email: String {
        get {
            return String(cString: raw.pointee.email)
        }
    }

    public var avatar: String {
        get {
            return String(cString: raw.pointee.avatar)
        }
    }

    override func cleanup(pointer: UnsafeMutablePointer<ProfileC>) {
        fxa_profile_free(raw)
    }
}

public class SyncKeys: RustStructPointer<SyncKeysC> {
    public var syncKey: String {
        get {
            return String(cString: raw.pointee.sync_key)
        }
    }

    public var xcs: String {
        get {
            return String(cString: raw.pointee.xcs)
        }
    }

    override func cleanup(pointer: UnsafeMutablePointer<SyncKeysC>) {
        fxa_sync_keys_free(raw)
    }
}

func copy_and_free_str(_ pointer: UnsafeMutablePointer<Int8>) -> String {
    let copy = String(cString: pointer)
    fxa_str_free(pointer)
    return copy
}
