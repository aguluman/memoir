# Memoir OCaml Static Site Generator Makefile
# This Makefile provides convenient shortcuts for development tasks

# Configuration
DUNE = dune
BUILD_DIR = _build
SITE_DIR = _site
STATIC_DIR = static
CONTENT_DIR = content
PORT = 8080
HOST = 127.0.0.1

# Colors for output
RED = \033[0;31m
GREEN = \033[0;32m
YELLOW = \033[0;33m
BLUE = \033[0;34m
MAGENTA = \033[0;35m
CYAN = \033[0;36m
NC = \033[0m # No Color

# Help target - shows available commands
.PHONY: help
help:
	@echo ""
	@echo "$(CYAN)Memoir Static Site Generator$(NC)"
	@echo "$(MAGENTA)=============================$(NC)"
	@echo ""
	@echo "$(YELLOW)Primary Development Commands:$(NC)"
	@echo "  $(GREEN)make generate$(NC)     - Generate the static site"
	@echo "  $(GREEN)make server$(NC)       - Start development server on http://$(HOST):$(PORT)"
	@echo "  $(GREEN)make dev$(NC)          - Start development server and open browser"
	@echo ""
	@echo "$(YELLOW)Build & Test Commands:$(NC)"
	@echo "  $(GREEN)make build$(NC)        - Build the project"
	@echo "  $(GREEN)make test$(NC)         - Run all tests"
	@echo "  $(GREEN)make test-watch$(NC)   - Run tests in watch mode"
	@echo "  $(GREEN)make clean$(NC)        - Clean build artifacts"
	@echo ""
	@echo "$(YELLOW)Utility Commands:$(NC)"
	@echo "  $(GREEN)make deps$(NC)         - Install OCaml dependencies"
	@echo "  $(GREEN)make format$(NC)       - Format OCaml code"
	@echo "  $(GREEN)make watch$(NC)        - Watch files and rebuild automatically"
	@echo "  $(GREEN)make preview$(NC)      - Preview the generated site in browser"
	@echo ""
	@echo "$(YELLOW)Content Commands:$(NC)"
	@echo "  $(GREEN)make new-post$(NC)     - Create a new blog post"
	@echo "  $(GREEN)make new-page$(NC)     - Create a new page"
	@echo ""
	@echo "$(YELLOW)Deployment Commands:$(NC)"
	@echo "  $(GREEN)make deploy$(NC)       - Deploy to GitHub Pages"
	@echo "  $(GREEN)make check$(NC)        - Run all checks before deployment"
	@echo "  $(GREEN)make check-links$(NC)  - Check for broken links in generated site"
	@echo ""
	@echo "$(YELLOW)Development Shortcuts:$(NC)"
	@echo "  $(GREEN)make quick$(NC)        - Quick build and generate"
	@echo "  $(GREEN)make full$(NC)         - Full build pipeline (clean, deps, build, test, generate)"
	@echo ""
	@echo "$(YELLOW)Debug Commands:$(NC)"
	@echo "  $(GREEN)make debug-build$(NC)  - Show debug build information"
	@echo "  $(GREEN)make debug-site$(NC)   - Show site structure and statistics"
	@echo "  $(GREEN)make info$(NC)         - Show project information and directory status"
	@echo ""

# Primary commands - what you asked for
.PHONY: generate
generate: build
	@echo "$(BLUE)🚀 Generating static site...$(NC)"
	@$(DUNE) exec bin/generator.exe
	@echo "$(GREEN)✅ Site generated successfully in $(SITE_DIR)/$(NC)"

.PHONY: server
server: build
	@echo "$(BLUE)🌐 Starting development server...$(NC)"
	@echo "$(YELLOW)📍 Server will be available at: http://$(HOST):$(PORT)$(NC)"
	@echo "$(MAGENTA)🛑 Press Ctrl+C to stop the server$(NC)"
	@$(DUNE) exec bin/server.exe

.PHONY: dev
dev: generate
	@echo "$(BLUE)🚀 Starting development environment...$(NC)"
	@($(DUNE) exec bin/server.exe &) && sleep 2 && open http://$(HOST):$(PORT) 2>/dev/null || xdg-open http://$(HOST):$(PORT) 2>/dev/null || echo "$(YELLOW)Manual browser open: http://$(HOST):$(PORT)$(NC)"

# Build commands
.PHONY: build
build:
	@echo "$(BLUE)🔧 Building project...$(NC)"
	@$(DUNE) build
	@echo "$(GREEN)✅ Build completed$(NC)"

.PHONY: build-release
build-release:
	@echo "$(BLUE)🔧 Building project in release mode...$(NC)"
	@$(DUNE) build --profile release
	@echo "$(GREEN)✅ Release build completed$(NC)"

.PHONY: deps
deps:
	@echo "$(BLUE)📦 Installing dependencies...$(NC)"
	@opam install . --deps-only --with-test
	@echo "$(GREEN)✅ Dependencies installed$(NC)"

# Test commands
.PHONY: test
test: build
	@echo "$(BLUE)🧪 Running tests...$(NC)"
	@$(DUNE) runtest || (echo "$(RED)❌ Some tests failed$(NC)" && exit 1)
	@echo "$(GREEN)✅ All tests passed$(NC)"

.PHONY: test-watch
test-watch:
	@echo "$(BLUE)🔍 Running tests in watch mode...$(NC)"
	@$(DUNE) runtest --watch

.PHONY: test-verbose
test-verbose: build
	@echo "$(BLUE)🧪 Running tests with verbose output...$(NC)"
	@$(DUNE) runtest --verbose

# Clean commands
.PHONY: clean
clean:
	@echo "$(BLUE)🧹 Cleaning build artifacts...$(NC)"
	@$(DUNE) clean
	@rm -rf $(SITE_DIR)
	@echo "$(GREEN)✅ Clean completed$(NC)"

.PHONY: distclean
distclean: clean
	@echo "$(BLUE)🧹 Deep cleaning...$(NC)"
	@rm -rf _opam
	@echo "$(GREEN)✅ Deep clean completed$(NC)"

# Development utilities
.PHONY: format
format:
	@echo "$(BLUE)💅 Formatting OCaml code...$(NC)"
	@$(DUNE) build @fmt --auto-promote
	@echo "$(GREEN)✅ Code formatted$(NC)"

.PHONY: watch
watch:
	@echo "$(BLUE)👀 Watching for changes...$(NC)"
	@$(DUNE) build --watch

.PHONY: watch-generate
watch-generate:
	@echo "$(BLUE)👀 Watching for changes and regenerating site...$(NC)"
	@while true; do \
		$(DUNE) exec bin/generator.exe; \
		echo "$(GREEN)✅ Site regenerated at $$(date)$(NC)"; \
		inotifywait -r -e modify,create,delete $(CONTENT_DIR) $(STATIC_DIR) lib/ bin/ 2>/dev/null || sleep 2; \
	done

# Content creation helpers
.PHONY: new-post
new-post:
	@read -p "Enter blog post title: " title; \
	slug=$$(echo "$$title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$$//g'); \
	file="$(CONTENT_DIR)/blog/$$slug.md"; \
	date=$$(date +%Y-%m-%d); \
	echo "$(BLUE)📝 Creating new blog post: $$file$(NC)"; \
	mkdir -p $$(dirname "$$file"); \
	echo "---" > "$$file"; \
	echo "title: \"$$title\"" >> "$$file"; \
	echo "date: $$date" >> "$$file"; \
	echo "tags: []" >> "$$file"; \
	echo "draft: true" >> "$$file"; \
	echo "description: \"\"" >> "$$file"; \
	echo "---" >> "$$file"; \
	echo "" >> "$$file"; \
	echo "# $$title" >> "$$file"; \
	echo "" >> "$$file"; \
	echo "Your content here..." >> "$$file"; \
	echo "$(GREEN)✅ Created: $$file$(NC)"

.PHONY: new-page
new-page:
	@read -p "Enter page title: " title; \
	slug=$$(echo "$$title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$$//g'); \
	file="$(CONTENT_DIR)/pages/$$slug.md"; \
	echo "$(BLUE)📄 Creating new page: $$file$(NC)"; \
	mkdir -p $$(dirname "$$file"); \
	echo "---" > "$$file"; \
	echo "title: \"$$title\"" >> "$$file"; \
	echo "layout: \"page\"" >> "$$file"; \
	echo "description: \"\"" >> "$$file"; \
	echo "---" >> "$$file"; \
	echo "" >> "$$file"; \
	echo "# $$title" >> "$$file"; \
	echo "" >> "$$file"; \
	echo "Your content here..." >> "$$file"; \
	echo "$(GREEN)✅ Created: $$file$(NC)"

# Preview and serve
.PHONY: preview
preview: generate
	@echo "$(BLUE)🌐 Opening site preview...$(NC)"
	@if [ -f "$(SITE_DIR)/index.html" ]; then \
		open "$(SITE_DIR)/index.html" 2>/dev/null || xdg-open "$(SITE_DIR)/index.html" 2>/dev/null || echo "$(YELLOW)Manual preview: open $(SITE_DIR)/index.html$(NC)"; \
	else \
		echo "$(RED)❌ No site found. Run 'make generate' first$(NC)"; \
	fi


# Check commands
.PHONY: check
check: test format
	@echo "$(BLUE)🔍 Running all checks...$(NC)"
	@$(DUNE) build
	@echo "$(GREEN)✅ All checks passed$(NC)"

.PHONY: check-links
check-links: generate
	@echo "$(BLUE)🔗 Checking for broken links...$(NC)"
	@find $(SITE_DIR) -name "*.html" -exec grep -l "href=" {} \; | head -5
	@echo "$(YELLOW)💡 Link checking would require additional tools like linkchecker$(NC)"

# Deployment
.PHONY: deploy
deploy: check build-release check-links generate
	@echo "$(BLUE)🚀 Deploying to GitHub Pages...$(NC)"
	@git add $(SITE_DIR)
	@git commit -m "Deploy site: $$(date)" || echo "$(YELLOW)⚠️  Nothing to commit$(NC)"
	@git push origin main
	@echo "$(GREEN)✅ Deployed to GitHub Pages$(NC)"

# Development shortcuts
.PHONY: quick
quick: build generate
	@echo "$(GREEN)⚡ Quick build and generate completed$(NC)"

.PHONY: full
full: clean deps build test generate
	@echo "$(GREEN)🎉 Full build pipeline completed$(NC)"

# Debug commands
.PHONY: debug-build
debug-build:
	@echo "$(BLUE)🐛 Debug build information...$(NC)"
	@$(DUNE) build --verbose

.PHONY: debug-site
debug-site: generate
	@echo "$(BLUE)🐛 Site structure:$(NC)"
	@find $(SITE_DIR) -type f | head -20
	@echo ""
	@echo "$(BLUE)📊 Site statistics:$(NC)"
	@echo "Files: $$(find $(SITE_DIR) -type f | wc -l)"
	@echo "Size: $$(du -sh $(SITE_DIR) | cut -f1)"

# Info commands
.PHONY: info
info:
	@echo "$(CYAN)📋 Project Information$(NC)"
	@echo "Build tool: $(DUNE)"
	@echo "Build directory: $(BUILD_DIR)"
	@echo "Site directory: $(SITE_DIR)"
	@echo "Content directory: $(CONTENT_DIR)"
	@echo "Server: http://$(HOST):$(PORT)"
	@echo ""
	@echo "$(BLUE)📁 Directory status:$(NC)"
	@ls -la | grep -E "($(BUILD_DIR)|$(SITE_DIR)|$(CONTENT_DIR)|$(STATIC_DIR))"

# Default target
.DEFAULT_GOAL := help

# Make sure these directories exist
$(SITE_DIR):
	@mkdir -p $(SITE_DIR)

$(CONTENT_DIR):
	@mkdir -p $(CONTENT_DIR)/pages $(CONTENT_DIR)/blog

# Phony targets to avoid conflicts with files
.PHONY: all clean install uninstall help build test generate server dev preview
