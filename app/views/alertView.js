// Generated by CoffeeScript 1.3.3
(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  define(function(require) {
    var $, AlertView, boostrap, marionette, template, _;
    $ = require('jquery');
    _ = require('underscore');
    boostrap = require('bootstrap');
    marionette = require('marionette');
    template = require("text!templates/alert.tmpl");
    AlertView = (function(_super) {

      __extends(AlertView, _super);

      AlertView.prototype.template = template;

      function AlertView(options) {
        this.onRender = __bind(this.onRender, this);
        AlertView.__super__.constructor.call(this, options);
        this.app = require('app');
        this.model = new Backbone.Model({
          "title": "blahg"
        });
      }

      AlertView.prototype.onRender = function() {
        return $(".alert").alert();
      };

      return AlertView;

    })(Backbone.Marionette.ItemView);
    return AlertView;
  });

}).call(this);
