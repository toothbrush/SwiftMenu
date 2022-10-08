<p align="center">
  <img src="SwiftMenu/Assets.xcassets/AppIcon.appiconset/appicon-256.png" alt="SwiftMenu icon" />
</p>

# SwiftMenu

This is another chooser menu.  The world doesn't really need another chooser.  I used to use `dmenu`
then `xmenu` and that was fine.  I wish it still were fine.  Unfortunately, these days macOS
prevents another app from foregrounding itself while a NSSecureTextField has focus, which is fair
enough.  However, this breaks the old-fashioned flow of using Hammerspoon to bind a keyboard
shortcut to run a script which does something like `pass show $(xmenu $options)`.

This crappy little utility gets around that by having an "out of band" way of talking to it, namely
via a very simple REST API.  You can first call `/show` on it, then use Hammerspoon to foreground
it, then call the (synchronous) `/query_password` endpoint which will return the option the user
picked or 404 if cancelled.

I think i need to go away and take a few consecutive showers.

Here's a screenshot:

<img src="/img/screenshot.png" alt="A screenshot of the SwiftMenu window" />

## Some rough edges

* I'd like to improve the matching.  For example, "ing." should surface ing.com.au, not booking.com,
  even though the latter is lexicographically earlier.
  * Some sort of logic based on whether a term is the first word or a subsequent word?
  * If inputting "asdf jkl" maybe anchor "asdf" at the start and "jkl" anywhere after "asdf"?
    Perhaps with fallback if "^asdf" turns up zero results?
  * We should be splitting search terms on whitespace anyway, not expecting literal spaces in documents

* Maybe add a prompt label at the beginning?
* Maybe a filtered/total counter?
* Maybe a down-arrow indicator that there's more?
