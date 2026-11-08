import QtQuick
import QtTest
import "../services/WebApps.js" as WebApps

// The rules behind web apps: which text is a URL, the name a site gets when
// its page has none, duplicates and the window class Chrome gives an --app
// window (checked against a real Chrome window).
TestCase {
    name: "WebApps"

    function test_aBareHostGetsHttps() {
        compare(WebApps.normalize("youtube.com"), "https://youtube.com/");
        compare(WebApps.normalize("  mail.google.com/mail/u/0 "), "https://mail.google.com/mail/u/0");
    }

    function test_httpAndHttpsAreKept() {
        compare(WebApps.normalize("http://example.com/a?b=1#c"), "http://example.com/a?b=1#c");
        compare(WebApps.normalize("HTTPS://Example.COM"), "https://example.com/");
    }

    function test_aHostAndPortIsAHost() {
        compare(WebApps.normalize("localhost:8080"), "https://localhost:8080/");
    }

    function test_otherSchemesAndNonUrlsAreRefused() {
        for (const text of ["file:///etc/passwd", "chrome://settings", "mailto:a@b.com",
                "javascript:alert(1)", "not a url", "nodot", "", "https://", "https:example.com"])
            compare(WebApps.normalize(text), "", text);
    }

    function test_theFallbackNameIsTheMainDomainLabel() {
        compare(WebApps.fallbackName("https://www.youtube.com/"), "Youtube");
        compare(WebApps.fallbackName("https://web.whatsapp.com/"), "Whatsapp");
        compare(WebApps.fallbackName("https://localhost:8080/"), "Localhost");
    }

    function test_thePageNameIsTidiedOrFallsBack() {
        compare(WebApps.nameFor("  You\n  Tube ", "https://youtube.com/"), "You Tube");
        compare(WebApps.nameFor("", "https://youtube.com/"), "Youtube");
    }

    function test_onlyTheExactUrlIsADuplicate() {
        const apps = [{ id: "webapp-docs", name: "Docs", url: "https://docs.google.com/document/d/1" }];
        compare(WebApps.duplicateOf(apps, "docs.google.com/document/d/1").name, "Docs");
        compare(WebApps.duplicateOf(apps, "https://docs.google.com/document/d/2"), null);
        compare(WebApps.duplicateOf([], "https://docs.google.com/"), null);
    }

    function test_theWindowClassFollowsChrome() {
        compare(WebApps.windowClass("https://example.com/foo/bar"), "chrome-example.com__foo_bar-Default");
        compare(WebApps.windowClass("https://web.whatsapp.com/"), "chrome-web.whatsapp.com__-Default");
        compare(WebApps.windowClass("https://example.com/a?b=1"), "chrome-example.com__a-Default");
    }
}
