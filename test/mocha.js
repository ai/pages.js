$ = jQuery = require('jquery');

chai       = require('chai');
sinon      = require('sinon');
sinonChai  = require('sinon-chai');
chaiJquery = require('chai-jquery');
chai.should();
chai.use(sinonChai);
chai.use(chaiJquery);

jsdom    = require('jsdom')
window   = jsdom.jsdom().createWindow();
document = window.document;
location = require('location');
history  = window.history = {
  pushState: function() {}
};
document.implementation.createHTMLDocument = function(html, url) {
  return jsdom.html(html);
};

// Hack to fix Wrong Document error somewhere between node-jquery and jsdom
var core = require('jsdom/lib/jsdom/level1/core').dom.level1.core;
var originInsertBefore = core.Node.prototype.insertBefore;
core.Node.prototype.insertBefore = function(newChild, refChild) {
  newChild._ownerDocument = this._ownerDocument;
  return originInsertBefore.apply(this, arguments);
};
var originSetNamedItem = core.NamedNodeMap.prototype.setNamedItem;
core.NamedNodeMap.prototype.setNamedItem = function(arg) {
  if ( arg ) {
    arg._ownerDocument = this._ownerDocument;
  }
  return originSetNamedItem.apply(this, arguments);
};
