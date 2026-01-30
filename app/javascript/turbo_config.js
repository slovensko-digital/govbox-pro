import { Turbo } from "@hotwired/turbo-rails"

// Enable Turbo prefetching for Rails 8
// This will prefetch pages on hover/touch to make navigation feel instant
Turbo.session.drive = true

// Enable prefetching for all links with data-turbo-prefetch attribute
// You can also add this to specific links: <a href="/page" data-turbo-prefetch>
document.addEventListener("turbo:load", () => {
  // Add prefetch to internal navigation links
  const internalLinks = document.querySelectorAll('a[href^="/"]:not([data-turbo-method]):not([data-turbo-confirm])')
  internalLinks.forEach(link => {
    if (!link.hasAttribute('data-turbo-prefetch')) {
      link.setAttribute('data-turbo-prefetch', 'true')
    }
  })
})