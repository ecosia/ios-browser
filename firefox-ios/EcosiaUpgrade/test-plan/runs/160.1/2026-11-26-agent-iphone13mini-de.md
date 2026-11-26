# Run: 160.1, 2026-11-26, agent: Claude Opus 5.5, iPhone 13 mini iOS 26.5, de

**Upgrade build:** `dc-mob-5044-agentic-test-plan` at `1298417f9c` (`upgrade/firefox` `fe95e55aa3` on Firefox 160.1, plus this plan), scheme `Ecosia`, Debug · **Main build:** `main` at `f467aa431f`, same scheme and configuration, built the same day.

**Purpose:** the end-to-end check of this plan before review (MOB-5044): both builds made fresh, two new simulators, the run sheet from `test_plan.py --todo 160.1`, `AGENT.md` followed from the start, including an `update from main` path; `verify.sh` for the automated flows.

**Simulators:** "iPhone 13 mini MOB-5044 e2e" (main, then the upgrade installed over it; later reinstalled fresh) and "iPhone 13 mini MOB-5044 e2e main", German (`AppleLanguages de-DE`). Screenshots: `<flow id>-<build>.png`, kept outside git for MOB-5044's ticket.

**Summary:** 11 agent flows run: 6 pass · 5 fail. Upgrade regressions: the start screen default (fresh installs and updates), the translate button's active icon, and a new one, the summarize menu row's icon. The homepage settings entry points differ on main too. Settings detail text is fixed by 160.1. Automated flows: `verify.sh` passed on the upgrade branch (5885 unit tests: 5874 passed, 0 failed, 11 skipped; lint clean; 20 feature decisions hold on developer, beta and release; plan check OK). The 12 `FeatureConfigurationTests` flows pass; the 2 snapshot flows are left to CI, because `verify.sh` doesn't run `EcosiaSnapshotTests`.

106 flows: 89 agent · 14 automated · 3 human. Results: pass, fail, blocked, not run.

| Flow | Priority | Runner | Result | Note | Evidence |
| --- | --- | --- | --- | --- | --- |
| `accounts.sign-in` | p1 | agent | not run |  |  |
| `accounts.invisible-tab` | p1 | agent | not run |  |  |
| `accounts.web-session` | p1 | agent | not run |  |  |
| `accounts.sign-out` | p1 | agent | not run |  |  |
| `accounts.signed-out-header` | p2 | agent | not run |  |  |
| `ai-features.translate-icon` | p1 | agent | fail | Globe shown before translating; after translating the button is still tappable but has no icon (`translateActive` asset missing). MOB-5282 item 1. | ai-features.translate-icon-{before,translated}-upgrade.png |
| `ai-features.translate-page` | p1 | agent | pass | en.wikipedia.org/wiki/Tree → German ("Baum") in a few seconds. Afterwards the "Seiten automatisch übersetzen?" bar stayed visible on a new tab's homepage, between the search field and the keyboard: worth a look. | ai-features.translate-icon-translated-upgrade.png, widgets.search-quick-action-upgrade.png |
| `ai-features.translation-speed` | p2 | human: translation speed and model download on a real device | not run |  |  |
| `ai-features.summarize-on-device` | p1 | agent | not run |  |  |
| `ai-features.summarize-hidden` | p1 | agent | not run |  |  |
| `ai-features.hub` | p1 | agent | not run |  |  |
| `ai-features.ai-free-searching` | p1 | agent | not run |  |  |
| `ai-features.flags` | p1 | automated | pass | `FeatureConfigurationTests` in `verify.sh`. |  |
| `homepage.layout` | p1 | agent | pass | Portrait: same layout as main. The seed counter showed 1 on the upgrade and 0 on main right after onboarding; main showed 1 a minute later (timing, not a difference). | homepage.layout-{upgrade,main}.png |
| `homepage.impact-counter` | p1 | agent | not run |  |  |
| `homepage.rotating-titles` | p2 | agent | not run |  |  |
| `homepage.shortcuts` | p1 | agent | not run |  |  |
| `homepage.shortcuts-pin` | p1 | agent | not run |  |  |
| `homepage.customise` | p1 | agent | not run |  |  |
| `homepage.news-about` | p3 | agent | not run |  |  |
| `homepage.components-snapshot` | p1 | automated | not run | Snapshot test: CI only, `verify.sh` doesn't run it. |  |
| `integrations.acquisition-events` | p1 | agent | not run |  |  |
| `integrations.opt-out` | p1 | agent | not run |  |  |
| `integrations.unleash` | p2 | agent | not run |  |  |
| `integrations.singular` | p2 | agent | not run |  |  |
| `integrations.braze-push` | p2 | human: Braze push needs a real device and the Braze dashboard | not run |  |  |
| `integrations.no-mozilla-telemetry` | p1 | agent | not run |  |  |
| `l10n.german-sweep` | p1 | agent | not run |  |  |
| `l10n.firefox-branding` | p1 | agent | not run |  |  |
| `launch.welcome` | p1 | agent | pass | Same welcome screen as main, German. | launch.welcome-{upgrade,main}.png |
| `launch.no-product-tour` | p2 | agent | not run |  |  |
| `launch.default-browser-after-searches` | p2 | agent | not run |  |  |
| `launch.start-at-home` | p2 | agent | not run |  |  |
| `launch.whats-new` | p3 | agent | not run |  |  |
| `launch.onboarding-snapshot` | p1 | automated | not run | Snapshot test: CI only, `verify.sh` doesn't run it. |  |
| `library.bookmarks` | p1 | agent | not run |  |  |
| `library.bookmarks-import-export` | p2 | agent | not run |  |  |
| `library.history` | p1 | agent | not run |  |  |
| `library.reading-list` | p2 | agent | not run |  |  |
| `library.reading-list-empty` | p3 | agent | not run |  |  |
| `library.downloads` | p2 | agent | not run |  |  |
| `menu.homepage-options` | p1 | agent | not run |  |  |
| `menu.page-options` | p1 | agent | fail | New: the "Seite zusammenfassen" row has no icon. `summarizerLarge.imageset` ships in firefox-v160.1 but not in Ecosia's tree (`main` never shows summaries). Also the protection chip reads "Schutzmaßnahmen" (main: "Der Schutz ist aktiviert"); check whether that is upstream's new string. | menu.page-options-after-update-upgrade.png |
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
| `removed-features.lens-off` | p1 | automated | pass | `FeatureConfigurationTests` in `verify.sh`. |  |
| `removed-features.quick-answers-off` | p1 | automated | pass | `FeatureConfigurationTests` in `verify.sh`. |  |
| `removed-features.vpn-off` | p1 | automated | pass | `FeatureConfigurationTests` in `verify.sh`. |  |
| `removed-features.ad-blocker-off` | p1 | automated | pass | `FeatureConfigurationTests` in `verify.sh`. |  |
| `removed-features.nova-off` | p2 | automated | pass | `FeatureConfigurationTests` in `verify.sh`. |  |
| `removed-features.report-broken-site-off` | p2 | automated | pass | `FeatureConfigurationTests` in `verify.sh`. |  |
| `removed-features.privacy-dashboard-off` | p2 | automated | pass | `FeatureConfigurationTests` in `verify.sh`. |  |
| `removed-features.multi-day-onboarding-off` | p2 | automated | pass | `FeatureConfigurationTests` in `verify.sh`. |  |
| `removed-features.search-config-v3-off` | p1 | automated | pass | `FeatureConfigurationTests` in `verify.sh`. |  |
| `removed-features.reinstall-check-off` | p2 | automated | pass | `FeatureConfigurationTests` in `verify.sh`. |  |
| `removed-features.wallpaper-sheet-off` | p2 | automated | pass | `FeatureConfigurationTests` in `verify.sh`. |  |
| `search.default-engine` | p1 | agent | not run |  |  |
| `search.from-address-bar` | p1 | agent | not run |  |  |
| `search.suggestions` | p2 | agent | not run |  |  |
| `search.count-and-seeds` | p1 | agent | not run |  |  |
| `search.ai-chat` | p2 | agent | not run |  |  |
| `search.cookies-native-to-web` | p1 | agent | not run |  |  |
| `search.cookies-web-to-native` | p1 | agent | not run |  |  |
| `search.events` | p2 | agent | not run |  |  |
| `settings.structure` | p1 | agent | fail | Same sections and rows as main, but the start screen defaults to "Letzter Tab" (main: "Startseite nach vier Stunden Inaktivität"). | update-paths.settings-startscreen-after-upgrade.png |
| `settings.detail-font` | p1 | agent | pass | Values on the right ("Ecosia", "Deutschland", "Streng", "Ein") are body size again on 160.1 (upstream FXIOS-17242); switch-row subtitles are caption size, an intended change. | update-paths.settings-after-upgrade.png |
| `settings.homepage-entry-points` | p1 | agent | fail | Also on main: the homepage pencil opens "Homepage" (shortcuts, climate impact), Settings → Homepage opens "Startseite" (start screen, shortcuts, climate impact, stories). Production bug; MOB-5282 item 4 fixes it. | settings.homepage-entry-points-pencil-{upgrade,main}.png |
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
| `update-paths.browsing-data` | p1 | agent | pass | Partial: 3 tabs (selected tab restored) and a bookmark made on main survived installing the upgrade over it. History, reading list, passwords and shortcuts not created. | update-paths.browsing-data-after-upgrade.png, menu.page-options-after-update-upgrade.png |
| `update-paths.settings` | p1 | agent | fail | Safe search "Streng" and address bar "Oben" survived. The start screen, never changed on main ("Startseite nach vier Stunden Inaktivität"), is "Letzter Tab" after the update: Firefox 159.1's `startAtHomeFeature.yaml` default (see target file, Migrations). | update-paths.settings-{before-main,after-upgrade}.png, update-paths.settings-startscreen-{before-main,after-upgrade}.png |
| `update-paths.account-and-impact` | p1 | agent | not run |  |  |
| `update-paths.app-store` | p1 | human: App Store update to a TestFlight build needs a real device | not run |  |  |
| `widgets.search-quick-action` | p1 | agent | pass | Added from the widget gallery on both; tapping it opens a new tab with the search field focused, as on main (the 159.1 build didn't focus it). | widgets.search-quick-action-{upgrade,main}.png |
| `widgets.gallery` | p2 | agent | not run |  |  |
| `target.settings-switch-rows` | p1 | agent | not run |  |  |
| `target.videos-inline` | p2 | agent | not run |  |  |
| `target.iphone-duo` | p2 | agent | not run |  |  |
| `target.qa-round-mob-5282` | p1 | agent | not run |  |  |
