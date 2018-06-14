import $ from 'jquery'

"use strict";

(function() {
  function query_function (element) {
    var response_container = $(element).parents("[data-function]:eq(0)").find("[data-function-response]:eq(0)");
    var form = $(element).parents("[data-form-read-contract]:eq(0)");
    var url = $(form).data("url");

    var function_name = $(form).find("input[name=function_name]:eq(0)").val();

    var input_values = $.map($(form).find("input[name=function_input]"), function(element) {
      return $(element).val();
    });

    $.get(url, {
      function_name: function_name,
      parameters: input_values
    }, response => {
      $(response_container).html(response);
    });
  };

  function initialize(){
    $("[data-query-button]").on("click", function(click){
      query_function($(this));

      event.stopPropagation();
      event.preventDefault();
    });
  };

  initialize();
})();
