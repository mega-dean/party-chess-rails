// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails

import "controllers"

import "@hotwired/turbo-rails"

Element.prototype.$ = function(selector) {
  const results = this.querySelectorAll(selector);

  if (selector[0] === '#') {
    if (results.length > 1) {
      console.error(`$ - found multiple elements with id #${selector}`);
    }
    return results[0];
  } else if (selector[0] === '.') {
    if (results.length > 1) {
      console.error(`$ - found multiple elements with class .${selector}`);
    }
    return results[0];
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
