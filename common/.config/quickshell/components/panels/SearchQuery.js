.pragma library

// What a unified search query asks for. Pure, no Quickshell.

// The leading character that narrows a query to one mode. A new mode is one
// more entry here.
const prefixes = {
    ">": "commands",
    "?": "web",
    "@": "windows",
    "=": "calculator",
    ":": "emoji"
};

// The mode `query`'s prefix picks ("" for none) and the text after it.
function mode(query) {
    const text = String(query).trim();
    const picked = prefixes[text.charAt(0)];

    if (picked === undefined)
        return { mode: "", text: text };

    return { mode: picked, text: text.slice(1).trim() };
}

// Only numbers, brackets and operators, with an operator between two
// operands: "2*(3+4)", "1/3", "2^10". A bare number ("2048") is an app search.
const arithmetic = /^[\d\s.,+\-*/^×÷()]+$/;
const operatorBetween = /[\d)]\s*[+\-*/^×÷]\s*[\d(.]/;
// A function written straight against its bracket, with a number inside, then
// maybe more arithmetic: "sqrt(16)", "log(100) * 2". "Steam (2)" is an app.
const functionCall = /^[a-z]+\([^()]*\d[^()]*\)[\d\s.,+\-*/^×÷()]*$/i;
// A number with a unit, then "to"/"in"/"as" and the unit to convert it to:
// "5 km to mi", "30 °C to °F". The query has to start with the number.
const conversion = /^-?\d[\d.,]*\s*[^\d\s]+\s+(to|in|as)\s+\S+$/i;
// "20% of 80". qalc reads "of" as a unit, so it's asked as "20% * 80".
const percentageOf = /^(\d[\d.,]*)\s*%\s*of\s+(\d[\d.,]*)$/i;

// The expression to hand qalc for `query`, or "" when the query isn't maths.
// After "=" anything is maths; another prefix never is.
function calculation(query) {
    const picked = mode(query);
    const text = picked.text;
    const percentage = text.match(percentageOf);

    if (picked.mode !== "" && picked.mode !== "calculator")
        return "";
    if (percentage)
        return percentage[1] + "% * " + percentage[2];
    if (picked.mode === "calculator")
        return text;
    if (arithmetic.test(text) && operatorBetween.test(text))
        return text;
    if (conversion.test(text) || functionCall.test(text))
        return text;

    return "";
}

// How long qalc may take before it is killed, in seconds: one query runs at a
// time, so a hung qalc would otherwise hold back every later one. It is sent
// SIGTERM, then SIGKILL a second later if it ignores that.
const qalcTimeoutSeconds = 3;

// How qalc is run for `expression`: terse output, and the expression as its
// own argument, never through a shell; under `timeout`, which exits 124 (or
// 137 once it has to kill it), so a killed qalc gives no answer.
function qalcCommand(expression) {
    return ["timeout", "-k", "1", String(qalcTimeoutSeconds), "qalc", "-t", String(expression)];
}

// qalc's answer from the lines it printed and its exit code: the last line it
// printed, or "" when it failed or said nothing. qalc still prints a guess
// when it can't read the expression, but exits 1.
function answer(lines, exitCode) {
    if (exitCode !== 0)
        return "";

    const printed = lines.map(line => String(line).trim()).filter(line => line !== "");
    return printed.length > 0 ? printed[printed.length - 1] : "";
}
