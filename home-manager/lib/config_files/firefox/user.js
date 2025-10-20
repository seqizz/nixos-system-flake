/* Privacy stuff, it's a damn shame that we need to do it this way ***/
user_pref("app.normandy.first_run", false);
user_pref("app.shield.optoutstudies.enabled", false);
user_pref("browser.newtabpage.activity-stream.asrouter.userprefs.cfr", false);
user_pref("browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features", false);
user_pref("browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons", false);
user_pref("browser.newtabpage.activity-stream.disableSnippets", true);
user_pref("browser.newtabpage.activity-stream.feeds.section.highlights", false);
user_pref("browser.newtabpage.activity-stream.feeds.snippets", false);
user_pref("browser.pocket.enabled", false);
user_pref("extensions.pocket.enabled", false);
user_pref("privacy.trackingprotection.fingerprinting.enabled", true);
user_pref("privacy.trackingprotection.cryptomining.enabled", true);
user_pref("privacy.trackingprotection.socialtracking.enabled", true);
user_pref("dom.private-attribution.submission.enabled", false);

/* Cache less ***/
user_pref("browser.cache.disk.capacity", 100000);
user_pref("browser.cache.disk.smart_size.enabled", false);

/* Feature & security stuff ***/
user_pref("dom.w3c_touch_events.enabled", 1);
user_pref("dom.security.https_only_mode", true);
user_pref("security.webauth.u2f", true);
user_pref("browser.urlbar.speculativeConnect.enabled", false);
user_pref("browser.tabs.warnOnClose", false);
user_pref("browser.tabs.closeWindowWithLastTab", false);
user_pref("browser.toolbars.bookmarks.showOtherBookmarks", false);
user_pref("general.warnOnAboutConfig", false);
user_pref("dom.webnotifications.enabled", false);
user_pref("browser.urlbar.clickSelectsAll", true);
user_pref("browser.urlbar.doubleClickSelectsAll", false);
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
user_pref("browser.contentblocking.category", "strict");
user_pref("privacy.partition.serviceWorkers", true);
user_pref("browser.download.start_downloads_in_tmp_dir", true);
user_pref("browser.shopping.experience2023.enabled", false);
user_pref("browser.urlbar.addons.featureGate", false);
user_pref("browser.urlbar.mdn.featureGate", false);
user_pref("browser.urlbar.pocket.featureGate", false);
user_pref("browser.urlbar.trending.featureGate", false);
user_pref("browser.urlbar.weather.featureGate", false);
user_pref("ui.systemUsesDarkTheme", 1);
user_pref("devtools.accessibility.enabled", false);

/* I am not in content with this, but can't find a better way ***/
user_pref("browser.download.useDownloadDir", true);
user_pref("browser.download.dir", "/home/gurkan/Downloads");

/* Do not have "offline mode" for fucks sake, we're not on 1992 ***/
user_pref("network.manage-offline-status", false);

/* Wider cooler scrollbars ***/
user_pref("widget.non-native-theme.scrollbar.size.override", 15);
user_pref("widget.non-native-theme.scrollbar.style", 1);

/* I heard this increases performance ***/
user_pref("accessibility.force_disabled", 1);

/* Yo fuck off what is 1 second wait***/
user_pref("security.dialog_enable_delay", 200);

/* I am doing my own relay thanks***/
user_pref("signon.firefoxRelay.feature", "disabled");

/* Disable ugly footer popping up for completion***/
user_pref("signon.showAutoCompleteFooter", false);

/* Moronic ad stuff ***/
user_pref("browser.urlbar.suggest.topsites", false);
user_pref("browser.urlbar.sponsoredTopSites", false);
user_pref("browser.newtabpage.activity-stream.showSponsoredTopSites", false);
user_pref("browser.newtabpage.activity-stream.showSponsored", false);
user_pref("browser.newtabpage.activity-stream.discoverystream.sponsored-collections.enabled", false);
user_pref("services.sync.prefs.sync.browser.newtabpage.activity-stream.showSponsored", false);
user_pref("services.sync.prefs.sync.browser.newtabpage.activity-stream.showSponsoredTopSites", false);

/* Ah yes everyone needs LLMs, right?? Also HOLY SHIT how many of these */
user_pref("browser.ml.chat.enabled", false);
user_pref("browser.ml.chat.sidebar", false);
user_pref("browser.ml.chat.menu", false); // remove "Ask a chatbot" from tab context menu
user_pref("browser.ml.chat.page", false); // remove option in page context menu (https://github.com/mozilla/policy-templates/issues/1230)
user_pref("browser.ml.linkPreview.enabled", false);
user_pref("browser.tabs.groups.smart.enabled", false); // "Use AI to suggest tabs and a name for tab groups" in settings
user_pref("browser.tabs.groups.smart.userEnabled", false);
user_pref("pdfjs.enableAltTextModelDownload", false); // "This prevents downloading the AI model unless the user opts in (by enabling the toggle to "Create alt text automatically" from "Image alt text settings" when viewing a PDF)"
user_pref("pdfjs.enableGuessAltText", false);
