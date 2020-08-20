# Documentation

From v4 onwards, we use [GitHub Pages](http://docs.ixpmanager.org/) with [MkDocs](http://www.mkdocs.org/) to build the documentation.

Both the site and the content are hosted on [GitHub](https://github.com/inex/ixp-manager-docs-md).

## Contributing / Suggesting Errata

We welcome contributions or errata that improve the quality of our documentation. Please use one of the following two channels:

1. Via the standard GitHub workflow of forking [our documentation repository](https://github.com/inex/ixp-manager-docs-md), making your edits in your fork and them opening a pull request.
2. If you are not familiar with GitHub, then please [open an issue on the documentation repository](https://github.com/inex/ixp-manager-docs-md/issues) with your suggestions.


## Building Locally

If you haven't already, install MkDocs:

```sh
pip install mkdocs
pip install pymdown-extensions
```

The documentation can then be built locally as follows:

```sh
git clone https://github.com/inex/ixp-manager-docs-md.git
cd ixp-manager-docs-md
mkdocs build
```

You can *serve* them locally with the following and then access them via http://127.0.0.1:8000 -

```sh
mkdocs serve
```

To automatically deploy to GitHub and make live:

```sh
mkdocs gh-deploy
```

You must be an authorised user for this but we **welcome pull requests against the documentation repository!**

**Do not forget to push your changes to GutHub** (if you have push permissions):

```sh
git add .
git commit -am "your commit message"
git push
```

There is a simple script in the documentation root directory that combiles these deploy and commit steps:

```sh
./build-deploy-push.sh "your commit message"
```
