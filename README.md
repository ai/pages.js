# Pages.js

Pages.js is a framework for [History pushState]. It allows you to manage
pages JS code and forget about low-level APIs.

History pushState is a API to manage user history, it allows you to change
document URL from JS and have full AJAX pages, without `#` in URL.

For example, user on `example.com` click on usual link (`example.com/conacts`),
but browser doesn’t load new URL. JS loads new page by AJAX, changes pages
with some animation and changes URL to `example.com/contacts`. Of course,
you can use Back button (and go to `example.com`) or send current URL to your
friend (and friend will open contact’s page directly).

History pushState is supported by modern browsers, but Pages.js will work in
browsers without this API too. They will load pages in an old way with document
reloading.

Sponsored by [Evil Martians].

[History pushState]: http://diveintohtml5.info/history.html
[Evil Martians]:     http://evilmartians.com/

## Quick Start

1. Wrap your page content (without layout, header and footer) into
   `<article class="page" data-url="/url" data-title="Page">…</article>`
   and set page URL to `data-url` and title to `data-title` attribute.
2. Change your server code, to respond AJAX requests without layout.
   Just check `HTTP_X_REQUESTED_WITH` HTTP header to equal `"XMLHttpRequest"`.

   For example, in Ruby on Rails add to `ApplicationController`:
   ```ruby
   layout :disable_for_ajax
   def disable_for_ajax
     request.xhr? ? nil : 'application'
   end
   ```
3. Add Pages.js library to your pages:
   ```html
   <script src="./pages.js"></script>
   ```
   See Installing section for details.

That’s all. Now your pages will be changed without document reloading
(and JS interruption) and with simple nice animation.

Of cource, you can customize wrap tags and load method. Quick Start show only
default way.

## Installing

### Ruby on Rails

For Ruby on Rails you can use gem for Assets Pipeline.

1. Add `pagesjs` gem to `Gemfile`:

   ```ruby
   gem "pagesjs"
   ```

2. Install gems:

   ```sh
   bundle install
   ```

3. Include Pages.js to your `application.js.coffee`:

   ```coffee
   #= require pages
   ```

### Others

If you don’t use any assets packaging manager (it’s very bad idea), you can use
already minified version of the library.
Take it from: <https://github.com/ai/pages.js/downloads>.

## Usage

### Events

You can register page handler, to run some JS code for special pages:

```js
Pages.add('.comments-page', {
  load:  function($, $$, page) {
    $$('.add').click(function() {
        postNewComment();
    });
  },
  open:  function($, $$, page) {
    page.enableAutoUpdate();
  },
  close: function($, $$, page) {
    page.disableAutoUpdate();
  }
});
```

`Pages.add(selector, options)` allow you to set options for all pages selected
by `selector`:

* `load`: `function ($, $$, page)` which will be called, when page is loaded
  (already contained in document or loaded after by AJAX). Good place to add
  events handlers to HTML tags.
* `open`:  `function ($, $$, page)` which will be called, when page becomes
  visible (it is happened when document ready and when URL is changed).
* `close`: `function ($, $$, page)` which will be called, when page becomes
  hidden (URL changed and another page become to be open).
* `animation`: `function (prev)` to return animation, depend on previous page.
  For simple solution use `data-page-animation` attribute in page or link tags.

Callbacks get three arguments:

* `$`: jQuery.
* `$$`: jQuery finder only in current page (a little bit faster and more safely
  than `$`). For example `$$('a')` is equal to `$('a', page)`.
* `page`: jQuery-nodes of selected pages.

You can pass `load` as second argument without other options:

```js
Pages.add('.comments-page', function($, $$, page) {
  $$('.pagination').ajaxPagination();
});
```

### Loading

When Pages.js load new page by AJAX it sets `page-loading` class to body and
trigger `page-loading` event on it. When page is loaded, `page-loading`
class will be removed and `page-loaded` event will be triggered.

```css
body.page-loading .loader {
  display: block;
}
```

Link, which is clicked to open new page, will get `page-loading` class and
`page-loading`, `page-loaded` events too.

```css
.menu a.page-loading {
  background: url(loading.gif);
}
```

### Animation

`Pages.animations` hash contain available animations. You can change current
animation by `Pages.animation`:

```js
Pages.animation = 'fade';
```

You can change animation for special page or link by `data-page-animation`
attribute.

You can create you own animation, just add object with `animate` function.
When animation ends, you *must* call `done` argument.

```js
Pages.animation.cool = {
  animate: function(prev, next, done, data) {
    prev.coolHiding();
    next.coolShowing(function() {
      done();
    });
  }
};
Pages.animation = 'cool';
```

Argument `data` contains merged page and link data attributes:

```html
<a href="/" data-direction="right">Home</a>
<a href="/products" class="current">Products</a>
<a href="/contacts" data-direction="left">Contacts</a>
```

```js
Pages.animation.slide = {
  animate: function(prev, next, done, data) {
    prev.slideHide(data.direction);
    next.slideShow(data.direction, function() {
      done();
    });
  }
};
Pages.animation = 'slide';
```

### Preload

If you want to preload some pages, just add them to HTML and hide. For example:

```html
<article class="page" data-url="/products">
  <a href="/products/1">Product 1</a>
  <a href="/products/2">Product 2</a>
  <a href="/products/3">Product 3</a>
</article>

<article class="page" data-url="/products/1" style="display: none"></article>
<article class="page" data-url="/products/2" style="display: none"></article>
<article class="page" data-url="/products/3" style="display: none"></article>
```

If you want to preload page by JS (for example, after `onload` event), just use
`Pages.preload(url)` method. URL can contain several pages, and can be
different from pages URL.

```js
$(document).load(function() {
  Pages.preload('/posts/all');
});
```

## Contributing

1. To run tests you need node.js and npm. For example, in Ubuntu run:

   ```sh
   sudo apt-get install nodejs npm
   ```

2. Next install npm dependencies:

   ```sh
   npm install
   ```

3. Run test server:

   ```sh
   ./node_modules/.bin/cake test
   ```

4. Open tests in browser: <localhost:8000>.
5. Also you can see real usage example in integration test:
   <localhost:8000/integration>.
