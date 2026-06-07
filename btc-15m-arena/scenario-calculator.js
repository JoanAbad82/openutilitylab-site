(function () {
  "use strict";

  var form = document.getElementById("btc-scenario-calculator");
  var output = document.getElementById("btc-scenario-output");

  if (!form || !output) {
    return;
  }

  var fields = {
    side: document.getElementById("btc-position-side"),
    positionSize: document.getElementById("btc-position-size"),
    entryPrice: document.getElementById("btc-entry-price"),
    visiblePrice: document.getElementById("btc-visible-price"),
    executablePrice: document.getElementById("btc-executable-price"),
    hedgePrice: document.getElementById("btc-hedge-price"),
    hedgeSize: document.getElementById("btc-hedge-size"),
    feeSlippage: document.getElementById("btc-fee-slippage"),
    timeBucket: document.getElementById("btc-time-bucket"),
    liquidityFlag: document.getElementById("btc-liquidity-flag")
  };

  function readNumber(name, min, max) {
    var field = fields[name];
    var value = Number(field.value);

    if (!Number.isFinite(value)) {
      return { valid: false, value: 0, message: name + " must be numeric." };
    }

    if (value < min) {
      return { valid: false, value: 0, message: name + " must be at least " + min + "." };
    }

    if (typeof max === "number" && value > max) {
      return { valid: false, value: 0, message: name + " must be at most " + max + "." };
    }

    return { valid: true, value: value, message: "" };
  }

  function money(value) {
    var rounded = Math.round(value * 100) / 100;
    return rounded.toFixed(2);
  }

  function decimal(value) {
    var rounded = Math.round(value * 10000) / 10000;
    return rounded.toFixed(4);
  }

  function createItem(label, value) {
    var item = document.createElement("li");
    var strong = document.createElement("strong");
    strong.textContent = label + ": ";
    item.appendChild(strong);
    item.appendChild(document.createTextNode(value));
    return item;
  }

  function renderMessage(title, messages) {
    output.replaceChildren();

    var notice = document.createElement("p");
    notice.innerHTML = "<strong>Simulation only.</strong> Manual inputs. No wallet, no orders, no live data, no financial advice.";
    output.appendChild(notice);

    var heading = document.createElement("h3");
    heading.textContent = title;
    output.appendChild(heading);

    var list = document.createElement("ul");
    messages.forEach(function (message) {
      var item = document.createElement("li");
      item.textContent = message;
      list.appendChild(item);
    });
    output.appendChild(list);
  }

  function calculateScenario() {
    var numeric = {
      positionSize: readNumber("positionSize", 0, null),
      entryPrice: readNumber("entryPrice", 0, 1),
      visiblePrice: readNumber("visiblePrice", 0, 1),
      executablePrice: readNumber("executablePrice", 0, 1),
      hedgePrice: readNumber("hedgePrice", 0, 1),
      hedgeSize: readNumber("hedgeSize", 0, null),
      feeSlippage: readNumber("feeSlippage", 0, null)
    };

    var validationMessages = Object.keys(numeric)
      .filter(function (key) { return !numeric[key].valid; })
      .map(function (key) { return numeric[key].message; });

    if (validationMessages.length > 0) {
      renderMessage("Input review needed", validationMessages);
      return;
    }

    var positionSize = numeric.positionSize.value;
    var entryPrice = numeric.entryPrice.value;
    var visiblePrice = numeric.visiblePrice.value;
    var executablePrice = numeric.executablePrice.value;
    var hedgePrice = numeric.hedgePrice.value;
    var hedgeSize = numeric.hedgeSize.value;
    var feeSlippage = numeric.feeSlippage.value;
    var timeBucket = fields.timeBucket.value;
    var liquidityFlag = fields.liquidityFlag.value;

    var entryCost = positionSize * entryPrice;
    var hedgeCost = hedgeSize * hedgePrice;
    var totalEstimatedCost = entryCost + hedgeCost + feeSlippage;
    var grossIfOriginalWins = positionSize;
    var grossIfOppositeWins = hedgeSize;
    var netIfOriginalWins = grossIfOriginalWins - totalEstimatedCost;
    var netIfOppositeWins = grossIfOppositeWins - totalEstimatedCost;
    var simulatedMin = Math.min(netIfOriginalWins, netIfOppositeWins);
    var simulatedMax = Math.max(netIfOriginalWins, netIfOppositeWins);
    var executionGap = Math.abs(visiblePrice - executablePrice);

    var warnings = [];

    if (liquidityFlag === "very-thin") {
      warnings.push("EXIT_RISK_WARNING: very-thin liquidity assumption.");
    }

    if (timeBucket === "final-minute") {
      warnings.push("LATE_HEDGE_RISK_REVIEW: final-minute scenarios are fragile.");
    }

    if (executionGap >= 0.05) {
      warnings.push("EXIT_RISK_WARNING: visible price and executable price differ materially.");
    }

    var primaryLabel = "NO_TRADE";

    if (netIfOriginalWins > 0 && netIfOppositeWins > 0) {
      primaryLabel = "LOCK_PROFIT_SIMULATION";
    } else if (totalEstimatedCost > 0 && simulatedMin >= -0.05 * totalEstimatedCost) {
      primaryLabel = "REDUCE_LOSS_SIMULATION";
    }

    output.replaceChildren();

    var notice = document.createElement("p");
    notice.innerHTML = "<strong>Simulation only.</strong> Manual inputs. No wallet, no orders, no live data, no financial advice.";
    output.appendChild(notice);

    var heading = document.createElement("h3");
    heading.textContent = primaryLabel;
    output.appendChild(heading);

    var summary = document.createElement("p");
    summary.textContent = "This is a hypothetical, assumption-dependent paper calculation. It is not a recommendation.";
    output.appendChild(summary);

    var list = document.createElement("ul");
    list.appendChild(createItem("Entry cost", money(entryCost)));
    list.appendChild(createItem("Hedge cost", money(hedgeCost)));
    list.appendChild(createItem("Total estimated cost", money(totalEstimatedCost)));
    list.appendChild(createItem("Net if original side wins", money(netIfOriginalWins)));
    list.appendChild(createItem("Net if opposite side wins", money(netIfOppositeWins)));
    list.appendChild(createItem("Simulated P/L range", money(simulatedMin) + " to " + money(simulatedMax)));
    list.appendChild(createItem("Execution gap", decimal(executionGap)));
    list.appendChild(createItem("Time bucket", timeBucket));
    list.appendChild(createItem("Liquidity flag", liquidityFlag));
    output.appendChild(list);

    if (warnings.length > 0) {
      var warningTitle = document.createElement("h4");
      warningTitle.textContent = "Warnings";
      output.appendChild(warningTitle);

      var warningList = document.createElement("ul");
      warnings.forEach(function (warning) {
        var item = document.createElement("li");
        item.textContent = warning;
        warningList.appendChild(item);
      });
      output.appendChild(warningList);
    }
  }

  form.addEventListener("submit", function (event) {
    event.preventDefault();
    calculateScenario();
  });

  form.addEventListener("reset", function () {
    output.replaceChildren();

    var notice = document.createElement("p");
    notice.innerHTML = "<strong>Simulation only.</strong> Manual inputs. No wallet, no orders, no live data, no financial advice.";
    output.appendChild(notice);

    var message = document.createElement("p");
    message.textContent = "Enter assumptions and calculate to review the scenario.";
    output.appendChild(message);
  });
}());