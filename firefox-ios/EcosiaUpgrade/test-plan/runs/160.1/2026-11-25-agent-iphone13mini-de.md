# Run: 160.1, 2026-11-25, agent: Claude Opus 5.5, iPhone 13 mini iOS 26.5, de

**Upgrade build:** `upgrade/firefox` at `794076d4d9`, scheme `Ecosia`, Debug · **Main build:** `main` as of 2026-11-20, `6913354a7e` (built that day by the MOB-5282 session; later `main` commits change only logs, Transifex strings and Ruby), same scheme and configuration.

**Purpose:** the first agent run of this plan (MOB-5044), proving the format on flows from the MOB-5282 QA round. The upgrade build doesn't have the MOB-5282 fixes yet, so the flows should find what QA found by hand. Seven flows run, the rest not run.

**Simulators:** "iPhone 13 mini MOB-5282" (upgrade) and "iPhone 13 mini MOB-5282 main", German (`AppleLanguages de-DE`), app reinstalled before the run (fresh install). Screenshots: `<flow id>-<build>.png`, kept outside git for MOB-5044's ticket.

**Summary:** 3 pass · 4 fail (3 upgrade regressions: detail font, translate icon, start-screen default; 1 also on main: homepage settings entry points) · 86 not run · 9 automated (left to CI). The detail font and translate icon are MOB-5282 items 3 and 1, both already fixed on `dc-mob-5282-qa-fixes`. The start-screen default is new: Firefox 159.1 changed it upstream and the merge took it silently.

102 flows: 90 agent · 9 automated · 3 human. Results: pass, fail, blocked, not run.

| Flow | Priority | Runner | Result | Note | Evidence |
| --- | --- | --- | --- | --- | --- |
| `accounts.sign-in` | p1 | agent | not run |  |  |
| `accounts.invisible-tab` | p1 | agent | not run |  |  |
| `accounts.web-session` | p1 | agent | not run |  |  |
| `accounts.sign-out` | p1 | agent | not run |  |  |
| `accounts.signed-out-header` | p2 | agent | not run |  |  |
| `ai-features.translate-icon` | p1 | agent | fail | Before translating, the address bar shows the globe button. After translating, the button is still there and works (tapping it shows the original) but has no icon: `translateActive` is missing. MOB-5282 item 1. | ai-features.translate-icon-{before,translated,reverted}-upgrade.png |
| `ai-features.translate-page` | p1 | agent | pass | en.wikipedia.org/wiki/Tree translated to German in about 20 s ("Baum"), and back to English from the address bar button. Offers "Seiten automatisch übersetzen" afterwards. | ai-features.translate-icon-translated-upgrade.png |
| `ai-features.translation-speed` | p2 | human: translation speed and model download on a real device | not run |  |  |
| `ai-features.summarize-on-device` | p1 | agent | not run |  |  |
| `ai-features.summarize-hidden` | p1 | agent | not run |  |  |
| `ai-features.hub` | p1 | agent | not run |  |  |
| `ai-features.ai-free-searching` | p1 | agent | not run |  |  |
| `ai-features.flags` | p1 | automated | automated (CI) |  |  |
| `homepage.layout` | p1 | agent | pass | Fresh install, portrait only: same header, headline, counters and search bar as main. Landscape and new-tab steps not run. | homepage.layout-{upgrade,main}.png |
| `homepage.impact-counter` | p1 | agent | not run | Seen in passing: "funding climate projects" is English on both builds (production gap, not a regression). |  |
| `homepage.rotating-titles` | p2 | agent | not run |  |  |
| `homepage.shortcuts` | p1 | agent | not run |  |  |
| `homepage.shortcuts-pin` | p1 | agent | not run |  |  |
| `homepage.customise` | p1 | agent | not run |  |  |
| `homepage.news-about` | p3 | agent | not run |  |  |
| `homepage.components-snapshot` | p1 | automated | automated (CI) |  |  |
| `homepage.ntp-snapshot` | p2 | automated | automated (CI) |  |  |
| `integrations.acquisition-events` | p1 | agent | not run |  |  |
| `integrations.opt-out` | p1 | agent | not run |  |  |
| `integrations.unleash` | p2 | agent | not run |  |  |
| `integrations.singular` | p2 | agent | not run |  |  |
| `integrations.braze-push` | p2 | human: Braze push needs a real device and the Braze dashboard | not run |  |  |
| `integrations.no-mozilla-telemetry` | p1 | agent | not run |  |  |
| `l10n.german-sweep` | p1 | agent | not run |  |  |
| `l10n.firefox-branding` | p1 | agent | not run |  |  |
| `launch.welcome` | p1 | agent | pass | Same welcome screen as main ("Willkommen bei Ecosia", Anmelden / Vielleicht später), German, ends on the homepage. |  |
| `launch.no-product-tour` | p2 | agent | not run |  |  |
| `launch.default-browser-after-searches` | p2 | agent | not run |  |  |
| `launch.start-at-home` | p2 | agent | not run |  |  |
| `launch.whats-new` | p3 | agent | not run |  |  |
| `launch.onboarding-snapshot` | p1 | automated | automated (CI) |  |  |
| `library.bookmarks` | p1 | agent | not run |  |  |
| `library.bookmarks-import-export` | p2 | agent | not run |  |  |
| `library.history` | p1 | agent | not run |  |  |
| `library.reading-list` | p2 | agent | not run |  |  |
| `library.reading-list-empty` | p3 | agent | not run |  |  |
| `library.downloads` | p2 | agent | not run |  |  |
| `menu.homepage-options` | p1 | agent | not run |  |  |
| `menu.page-options` | p1 | agent | not run |  |  |
| `menu.context-menu` | p2 | agent | not run |  |  |
| `no-internet.error-page` | p1 | agent | not run |  |  |
| `no-internet.recovery` | p2 | agent | not run |  |  |
| `no-internet.bad-host` | p2 | agent | not run |  |  |
| `passwords.add-manually` | p2 | agent | not run |  |  |
| `passwords.save-from-login` | p2 | agent | not run |  |  |
| `passwords.use-on-login` | p2 | agent | not run |  |  |
| `passwords.delete` | p3 | agent | not run |  |  |
| `payments.paypal` | p2 | agent | not run |  |  |
| `payments.bank-login` | p3 | agent | not run |  |  |
| `removed-features.no-entry-points` | p1 | agent | not run |  |  |
| `removed-features.lens-off` | p1 | automated | automated (CI) |  |  |
| `removed-features.quick-answers-off` | p1 | automated | automated (CI) |  |  |
| `removed-features.vpn-off` | p1 | automated | automated (CI) |  |  |
| `removed-features.ad-blocker-off` | p1 | automated | automated (CI) |  |  |
| `removed-features.nova-off` | p2 | automated | automated (CI) |  |  |
| `search.default-engine` | p1 | agent | not run |  |  |
| `search.from-address-bar` | p1 | agent | not run |  |  |
| `search.suggestions` | p2 | agent | not run |  |  |
| `search.count-and-seeds` | p1 | agent | not run |  |  |
| `search.ai-chat` | p2 | agent | not run |  |  |
| `search.cookies-native-to-web` | p1 | agent | not run |  |  |
| `search.cookies-web-to-native` | p1 | agent | not run |  |  |
| `search.events` | p2 | agent | not run |  |  |
| `settings.structure` | p1 | agent | fail | Partial run (first two settings screens and Homepage). Same sections and rows as main, but on a fresh install the start screen defaults to "Letzter Tab" on the upgrade and "Startseite nach vier Stunden Inaktivität" on main. New finding. Cause: Firefox 159.1 changed `start-at-home-feature.setting`'s default in `nimbus-features/startAtHomeFeature.yaml` from `afterFourHours` to `disabled`; the 159.1 merge (`6ebbb0484b`) took it without a conflict. Users who never changed the setting also switch to "last tab" on update. Not locked by `FeatureConfigurationTests`. | settings.homepage-entry-points-settings-{upgrade,main}.png |
| `settings.detail-font` | p1 | agent | fail | Values on the right of rows ("Ecosia", "Deutschland", "Mittel", "Ein") are caption-size on the upgrade, body-size on main. MOB-5282 item 3; fixed on `dc-mob-5282-qa-fixes`, not yet on `upgrade/firefox`. | settings.detail-font-{upgrade,main}.png |
| `settings.homepage-entry-points` | p1 | agent | fail | Also on main. Settings → Homepage opens "Startseite" (start screen + shortcuts, climate impact, stories); the homepage pencil opens "Homepage" (shortcuts, climate impact only). Production bug; MOB-5282 item 4 makes both open the same screen. | settings.homepage-entry-points-{settings,pencil}-{upgrade,main}.png |
| `settings.help-center-locale` | p1 | agent | not run |  |  |
| `settings.preference-keys` | p1 | agent | not run |  |  |
| `settings.default-browser-card` | p2 | agent | not run |  |  |
| `tabs.tray` | p1 | agent | not run |  |  |
| `tabs.close-and-undo` | p2 | agent | not run |  |  |
| `tabs.private-anonymous` | p1 | agent | not run |  |  |
| `tabs.close-private-setting` | p2 | agent | not run |  |  |
| `theme.dark-light` | p1 | agent | not run |  |  |
| `theme.main-screens` | p1 | agent | not run |  |  |
| `theme.icons` | p2 | agent | not run |  |  |
| `toolbar.layout` | p1 | agent | not run |  |  |
| `toolbar.search-term-on-results` | p1 | agent | not run |  |  |
| `toolbar.swipe-to-tab-tray` | p1 | agent | not run |  |  |
| `toolbar.swipe-between-tabs` | p2 | agent | not run |  |  |
| `toolbar.position` | p1 | agent | not run |  |  |
| `toolbar.share-and-reload` | p2 | agent | not run |  |  |
| `toolbar.collapse-on-scroll` | p2 | agent | not run |  |  |
| `tracking-protection.panel` | p1 | agent | not run |  |  |
| `tracking-protection.settings` | p1 | agent | not run |  |  |
| `tracking-protection.ecosia-ads` | p1 | agent | not run |  |  |
| `update-paths.browsing-data` | p1 | agent | not run |  |  |
| `update-paths.settings` | p1 | agent | not run |  |  |
| `update-paths.account-and-impact` | p1 | agent | not run |  |  |
| `update-paths.app-store` | p1 | human: App Store update to a TestFlight build needs a real device | not run |  |  |
| `widgets.search-quick-action` | p1 | agent | not run |  |  |
| `widgets.gallery` | p2 | agent | not run |  |  |
| `target.settings-switch-rows` | p1 | agent | not run |  |  |
| `target.videos-inline` | p2 | agent | not run |  |  |
| `target.iphone-duo` | p2 | agent | not run |  |  |
| `target.new-flags-off` | p1 | agent | not run |  |  |
| `target.qa-round-mob-5282` | p1 | agent | not run |  |  |
