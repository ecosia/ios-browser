/* vim: set ts=2 sts=2 sw=2 et tw=80: */
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

"use strict";
import { isProbablyReaderable, Readability } from "@mozilla/readability";
import {setStyle} from "./ReaderModeStyles.js";

const DEBUG = false;

var readabilityResult = null;

const readerModeURL = /^http:\/\/localhost:\d+\/reader-mode\/page/;

const BLOCK_IMAGES_SELECTOR =
  ".content p > img:only-child, " +
  ".content p > a:only-child > img:only-child, " +
  ".content .wp-caption img, " +
  ".content figure img";

function debug(s) {
  if (!DEBUG) {
    return;
  }
  console.log(s);
}

function checkReadability() {
  setTimeout(function() {
    if (document.location.href.match(readerModeURL)) {
      debug({Type: "ReaderModeStateChange", Value: "Active"});
      webkit.messageHandlers.readerModeMessageHandler.postMessage({Type: "ReaderModeStateChange", Value: "Active"});
      return;
    }

    if(!isProbablyReaderable(document)) {
      webkit.messageHandlers.readerModeMessageHandler.postMessage({Type: "ReaderModeStateChange", Value: "Unavailable"});
      return;
    }

    if ((document.location.protocol === "http:" || document.location.protocol === "https:") && document.location.pathname !== "/") {
      // Short circuit in case we already ran Readability. This mostly happens when going
      // back/forward: the page will be cached and the result will still be there.
      if (readabilityResult && readabilityResult.content) {
        debug({Type: "ReaderModeStateChange", Value: "Available"});
        webkit.messageHandlers.readerModeMessageHandler.postMessage({Type: "ReaderModeStateChange", Value: "Available"});
        webkit.messageHandlers.readerModeMessageHandler.postMessage({Type: "ReaderContentParsed", Value: readabilityResult});
        return;
      }

      /* Ecosia: Skip the upfront DOMPurify + full Readability parse during detection.
         DOMPurify.sanitize() on large pages (e.g. Wikipedia) fails inside WKWebView's
         sandboxed JS context, causing the try/catch to send "Unavailable" and hiding the
         button even on genuinely readable pages. isProbablyReaderable() is a fast heuristic
         that is accurate enough to determine button visibility; the full parse is deferred
         to readerize(), which runs only when the user actually taps the reader-mode button.

      var uri = {
        spec: document.location.href,
        host: document.location.host,
        prePath: document.location.protocol + "//" + document.location.host,
        scheme: document.location.protocol.substr(0, document.location.protocol.indexOf(":")),
        pathBase: document.location.protocol + "//" + document.location.host + location.pathname.substr(0, location.pathname.lastIndexOf("/") + 1)
      }

      var docStr = new XMLSerializer().serializeToString(document);

      if (docStr.indexOf("<frameset ") > -1) {
        debug({Type: "ReaderModeStateChange", Value: "Unavailable"});
        webkit.messageHandlers.readerModeMessageHandler.postMessage({Type: "ReaderModeStateChange", Value: "Unavailable"});
        return;
      }

      const DOMPurify = require('dompurify');
      const clean = DOMPurify.sanitize(docStr, {WHOLE_DOCUMENT: true});
      var doc = new DOMParser().parseFromString(clean, "text/html");
      var readability = new Readability(uri, doc, { debug: DEBUG });
      readabilityResult = readability.parse();

      if (!readabilityResult) {
        debug({Type: "ReaderModeStateChange", Value: "Unavailable"});
        webkit.messageHandlers.readerModeMessageHandler.postMessage({Type: "ReaderModeStateChange", Value: "Unavailable"});
        return;
      }

      readabilityResult.title = escapeHTML(readabilityResult.title);
      readabilityResult.byline = escapeHTML(readabilityResult.byline);

      debug({Type: "ReaderModeStateChange", Value: readabilityResult !== null ? "Available" : "Unavailable"});
      webkit.messageHandlers.readerModeMessageHandler.postMessage({Type: "ReaderModeStateChange", Value: readabilityResult !== null ? "Available" : "Unavailable"});
      webkit.messageHandlers.readerModeMessageHandler.postMessage({Type: "ReaderContentParsed", Value: readabilityResult});
      */
      debug({Type: "ReaderModeStateChange", Value: "Available"});
      webkit.messageHandlers.readerModeMessageHandler.postMessage({Type: "ReaderModeStateChange", Value: "Available"});
      return;
    }

    debug({Type: "ReaderModeStateChange", Value: "Unavailable"});
    webkit.messageHandlers.readerModeMessageHandler.postMessage({Type: "ReaderModeStateChange", Value: "Unavailable"});
  }, 100);
}

/* Ecosia: Rewrite readerize() to use document.cloneNode(true) instead of the
   XMLSerializer → DOMPurify → DOMParser pipeline. DOMPurify.sanitize() strips nearly
   all content on large pages inside WKWebView's sandboxed JS context, leaving Readability
   with an empty document. cloneNode(true) is the canonical Readability.js usage, is orders
   of magnitude faster, and avoids the sanitisation issue entirely. The full parse is now
   done lazily (on user tap) so button visibility in checkReadability() is not blocked.

// Readerize the document. Since we did the actual readerization already in checkReadability, we
// can simply return the results we already have.
function readerize() {
  return readabilityResult;
}
*/
function readerize() {
  if (readabilityResult) return readabilityResult;

  try {
    // Frameset pages cannot be readerized.
    if (document.querySelector("frameset")) return null;

    // Deep-clone so Readability can destructively mutate the DOM without
    // affecting the live page.
    var docClone = document.cloneNode(true);
    var readability = new Readability(docClone, { debug: DEBUG });
    readabilityResult = readability.parse();
    if (readabilityResult) {
      readabilityResult.title = escapeHTML(readabilityResult.title);
      readabilityResult.byline = escapeHTML(readabilityResult.byline);
    }
  } catch (e) {
    readabilityResult = null;
  }

  return readabilityResult;
}

function updateImageMargins() {
  var contentElement = document.getElementById("reader-content");
  if (!contentElement) {
    return;
  }

  var windowWidth = window.innerWidth;
  var contentWidth = contentElement.offsetWidth;
  var maxWidthStyle = windowWidth + "px !important";

  var setImageMargins = function(img) {
    if (!img._originalWidth) {
      img._originalWidth = img.offsetWidth;
    }

    var imgWidth = img._originalWidth;

    // If the image is taking more than half of the screen, just make
    // it fill edge-to-edge.
    if (imgWidth < contentWidth && imgWidth > windowWidth * 0.55) {
      imgWidth = windowWidth;
    }

    var sideMargin = Math.max((contentWidth - windowWidth) / 2, (contentWidth - imgWidth) / 2);

    var imageStyle = sideMargin + "px !important";
    var widthStyle = imgWidth + "px !important";

    var cssText =
      "max-width: " + maxWidthStyle + ";" +
      "width: " + widthStyle + ";" +
      "margin-left: " + imageStyle + ";" +
      "margin-right: " + imageStyle + ";";

    img.style.cssText = cssText;
  };

  var imgs = document.querySelectorAll(BLOCK_IMAGES_SELECTOR);
  for (var i = imgs.length; --i >= 0;) {
    var img = imgs[i];
    if (img.width > 0) {
      setImageMargins(img);
    } else {
      img.onload = function() {
        setImageMargins(img);
      }
    }
  }
}

function showContent() {
  // Make the reader visible
  var messageElement = document.getElementById("reader-message");
  if (messageElement) {
    messageElement.style.display = "none";
  }
  var headerElement = document.getElementById("reader-header");
  if (headerElement) {
    headerElement.style.display = "block"
  }
  var contentElement = document.getElementById("reader-content");
  if (contentElement) {
    contentElement.style.display = "block";
  }
}

function configureReader() {
  // Configure the reader with the initial style that was injected in the page.
  var style = JSON.parse(document.body.getAttribute("data-readerStyle"));
  setStyle(style);

  // The order here is important. Because updateImageMargins depends on contentElement.offsetWidth which
  // will not be set until contentElement is visible. If this leads to annoying content reflowing then we
  // need to look at an alternative way to do
  showContent();
  updateImageMargins();
}

function escapeHTML(string) {
  if (typeof(string) !== 'string') { return ''; }
  return string
    .replace(/\&/g, "&amp;")
    .replace(/\</g, "&lt;")
    .replace(/\>/g, "&gt;")
    .replace(/\"/g, "&quot;")
    .replace(/\'/g, "&#039;");
}

Object.defineProperty(window.__firefox__, "reader", {
  enumerable: false,
  configurable: false,
  writable: false,
  value: Object.freeze({
    checkReadability: checkReadability,
    readerize: readerize,
    setStyle: setStyle
  })
});

window.addEventListener("load", function(event) {
  // If this is an about:reader page that we are loading, apply the initial style to the page.
  if (document.location.href.match(readerModeURL)) {
    configureReader();
  }
});

window.addEventListener("pageshow", function(event) {
  // If this is an about:reader page that we are showing, fire an event to the native code
  if (document.location.href.match(readerModeURL)) {
    webkit.messageHandlers.readerModeMessageHandler.postMessage({Type: "ReaderPageEvent", Value: "PageShow"});
  }
});
