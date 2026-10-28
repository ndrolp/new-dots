.pragma library
.import "EmojiData.js" as EmojiData

// Which emoji the emoji picker lists for the text after ":". Pure, no
// Quickshell.

// What ":" alone lists, most used first.
const common = [
    "😂", "❤️", "🤣", "👍", "😭", "🙏", "😘", "🥰", "😍", "😊", "🎉", "😁",
    "💕", "🥺", "😅", "🔥", "🤦", "🤷", "🙄", "😆", "🤗", "😉", "🤔", "👏",
    "🙂", "😳", "🥳", "😎", "👌", "💜", "😔", "💪", "✨", "👀", "😋", "😏",
    "✅", "👋", "💯", "🚀"
];

// The same emoji with or without the selector that asks for colour.
function bare(emoji) {
    return emoji.replace(/️/g, "");
}

const entries = EmojiData.list.map(([emoji, name, keywords]) => ({
    emoji: emoji,
    name: name,
    keywords: keywords === "" ? [] : keywords.split(" ").map(word => word.replace(/_/g, " ")),
    words: (name + " " + keywords).split(/[\s_-]+/).filter(word => word !== "")
}));

const byEmoji = {};
for (const entry of entries)
    byEmoji[bare(entry.emoji)] = entry;

// How well `entry` fits `text`, lower is better, -1 for not at all: the name
// or a shortcode is the text, then the name starts with it, then a shortcode
// does, then every word of the text starts one of its words.
function rank(entry, text, textWords) {
    if (entry.name === text || entry.keywords.includes(text))
        return 0;
    if (entry.name.startsWith(text))
        return 1;
    if (entry.keywords.some(keyword => keyword.startsWith(text)))
        return 2;
    if (textWords.every(word => entry.words.some(own => own.startsWith(word))))
        return 3;

    return -1;
}

// Up to `limit` emoji for `text`, best first, as { emoji, name }. No text
// lists the common ones.
function matches(text, limit) {
    const query = String(text).trim().toLowerCase();
    let found;

    if (query === "") {
        found = common.map(emoji => byEmoji[bare(emoji)]).filter(entry => entry !== undefined);
    } else {
        const queryWords = query.split(/\s+/);
        found = entries.map((entry, index) => ({ entry: entry, index: index,
                rank: rank(entry, query, queryWords) }))
            .filter(match => match.rank >= 0)
            .sort((first, second) => first.rank - second.rank || first.index - second.index)
            .map(match => match.entry);
    }

    return found.slice(0, limit).map(entry => ({ emoji: entry.emoji, name: entry.name }));
}
