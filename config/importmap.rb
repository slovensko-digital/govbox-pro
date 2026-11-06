# JavaScript is served through the import map (no esbuild/yarn bundle).
# `pin_all_from` maps every file under app/javascript to a browser-importable
# module, so relative imports must use these specifiers (e.g. "controllers/x").
pin "application", preload: true

# Turbo and Stimulus are shipped by their gems, so keep the default pins.
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true

# Not shipped by any gem, so vendored into vendor/javascript (bump with
# `bin/importmap pin pkg@version`).
pin "@rails/request.js", to: "@rails--request.js.js" # @0.0.13
pin "tailwindcss-stimulus-components" # @4.0.4

pin "autogram"
pin "fix-target-behaviour"
pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "app/javascript/custom", under: "custom"
pin_all_from "app/javascript/turbo_streams", under: "turbo_streams"
