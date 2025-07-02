// lib/currency_data.dart

// Helper function to convert a 2-letter country code to a flag emoji
// Note: This is a heuristic and works for standard ISO 3166-1 alpha-2 codes.
// It might not produce a valid flag for all 2-letter combinations derived from currency codes.
String currencyCodeToFlagEmoji(String currencyCode) {
  if (currencyCode.length < 2) {
    return '🏳️'; // Default/placeholder flag for codes less than 2 chars
  }
  // Use the first two letters of the currency code as a heuristic for the country code.
  // This is not always accurate (e.g., EUR, XCD) but is a common approach for a broad list.
  String countryCode = currencyCode.substring(0, 2).toUpperCase();

  // For specific multi-country currencies, we can assign a representative flag or a generic one.
  if (currencyCode == 'EUR') return '🇪🇺'; // European Union flag
  if (currencyCode == 'XCD') return '⭐'; // Placeholder, East Caribbean Dollar uses a symbol
  if (currencyCode == 'XOF') return '🌍'; // Placeholder, West African CFA franc
  if (currencyCode == 'XPF') return '🇵🇫'; // French Polynesia often associated with CFP franc

  // Check if the country code consists of valid uppercase letters A-Z
  if (!RegExp(r'^[A-Z]{2}$').hasMatch(countryCode)) {
    return '🏳️'; // Default flag if not two uppercase letters
  }

  final int firstLetter = countryCode.codeUnitAt(0) - 0x41 + 0x1F1E6;
  final int secondLetter = countryCode.codeUnitAt(1) - 0x41 + 0x1F1E6;

  // Basic validation for Unicode regional indicator symbols
  if (firstLetter < 0x1F1E6 || firstLetter > 0x1F1FF || secondLetter < 0x1F1E6 || secondLetter > 0x1F1FF) {
    return '🏳️';
  }
  return String.fromCharCode(firstLetter) + String.fromCharCode(secondLetter);
}

// Comprehensive list of currencies supported by ExchangeRate-API
// Source: https://www.exchangerate-api.com/docs/supported-currencies (as of a recent check)
// Each map contains: 'code', 'name', and 'flag' (generated)
final List<Map<String, String>> allSupportedCurrencies = [
  {'code': 'USD', 'name': 'United States Dollar'},
  {'code': 'AED', 'name': 'United Arab Emirates Dirham'},
  {'code': 'AFN', 'name': 'Afghan Afghani'},
  {'code': 'ALL', 'name': 'Albanian Lek'},
  {'code': 'AMD', 'name': 'Armenian Dram'},
  {'code': 'ANG', 'name': 'Netherlands Antillean Guilder'},
  {'code': 'AOA', 'name': 'Angolan Kwanza'},
  {'code': 'ARS', 'name': 'Argentine Peso'},
  {'code': 'AUD', 'name': 'Australian Dollar'},
  {'code': 'AWG', 'name': 'Aruban Florin'},
  {'code': 'AZN', 'name': 'Azerbaijani Manat'},
  {'code': 'BAM', 'name': 'Bosnia-Herzegovina Convertible Mark'},
  {'code': 'BBD', 'name': 'Barbadian Dollar'},
  {'code': 'BDT', 'name': 'Bangladeshi Taka'},
  {'code': 'BGN', 'name': 'Bulgarian Lev'},
  {'code': 'BHD', 'name': 'Bahraini Dinar'},
  {'code': 'BIF', 'name': 'Burundian Franc'},
  {'code': 'BMD', 'name': 'Bermudian Dollar'},
  {'code': 'BND', 'name': 'Brunei Dollar'},
  {'code': 'BOB', 'name': 'Bolivian Boliviano'},
  {'code': 'BRL', 'name': 'Brazilian Real'},
  {'code': 'BSD', 'name': 'Bahamian Dollar'},
  {'code': 'BTN', 'name': 'Bhutanese Ngultrum'},
  {'code': 'BWP', 'name': 'Botswanan Pula'},
  {'code': 'BYN', 'name': 'Belarusian Ruble'},
  {'code': 'BZD', 'name': 'Belize Dollar'},
  {'code': 'CAD', 'name': 'Canadian Dollar'},
  {'code': 'CDF', 'name': 'Congolese Franc'},
  {'code': 'CHF', 'name': 'Swiss Franc'},
  {'code': 'CLP', 'name': 'Chilean Peso'},
  {'code': 'CNY', 'name': 'Chinese Yuan'},
  {'code': 'COP', 'name': 'Colombian Peso'},
  {'code': 'CRC', 'name': 'Costa Rican Colón'},
  {'code': 'CUP', 'name': 'Cuban Peso'},
  {'code': 'CVE', 'name': 'Cape Verdean Escudo'},
  {'code': 'CZK', 'name': 'Czech Koruna'},
  {'code': 'DJF', 'name': 'Djiboutian Franc'},
  {'code': 'DKK', 'name': 'Danish Krone'},
  {'code': 'DOP', 'name': 'Dominican Peso'},
  {'code': 'DZD', 'name': 'Algerian Dinar'},
  {'code': 'EGP', 'name': 'Egyptian Pound'},
  {'code': 'ERN', 'name': 'Eritrean Nakfa'},
  {'code': 'ETB', 'name': 'Ethiopian Birr'},
  {'code': 'EUR', 'name': 'Euro'},
  {'code': 'FJD', 'name': 'Fijian Dollar'},
  {'code': 'FKP', 'name': 'Falkland Islands Pound'},
  {'code': 'FOK', 'name': 'Faroese Króna'},
  {'code': 'GBP', 'name': 'British Pound Sterling'},
  {'code': 'GEL', 'name': 'Georgian Lari'},
  {'code': 'GGP', 'name': 'Guernsey Pound'},
  {'code': 'GHS', 'name': 'Ghanaian Cedi'},
  {'code': 'GIP', 'name': 'Gibraltar Pound'},
  {'code': 'GMD', 'name': 'Gambian Dalasi'},
  {'code': 'GNF', 'name': 'Guinean Franc'},
  {'code': 'GTQ', 'name': 'Guatemalan Quetzal'},
  {'code': 'GYD', 'name': 'Guyanaese Dollar'},
  {'code': 'HKD', 'name': 'Hong Kong Dollar'},
  {'code': 'HNL', 'name': 'Honduran Lempira'},
  {'code': 'HRK', 'name': 'Croatian Kuna'},
  {'code': 'HTG', 'name': 'Haitian Gourde'},
  {'code': 'HUF', 'name': 'Hungarian Forint'},
  {'code': 'IDR', 'name': 'Indonesian Rupiah'},
  {'code': 'ILS', 'name': 'Israeli New Shekel'},
  {'code': 'IMP', 'name': 'Manx pound'},
  {'code': 'INR', 'name': 'Indian Rupee'},
  {'code': 'IQD', 'name': 'Iraqi Dinar'},
  {'code': 'IRR', 'name': 'Iranian Rial'},
  {'code': 'ISK', 'name': 'Icelandic Króna'},
  {'code': 'JEP', 'name': 'Jersey Pound'},
  {'code': 'JMD', 'name': 'Jamaican Dollar'},
  {'code': 'JOD', 'name': 'Jordanian Dinar'},
  {'code': 'JPY', 'name': 'Japanese Yen'},
  {'code': 'KES', 'name': 'Kenyan Shilling'},
  {'code': 'KGS', 'name': 'Kyrgystani Som'},
  {'code': 'KHR', 'name': 'Cambodian Riel'},
  {'code': 'KID', 'name': 'Kiribati Dollar'},
  {'code': 'KMF', 'name': 'Comorian Franc'},
  {'code': 'KRW', 'name': 'South Korean Won'},
  {'code': 'KWD', 'name': 'Kuwaiti Dinar'},
  {'code': 'KYD', 'name': 'Cayman Islands Dollar'},
  {'code': 'KZT', 'name': 'Kazakhstani Tenge'},
  {'code': 'LAK', 'name': 'Laotian Kip'},
  {'code': 'LBP', 'name': 'Lebanese Pound'},
  {'code': 'LKR', 'name': 'Sri Lankan Rupee'},
  {'code': 'LRD', 'name': 'Liberian Dollar'},
  {'code': 'LSL', 'name': 'Lesotho Loti'},
  {'code': 'LYD', 'name': 'Libyan Dinar'},
  {'code': 'MAD', 'name': 'Moroccan Dirham'},
  {'code': 'MDL', 'name': 'Moldovan Leu'},
  {'code': 'MGA', 'name': 'Malagasy Ariary'},
  {'code': 'MKD', 'name': 'Macedonian Denar'},
  {'code': 'MMK', 'name': 'Myanmar Kyat'},
  {'code': 'MNT', 'name': 'Mongolian Tugrik'},
  {'code': 'MOP', 'name': 'Macanese Pataca'},
  {'code': 'MRU', 'name': 'Mauritanian Ouguiya'},
  {'code': 'MUR', 'name': 'Mauritian Rupee'},
  {'code': 'MVR', 'name': 'Maldivian Rufiyaa'},
  {'code': 'MWK', 'name': 'Malawian Kwacha'},
  {'code': 'MXN', 'name': 'Mexican Peso'},
  {'code': 'MYR', 'name': 'Malaysian Ringgit'},
  {'code': 'MZN', 'name': 'Mozambican Metical'},
  {'code': 'NAD', 'name': 'Namibian Dollar'},
  {'code': 'NGN', 'name': 'Nigerian Naira'},
  {'code': 'NIO', 'name': 'Nicaraguan Córdoba'},
  {'code': 'NOK', 'name': 'Norwegian Krone'},
  {'code': 'NPR', 'name': 'Nepalese Rupee'},
  {'code': 'NZD', 'name': 'New Zealand Dollar'},
  {'code': 'OMR', 'name': 'Omani Rial'},
  {'code': 'PAB', 'name': 'Panamanian Balboa'},
  {'code': 'PEN', 'name': 'Peruvian Sol'},
  {'code': 'PGK', 'name': 'Papua New Guinean Kina'},
  {'code': 'PHP', 'name': 'Philippine Peso'},
  {'code': 'PKR', 'name': 'Pakistani Rupee'},
  {'code': 'PLN', 'name': 'Polish Zloty'},
  {'code': 'PYG', 'name': 'Paraguayan Guarani'},
  {'code': 'QAR', 'name': 'Qatari Rial'},
  {'code': 'RON', 'name': 'Romanian Leu'},
  {'code': 'RSD', 'name': 'Serbian Dinar'},
  {'code': 'RUB', 'name': 'Russian Ruble'},
  {'code': 'RWF', 'name': 'Rwandan Franc'},
  {'code': 'SAR', 'name': 'Saudi Riyal'},
  {'code': 'SBD', 'name': 'Solomon Islands Dollar'},
  {'code': 'SCR', 'name': 'Seychellois Rupee'},
  {'code': 'SDG', 'name': 'Sudanese Pound'},
  {'code': 'SEK', 'name': 'Swedish Krona'},
  {'code': 'SGD', 'name': 'Singapore Dollar'},
  {'code': 'SHP', 'name': 'Saint Helena Pound'},
  {'code': 'SLE', 'name': 'Sierra Leonean Leone'},
  {'code': 'SOS', 'name': 'Somali Shilling'},
  {'code': 'SRD', 'name': 'Surinamese Dollar'},
  {'code': 'SSP', 'name': 'South Sudanese Pound'},
  {'code': 'STN', 'name': 'São Tomé and Príncipe Dobra'},
  {'code': 'SYP', 'name': 'Syrian Pound'},
  {'code': 'SZL', 'name': 'Swazi Lilangeni'},
  {'code': 'THB', 'name': 'Thai Baht'},
  {'code': 'TJS', 'name': 'Tajikistani Somoni'},
  {'code': 'TMT', 'name': 'Turkmenistani Manat'},
  {'code': 'TND', 'name': 'Tunisian Dinar'},
  {'code': 'TOP', 'name': 'Tongan Paʻanga'},
  {'code': 'TRY', 'name': 'Turkish Lira'},
  {'code': 'TTD', 'name': 'Trinidad and Tobago Dollar'},
  {'code': 'TVD', 'name': 'Tuvaluan Dollar'},
  {'code': 'TWD', 'name': 'New Taiwan Dollar'},
  {'code': 'TZS', 'name': 'Tanzanian Shilling'},
  {'code': 'UAH', 'name': 'Ukrainian Hryvnia'},
  {'code': 'UGX', 'name': 'Ugandan Shilling'},
  {'code': 'UYU', 'name': 'Uruguayan Peso'},
  {'code': 'UZS', 'name': 'Uzbekistan Som'},
  {'code': 'VES', 'name': 'Venezuelan Bolívar Soberano'},
  {'code': 'VND', 'name': 'Vietnamese Dong'},
  {'code': 'VUV', 'name': 'Vanuatu Vatu'},
  {'code': 'WST', 'name': 'Samoan Tala'},
  {'code': 'XAF', 'name': 'Central African CFA Franc'},
  {'code': 'XCD', 'name': 'East Caribbean Dollar'},
  {'code': 'XDR', 'name': 'Special Drawing Rights'},
  {'code': 'XOF', 'name': 'West African CFA Franc'},
  {'code': 'XPF', 'name': 'CFP Franc'},
  {'code': 'YER', 'name': 'Yemeni Rial'},
  {'code': 'ZAR', 'name': 'South African Rand'},
  {'code': 'ZMW', 'name': 'Zambian Kwacha'},
  {'code': 'ZWL', 'name': 'Zimbabwean Dollar'},
].map((currency) {
  // Automatically add the 'flag' key to each currency map
  return {
    ...currency,
    'flag': currencyCodeToFlagEmoji(currency['code']!),
  };
}).toList();

