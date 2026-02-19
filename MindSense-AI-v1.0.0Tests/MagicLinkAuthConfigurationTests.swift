import XCTest
@testable import MindSense_AI_v1_0_0

final class MagicLinkAuthConfigurationTests: XCTestCase {
    func testLiveConfigurationUsesDefaultsWhenEnvironmentIsEmpty() {
        let configuration = MagicLinkAuthConfiguration.live(environment: [:])

        XCTAssertEqual(configuration.providerName, "MindSense Auth")
        XCTAssertEqual(configuration.redirectScheme, "mindsense")
        XCTAssertEqual(configuration.redirectHost, "auth")
        XCTAssertEqual(configuration.normalizedRedirectPath, "/verify")
        XCTAssertNil(configuration.requestEndpointURL)
        XCTAssertEqual(configuration.tokenTTLMinutes, 15)
        XCTAssertEqual(configuration.resendCooldownSeconds, 20)
    }

    func testLiveConfigurationAppliesEnvironmentOverrides() {
        let configuration = MagicLinkAuthConfiguration.live(
            environment: [
                "MINDSENSE_MAGIC_LINK_PROVIDER": "Supabase",
                "MINDSENSE_MAGIC_LINK_API_BASE_URL": "https://api.example.com/v1",
                "MINDSENSE_MAGIC_LINK_REQUEST_URL": "https://api.example.com/v1/auth/send-magic-link",
                "MINDSENSE_MAGIC_LINK_SUPABASE_ANON_KEY": "supabase-anon-key",
                "MINDSENSE_MAGIC_LINK_REDIRECT_SCHEME": "msapp",
                "MINDSENSE_MAGIC_LINK_REDIRECT_HOST": "login",
                "MINDSENSE_MAGIC_LINK_REDIRECT_PATH": "verify",
                "MINDSENSE_MAGIC_LINK_UNIVERSAL_HOST": "auth.example.com",
                "MINDSENSE_MAGIC_LINK_TTL_MINUTES": "30",
                "MINDSENSE_MAGIC_LINK_RESEND_COOLDOWN_SECONDS": "45",
                "MINDSENSE_MAGIC_LINK_DEBUG_SHOW_LINK_PREVIEW": "1",
                "MINDSENSE_MAGIC_LINK_DEBUG_AUTO_OPEN": "true"
            ]
        )

        XCTAssertEqual(configuration.providerName, "Supabase")
        XCTAssertEqual(configuration.apiBaseURL?.absoluteString, "https://api.example.com/v1")
        XCTAssertEqual(configuration.requestEndpointURL?.absoluteString, "https://api.example.com/v1/auth/send-magic-link")
        XCTAssertEqual(configuration.supabaseAnonKey, "supabase-anon-key")
        XCTAssertEqual(configuration.redirectScheme, "msapp")
        XCTAssertEqual(configuration.redirectHost, "login")
        XCTAssertEqual(configuration.normalizedRedirectPath, "/verify")
        XCTAssertEqual(configuration.universalLinkHost, "auth.example.com")
        XCTAssertEqual(configuration.tokenTTLMinutes, 30)
        XCTAssertEqual(configuration.resendCooldownSeconds, 45)
        XCTAssertTrue(configuration.debugShowLinkPreview)
        XCTAssertTrue(configuration.debugAutoOpenReceivedLink)
    }

    func testSupabaseConfigurationDerivesOTPRequestEndpointFromAPIBase() {
        let configuration = MagicLinkAuthConfiguration.live(
            environment: [
                "MINDSENSE_MAGIC_LINK_PROVIDER": "Supabase",
                "MINDSENSE_MAGIC_LINK_API_BASE_URL": "https://api.example.com"
            ]
        )

        XCTAssertNil(configuration.requestEndpointURL)
        XCTAssertEqual(configuration.resolvedRequestEndpointURL?.absoluteString, "https://api.example.com/auth/v1/otp")
    }

    func testVerificationURLContainsTokenEmailAndIntent() throws {
        let configuration = MagicLinkAuthConfiguration.live(environment: [:])
        let url = configuration.verificationURL(
            email: "user@example.com",
            token: "abc123",
            intent: .createAccount
        )
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let queryItems = try XCTUnwrap(components.queryItems)

        XCTAssertEqual(components.scheme, "mindsense")
        XCTAssertEqual(components.host, "auth")
        XCTAssertEqual(components.path, "/verify")
        XCTAssertEqual(queryItems.first(where: { $0.name == "token" })?.value, "abc123")
        XCTAssertEqual(queryItems.first(where: { $0.name == "email" })?.value, "user@example.com")
        XCTAssertEqual(queryItems.first(where: { $0.name == "intent" })?.value, MagicLinkIntent.createAccount.rawValue)
    }
}
