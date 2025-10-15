## Project Overview

This project aims to create a memoir website using OCaml, featuring a server-side component with Dream and a client-side component using Tyxml.

The website will be statically hosted on GitHub Pages and will include comprehensive tests and an RSS feed.

## GitHub Pages Configuration

This project is set up to deploy automatically to GitHub Pages using GitHub Actions. 

The site is available at [https://fearful-odds.rocks/](https://fearful-odds.rocks/).

## Getting Started
To get started with this project for the first time, run `make help` to see the list available commands and their descriptions.

You would see this,
```
Memoir Static Site Generator 
============================= 

Primary Development Commands: 
  make generate          - Generate the static site (incremental)
  make generate-force    - Force full rebuild (ignore cache)
  make serve             - Start development server on http://localhost:6060

Build & Test Commands: 
  make build             - Build the project
  make test              - Run all tests
  make test-verbose      - Run all tests with verbose output
  make test-watch        - Run tests in watch mode
  make clean             - Clean build artifacts

Utility Commands: 
  make fmt               - Format OCaml code
  make analyze-size      - Analyze the size of the generated site

Content Commands: 
  make new-post          - Create a new blog post
  make new-journal       - Create a new journal entry
  make new-page          - Create a new page

Documentation Commands: 
  make docs              - Build documentation and show on the browser
  make docs-build        - Build documentation only
```

## Issues
If you noticed any issue or bug or a better way to do something, please open an issue or a PR.

## Contributions
Contributions are welcome!
Thank you for your interest in this project!