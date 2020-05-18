## Actions dashboard

This tool generates a dashboard that shows live status of all github action
workflows in a given set of github repositories.

The [`generate.sh`](./generate.sh) script can read input files that contain
single line records of github repositories, scan all workflows listed in
`.github/workflows` and generate a markdown file that shows the current status
of each workflow.

**Usage**
```sh
generate.sh
```

The repo input list is currently read from the following input files/urls:
* https://github.com/paketo-buildpacks/github-config/tree/master/.github/data/language-family-cnbs
* https://github.com/paketo-buildpacks/github-config/tree/master/.github/data/implementation-cnbs
* [./non-cnbs](./non-cnbs)


### Auto-regenerate

This repo [runs the generate script every
day](.github/workflows/check-for-workflows.yml) to see if any workflow files
have been added/removed from the repos listed in the input files. So your newly
created workflow will appear here within a day's time.

If you would like to have a new workflow listed here immediately, do as
follows:
* Make sure your repo is listed in one of the input files/input urls.
* Run `./generate.sh`, and git commit and push the changes to `README.md`.
