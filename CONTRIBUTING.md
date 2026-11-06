# Contribution Guidelines

Thank you for your interest in contributing to Chess Clock!  I hope this
work-in-progress document will help you get started.

## Making your first contribution

While not technically required, I highly recommend using
[Gnome Builder](https://wiki.gnome.org/Apps/Builder) to develop Chess Clock.
Builder manages dependencies and builds the app using Flatpak, so you get a
consistent environment with all the other developers.  Fewer discrepancies
means fewer bugs, after all. 😄️

After cloning the repository with Builder, open the terminal and create a new
Git branch for your contribution:

```sh
$ git checkout -b your-branch
```

If you're writing code, please follow the standard Python code style,
[PEP 8](https://peps.python.org/pep-0008/).
Not all contributions are code though, so this may not apply to you!

Once you've finished working on your changes, add any files that you've changed
and commit them:

```sh
$ git commit -a
```

An editor will open for you to write a commit message.  I prefer messages to
follow the typical format, e.g.:

```
One-line explanation of the commit (50 chars max)

Longer description explaining what was wrong, and why you changed what
you did.  Try to focus on non-technical aspects, since the code itself
should explain the technical nature of the change.  If you need
multiple paragraphs, put a blank line between them.  Keep this part to
a maximum of 72 characters per line, please. :)
```

If your commit closes an issue, include a phrase like `Closes #1337` or
`Fixes #9001` so it will be automatically closed when the commit is merged.

Once you've committed, push your changes with:

```sh
$ git push
```

And create a merge request on the GitLab interface.

## Credit where it's due

I whole-heartedly want all contributors to be credited for their work!  As
such, when making your first contribution, please add yourself to the
appropriate list in the About window.  The code creating this window is located
in `src/main.py`, in the `on_about_action` method of the
`ChessClockApplication` class.  It's an
[AdwAboutWindow](https://gnome.pages.gitlab.gnome.org/libadwaita/doc/main/class.AboutWindow.html),
which provides five lists for different types of contributor:

* `developers`
* `designers`
* `artists`
* `documenters`
* `translator_credits`

Add your name to the right list (adding the list if necessary), and build the
app again.  Open the About window, and you should see your name in the credits!

To keep things simple, the copyright information everywhere should just read
"the Chess Clock contributors".  That way you only have to list your name in
one place, and the copyright screen doesn't get too cluttered with the same
information as the credits screen.

## Getting around the repository

All the sources of the app are located in the `src/` directory.  The non-code
parts of the GUI (`.ui` and `.css` files) are located in `src/gtk/`.  Other
data such as icons, AppStream information, etc. are kept in `data/`.
Translations, once they exist, will be located in `po/`.
