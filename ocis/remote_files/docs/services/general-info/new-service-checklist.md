---
title: New Service Checklist
date: 2023-03-23T00:00:00+00:00
weight: 20
geekdocRepo: https://github.com/owncloud/ocis
geekdocEditPath: edit/master/docs/services/general-info
geekdocFilePath: new-service-checklist.md
geekdocCollapseSection: true
---

When a new service gets introduced, this checklist is a good startingpoint for things that need to be completed before the service gets published (merged). This list is without claim of completeness or correct sort order.

## New Service Checklist

Use this checklist with copy/paste in your PR - right from the beginning. It renders correctly in your PR.

```markdown
- [ ] Provide a README.md for that service in the root folder of that service.
  - Use CamelCase for section headers.
- [ ] For images and example files used in README.md:
  - Create a folder named `md-sources` on the same level where README.md is located. Put all the images and example files referenced by README.md into this folder.
  - Use absolute references like `https://raw.githubusercontent.com/owncloud/ocis/master/services/<service-name>/md-sources/file` to make the content accessible for both README.md and owncloud.dev
    bad `<img src="https://github.com/owncloud/ocis/blob/master/services/graph/images/mermaid-graph.svg" width="500" />`  
    good `<img src="https://raw.githubusercontent.com/owncloud/ocis/master/services/graph/images/mermaid-graph.svg" width="500" />`
- [ ] If new CLI command are introduced, that command must be described in readme.md.
- [ ] If new global envvar is introduced, the name must start with `OCIS_`.
- [ ] Add the service to the makefile in the ocis repo root.
- [ ] Make the service startable for binary and individual startup:
  - For single binary add service to `ocis/pkg/runtime`
  - For individual startup add service to `ocis/pkg/commands`
- [ ] Add the service to `.drone.star` to enable CI.
- [ ] Inform doc team in an _early stage_ to review the readme AND the environment variables created.
  - The description must reflect the behaviour AND usually has a positive code quality impact.
- [ ] Create proper description strings for envvars - see other services for examples, especially when it comes to multiple values. This must include:
  - base description, set of available values, description of each value.
- [ ] When suggestable commits are created for text changes and you agree, collect them to a batch and commit them. Do not forget to rebase locally to avoid overwriting the changes made.
- [ ] If new envvars are introduced which serve the same purpose but in multiple services, an additional envvar must be added at the beginning of the list starting with `OCIS_` (global envvar).
- [ ] Ensure that a service has a debug port
- [ ] If the new service introduces a new port:
  - the port must be added to [port-ranges.md](https://github.com/owncloud/ocis/blob/master/docs/services/port-ranges.md) and to the readme.md file.
- [ ] Make sure to have a function `FullDefaultConfig()` in `pkg/config/defaults/defaultconfig.go` of your service. It is needed to create the documentation.
```
