.pragma library

// The launcher's calculator: arithmetic, unit conversion and currency
// conversion. Plain JavaScript with no QML, so it can be tested with node.
//
//   evaluate(query, rates) -> null when the query isn't a calculation, else
//   { kind: "math" | "unit" | "currency", value: Number, text: String,
//     detail: String, needsRates: Bool }
//
// `rates` is { base: "EUR", rates: { USD: 1.08, ... } } or null. When a
// currency conversion is typed without rates, the result has
// needsRates: true and no value.

// ---- Arithmetic ------------------------------------------------------------

const FUNCTIONS = {
    sqrt: Math.sqrt, cbrt: Math.cbrt, abs: Math.abs,
    sin: x => Math.sin(x), cos: x => Math.cos(x), tan: x => Math.tan(x),
    asin: Math.asin, acos: Math.acos, atan: Math.atan,
    sinh: Math.sinh, cosh: Math.cosh, tanh: Math.tanh,
    ln: Math.log, log: Math.log10, log2: Math.log2, exp: Math.exp,
    round: Math.round, floor: Math.floor, ceil: Math.ceil
};
const CONSTANTS = { pi: Math.PI, "π": Math.PI, e: Math.E, tau: 2 * Math.PI };

function tokenize(src) {
    const tokens = [];
    let i = 0;
    while (i < src.length) {
        const c = src[i];
        if (/\s/.test(c)) {
            i++;
        } else if (/[0-9.]/.test(c)) {
            // Numbers, with optional exponent: 1.5e3. Commas as thousands
            // separators ("1,000") are dropped before this point.
            const m = /^(\d+\.?\d*|\.\d+)(e[+-]?\d+)?/i.exec(src.slice(i));
            if (!m)
                throw new Error("bad number");
            tokens.push({ t: "num", v: parseFloat(m[0]) });
            i += m[0].length;
        } else if (/[a-zπ]/i.test(c)) {
            const m = /^[a-zπ][a-z0-9]*/i.exec(src.slice(i));
            tokens.push({ t: "id", v: m[0].toLowerCase() });
            i += m[0].length;
        } else if ("+-*/^%()!×÷−".includes(c)) {
            const map = { "×": "*", "÷": "/", "−": "-" };
            tokens.push({ t: "op", v: map[c] || c });
            i++;
        } else {
            throw new Error("unexpected " + c);
        }
    }
    return tokens;
}

// Recursive descent. Precedence, lowest first:
//   + -  |  * / and implicit multiplication (2pi, 3(4))  |  unary -  |  ^ (right)  |  postfix ! %
function parse(tokens) {
    let pos = 0;
    const peek = () => tokens[pos];
    const isOp = (v) => peek() && peek().t === "op" && peek().v === v;

    function expr() {
        let v = term();
        while (isOp("+") || isOp("-")) {
            const op = tokens[pos++].v;
            const r = term();
            v = op === "+" ? v + r : v - r;
        }
        return v;
    }

    function startsFactor() {
        const t = peek();
        return t && (t.t === "num" || t.t === "id" || (t.t === "op" && t.v === "("));
    }

    function term() {
        let v = unary();
        for (;;) {
            if (isOp("*") || isOp("/")) {
                const op = tokens[pos++].v;
                const r = unary();
                v = op === "*" ? v * r : v / r;
            } else if (startsFactor()) {
                v *= unary();
            } else {
                return v;
            }
        }
    }

    function unary() {
        if (isOp("-")) {
            pos++;
            return -unary();
        }
        if (isOp("+")) {
            pos++;
            return unary();
        }
        return power();
    }

    function power() {
        const base = postfix();
        if (isOp("^")) {
            pos++;
            return Math.pow(base, unary());
        }
        return base;
    }

    function postfix() {
        let v = primary();
        for (;;) {
            if (isOp("!")) {
                pos++;
                v = factorial(v);
            } else if (isOp("%")) {
                pos++;
                v = v / 100;
            } else {
                return v;
            }
        }
    }

    function primary() {
        const t = tokens[pos++];
        if (!t)
            throw new Error("unexpected end");
        if (t.t === "num")
            return t.v;
        if (t.t === "op" && t.v === "(") {
            const v = expr();
            if (!isOp(")"))
                throw new Error("missing )");
            pos++;
            return v;
        }
        if (t.t === "id") {
            if (Object.prototype.hasOwnProperty.call(CONSTANTS, t.v))
                return CONSTANTS[t.v];
            if (Object.prototype.hasOwnProperty.call(FUNCTIONS, t.v)) {
                // sqrt(2) or sqrt 2
                return FUNCTIONS[t.v](isOp("(") ? primary() : unary());
            }
        }
        throw new Error("unexpected token");
    }

    const v = expr();
    if (pos !== tokens.length)
        throw new Error("trailing input");
    return v;
}

function factorial(n) {
    if (n < 0 || n !== Math.floor(n) || n > 170)
        return NaN;
    let r = 1;
    for (let i = 2; i <= n; i++)
        r *= i;
    return r;
}

function evalMath(src) {
    const cleaned = src.replace(/(\d),(?=\d{3}\b)/g, "$1").replace(/\*\*/g, "^");
    return parse(tokenize(cleaned));
}

// ---- Units -----------------------------------------------------------------

// Each unit: [factor to the category's base unit, names...]. The first name is
// the one shown in results.
const UNITS = {
    length: [ // metres
        [1, "m", "meter", "meters", "metre", "metres"],
        [1000, "km", "kilometer", "kilometers", "kilometre", "kilometres"],
        [0.01, "cm", "centimeter", "centimeters", "centimetre", "centimetres"],
        [0.001, "mm", "millimeter", "millimeters", "millimetre", "millimetres"],
        [1e-6, "µm", "um", "micrometer", "micrometers", "micron", "microns"],
        [1e-9, "nm", "nanometer", "nanometers"],
        [1609.344, "mi", "mile", "miles"],
        [0.9144, "yd", "yard", "yards"],
        [0.3048, "ft", "foot", "feet", "'"],
        [0.0254, "in", "inch", "inches", "\""],
        [1852, "nmi", "nautical mile", "nautical miles"],
        [9.4607e15, "ly", "light year", "light years", "lightyear", "lightyears"],
        [1.495978707e11, "au"]
    ],
    mass: [ // kilograms
        [1, "kg", "kilogram", "kilograms", "kilo", "kilos"],
        [0.001, "g", "gram", "grams"],
        [1e-6, "mg", "milligram", "milligrams"],
        [1000, "t", "tonne", "tonnes", "metric ton", "metric tons"],
        [0.45359237, "lb", "lbs", "pound", "pounds"],
        [0.028349523125, "oz", "ounce", "ounces"],
        [6.35029318, "st", "stone", "stones"],
        [907.18474, "short ton", "short tons", "us ton", "us tons"],
        [0.0002, "ct", "carat", "carats"]
    ],
    volume: [ // litres
        [1, "l", "liter", "liters", "litre", "litres"],
        [0.001, "ml", "milliliter", "milliliters", "millilitre", "millilitres"],
        [0.01, "cl", "centiliter", "centiliters", "centilitre", "centilitres"],
        [0.1, "dl", "deciliter", "deciliters", "decilitre", "decilitres"],
        [1000, "m³", "m3", "cubic meter", "cubic meters", "cubic metre", "cubic metres"],
        [0.001, "cm³", "cm3", "cc"],
        [3.785411784, "gal", "gallon", "gallons", "us gallon", "us gallons"],
        [4.54609, "imp gal", "imperial gallon", "imperial gallons"],
        [0.946352946, "qt", "quart", "quarts"],
        [0.473176473, "pt", "pint", "pints"],
        [0.2365882365, "cup", "cups"],
        [0.0295735295625, "fl oz", "floz", "fluid ounce", "fluid ounces"],
        [0.01478676478125, "tbsp", "tablespoon", "tablespoons"],
        [0.00492892159375, "tsp", "teaspoon", "teaspoons"]
    ],
    area: [ // square metres
        [1, "m²", "m2", "sq m", "square meter", "square meters", "square metre", "square metres"],
        [1e6, "km²", "km2", "sq km", "square kilometer", "square kilometers", "square kilometre", "square kilometres"],
        [1e-4, "cm²", "cm2", "sq cm", "square centimeter", "square centimeters"],
        [10000, "ha", "hectare", "hectares"],
        [4046.8564224, "acre", "acres", "ac"],
        [0.09290304, "ft²", "ft2", "sq ft", "square foot", "square feet"],
        [0.00064516, "in²", "in2", "sq in", "square inch", "square inches"],
        [2589988.110336, "mi²", "mi2", "sq mi", "square mile", "square miles"]
    ],
    time: [ // seconds
        [1, "s", "sec", "secs", "second", "seconds"],
        [0.001, "ms", "millisecond", "milliseconds"],
        [1e-6, "µs", "us", "microsecond", "microseconds"],
        [1e-9, "ns", "nanosecond", "nanoseconds"],
        [60, "min", "mins", "minute", "minutes"],
        [3600, "h", "hr", "hrs", "hour", "hours"],
        [86400, "d", "day", "days"],
        [604800, "wk", "week", "weeks"],
        [2629746, "mo", "month", "months"],
        [31556952, "yr", "year", "years"]
    ],
    data: [ // bytes
        [1, "B", "byte", "bytes"],
        [0.125, "bit", "bits"],
        [1e3, "KB", "kilobyte", "kilobytes"],
        [1e6, "MB", "megabyte", "megabytes"],
        [1e9, "GB", "gigabyte", "gigabytes"],
        [1e12, "TB", "terabyte", "terabytes"],
        [1e15, "PB", "petabyte", "petabytes"],
        [1024, "KiB", "kibibyte", "kibibytes"],
        [1048576, "MiB", "mebibyte", "mebibytes"],
        [1073741824, "GiB", "gibibyte", "gibibytes"],
        [1099511627776, "TiB", "tebibyte", "tebibytes"],
        [125, "Kb", "kbit", "kilobit", "kilobits"],
        [125000, "Mb", "mbit", "megabit", "megabits"],
        [1.25e8, "Gb", "gbit", "gigabit", "gigabits"]
    ],
    speed: [ // metres per second
        [1, "m/s", "mps", "meters per second", "metres per second"],
        [1 / 3.6, "km/h", "kmh", "kph", "kmph", "kilometers per hour", "kilometres per hour"],
        [0.44704, "mph", "miles per hour"],
        [0.514444, "kn", "kt", "knot", "knots"],
        [0.3048, "ft/s", "fps", "feet per second"]
    ],
    energy: [ // joules
        [1, "J", "joule", "joules"],
        [1000, "kJ", "kilojoule", "kilojoules"],
        [4.184, "cal", "calorie", "calories"],
        [4184, "kcal", "kilocalorie", "kilocalories", "Cal"],
        [3.6e6, "kWh", "kilowatt hour", "kilowatt hours"],
        [3600, "Wh", "watt hour", "watt hours"],
        [1.602176634e-19, "eV", "electronvolt", "electronvolts"],
        [1055.05585262, "BTU", "btu"]
    ],
    pressure: [ // pascals
        [1, "Pa", "pascal", "pascals"],
        [1000, "kPa", "kilopascal", "kilopascals"],
        [100, "hPa", "hectopascal", "hectopascals", "mbar", "millibar", "millibars"],
        [100000, "bar", "bars"],
        [101325, "atm", "atmosphere", "atmospheres"],
        [6894.757293168, "psi"],
        [133.322387415, "mmHg", "torr"]
    ],
    angle: [ // radians
        [1, "rad", "radian", "radians"],
        [Math.PI / 180, "°", "deg", "degree", "degrees"],
        [Math.PI / 200, "grad", "gon", "gradian", "gradians"],
        [2 * Math.PI, "turn", "turns", "rev", "revolution", "revolutions"]
    ]
};

// Temperature isn't a plain factor.
const TEMPERATURES = [
    { name: "°C", names: ["c", "°c", "celsius", "centigrade", "degc"], toK: v => v + 273.15, fromK: k => k - 273.15 },
    { name: "°F", names: ["f", "°f", "fahrenheit", "degf"], toK: v => (v - 32) * 5 / 9 + 273.15, fromK: k => (k - 273.15) * 9 / 5 + 32 },
    { name: "K", names: ["k", "kelvin", "kelvins"], toK: v => v, fromK: k => k }
];

// name -> { category, factor, display }. Case-sensitive names win (MB vs Mb),
// then case-insensitive ones.
const exactUnits = {};
const lowerUnits = {};
for (const category in UNITS) {
    for (const entry of UNITS[category]) {
        const factor = entry[0];
        const display = entry[1];
        for (let i = 1; i < entry.length; i++) {
            const unit = { category, factor, display };
            exactUnits[entry[i]] = unit;
            const lower = entry[i].toLowerCase();
            if (!(lower in lowerUnits))
                lowerUnits[lower] = unit;
        }
    }
}

function findUnit(name) {
    const n = name.trim().replace(/\s+/g, " ");
    if (n in exactUnits)
        return exactUnits[n];
    const lower = n.toLowerCase();
    if (lower in lowerUnits)
        return lowerUnits[lower];
    return null;
}

function findTemperature(name) {
    const n = name.trim().toLowerCase().replace(/^degrees?\s+/, "").replace(/\s+/g, "");
    return TEMPERATURES.find(t => t.names.includes(n)) || null;
}

// ---- Currencies ------------------------------------------------------------

const CURRENCY_SYMBOLS = { "$": "USD", "€": "EUR", "£": "GBP", "¥": "JPY", "₹": "INR", "₩": "KRW", "₽": "RUB", "₺": "TRY", "₪": "ILS", "฿": "THB", "₫": "VND", "₱": "PHP", "₦": "NGN", "₴": "UAH", "₿": "BTC" };
const CURRENCY_NAMES = {
    dollar: "USD", dollars: "USD", usd: "USD", buck: "USD", bucks: "USD",
    euro: "EUR", euros: "EUR",
    pound: "GBP", pounds: "GBP", quid: "GBP", sterling: "GBP",
    yen: "JPY", rupee: "INR", rupees: "INR", rs: "INR",
    yuan: "CNY", renminbi: "CNY", rmb: "CNY", won: "KRW",
    franc: "CHF", francs: "CHF", real: "BRL", reais: "BRL",
    peso: "MXN", pesos: "MXN", rand: "ZAR", lira: "TRY", zloty: "PLN", forint: "HUF",
    krona: "SEK", kronor: "SEK", krone: "NOK", kroner: "NOK",
    dirham: "AED", dirhams: "AED", riyal: "SAR", riyals: "SAR",
    ruble: "RUB", rubles: "RUB", rouble: "RUB", roubles: "RUB", hryvnia: "UAH",
    shekel: "ILS", shekels: "ILS", baht: "THB", ringgit: "MYR", rupiah: "IDR",
    naira: "NGN", taka: "BDT", dong: "VND",
    bitcoin: "BTC", bitcoins: "BTC", ethereum: "ETH", ether: "ETH",
    gold: "XAU", silver: "XAG", platinum: "XPT", palladium: "XPD"
};
// Codes the rates source is known to cover, so "5 m to cm" isn't taken for a
// currency before rates have loaded.
// (Frankfurter's v2 list: world currencies, precious metals (XAU gold, XAG
// silver, XPT, XPD) and cryptocurrencies.)
const KNOWN_CODES = [
    "AED", "AFN", "ALL", "AMD", "ANG", "AOA", "ARS", "AUD", "AWG", "AZN", "BAM", "BBD", "BDT",
    "BHD", "BIF", "BMD", "BND", "BOB", "BRL", "BSD", "BTN", "BWP", "BYN", "BZD", "CAD", "CDF",
    "CHF", "CLP", "CNH", "CNY", "COP", "CRC", "CUP", "CVE", "CZK", "DJF", "DKK", "DOP", "DZD",
    "EGP", "ERN", "ETB", "EUR", "FJD", "FKP", "GBP", "GEL", "GGP", "GHS", "GIP", "GMD", "GNF",
    "GTQ", "GYD", "HKD", "HNL", "HTG", "HUF", "IDR", "ILS", "IMP", "INR", "IQD", "IRR", "ISK",
    "JEP", "JMD", "JOD", "JPY", "KES", "KGS", "KHR", "KMF", "KPW", "KRW", "KWD", "KYD", "KZT",
    "LAK", "LBP", "LKR", "LRD", "LSL", "LYD", "MAD", "MDL", "MGA", "MKD", "MMK", "MNT", "MOP",
    "MRU", "MUR", "MVR", "MWK", "MXN", "MYR", "MZN", "NAD", "NGN", "NIO", "NOK", "NPR", "NZD",
    "OMR", "PAB", "PEN", "PGK", "PHP", "PKR", "PLN", "PYG", "QAR", "RON", "RSD", "RUB", "RWF",
    "SAR", "SBD", "SCR", "SDG", "SEK", "SGD", "SHP", "SLE", "SOS", "SRD", "SSP", "STN", "SVC",
    "SYP", "SZL", "THB", "TJS", "TMT", "TND", "TOP", "TRY", "TTD", "TWD", "TZS", "UAH", "UGX",
    "USD", "UYU", "UZS", "VES", "VND", "VUV", "WST", "XAF", "XAG", "XAU", "XCD", "XCG", "XDR",
    "XOF", "XPD", "XPF", "XPT", "YER", "ZAR", "ZMW", "ZWG",
    "AAVE", "ADA", "ALGO", "APT", "ARB", "ATOM", "AVAX", "AXS", "BCH", "BTC", "CHZ", "CRV", "DOT",
    "ENA", "ETC", "ETH", "FIL", "HBAR", "ICP", "LINK", "LTC", "MANA", "NEAR", "ONDO", "POL", "SNX",
    "SOL", "SUI", "UNI", "USDC", "USDT", "XLM", "XRP", "XTZ", "ZEC"
];

function findCurrency(name, rates) {
    const n = name.trim();
    if (n in CURRENCY_SYMBOLS)
        return CURRENCY_SYMBOLS[n];
    const lower = n.toLowerCase();
    if (lower in CURRENCY_NAMES)
        return CURRENCY_NAMES[lower];
    const upper = n.toUpperCase();
    if (/^[A-Z]{3,5}$/.test(upper) && (KNOWN_CODES.includes(upper) || (rates && rates.rates && (upper in rates.rates || upper === rates.base))))
        return upper;
    return null;
}

function rateOf(code, rates) {
    return code === rates.base ? 1 : rates.rates[code];
}

// ---- Formatting ------------------------------------------------------------

function format(v) {
    if (!isFinite(v))
        return String(v);
    if (v === 0)
        return "0";
    const abs = Math.abs(v);
    if (abs >= 1e15 || abs < 1e-6)
        return v.toExponential(6).replace(/\.?0+e/, "e");
    // Up to 10 significant digits, no trailing zeros, thousands separators.
    let s = Number(v.toPrecision(10)).toString();
    const parts = s.split(".");
    parts[0] = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, ",");
    return parts.join(".");
}

// Two decimals, or 4 significant digits for amounts under 1 (crypto, gold).
function formatMoney(v) {
    if (v !== 0 && Math.abs(v) < 1)
        return format(Number(v.toPrecision(4)));
    const s = (Math.round(v * 100) / 100).toFixed(2);
    const parts = s.split(".");
    parts[0] = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, ",");
    return parts.join(".");
}

// ---- Entry point -----------------------------------------------------------

// "<amount> <from> to|in|as|= <to>", amount optional (1), possibly with a
// currency symbol in front ("$20 to eur", "€5 in ₹").
const CONVERSION = /^\s*([$€£¥₹₩₽₺₪฿₫₱₦₴₿])?\s*([-+]?[\d.,]*\d(?:e[+-]?\d+)?|[-+]?[\d.,]*\d?)\s*(.*?)\s+(?:to|in|into|as|=|->|→)\s+(.+?)\s*$/i;

function evaluate(query, rates) {
    const q = String(query || "").trim();
    if (q === "" || q.length > 200)
        return null;

    const conv = CONVERSION.exec(q);
    if (conv) {
        const symbol = conv[1] || "";
        const amountText = (conv[2] || "").replace(/,/g, "");
        const fromName = symbol || conv[3];
        const toName = conv[4];
        const amount = amountText === "" || amountText === "+" || amountText === "-" ? 1 : parseFloat(amountText);
        if (fromName && isFinite(amount)) {
            const result = convert(amount, fromName, toName, rates);
            if (result)
                return result;
        }
    }

    // Plain arithmetic. Must contain an operator or function, so typing a
    // bare number or an app name doesn't show a "result".
    if (!/[\d)πe]/i.test(q) || !/[-+*/^%!×÷−(]|(sqrt|cbrt|sin|cos|tan|ln|log|exp|abs|round|floor|ceil|pi|tau)|π/i.test(q))
        return null;
    try {
        const v = evalMath(q);
        if (typeof v !== "number" || isNaN(v))
            return null;
        return { kind: "math", value: v, text: format(v), detail: q.replace(/\s+/g, " ") + " =", needsRates: false };
    } catch (e) {
        return null;
    }
}

function convert(amount, fromName, toName, rates) {
    // Temperature.
    const tFrom = findTemperature(fromName);
    const tTo = findTemperature(toName);
    if (tFrom && tTo) {
        const v = tTo.fromK(tFrom.toK(amount));
        return { kind: "unit", value: v, text: `${format(round(v, 2))} ${tTo.name}`, detail: `${format(amount)} ${tFrom.name} =`, needsRates: false };
    }

    // Plain units.
    const uFrom = findUnit(fromName);
    const uTo = findUnit(toName);
    if (uFrom && uTo && uFrom.category === uTo.category) {
        const v = amount * uFrom.factor / uTo.factor;
        return { kind: "unit", value: v, text: `${format(v)} ${uTo.display}`, detail: `${format(amount)} ${uFrom.display} =`, needsRates: false };
    }

    // Currencies.
    const cFrom = findCurrency(fromName, rates);
    const cTo = findCurrency(toName, rates);
    if (cFrom && cTo) {
        if (!rates || !rates.rates)
            return { kind: "currency", value: NaN, text: "", detail: `${formatMoney(amount)} ${cFrom} → ${cTo}`, needsRates: true };
        const rFrom = rateOf(cFrom, rates);
        const rTo = rateOf(cTo, rates);
        if (!rFrom || !rTo)
            return null;
        const v = amount / rFrom * rTo;
        // The older of the two rates' dates (some aren't updated daily).
        const dates = rates.dates || {};
        const date = [dates[cFrom], dates[cTo]].filter(d => d).sort()[0] || rates.date || "";
        return { kind: "currency", value: v, text: `${formatMoney(v)} ${cTo}`, detail: `${formatMoney(amount)} ${cFrom} =`, needsRates: false, date };
    }
    return null;
}

function round(v, digits) {
    const f = Math.pow(10, digits);
    return Math.round(v * f) / f;
}

// For node: module.exports when loaded outside QML.
if (typeof module !== "undefined")
    module.exports = { evaluate, format };
