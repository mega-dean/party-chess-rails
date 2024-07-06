// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails

import "controllers"

import "@hotwired/turbo-rails"

Element.prototype.$ = function(selector) {
  if (/^[.#]/.test(selector)) {
    const results = this.querySelectorAll(selector);

    if (results.length > 1) {
      const message = `$ - found multiple elements with selector '${selector}'`;
      console.error(message);
      if (document.$('#board-grid')?.dataset.environment === 'development') {
        alert(message);
      }
      return;
    }

    return results[0] || null;
  } else {
    console.error(`$ - invalid selector '${selector}' - needs to start with '#' or '.'`);
    return;
  }
}

Element.prototype.$$ = function(selector) {
  if (selector[0] === '.') {
    return this.querySelectorAll(selector);
  } else {
    console.error(`$$ - invalid selector '${selector}' - needs to start with '.'`);
    return;
  }
}

Document.prototype.$ = Element.prototype.$;
Document.prototype.$$ = Element.prototype.$$;
