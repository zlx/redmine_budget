function multiplyElement($container, afterClone) {
  var containerMultiplyId = $container.data("multiplyId"),
      $clone = $container.clone(true),
      cloneMultiplyId = (containerMultiplyId ? (new Date).getTime() : null);

  $clone.find("input, select, textarea").not("input[type=hidden]").val("");
      
  if (cloneMultiplyId) {
    $clone.data("multiplyId", cloneMultiplyId);

    $clone.find("*").each(function(i, element){
      for (var j in element.attributes) {
        if (!element.attributes.hasOwnProperty(j)) {
          continue;
        }
        var attribute = element.attributes[j],
            name = attribute.name,
            value = attribute.value;

        if(value) {
          value = value.replace(containerMultiplyId, cloneMultiplyId);
          element.setAttribute(name, value);
        }
      }
    });
  }

  $clone.insertAfter($container);
  $container.find(".js-multiply-button").remove();

  if (afterClone) {
    afterClone($clone, $container);
  }
}


function installBudgetForm($form) {
  function recountProjectRoleBudgetsSummary() {
    var sum = Array.prototype.reduce.call( $(".js-project_role_budget-hours_count").map(function() {
      return +$(this).val();
    }), function(x, y){ return x + y; } );

    $(".js-project_role_budget-hours_count-sum").html(sum);
  }

  function getRoleBudgetHoursCount(roleId) {
    if (!roleId) {
      return 0;
    }

    var $select = $(".js-project_role_budget-role_id[value=" + +roleId + "]").first(),
        hoursCount = +$select.closest("tr").find(".js-project_role_budget-hours_count").val() || 0;

    return hoursCount;
  }

  function recountWagesSummary() {
    $(".js-wages").each(function(){
      $table = $(this);

      var sum = Array.prototype.reduce.call( $table.find(".js-wage-price").map(function() {
        var price = +$(this).val(),
            roleId = $(this).closest("tr").find("select").val(),
            roleHoursCount = getRoleBudgetHoursCount(roleId);

        return price * roleHoursCount;
      }), function(x, y){ return x + y; } );

      $table.find(".js-wage-price-sum").html(sum);
    });
  }

  function recountSummary() {
    var profit = +$(".js-client_wages .js-wage-price-sum").html() - +$(".js-cost_wages .js-wage-price-sum").html();
    $(".js-profit").html(profit);
  }

  $form.on("change", "select, input", function(){
    recountProjectRoleBudgetsSummary();
    recountWagesSummary();
    recountSummary();
  });

  $form.on("change", "select, input", function(){
    recountWagesSummary();
    recountSummary();
  });

  recountProjectRoleBudgetsSummary();
  recountWagesSummary();
  recountSummary();
}


$(document).ready(function(){
  $(".js-datepicker").datepicker(datepickerOptions);


  $(document).on('click', '.js-multiply-button', function(event) {
    event.preventDefault();

    var $container = $(this).closest(".js-multiply-container");
    multiplyElement($container);
  });


  $("#budget-form").each(function(){
    installBudgetForm($(this));
  });
});
