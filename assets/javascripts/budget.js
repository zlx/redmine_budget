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
  $clone.find(".js-multiply-button").first().focus();

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

  function getRemainingPlannedHoursCountForRole(roleId) {
    if (!roleId) {
      return 0;
    }

    var $select = $(".js-project_role_budget-role_id[value=" + +roleId + "]").last(),
        hoursCount = +$select.closest("tr").find(".js-project_role_budget-hours_count").val() || 0;

    return Math.max(0, hoursCount - (+(window._realRoles[roleId] || {}).real_hours_count || 0));
  }

  function getCurrentPricePerHourForRole(roleId, wagesType) {
    var $table = $("table.js-"+ wagesType +"_wages"),
        wages = $table.find(".js-wage-role_id[value="+ roleId +"]").map(function(){
          var $row = $(this).closest("tr"),
              $pricePerHour = $row.find(".js-wage-price_per_hour"),
              $startDate = $row.find(".js-wage-start_date"),
              $endDate = $row.find(".js-wage-end_date");

          return {
            roleId: roleId,
            pricePerHour: +$pricePerHour.val(),
            startDate: new Date( $startDate.val() || $startDate.attr("placeholder") ),
            endDate: new Date( $endDate.val() || $endDate.attr("placeholder") ),
          };
        }).toArray();

    wages.sort(function(a, b){
      return a.startDate - b.startDate;
    });

    var currentDate = new Date();
    // 1) get first one of those in present
    // 2) get first one of those in future
    // 3) get last one of those in past
    var wage = wages.filter(function(w){
      return currentDate >= w.startDate && currentDate <= w.endDate;
    })[0] || wages.filter(function(w){
      return currentDate <= w.startDate;
    })[0] || wages[wages.length - 1];

    return wage ? wage.pricePerHour : 0;
  }

  function recountWagesSummary() {
    $(".js-wages").each(function(){
      var $table = $(this),
          wagesType = $table.data("wagesType"),
          roles = {};

      var sum = Array.prototype.reduce.call( $table.find(".js-wage-price_per_hour").map(function() {
        var roleId = +$(this).closest("tr").find("select").val();

        if (roles[roleId]) {
          return 0;
        } else {
          roles[roleId] = true;
          plannedCash = (+(window._realRoles[roleId] || {})["real_" + wagesType] || 0);

          return plannedCash + getCurrentPricePerHourForRole(roleId, wagesType) * getRemainingPlannedHoursCountForRole(roleId);
        }
      }), function(x, y){ return x + y; } );

      $table.find(".js-wage-price_per_hour-sum").html(sum);
    });
  }

  function recountSummary() {
    var profit = +$(".js-income_wages .js-wage-price_per_hour-sum").html() - +$(".js-cost_wages .js-wage-price_per_hour-sum").html();
    $(".js-profit").html(profit);
  }

  $form.on("change", "select, input", function(){
    recountProjectRoleBudgetsSummary();
    recountWagesSummary();
    recountSummary();
  });

  recountProjectRoleBudgetsSummary();
  recountWagesSummary();
  recountSummary();
}


$(document).ready(function(){
  $(".js-datepicker").datepicker(datepickerOptions);


  // budget#show - budget entries tables
  $(".js-toggle-budget-entries-rows").click(function toggleBudgetEntriesRows(event) {
    event.preventDefault();

    var budgetEntriesCategoryId = + $(this).data("categoryId");

    $("tr.budget-entry-for-" + budgetEntriesCategoryId).toggle();
  });
  $("tr.budget-entry").hide()


  // budget#edit
  $(document).on('click', '.js-multiply-button', function(event) {
    event.preventDefault();

    var $container = $(this).closest(".js-multiply-container");
    multiplyElement($container);
  });


  // budget_entries#new, #edit
  $("#budget_entry_category_id").on("change", function updateBudgetEntryDefaults() {
    var actualId = + $(this).val();
    var selectedCategory = window._budgetEntriesCategories[actualId];

    if (selectedCategory) {
      if (selectedCategory.netto_amount) {
        $("#budget_entry_netto_amount").val( selectedCategory.netto_amount );
      }
      if (selectedCategory.tax) {
        $("#budget_entry_tax").val( selectedCategory.tax );
      }
    }
  }).change();


  $("#budget-form").each(function(){
    installBudgetForm($(this));
  });

  $(document).on("click", ".js-extend-row-button", function extendRow(event) {
    event.preventDefault();
    
    var rows = $( $(event.target).data("extendTarget") );
    rows.toggle();
  });
});
