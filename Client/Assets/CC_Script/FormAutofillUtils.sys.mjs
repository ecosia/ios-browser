/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import { FormAutofill } from "resource://autofill/FormAutofill.sys.mjs";
import { XPCOMUtils } from "resource://gre/modules/XPCOMUtils.sys.mjs";

const lazy = {};
ChromeUtils.defineESModuleGetters(lazy, {
  CreditCard: "resource://gre/modules/CreditCard.sys.mjs",
  FormAutofillNameUtils:
    "resource://gre/modules/shared/FormAutofillNameUtils.sys.mjs",
  OSKeyStore: "resource://gre/modules/OSKeyStore.sys.mjs",
});

export let FormAutofillUtils;

const ADDRESS_METADATA_PATH = "resource://autofill/addressmetadata/";
const ADDRESS_REFERENCES = "addressReferences.js";
const ADDRESS_REFERENCES_EXT = "addressReferencesExt.js";

const ADDRESSES_COLLECTION_NAME = "addresses";
const CREDITCARDS_COLLECTION_NAME = "creditCards";
const MANAGE_ADDRESSES_L10N_IDS = [
  "autofill-add-new-address-title",
  "autofill-manage-addresses-title",
];
const EDIT_ADDRESS_L10N_IDS = [
  "autofill-address-given-name",
  "autofill-address-additional-name",
  "autofill-address-family-name",
  "autofill-address-organization",
  "autofill-address-street",
  "autofill-address-state",
  "autofill-address-province",
  "autofill-address-city",
  "autofill-address-country",
  "autofill-address-zip",
  "autofill-address-postal-code",
  "autofill-address-email",
  "autofill-address-tel",
];
const MANAGE_CREDITCARDS_L10N_IDS = [
  "autofill-add-new-card-title",
  "autofill-manage-credit-cards-title",
];
const EDIT_CREDITCARD_L10N_IDS = [
  "autofill-card-number",
  "autofill-card-name-on-card",
  "autofill-card-expires-month",
  "autofill-card-expires-year",
  "autofill-card-network",
];
const FIELD_STATES = {
  NORMAL: "NORMAL",
  AUTO_FILLED: "AUTO_FILLED",
  PREVIEW: "PREVIEW",
};
const FORM_SUBMISSION_REASON = {
  FORM_SUBMIT_EVENT: "form-submit-event",
  FORM_REMOVAL_AFTER_FETCH: "form-removal-after-fetch",
  IFRAME_PAGEHIDE: "iframe-pagehide",
};

const ELIGIBLE_INPUT_TYPES = ["text", "email", "tel", "number", "month"];

// The maximum length of data to be saved in a single field for preventing DoS
// attacks that fill the user's hard drive(s).
const MAX_FIELD_VALUE_LENGTH = 200;

export let AddressDataLoader = {
  // Status of address data loading. We'll load all the countries with basic level 1
  // information while requesting conutry information, and set country to true.
  // Level 1 Set is for recording which country's level 1/level 2 data is loaded,
  // since we only load this when getCountryAddressData called with level 1 parameter.
  _dataLoaded: {
    country: false,
    level1: new Set(),
  },

  /**
   * Load address data and extension script into a sandbox from different paths.
   *
   * @param   {string} path
   *          The path for address data and extension script. It could be root of the address
   *          metadata folder(addressmetadata/) or under specific country(addressmetadata/TW/).
   * @returns {object}
   *          A sandbox that contains address data object with properties from extension.
   */
  _loadScripts(path) {
    let sandbox = {};
    let extSandbox = {};

    try {
      sandbox = FormAutofillUtils.loadDataFromScript(path + ADDRESS_REFERENCES);
      extSandbox = FormAutofillUtils.loadDataFromScript(
        path + ADDRESS_REFERENCES_EXT
      );
    } catch (e) {
      // Will return only address references if extension loading failed or empty sandbox if
      // address references loading failed.
      return sandbox;
    }

    if (extSandbox.addressDataExt) {
      for (let key in extSandbox.addressDataExt) {
        let addressDataForKey = sandbox.addressData[key];
        if (!addressDataForKey) {
          addressDataForKey = sandbox.addressData[key] = {};
        }

        Object.assign(addressDataForKey, extSandbox.addressDataExt[key]);
      }
    }
    return sandbox;
  },

  /**
   * Convert certain properties' string value into array. We should make sure
   * the cached data is parsed.
   *
   * @param   {object} data Original metadata from addressReferences.
   * @returns {object} parsed metadata with property value that converts to array.
   */
  _parse(data) {
    if (!data) {
      return null;
    }

    const properties = [
      "languages",
      "sub_keys",
      "sub_isoids",
      "sub_names",
      "sub_lnames",
    ];
    for (let key of properties) {
      if (!data[key]) {
        continue;
      }
      // No need to normalize data if the value is array already.
      if (Array.isArray(data[key])) {
        return data;
      }

      data[key] = data[key].split("~");
    }
    return data;
  },

  /**
   * We'll cache addressData in the loader once the data loaded from scripts.
   * It'll become the example below after loading addressReferences with extension:
   * addressData: {
   *               "data/US": {"lang": ["en"], ...// Data defined in libaddressinput metadata
   *                           "alternative_names": ... // Data defined in extension }
   *               "data/CA": {} // Other supported country metadata
   *               "data/TW": {} // Other supported country metadata
   *               "data/TW/台北市": {} // Other supported country level 1 metadata
   *              }
   *
   * @param   {string} country
   * @param   {string?} level1
   * @returns {object} Default locale metadata
   */
  _loadData(country, level1 = null) {
    // Load the addressData if needed
    if (!this._dataLoaded.country) {
      this._addressData = this._loadScripts(ADDRESS_METADATA_PATH).addressData;
      this._dataLoaded.country = true;
    }
    if (!level1) {
      return this._parse(this._addressData[`data/${country}`]);
    }
    // If level1 is set, load addressReferences under country folder with specific
    // country/level 1 for level 2 information.
    if (!this._dataLoaded.level1.has(country)) {
      Object.assign(
        this._addressData,
        this._loadScripts(`${ADDRESS_METADATA_PATH}${country}/`).addressData
      );
      this._dataLoaded.level1.add(country);
    }
    return this._parse(this._addressData[`data/${country}/${level1}`]);
  },

  /**
   * Return the region metadata with default locale and other locales (if exists).
   *
   * @param   {string} country
   * @param   {string?} level1
   * @returns {object} Return default locale and other locales metadata.
   */
  getData(country, level1 = null) {
    let defaultLocale = this._loadData(country, level1);
    if (!defaultLocale) {
      return null;
    }

    let countryData = this._parse(this._addressData[`data/${country}`]);
    let locales = [];
    // TODO: Should be able to support multi-locale level 1/ level 2 metadata query
    //      in Bug 1421886
    if (countryData.languages) {
      let list = countryData.languages.filter(key => key !== countryData.lang);
      locales = list.map(key =>
        this._parse(this._addressData[`${defaultLocale.id}--${key}`])
      );
    }
    return { defaultLocale, locales };
  },
};

FormAutofillUtils = {
  get AUTOFILL_FIELDS_THRESHOLD() {
    return 3;
  },

  ADDRESSES_COLLECTION_NAME,
  CREDITCARDS_COLLECTION_NAME,
  MANAGE_ADDRESSES_L10N_IDS,
  EDIT_ADDRESS_L10N_IDS,
  MANAGE_CREDITCARDS_L10N_IDS,
  EDIT_CREDITCARD_L10N_IDS,
  MAX_FIELD_VALUE_LENGTH,
  FIELD_STATES,
  FORM_SUBMISSION_REASON,

  _fieldNameInfo: {
    name: "name",
    "given-name": "name",
    "additional-name": "name",
    "family-name": "name",
    organization: "organization",
    "street-address": "address",
    "address-line1": "address",
    "address-line2": "address",
    "address-line3": "address",
    "address-level1": "address",
    "address-level2": "address",
    "postal-code": "address",
    country: "address",
    "country-name": "address",
    tel: "tel",
    "tel-country-code": "tel",
    "tel-national": "tel",
    "tel-area-code": "tel",
    "tel-local": "tel",
    "tel-local-prefix": "tel",
    "tel-local-suffix": "tel",
    "tel-extension": "tel",
    email: "email",
    "cc-name": "creditCard",
    "cc-given-name": "creditCard",
    "cc-additional-name": "creditCard",
    "cc-family-name": "creditCard",
    "cc-number": "creditCard",
    "cc-exp-month": "creditCard",
    "cc-exp-year": "creditCard",
    "cc-exp": "creditCard",
    "cc-type": "creditCard",
    "cc-csc": "creditCard",
  },

  _collators: {},
  _reAlternativeCountryNames: {},

  isAddressField(fieldName) {
    return (
      !!this._fieldNameInfo[fieldName] && !this.isCreditCardField(fieldName)
    );
  },

  isCreditCardField(fieldName) {
    return this._fieldNameInfo?.[fieldName] == "creditCard";
  },

  isCCNumber(ccNumber) {
    return ccNumber && lazy.CreditCard.isValidNumber(ccNumber);
  },

  ensureLoggedIn(promptMessage) {
    return lazy.OSKeyStore.ensureLoggedIn(
      this._reauthEnabledByUser && promptMessage ? promptMessage : false
    );
  },

  /**
   * Get the array of credit card network ids ("types") we expect and offer as valid choices
   *
   * @returns {Array}
   */
  getCreditCardNetworks() {
    return lazy.CreditCard.getSupportedNetworks();
  },

  getCategoryFromFieldName(fieldName) {
    return this._fieldNameInfo[fieldName];
  },

  getCategoriesFromFieldNames(fieldNames) {
    let categories = new Set();
    for (let fieldName of fieldNames) {
      let info = this.getCategoryFromFieldName(fieldName);
      if (info) {
        categories.add(info);
      }
    }
    return Array.from(categories);
  },

  getAddressSeparator() {
    // The separator should be based on the L10N address format, and using a
    // white space is a temporary solution.
    return " ";
  },

  /**
   * Get address display label. It should display information separated
   * by a comma.
   *
   * @param  {object} address
   * @returns {string}
   */
  getAddressLabel(address) {
    // TODO: Implement a smarter way for deciding what to display
    //       as option text. Possibly improve the algorithm in
    //       ProfileAutoCompleteResult.jsm and reuse it here.
    let fieldOrder = [
      "name",
      "-moz-street-address-one-line", // Street address
      "address-level3", // Townland / Neighborhood / Village
      "address-level2", // City/Town
      "organization", // Company or organization name
      "address-level1", // Province/State (Standardized code if possible)
      "country", // Country name
      "postal-code", // Postal code
      "tel", // Phone number
      "email", // Email address
    ];

    address = { ...address };
    let parts = [];
    if (address["street-address"]) {
      address["-moz-street-address-one-line"] = this.toOneLineAddress(
        address["street-address"]
      );
    }

    if (!("name" in address)) {
      address.name = lazy.FormAutofillNameUtils.joinNameParts({
        given: address["given-name"],
        middle: address["additional-name"],
        family: address["family-name"],
      });
    }

    for (const fieldName of fieldOrder) {
      let string = address[fieldName];
      if (string) {
        parts.push(string);
      }
    }
    return parts.join(", ");
  },

  /**
   * Internal method to split an address to multiple parts per the provided delimiter,
   * removing blank parts.
   *
   * @param {string} address The address the split
   * @param {string} [delimiter] The separator that is used between lines in the address
   * @returns {string[]}
   */
  _toStreetAddressParts(address, delimiter = "\n") {
    let array = typeof address == "string" ? address.split(delimiter) : address;

    if (!Array.isArray(array)) {
      return [];
    }
    return array.map(s => (s ? s.trim() : "")).filter(s => s);
  },

  /**
   * Converts a street address to a single line, removing linebreaks marked by the delimiter
   *
   * @param {string} address The address the convert
   * @param {string} [delimiter] The separator that is used between lines in the address
   * @returns {string}
   */
  toOneLineAddress(address, delimiter = "\n") {
    let addressParts = this._toStreetAddressParts(address, delimiter);
    return addressParts.join(this.getAddressSeparator());
  },

  /**
   * In-place concatenate tel-related components into a single "tel" field and
   * delete unnecessary fields.
   *
   * @param {object} address An address record.
   */
  compressTel(address) {
    let telCountryCode = address["tel-country-code"] || "";
    let telAreaCode = address["tel-area-code"] || "";

    if (!address.tel) {
      if (address["tel-national"]) {
        address.tel = telCountryCode + address["tel-national"];
      } else if (address["tel-local"]) {
        address.tel = telCountryCode + telAreaCode + address["tel-local"];
      } else if (address["tel-local-prefix"] && address["tel-local-suffix"]) {
        address.tel =
          telCountryCode +
          telAreaCode +
          address["tel-local-prefix"] +
          address["tel-local-suffix"];
      }
    }

    for (let field in address) {
      if (field != "tel" && this.getCategoryFromFieldName(field) == "tel") {
        delete address[field];
      }
    }
  },

  /**
   * Determines if an element can be autofilled or not.
   *
   * @param {HTMLElement} element
   * @returns {boolean} true if the element can be autofilled
   */
  isFieldAutofillable(element) {
    return element && !element.readOnly && !element.disabled;
  },

  /**
   * Determines if an element is visually hidden or not.
   *
   * @param {HTMLElement} element
   * @param {boolean} visibilityCheck true to run visiblity check against
   *                  element.checkVisibility API. Otherwise, test by only checking
   *                  `hidden` and `display` attributes
   * @returns {boolean} true if the element is visible
   */
  isFieldVisible(element, visibilityCheck = true) {
    if (visibilityCheck && element.checkVisibility) {
      return element.checkVisibility({
        checkOpacity: true,
        checkVisibilityCSS: true,
      });
    }

    return !element.hidden && element.style.display != "none";
  },

  /**
   * Determines if an element is focusable
   * and accessible via keyboard navigation or not.
   *
   * @param {HTMLElement} element
   *
   * @returns {bool} true if the element is focusable and accessible
   */
  isFieldFocusable(element) {
    return (
      // The Services.focus.elementIsFocusable API considers elements with
      // tabIndex="-1" set as focusable. But since they are not accessible
      // via keyboard navigation we treat them as non-interactive
      Services.focus.elementIsFocusable(element, 0) && element.tabIndex != "-1"
    );
  },

  /**
   * Determines if an element is eligible to be used by credit card or address autofill.
   *
   * @param {HTMLElement} element
   * @returns {boolean} true if element can be used by credit card or address autofill
   */
  isCreditCardOrAddressFieldType(element) {
    if (!element) {
      return false;
    }

    if (HTMLInputElement.isInstance(element)) {
      // `element.type` can be recognized as `text`, if it's missing or invalid.
      return ELIGIBLE_INPUT_TYPES.includes(element.type);
    }

    return HTMLSelectElement.isInstance(element);
  },

  loadDataFromScript(url, sandbox = {}) {
    Services.scriptloader.loadSubScript(url, sandbox);
    return sandbox;
  },

  /**
   * Get country address data and fallback to US if not found.
   * See AddressDataLoader._loadData for more details of addressData structure.
   *
   * @param {string} [country=FormAutofill.DEFAULT_REGION]
   *        The country code for requesting specific country's metadata. It'll be
   *        default region if parameter is not set.
   * @param {string} [level1=null]
   *        Return address level 1/level 2 metadata if parameter is set.
   * @returns {object|null}
   *          Return metadata of specific region with default locale and other supported
   *          locales. We need to return a default country metadata for layout format
   *          and collator, but for sub-region metadata we'll just return null if not found.
   */
  getCountryAddressRawData(
    country = FormAutofill.DEFAULT_REGION,
    level1 = null
  ) {
    let metadata = AddressDataLoader.getData(country, level1);
    if (!metadata) {
      if (level1) {
        return null;
      }
      // Fallback to default region if we couldn't get data from given country.
      if (country != FormAutofill.DEFAULT_REGION) {
        metadata = AddressDataLoader.getData(FormAutofill.DEFAULT_REGION);
      }
    }

    // TODO: Now we fallback to US if we couldn't get data from default region,
    //       but it could be removed in bug 1423464 if it's not necessary.
    if (!metadata) {
      metadata = AddressDataLoader.getData("US");
    }
    return metadata;
  },

  /**
   * Get country address data with default locale.
   *
   * @param {string} country
   * @param {string} level1
   * @returns {object|null} Return metadata of specific region with default locale.
   *          NOTE: The returned data may be for a default region if the
   *          specified one cannot be found. Callers who only want the specific
   *          region should check the returned country code.
   */
  getCountryAddressData(country, level1) {
    let metadata = this.getCountryAddressRawData(country, level1);
    return metadata && metadata.defaultLocale;
  },

  /**
   * Get country address data with all locales.
   *
   * @param {string} country
   * @param {string} level1
   * @returns {Array<object> | null}
   *          Return metadata of specific region with all the locales.
   *          NOTE: The returned data may be for a default region if the
   *          specified one cannot be found. Callers who only want the specific
   *          region should check the returned country code.
   */
  getCountryAddressDataWithLocales(country, level1) {
    let metadata = this.getCountryAddressRawData(country, level1);
    return metadata && [metadata.defaultLocale, ...metadata.locales];
  },

  /**
   * Get the collators based on the specified country.
   *
   * @param {string}  country The specified country.
   * @param {object}  [options = {}] a list of options for this method
   * @param {boolean} [options.ignorePunctuation = true] Whether punctuation should be ignored.
   * @param {string}  [options.sensitivity = 'base'] Which differences in the strings should lead to non-zero result values
   * @param {string}  [options.usage = 'search'] Whether the comparison is for sorting or for searching for matching strings
   * @returns {Array} An array containing several collator objects.
   */
  getSearchCollators(
    country,
    { ignorePunctuation = true, sensitivity = "base", usage = "search" } = {}
  ) {
    // TODO: Only one language should be used at a time per country. The locale
    //       of the page should be taken into account to do this properly.
    //       We are going to support more countries in bug 1370193 and this
    //       should be addressed when we start to implement that bug.

    if (!this._collators[country]) {
      let dataset = this.getCountryAddressData(country);
      let languages = dataset.languages || [dataset.lang];
      let options = {
        ignorePunctuation,
        sensitivity,
        usage,
      };
      this._collators[country] = languages.map(
        lang => new Intl.Collator(lang, options)
      );
    }
    return this._collators[country];
  },

  // Based on the list of fields abbreviations in
  // https://github.com/googlei18n/libaddressinput/wiki/AddressValidationMetadata
  FIELDS_LOOKUP: {
    N: "name",
    O: "organization",
    A: "street-address",
    S: "address-level1",
    C: "address-level2",
    D: "address-level3",
    Z: "postal-code",
    n: "newLine",
  },

  /**
   * Parse a country address format string and outputs an array of fields.
   * Spaces, commas, and other literals are ignored in this implementation.
   * For example, format string "%A%n%C, %S" should return:
   * [
   *   {fieldId: "street-address", newLine: true},
   *   {fieldId: "address-level2"},
   *   {fieldId: "address-level1"},
   * ]
   *
   * @param   {string} fmt Country address format string
   * @returns {Array<object>} List of fields
   */
  parseAddressFormat(fmt) {
    if (!fmt) {
      throw new Error("fmt string is missing.");
    }

    return fmt.match(/%[^%]/g).reduce((parsed, part) => {
      // Take the first letter of each segment and try to identify it
      let fieldId = this.FIELDS_LOOKUP[part[1]];
      // Early return if cannot identify part.
      if (!fieldId) {
        return parsed;
      }
      // If a new line is detected, add an attribute to the previous field.
      if (fieldId == "newLine") {
        let size = parsed.length;
        if (size) {
          parsed[size - 1].newLine = true;
        }
        return parsed;
      }
      return parsed.concat({ fieldId });
    }, []);
  },

  /**
   * Used to populate dropdowns in the UI (e.g. FormAutofill preferences).
   * Use findAddressSelectOption for matching a value to a region.
   *
   * @param {string[]} subKeys An array of regionCode strings
   * @param {string[]} subIsoids An array of ISO ID strings, if provided will be preferred over the key
   * @param {string[]} subNames An array of regionName strings
   * @param {string[]} subLnames An array of latinised regionName strings
   * @returns {Map?} Returns null if subKeys or subNames are not truthy.
   *                   Otherwise, a Map will be returned mapping keys -> names.
   */
  buildRegionMapIfAvailable(subKeys, subIsoids, subNames, subLnames) {
    // Not all regions have sub_keys. e.g. DE
    if (
      !subKeys ||
      !subKeys.length ||
      (!subNames && !subLnames) ||
      (subNames && subKeys.length != subNames.length) ||
      (subLnames && subKeys.length != subLnames.length)
    ) {
      return null;
    }

    // Overwrite subKeys with subIsoids, when available
    if (subIsoids && subIsoids.length && subIsoids.length == subKeys.length) {
      for (let i = 0; i < subIsoids.length; i++) {
        if (subIsoids[i]) {
          subKeys[i] = subIsoids[i];
        }
      }
    }

    // Apply sub_lnames if sub_names does not exist
    let names = subNames || subLnames;
    return new Map(subKeys.map((key, index) => [key, names[index]]));
  },

  /**
   * Parse a require string and outputs an array of fields.
   * Spaces, commas, and other literals are ignored in this implementation.
   * For example, a require string "ACS" should return:
   * ["street-address", "address-level2", "address-level1"]
   *
   * @param   {string} requireString Country address require string
   * @returns {Array<string>} List of fields
   */
  parseRequireString(requireString) {
    if (!requireString) {
      throw new Error("requireString string is missing.");
    }

    return requireString.split("").map(fieldId => this.FIELDS_LOOKUP[fieldId]);
  },

  /**
   * Use address data and alternative country name list to identify a country code from a
   * specified country name.
   *
   * @param   {string} countryName A country name to be identified
   * @param   {string} [countrySpecified] A country code indicating that we only
   *                                      search its alternative names if specified.
   * @returns {string} The matching country code.
   */
  identifyCountryCode(countryName, countrySpecified) {
    if (!countryName) {
      return null;
    }

    if (AddressDataLoader.getData(countryName)) {
      return countryName;
    }

    const countries = countrySpecified
      ? [countrySpecified]
      : [...FormAutofill.countries.keys()];

    for (const country of countries) {
      let collators = this.getSearchCollators(country);
      let metadata = this.getCountryAddressData(country);
      if (country != metadata.key) {
        // We hit the fallback logic in getCountryAddressRawData so ignore it as
        // it's not related to `country` and use the name from l10n instead.
        metadata = {
          id: `data/${country}`,
          key: country,
          name: FormAutofill.countries.get(country),
        };
      }
      let alternativeCountryNames = metadata.alternative_names || [
        metadata.name,
      ];
      let reAlternativeCountryNames = this._reAlternativeCountryNames[country];
      if (!reAlternativeCountryNames) {
        reAlternativeCountryNames = this._reAlternativeCountryNames[country] =
          [];
      }

      if (countryName.length == 3) {
        if (this.strCompare(metadata.alpha_3_code, countryName, collators)) {
          return country;
        }
      }

      for (let i = 0; i < alternativeCountryNames.length; i++) {
        let name = alternativeCountryNames[i];
        let reName = reAlternativeCountryNames[i];
        if (!reName) {
          reName = reAlternativeCountryNames[i] = new RegExp(
            "\\b" + this.escapeRegExp(name) + "\\b",
            "i"
          );
        }

        if (
          this.strCompare(name, countryName, collators) ||
          reName.test(countryName)
        ) {
          return country;
        }
      }
    }

    return null;
  },

  findSelectOption(selectEl, record, fieldName) {
    if (this.isAddressField(fieldName)) {
      return this.findAddressSelectOption(selectEl, record, fieldName);
    }
    if (this.isCreditCardField(fieldName)) {
      return this.findCreditCardSelectOption(selectEl, record, fieldName);
    }
    return null;
  },

  /**
   * Try to find the abbreviation of the given sub-region name
   *
   * @param   {string[]} subregionValues A list of inferable sub-region values.
   * @param   {string} [country] A country name to be identified.
   * @returns {string} The matching sub-region abbreviation.
   */
  getAbbreviatedSubregionName(subregionValues, country) {
    let values = Array.isArray(subregionValues)
      ? subregionValues
      : [subregionValues];

    let collators = this.getSearchCollators(country);
    for (let metadata of this.getCountryAddressDataWithLocales(country)) {
      let {
        sub_keys: subKeys,
        sub_names: subNames,
        sub_lnames: subLnames,
      } = metadata;
      if (!subKeys) {
        // Not all regions have sub_keys. e.g. DE
        continue;
      }
      // Apply sub_lnames if sub_names does not exist
      subNames = subNames || subLnames;

      let speculatedSubIndexes = [];
      for (const val of values) {
        let identifiedValue = this.identifyValue(
          subKeys,
          subNames,
          val,
          collators
        );
        if (identifiedValue) {
          return identifiedValue;
        }

        // Predict the possible state by partial-matching if no exact match.
        [subKeys, subNames].forEach(sub => {
          speculatedSubIndexes.push(
            sub.findIndex(token => {
              let pattern = new RegExp(
                "\\b" + this.escapeRegExp(token) + "\\b"
              );

              return pattern.test(val);
            })
          );
        });
      }
      let subKey = subKeys[speculatedSubIndexes.find(i => !!~i)];
      if (subKey) {
        return subKey;
      }
    }
    return null;
  },

  /**
   * Find the option element from select element.
   * 1. Try to find the locale using the country from address.
   * 2. First pass try to find exact match.
   * 3. Second pass try to identify values from address value and options,
   *    and look for a match.
   *
   * @param   {DOMElement} selectEl
   * @param   {object} address
   * @param   {string} fieldName
   * @returns {DOMElement}
   */
  findAddressSelectOption(selectEl, address, fieldName) {
    if (selectEl.options.length > 512) {
      // Allow enough space for all countries (roughly 300 distinct values) and all
      // timezones (roughly 400 distinct values), plus some extra wiggle room.
      return null;
    }
    let value = address[fieldName];
    if (!value) {
      return null;
    }

    let collators = this.getSearchCollators(address.country);

    for (let option of selectEl.options) {
      if (
        this.strCompare(value, option.value, collators) ||
        this.strCompare(value, option.text, collators)
      ) {
        return option;
      }
    }

    switch (fieldName) {
      case "address-level1": {
        let { country } = address;
        let identifiedValue = this.getAbbreviatedSubregionName(
          [value],
          country
        );
        // No point going any further if we cannot identify value from address level 1
        if (!identifiedValue) {
          return null;
        }
        for (let dataset of this.getCountryAddressDataWithLocales(country)) {
          let keys = dataset.sub_keys;
          if (!keys) {
            // Not all regions have sub_keys. e.g. DE
            continue;
          }
          // Apply sub_lnames if sub_names does not exist
          let names = dataset.sub_names || dataset.sub_lnames;

          // Go through options one by one to find a match.
          // Also check if any option contain the address-level1 key.
          let pattern = new RegExp(
            "\\b" + this.escapeRegExp(identifiedValue) + "\\b",
            "i"
          );
          for (let option of selectEl.options) {
            let optionValue = this.identifyValue(
              keys,
              names,
              option.value,
              collators
            );
            let optionText = this.identifyValue(
              keys,
              names,
              option.text,
              collators
            );
            if (
              identifiedValue === optionValue ||
              identifiedValue === optionText ||
              pattern.test(option.value)
            ) {
              return option;
            }
          }
        }
        break;
      }
      case "country": {
        if (this.getCountryAddressData(value)) {
          for (let option of selectEl.options) {
            if (
              this.identifyCountryCode(option.text, value) ||
              this.identifyCountryCode(option.value, value)
            ) {
              return option;
            }
          }
        }
        break;
      }
    }

    return null;
  },

  findCreditCardSelectOption(selectEl, creditCard, fieldName) {
    let oneDigitMonth = creditCard["cc-exp-month"]
      ? creditCard["cc-exp-month"].toString()
      : null;
    let twoDigitsMonth = oneDigitMonth ? oneDigitMonth.padStart(2, "0") : null;
    let fourDigitsYear = creditCard["cc-exp-year"]
      ? creditCard["cc-exp-year"].toString()
      : null;
    let twoDigitsYear = fourDigitsYear ? fourDigitsYear.substr(2, 2) : null;
    let options = Array.from(selectEl.options);

    switch (fieldName) {
      case "cc-exp-month": {
        if (!oneDigitMonth) {
          return null;
        }
        for (let option of options) {
          if (
            [option.text, option.label, option.value].some(s => {
              let result = /[1-9]\d*/.exec(s);
              return result && result[0] == oneDigitMonth;
            })
          ) {
            return option;
          }
        }
        break;
      }
      case "cc-exp-year": {
        if (!fourDigitsYear) {
          return null;
        }
        for (let option of options) {
          if (
            [option.text, option.label, option.value].some(
              s => s == twoDigitsYear || s == fourDigitsYear
            )
          ) {
            return option;
          }
        }
        break;
      }
      case "cc-exp": {
        if (!oneDigitMonth || !fourDigitsYear) {
          return null;
        }
        let patterns = [
          oneDigitMonth + "/" + twoDigitsYear, // 8/22
          oneDigitMonth + "/" + fourDigitsYear, // 8/2022
          twoDigitsMonth + "/" + twoDigitsYear, // 08/22
          twoDigitsMonth + "/" + fourDigitsYear, // 08/2022
          oneDigitMonth + "-" + twoDigitsYear, // 8-22
          oneDigitMonth + "-" + fourDigitsYear, // 8-2022
          twoDigitsMonth + "-" + twoDigitsYear, // 08-22
          twoDigitsMonth + "-" + fourDigitsYear, // 08-2022
          twoDigitsYear + "-" + twoDigitsMonth, // 22-08
          fourDigitsYear + "-" + twoDigitsMonth, // 2022-08
          fourDigitsYear + "/" + oneDigitMonth, // 2022/8
          twoDigitsMonth + twoDigitsYear, // 0822
          twoDigitsYear + twoDigitsMonth, // 2208
        ];

        for (let option of options) {
          if (
            [option.text, option.label, option.value].some(str =>
              patterns.some(pattern => str.includes(pattern))
            )
          ) {
            return option;
          }
        }
        break;
      }
      case "cc-type": {
        let network = creditCard["cc-type"] || "";
        for (let option of options) {
          if (
            [option.text, option.label, option.value].some(
              s => lazy.CreditCard.getNetworkFromName(s) == network
            )
          ) {
            return option;
          }
        }
        break;
      }
    }

    return null;
  },

  /**
   * Try to match value with keys and names, but always return the key.
   *
   * @param   {Array<string>} keys
   * @param   {Array<string>} names
   * @param   {string} value
   * @param   {Array} collators
   * @returns {string}
   */
  identifyValue(keys, names, value, collators) {
    let resultKey = keys.find(key => this.strCompare(value, key, collators));
    if (resultKey) {
      return resultKey;
    }

    let index = names.findIndex(name =>
      this.strCompare(value, name, collators)
    );
    if (index !== -1) {
      return keys[index];
    }

    return null;
  },

  /**
   * Compare if two strings are the same.
   *
   * @param   {string} a
   * @param   {string} b
   * @param   {Array} collators
   * @returns {boolean}
   */
  strCompare(a = "", b = "", collators) {
    return collators.some(collator => !collator.compare(a, b));
  },

  /**
   * Determine whether one string(b) may be found within another string(a)
   *
   * @param   {string} a
   * @param   {string} b
   * @param   {Array} collators
   * @returns {boolean} True if the string is found
   */
  strInclude(a = "", b = "", collators) {
    const len = a.length - b.length;
    for (let i = 0; i <= len; i++) {
      if (this.strCompare(a.substring(i, i + b.length), b, collators)) {
        return true;
      }
    }
    return false;
  },

  /**
   * Escaping user input to be treated as a literal string within a regular
   * expression.
   *
   * @param   {string} string
   * @returns {string}
   */
  escapeRegExp(string) {
    return string.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  },

  /**
   * Get formatting information of a given country
   *
   * @param   {string} country
   * @returns {object}
   *         {
   *           {string} addressLevel3L10nId
   *           {string} addressLevel2L10nId
   *           {string} addressLevel1L10nId
   *           {string} postalCodeL10nId
   *           {object} fieldsOrder
   *           {string} postalCodePattern
   *         }
   */
  getFormFormat(country) {
    let dataset = this.getCountryAddressData(country);
    // We hit a country fallback in `getCountryAddressRawData` but it's not relevant here.
    if (country != dataset.key) {
      // Use a sparse object so the below default values take effect.
      dataset = {
        /**
         * Even though data/ZZ only has address-level2, include the other levels
         * in case they are needed for unknown countries. Users can leave the
         * unnecessary fields blank which is better than forcing users to enter
         * the data in incorrect fields.
         */
        fmt: "%N%n%O%n%A%n%C %S %Z",
      };
    }
    return {
      // When particular values are missing for a country, the
      // data/ZZ value should be used instead:
      // https://chromium-i18n.appspot.com/ssl-aggregate-address/data/ZZ
      addressLevel3L10nId: this.getAddressFieldL10nId(
        dataset.sublocality_name_type || "suburb"
      ),
      addressLevel2L10nId: this.getAddressFieldL10nId(
        dataset.locality_name_type || "city"
      ),
      addressLevel1L10nId: this.getAddressFieldL10nId(
        dataset.state_name_type || "province"
      ),
      addressLevel1Options: this.buildRegionMapIfAvailable(
        dataset.sub_keys,
        dataset.sub_isoids,
        dataset.sub_names,
        dataset.sub_lnames
      ),
      countryRequiredFields: this.parseRequireString(dataset.require || "AC"),
      fieldsOrder: this.parseAddressFormat(dataset.fmt || "%N%n%O%n%A%n%C"),
      postalCodeL10nId: this.getAddressFieldL10nId(
        dataset.zip_name_type || "postal-code"
      ),
      postalCodePattern: dataset.zip,
    };
  },

  getAddressFieldL10nId(type) {
    return "autofill-address-" + type.replace(/_/g, "-");
  },

  CC_FATHOM_NONE: 0,
  CC_FATHOM_JS: 1,
  CC_FATHOM_NATIVE: 2,
  isFathomCreditCardsEnabled() {
    return this.ccHeuristicsMode != this.CC_FATHOM_NONE;
  },

  /**
   * Transform the key in FormAutofillConfidences (defined in ChromeUtils.webidl)
   * to fathom recognized field type.
   *
   * @param {string} key key from FormAutofillConfidences dictionary
   * @returns {string} fathom field type
   */
  formAutofillConfidencesKeyToCCFieldType(key) {
    const MAP = {
      ccNumber: "cc-number",
      ccName: "cc-name",
      ccType: "cc-type",
      ccExp: "cc-exp",
      ccExpMonth: "cc-exp-month",
      ccExpYear: "cc-exp-year",
    };
    return MAP[key];
  },
};

ChromeUtils.defineLazyGetter(FormAutofillUtils, "stringBundle", function () {
  return Services.strings.createBundle(
    "chrome://formautofill/locale/formautofill.properties"
  );
});

ChromeUtils.defineLazyGetter(FormAutofillUtils, "brandBundle", function () {
  return Services.strings.createBundle(
    "chrome://branding/locale/brand.properties"
  );
});

XPCOMUtils.defineLazyPreferenceGetter(
  FormAutofillUtils,
  "_reauthEnabledByUser",
  "extensions.formautofill.reauth.enabled",
  false
);

XPCOMUtils.defineLazyPreferenceGetter(
  FormAutofillUtils,
  "ccHeuristicsMode",
  "extensions.formautofill.creditCards.heuristics.mode",
  0
);

XPCOMUtils.defineLazyPreferenceGetter(
  FormAutofillUtils,
  "ccFathomConfidenceThreshold",
  "extensions.formautofill.creditCards.heuristics.fathom.confidenceThreshold",
  null,
  null,
  pref => parseFloat(pref)
);

XPCOMUtils.defineLazyPreferenceGetter(
  FormAutofillUtils,
  "ccFathomHighConfidenceThreshold",
  "extensions.formautofill.creditCards.heuristics.fathom.highConfidenceThreshold",
  null,
  null,
  pref => parseFloat(pref)
);

XPCOMUtils.defineLazyPreferenceGetter(
  FormAutofillUtils,
  "ccFathomTestConfidence",
  "extensions.formautofill.creditCards.heuristics.fathom.testConfidence",
  null,
  null,
  pref => parseFloat(pref)
);

XPCOMUtils.defineLazyPreferenceGetter(
  FormAutofillUtils,
  "visibilityCheckThreshold",
  "extensions.formautofill.heuristics.visibilityCheckThreshold",
  200
);

XPCOMUtils.defineLazyPreferenceGetter(
  FormAutofillUtils,
  "interactivityCheckMode",
  "extensions.formautofill.heuristics.interactivityCheckMode",
  "focusability"
);

// This is only used in iOS
XPCOMUtils.defineLazyPreferenceGetter(
  FormAutofillUtils,
  "focusOnAutofill",
  "extensions.formautofill.focusOnAutofill",
  true
);
