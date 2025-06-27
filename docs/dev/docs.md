# Documentation

From v4 onwards, we use [GitHub Pages](http://docs.ixpmanager.org/) with [MkDocs](http://www.mkdocs.org/) to build the documentation.

Both the site and the content are hosted on [GitHub](https://github.com/inex/ixp-manager-docs-md).

## Contributing / Suggesting Errata

We welcome contributions or errata that improve the quality of our documentation. Please use one of the following two channels:

1. Via the standard GitHub workflow of forking [our documentation repository](https://github.com/inex/ixp-manager-docs-md), making your edits in your fork and them opening a pull request.
2. If you are not familiar with GitHub, then please [open an issue on the documentation repository](https://github.com/inex/ixp-manager-docs-md/issues) with your suggestions.


## Building Locally

If you haven't already, install MkDocs. These instructions work on MacOS as of 2024:

```sh
# create a venv
python3 -m venv venv
cd venv

# install mkdocs
./bin/pip install mkdocs mike pymdown-extensions mkdocs-material \
    mkdocs-git-revision-date-localized-plugin
```

You can also update the local mkdocs packages via:

```sh
cd venv

./bin/pip install mkdocs mike pymdown-extensions mkdocs-material \
    mkdocs-git-revision-date-localized-plugin -U
```


The documentation can then be built locally as follows:

```sh
git clone https://github.com/inex/ixp-manager-docs-md.git
cd ixp-manager-docs-md
./venv/bin/mkdocs build
```

You can *serve* them locally with the following and then access them via http://127.0.0.1:8000 -

```sh
./venv/bin/mkdocs serve
```

Or to see the full versioning site, use:

```sh
./venv/bin/mike serve
```

## Deploying to Live Site

Since September 2024, we now use [documentation versioning](https://www.barryodonovan.com/2024/09/21/adding-versioning-to-an-existing-mkdocs-site) and so you should only be pushing to the latest *major.minor* release of the dev *major.minor* version. 

**Never deploy to historical versions!**

As an example, as the time of writing, 6.4.x is the latest release and 7.0 is in development. We did **our final** push to 6.4 via:

```sh
PATH=./venv/bin:$PATH ./venv/bin/mike deploy --push --update-aliases 6.4 latest
```

And all new documentation will be pushed to dev via:

```sh
PATH=./venv/bin:$PATH ./venv/bin/mike deploy --push --update-aliases 7.0 dev
```

Once 7.0 is released, we will push a final update to 7.0 updating it to latest:

```sh
PATH=./venv/bin:$PATH ./venv/bin/mike deploy --push --update-aliases 7.0 latest
```

And all new documentation will be pushed to dev via:

```sh
PATH=./venv/bin:$PATH ./venv/bin/mike deploy --push --update-aliases 7.1 dev
```

> Note that `PATH=./venv/bin:$PATH` is used as `mike` in turn calls `mkdocs` which is in this path.



You must be an authorised user for this but we **welcome pull requests against the documentation repository!**

**Do not forget to push your changes to GutHub** (if you have push permissions):

```sh
git add .
git commit -am "your commit message"
git push
```

