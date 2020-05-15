## Actions dashboard

This dashboard shows the current status of all workflows in the given repos.

The repo list is currently read from the following input files:

https://github.com/paketo-buildpacks/github-config/tree/master/.github/data

This repo [does a scan](.github/workflows/check-for-workflows.yml) every day to see if any workflow files have been
added/removed from these repos. So your newly created workflow will appear here within a day's time.

If you have created a new workflow, renamed the workflow or the workflow file and would like to have it listed here immediately,
do as follows:
* Make sure your repo is listed in the input files
* Run `./generate.sh`, and git commit and push the changes to `README.md`.
