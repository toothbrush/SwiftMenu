We assume Hammerspoon will somehow invoke this app from a hotkey, which will allow Hammerspoon to
bring it to front even if NSSecureTextField has focus.

This app will probably need a few HTTP verbs:

```
POST /show
POST /hide
POST /refresh_password_list
POST /get_password_entry # Can return 4xx if user cancels
```

Hitting `Esc`, `C-c` or `C-g` at any time the app has focus should hide it and return focus to
whatever app had focus previously.

## Check if it's alive, start otherwise

Doing a `curl localhost:3000` is extremely fast if the app is down; we can then start it and wait a
while and try again.

# Searching

Idea: no regex fanciness, but:

asdf fdas
^--  ^--

Treat the first whitespace-separated word as a search string anchored by `^`, and the others as
simple substrings? (order unimportant?)

If you want to find `finger` by typing `ing` you may have to prepend a space so it's actually the
first, not zeroth, filter word?

Something to try.
