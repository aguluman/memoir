# OCaml Memoir Website Implementation Plan

## Project Overview
This document outlines the implementation plan for building a personal memoir website using OCaml for both frontend and backend components. Based on the requirements, we'll be using:

- **Dream framework** for the OCaml server-side components
- **js_of_ocaml** for compiling OCaml to JavaScript for client-side interactivity
- **TyXML** for type-safe HTML generation
- **GitHub Pages** for hosting with a purchased custom domain
- **File-based content storage** instead of a database

## Project Structure

```
memoir/
├── dune-project             # Dune project configuration
├── lib/                     # Core OCaml library code
│   ├── types/               # Shared data types
│   ├── content/             # Content processing (markdown, etc.)
│   ├── templates/           # TyXML templates
│   ├── client/              # js_of_ocaml client-side code
│   └── feeds/               # RSS and feed generation
├── bin/                     # Executable for site generation
│   ├── generator.ml         # Static site generator
│   └── server.ml            # Development server
├── content/                 # Markdown content files
│   ├── blog/                # Blog posts
│   ├── projects/            # Project descriptions
│   ├── pages/               # Static pages (about, resume)
│   └── assets/              # Content-related assets
├── static/                  # Static assets
│   ├── images/              # Images and icons
│   ├── fonts/               # Web fonts
│   └── css/                 # Additional CSS if needed
├── templates/               # OCaml TyXML templates
│   ├── layouts/             # Page layouts
│   ├── components/          # Reusable UI components
│   └── partials/            # Partial templates
├── test/                    # Test suite
│   ├── content_test/        # Tests for content processing
│   ├── template_test/       # Tests for template rendering
│   └── integration_test/    # End-to-end tests
└── _site/                   # Generated static site (gitignored)
```

## Implementation Phases

### Phase 1: Project Setup and Infrastructure (1-2 weeks)

1. **OCaml Environment Setup**
   - Set up OCaml development environment
   - Configure OPAM with required packages
   - Create dune-project file with appropriate dependencies

2. **Project Structure Creation**
   - Set up directory structure as outlined above
   - Create initial dune files for each component

3. **Build Pipeline Configuration**
   - Implement Dune build configuration
   - Create basic Dream server for development
   - Set up js_of_ocaml compilation pipeline

4. **GitHub Pages Configuration**
   - Set up GitHub repository with appropriate structure
   - Configure GitHub Actions for automated builds
   - Set up custom domain with GitHub Pages

5. **Testing Framework Setup**
   - Configure Alcotest testing framework
   - Setup test structure and initial test helpers
   - Integrate tests into CI pipeline

### Phase 2: Core Components Development (2-3 weeks)

1. **Content Processing System**
   - Implement Markdown parser with YAML frontmatter support
   - Create content loader for blog posts, projects, and pages
   - Build file-based routing system

2. **TyXML Template System**
   - Create base layout templates
   - Implement responsive design templates
   - Develop reusable UI components

3. **Static Site Generation**
   - Build Dream-based static site generator
   - Implement file output system
   - Create asset processing pipeline

4. **Basic Styling Implementation**
   - Implement CSS framework in OCaml
   - Create dark/light mode support
   - Develop responsive design infrastructure

5. **RSS Feed Generation**
   - Implement XML feed generators for blog content
   - Create Atom feed format support
   - Add auto-discovery links in HTML templates

### Phase 3: Content Pages Implementation (2-3 weeks)

1. **Home Page**
   - Develop professional introduction section
   - Create featured skills component
   - Implement project highlights section

2. **About Page**
   - Create biography template
   - Implement education and career journey section
   - Develop personal interests component

3. **Projects Section**
   - Build project grid/list component
   - Implement project filtering system
   - Create detailed project page template

4. **Blog Section**
   - Develop blog listing page
   - Implement blog post template with syntax highlighting
   - Create category and tag filtering system
   - Add RSS/Atom feed subscription options

5. **Resume Page**
   - Create online resume template
   - Implement PDF generation from OCaml
   - Build skills and experience components

6. **Contact Section**
   - Implement contact form (using third-party service)
   - Create social media links component
   - Develop GitHub profile integration

### Phase 4: Client-Side Features (2-3 weeks)

1. **js_of_ocaml Components**
   - Set up js_of_ocaml infrastructure
   - Implement dark/light mode toggle
   - Create project filtering client-side logic

2. **OCaml Code Playground**
   - Implement lightweight OCaml interpreter in js_of_ocaml
   - Create code editor component
   - Develop predefined examples system

3. **Interactive Features**
   - Add smooth scrolling and animations
   - Implement form validation
   - Create responsive navigation

4. **Performance Optimization**
   - Implement lazy loading for images
   - Create efficient code splitting
   - Optimize assets loading

### Phase 5: Testing and Refinement (1-2 weeks)

1. **Automated Testing**
   - Implement unit tests for content processing with Alcotest
   - Create tests for HTML generation and template rendering
   - Develop integration tests for site generation process
   - Add property-based tests for complex logic using QCheck

2. **Manual Testing**
   - Perform cross-browser testing
   - Test mobile responsiveness
   - Conduct performance audits
   - Check accessibility compliance

3. **SEO and Analytics**
   - Implement meta tags system
   - Create sitemap generation
   - Set up structured data for rich snippets
   - Verify RSS feeds with validators

4. **Documentation**
   - Create README with development instructions
   - Document content management workflow
   - Write deployment guide

### Phase 6: Deployment and Launch (1 week)

1. **Final Deployment**
   - Configure custom domain with HTTPS
   - Set up GitHub Actions workflow
   - Perform final builds and tests

2. **Post-Launch Tasks**
   - Submit sitemap to search engines
   - Test analytics tracking
   - Verify all features in production
   - Submit RSS feeds to feed directories

## Technical Implementation Details

### Core OCaml Packages

```
dream           # Web framework for OCaml
tyxml           # Type-safe HTML generation
js_of_ocaml     # OCaml to JavaScript compiler
omd             # OCaml Markdown library
yaml            # YAML parsing for frontmatter
lwt             # Asynchronous programming library
core            # Standard library replacement
alcotest        # Lightweight and colorful test framework
qcheck          # Property-based testing
```

### Build System with Dune

```lisp
;; Example dune file for the main library
(library
 (name portfolio_lib)
 (libraries dream tyxml js_of_ocaml omd yaml lwt core)
 (preprocess (pps js_of_ocaml-ppx)))

;; Example dune file for the generator binary
(executable
 (name generator)
 (libraries portfolio_lib)
 (modes native))

;; Example dune file for tests
(test
 (name content_tests)
 (libraries portfolio_lib alcotest qcheck)
 (modules content_tests))
```

### Dream Implementation

The Dream framework will be used in two ways:

1. **Development Server**: Running a live server for development with hot reloading
   ```ocaml
   let () =
     Dream.run
     @@ Dream.logger
     @@ Dream.router [
          Dream.get "/" (fun _ -> Home.render () |> Dream.html);
          Dream.get "/blog/*" (fun request ->
              let slug = Dream.param request "1" in
              Blog.get_post slug |> Blog.render |> Dream.html);
          Dream.get "/feed.xml" (fun _ -> 
              Feeds.generate_rss () |> Dream.respond ~headers:(Dream.headers [("Content-Type", "application/rss+xml")]));
          (* Other routes *)
        ]
   ```

2. **Static Site Generator**: Processing all routes and generating static HTML
   ```ocaml
   let generate_site output_dir =
     let routes = [
       ("/", Home.render ());
       ("/about", About.render ());
       (* All other routes *)
     ] in
     List.iter (fun (path, content) ->
       let output_path = Filename.concat output_dir (path_to_file path) in
       write_html output_path content
     ) routes;
     
     (* Generate RSS feed *)
     let rss_content = Feeds.generate_rss () in
     let rss_path = Filename.concat output_dir "feed.xml" in
     write_file rss_path rss_content
   ```

### TyXML Templates

Type-safe HTML generation:

```ocaml
open Tyxml

let make_page ~title ~content =
  let open Html in
  html
    (head
       (title (txt title))
       [ meta ~a:[a_charset "utf-8"] ();
         meta ~a:[a_name "viewport"; a_content "width=device-width, initial-scale=1"] ();
         link ~rel:[`Stylesheet] ~href:"/static/css/main.css" ();
         link ~rel:[`Alternate] ~a:[a_type "application/rss+xml"; a_title "RSS Feed"; a_href "/feed.xml"] ()
       ])
    (body [
       header [ h1 [ txt title ] ];
       main [ content ];
       footer [ small [ txt "© 2025 My Memoir" ] ]
     ])
```

### RSS Feed Generation

```ocaml
open Tyxml

let generate_rss () =
  let posts = Content.get_all_blog_posts () in
  let items = List.map (fun post ->
    Rss.item
      ~title:post.title
      ~link:(Printf.sprintf "https://example.com/blog/%s" post.slug)
      ~description:post.excerpt
      ~pubDate:(post.date)
      ()
  ) posts in
  
  let channel = Rss.channel
    ~title:"My OCaml Blog"
    ~link:"https://example.com"
    ~description:"A blog about OCaml programming and more"
    ~language:"en-us"
    ~lastBuildDate:(current_time_string ())
    ~items
    () in
    
  Rss.to_string channel
```

### js_of_ocaml Client Components

```ocaml
open Js_of_ocaml
open Js_of_ocaml_lwt

let setup_theme_toggle () =
  let toggle_btn = Dom_html.document##getElementById(Js.string "theme-toggle") in
  Lwt_js_events.clicks toggle_btn (fun _ _ ->
    let body = Dom_html.document##.body in
    let has_dark = body##.classList##contains(Js.string "dark-theme") in
    if has_dark then
      body##.classList##remove(Js.string "dark-theme")
    else
      body##.classList##add(Js.string "dark-theme");
    Lwt.return_unit
  )
```

### Content Processing

```ocaml
type post = {
  title: string;
  date: string;
  tags: string list;
  excerpt: string;
  content: string;
  slug: string;
}

let parse_frontmatter content =
  match String.split_on_char '\n' content with
  | "---" :: rest ->
    let rec parse_yaml acc = function
      | "---" :: content_lines -> 
          (List.rev acc, String.concat "\n" content_lines)
      | line :: rest -> parse_yaml (line :: acc) rest
      | [] -> (List.rev acc, "")
    in
    let yaml_lines, content = parse_yaml [] rest in
    let yaml = String.concat "\n" yaml_lines in
    (* Parse YAML to structured data *)
    (yaml, content)
  | _ -> ("", content)
```

### Test Suite with Alcotest

```ocaml
open Alcotest

let test_parse_frontmatter () =
  let input = "---\ntitle: Test Post\ndate: 2025-05-01\ntags: [ocaml, web]\n---\nThis is a test post." in
  let (yaml, content) = Content.parse_frontmatter input in
  check string "content matches" "This is a test post." content;
  check bool "yaml contains title" true (String.contains yaml "title: Test Post")

let test_generate_html () =
  let post = { 
    title = "Test Post"; 
    date = "2025-05-01"; 
    tags = ["ocaml"; "web"];
    excerpt = "This is a test";
    content = "This is a test post.";
    slug = "test-post"
  } in
  let html = Templates.Blog.render_post post in
  check bool "HTML contains title" true (String.contains (Tyxml.Html.to_string html) "Test Post")

let () =
  run "Content Tests" [
    "frontmatter", [
      test_case "Parse frontmatter" `Quick test_parse_frontmatter;
    ];
    "templates", [
      test_case "Generate HTML" `Quick test_generate_html;
    ]
  ]
```

## GitHub Actions Workflow

Create a GitHub Actions workflow for automatic deployment:

```yaml
name: Build and Deploy
on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Set up OCaml
        uses: ocaml/setup-ocaml@v2
        with:
          ocaml-compiler: 5.3.0
          
      - name: Install dependencies
        run: |
          opam install . --deps-only --with-test
          opam install dune dream tyxml js_of_ocaml-ppx yaml omd alcotest qcheck
          
      - name: Run tests
        run: |
          eval $(opam env)
          dune runtest
          
      - name: Build site
        run: |
          eval $(opam env)
          dune build
          dune exec -- generator
          
      - name: Deploy to GitHub Pages
        uses: JamesIves/github-pages-deploy-action@4.1.4
        with:
          branch: gh-pages
          folder: _site
```

## Next Steps

1. Initialize the project structure
2. Set up the OCaml environment and test framework
3. Create the basic Dream server
4. Implement the content processing system
5. Begin developing the TyXML templates and RSS feed generator

By following this implementation plan, we'll create a fully OCaml-powered memoir website with both server-side and client-side components, hosted statically on GitHub Pages with comprehensive tests and RSS feed functionality.