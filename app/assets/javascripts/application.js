//= require jquery
//= require jquery_ujs
//= require bootstrap-sprockets
//= require bootstrap/tooltip
//= require bootstrap-editable

$(function() {
  $("[data-toggle=tooltip]").tooltip();

  $.fn.editable.defaults.ajaxOptions = {type: "PUT"};
  $.fn.editable.defaults.mode = 'inline';
  $('.js-editable').editable();
});
