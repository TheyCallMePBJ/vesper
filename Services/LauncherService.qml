pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import "calc.js" as Calc

// The launcher's data: app search ranked by match and how often you've
// launched each app, the calculator, and exchange rates for currency
// conversion (fetched from frankfurter.dev, only when a currency conversion
// is typed, and cached for 12 hours).
Singleton {
    id: root

    readonly property string usageFile: Settings.stateDir + "/launcher.json"
    readonly property string cacheDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/vesper"
    readonly property string ratesFile: cacheDir + "/rates.json"
    // v2 covers ~160 currencies plus metals and crypto (v1 only the ECB's ~30).
    readonly property string ratesUrl: "https://api.frankfurter.dev/v2/rates?base=EUR"
    readonly property int ratesMaxAge: 12 * 3600 * 1000

    // { desktopEntryId: launchCount }
    property var usage: ({})
    // { version: 2, base, date (newest), rates: { CODE: rate },
    //   dates: { CODE: "yyyy-mm-dd" }, fetched: ms }
    property var rates: null
    property bool ratesLoading: false
    property string ratesError: ""

    // ---- Apps ----------------------------------------------------------------

    readonly property var apps: DesktopEntries.applications.values.filter(e => !e.noDisplay)

    // Higher is better; 0 = no match.
    function matchScore(entry, q) {
        const name = (entry.name || "").toLowerCase();
        if (name === q)
            return 100;
        if (name.startsWith(q))
            return 80;
        if (name.split(/[\s\-_.]+/).some(w => w.startsWith(q)))
            return 65;
        if (name.includes(q))
            return 50;
        const generic = (entry.genericName || "").toLowerCase();
        if (generic.split(/[\s\-_.]+/).some(w => w.startsWith(q)))
            return 40;
        if ((entry.keywords || []).some(k => k.toLowerCase().startsWith(q)))
            return 35;
        if ((entry.id || "").toLowerCase().includes(q))
            return 30;
        if (generic.includes(q) || (entry.comment || "").toLowerCase().includes(q))
            return 15;
        // Letters in order: "vsc" matches "Visual Studio Code".
        let i = 0;
        for (const c of name)
            if (c === q[i])
                i++;
        return i === q.length ? 10 : 0;
    }

    function search(query) {
        const q = query.trim().toLowerCase();
        const useUsage = Settings.launcher.sortByUsage;
        const scored = [];
        for (const entry of apps) {
            const score = q === "" ? 1 : matchScore(entry, q);
            if (score > 0)
                scored.push({ entry, score, uses: useUsage ? (usage[entry.id] || 0) : 0 });
        }
        scored.sort((a, b) => {
            // Usage only reorders apps that match about as well.
            const band = x => Math.floor(x.score / 20);
            return (band(b) - band(a)) || (b.uses - a.uses) || (b.score - a.score) || a.entry.name.localeCompare(b.entry.name);
        });
        return scored.map(s => s.entry);
    }

    function launch(entry) {
        if (!entry)
            return;
        const next = Object.assign({}, usage);
        next[entry.id] = (next[entry.id] || 0) + 1;
        usage = next;
        saveUsage.restart();

        const prefix = (Settings.launcher.launchPrefix || "").trim();
        if (entry.runInTerminal) {
            const terminal = (Settings.launcher.terminal || "").trim() || "xterm -e";
            run(`${prefix} ${terminal} ${shellJoin(entry.command)}`.trim(), entry.workingDirectory);
        } else if (prefix !== "") {
            run(`${prefix} ${shellJoin(entry.command)}`, entry.workingDirectory);
        } else {
            entry.execute();
        }
    }

    function run(commandLine, workingDirectory) {
        Quickshell.execDetached({ command: ["sh", "-c", commandLine], workingDirectory: workingDirectory || Quickshell.env("HOME") });
    }

    function shellJoin(args) {
        return args.map(a => /^[\w@%+=:,./-]+$/.test(a) ? a : "'" + a.replace(/'/g, "'\\''") + "'").join(" ");
    }

    // ---- Calculator ----------------------------------------------------------

    // Result for a query, or null. Asks for exchange rates if it needs them.
    function calculate(query) {
        if (!Settings.launcher.calculator)
            return null;
        const result = Calc.evaluate(query, ratesFresh() ? rates : (rates || null));
        if (!result)
            return null;
        if (result.kind === "currency") {
            if (!Settings.launcher.currency)
                return null;
            // Not from inside the caller's binding.
            if (!ratesFresh())
                Qt.callLater(fetchRates);
        }
        return result;
    }

    function copy(text) {
        Quickshell.execDetached(["wl-copy", "--", text]);
    }

    // ---- Exchange rates ------------------------------------------------------

    function ratesFresh() {
        return rates !== null && rates.version === 2 && Date.now() - (rates.fetched || 0) < ratesMaxAge;
    }

    function fetchRates() {
        if (ratesProc.running)
            return;
        ratesLoading = true;
        ratesError = "";
        ratesProc.running = true;
    }

    Process {
        id: ratesProc
        command: ["curl", "-sSf", "--max-time", "15", root.ratesUrl]
        stdout: StdioCollector { id: ratesOut }
        stderr: StdioCollector { id: ratesErr }
        onExited: code => {
            root.ratesLoading = false;
            try {
                if (code !== 0)
                    throw new Error(ratesErr.text.trim() || `curl exit code ${code}`);
                // A list of { date, base, quote, rate }.
                const list = JSON.parse(ratesOut.text);
                if (!Array.isArray(list) || list.length === 0)
                    throw new Error("no rates in reply");
                const result = { version: 2, base: "EUR", date: "", rates: {}, dates: {}, fetched: Date.now() };
                for (const r of list) {
                    if (!r || typeof r.quote !== "string" || !(r.rate > 0))
                        continue;
                    result.rates[r.quote] = r.rate;
                    result.dates[r.quote] = r.date || "";
                    if (r.date > result.date)
                        result.date = r.date;
                }
                root.rates = result;
                ratesView.setText(JSON.stringify(root.rates) + "\n");
            } catch (err) {
                root.ratesError = "Couldn't get exchange rates";
                Logger.w("Launcher", `Exchange rates: ${err.message}`);
            }
        }
    }

    FileView {
        id: ratesView
        path: root.ratesFile
        printErrors: false
        onLoaded: {
            try {
                const data = JSON.parse(text());
                // Older caches (v1 format) are ignored and fetched again.
                if (data && data.rates && data.version === 2)
                    root.rates = data;
            } catch (err) {}
        }
    }

    // ---- Usage counts --------------------------------------------------------

    FileView {
        id: usageView
        path: root.usageFile
        printErrors: false
        onLoaded: {
            try {
                const data = JSON.parse(text());
                if (data && typeof data.usage === "object")
                    root.usage = data.usage;
            } catch (err) {
                Logger.w("Launcher", `Could not read ${root.usageFile}: ${err.message}`);
            }
        }
        onSaveFailed: error => Logger.e("Launcher", `Could not save ${root.usageFile}: ${FileViewError.toString(error)}`)
    }

    Timer {
        id: saveUsage
        interval: 1000
        onTriggered: usageView.setText(JSON.stringify({ usage: root.usage }) + "\n")
    }

    function clearUsage() {
        usage = {};
        saveUsage.restart();
    }
}
