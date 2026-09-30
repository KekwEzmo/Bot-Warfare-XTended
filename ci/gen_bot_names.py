#!/usr/bin/env python3
"""
Generates bots.txt for Bot Warfare XTended: human-looking gamer names, one per line.
Plutonium IW5 reads %LOCALAPPDATA%\\Plutonium\\storage\\iw5\\bots.txt for bot names.

Usage: python ci/gen_bot_names.py [count] [seed]
    count  how many names (default 300)
    seed   same seed gives the same list (default: random every run)

Writes ci/release/bots.txt, which the release build ships and install.bat copies
(only if you don't already have a bots.txt).
"""

import os
import random
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_PATH = os.path.join(ROOT, "ci", "release", "bots.txt")
MAX_LEN = 15  # IW5 player names are at most 15 characters

ADJECTIVES = [
    "silent", "rapid", "lazy", "dark", "frozen", "crimson", "lucky", "salty", "sneaky", "angry",
    "wild", "quiet", "toxic", "golden", "broken", "hidden", "savage", "sleepy", "cosmic", "rusty",
    "grim", "swift", "bold", "hollow", "wicked", "stormy", "chill", "feral", "neon", "lost",
]

NOUNS = [
    "wolf", "viper", "ghost", "falcon", "raven", "tiger", "cobra", "hawk", "fox", "bear",
    "shark", "reaper", "sniper", "panda", "badger", "hunter", "phantom", "spartan", "ninja", "rogue",
    "titan", "comet", "storm", "blade", "pixel", "toast", "noodle", "potato", "walrus", "moose",
]

FIRST_NAMES = [
    "jake", "mike", "chris", "alex", "sam", "tom", "nick", "dan", "matt", "ryan",
    "kevin", "josh", "ben", "luke", "adam", "leo", "max", "noah", "eric", "sean",
    "emma", "lisa", "anna", "kate", "mia", "zoe", "nina", "lena", "sara", "jess",
    "marco", "lukas", "jonas", "felix", "tomas", "ivan", "pavel", "mateo", "kenji", "omar",
]

WORDS = ADJECTIVES + NOUNS

LEET = str.maketrans({"a": "4", "e": "3", "i": "1", "o": "0", "s": "5"})


def cap(word):
    return word[:1].upper() + word[1:]


def number(rng):
    # birth years, lucky numbers and random digits are all common
    return rng.choice([
        str(rng.randint(1, 99)),
        str(rng.randint(1985, 2010)),
        rng.choice(["7", "13", "21", "42", "69", "77", "88", "99", "360", "420", "1337"]),
    ])


def make_name(rng):
    style = rng.choices(
        ["camel", "under", "first_num", "lower_combo", "leet", "word_num", "xx", "the", "caps"],
        weights=[22, 12, 16, 12, 6, 14, 3, 5, 10],
    )[0]

    adj, noun, word, first = rng.choice(ADJECTIVES), rng.choice(NOUNS), rng.choice(WORDS), rng.choice(FIRST_NAMES)

    if style == "camel":
        return cap(adj) + cap(noun)
    if style == "under":
        return adj + "_" + noun
    if style == "first_num":
        return rng.choice([first, cap(first)]) + number(rng)
    if style == "lower_combo":
        return adj + noun
    if style == "leet":
        return cap(noun).translate(LEET) + rng.choice(["", "", "x", "z"])
    if style == "word_num":
        return cap(word) + rng.choice(["", "_"]) + number(rng)
    if style == "xx":
        return "xX" + cap(noun) + "Xx"
    if style == "the":
        return "The" + cap(noun)
    return (adj + noun).upper()


def main():
    count = int(sys.argv[1]) if len(sys.argv) > 1 else 300
    rng = random.Random(sys.argv[2]) if len(sys.argv) > 2 else random.Random()

    names = set()
    attempts = 0

    while len(names) < count and attempts < count * 50:
        attempts += 1
        name = make_name(rng)

        if 3 <= len(name) <= MAX_LEN:
            names.add(name)

    names = list(names)
    rng.shuffle(names)

    with open(OUT_PATH, "w", newline="\r\n") as f:
        f.write("\n".join(names) + "\n")

    print("wrote %d names to %s" % (len(names), os.path.relpath(OUT_PATH, ROOT)))


if __name__ == "__main__":
    main()
