// https://github.com/hotwired/turbo/issues/592#issuecomment-1137827028

addEventListener('turbo:load', target)
addEventListener('hashchange', target) // for same-page navigations

function target () {
    if (location.hash) {
        const a = document.createElement('a')
        a.href = `#${location.hash.slice(1)}`
        a.click()
    }
}