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
