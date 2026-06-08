const BTC15M_STATIC_FIXTURE_PRESETS = [{"id":"scenario_a_clean_no_trade","title":"Clean no-trade","scenario_archetype":"Scenario A ÔÇö Clean no-trade","description":"Wide execution gap and weak liquidity make the simulated setup unsuitable even before considering hedge structure.","inputs":{"position_side":"UP","position_size":10.0,"entry_price":0.62,"visible_price":0.64,"simulated_executable_price":0.57,"opposite_side_hedge_price":0.45,"hedge_size":5.0,"fee_slippage_assumption":0.15,"time_remaining_bucket":"mid","liquidity_thin_book_flag":"thin"},"expected_calculations":{"entry_cost":6.2,"hedge_cost":2.25,"total_estimated_cost":8.6,"gross_if_original_wins":10.0,"gross_if_opposite_wins":5.0,"net_if_original_wins":1.4,"net_if_opposite_wins":-3.6,"simulated_pl_min":-3.6,"simulated_pl_max":1.4,"execution_gap":0.07},"expected_primary_label":"NO_TRADE","expected_secondary_warnings":["EXIT_RISK_WARNING"],"expected_explanation_checks":["execution gap is material","thin liquidity increases exit risk","paper-only no-trade classification"],"guardrail_copy":"Simulation only. Manual inputs. No wallet, no orders, no live data, no financial advice."},{"id":"scenario_b_paper_entry_only","title":"Paper entry only","scenario_archetype":"Scenario B ÔÇö Paper entry only","description":"A simple simulated entry without a hedge leg, intended only for decision training and later review.","inputs":{"position_side":"DOWN","position_size":12.0,"entry_price":0.44,"visible_price":0.45,"simulated_executable_price":0.46,"opposite_side_hedge_price":0.58,"hedge_size":0.0,"fee_slippage_assumption":0.1,"time_remaining_bucket":"early","liquidity_thin_book_flag":"normal"},"expected_calculations":{"entry_cost":5.28,"hedge_cost":0.0,"total_estimated_cost":5.38,"gross_if_original_wins":12.0,"gross_if_opposite_wins":0.0,"net_if_original_wins":6.62,"net_if_opposite_wins":-5.38,"simulated_pl_min":-5.38,"simulated_pl_max":6.62,"execution_gap":0.01},"expected_primary_label":"ENTER_SIMULATED_POSITION","expected_secondary_warnings":["UNHEDGED_EXPOSURE_REVIEW"],"expected_explanation_checks":["manual simulated entry","no hedge leg included","not an order recommendation"],"guardrail_copy":"Simulation only. Manual inputs. No wallet, no orders, no live data, no financial advice."},{"id":"scenario_c_free_roll_candidate","title":"Free-roll candidate","scenario_archetype":"Scenario C ÔÇö Free-roll candidate","description":"A hypothetical hedge structure where one side is near breakeven while the other side retains upside, subject to execution assumptions.","inputs":{"position_side":"UP","position_size":20.0,"entry_price":0.31,"visible_price":0.68,"simulated_executable_price":0.64,"opposite_side_hedge_price":0.39,"hedge_size":16.0,"fee_slippage_assumption":0.2,"time_remaining_bucket":"mid","liquidity_thin_book_flag":"normal"},"expected_calculations":{"entry_cost":6.2,"hedge_cost":6.24,"total_estimated_cost":12.64,"gross_if_original_wins":20.0,"gross_if_opposite_wins":16.0,"net_if_original_wins":7.36,"net_if_opposite_wins":3.36,"simulated_pl_min":3.36,"simulated_pl_max":7.36,"execution_gap":0.04},"expected_primary_label":"REDUCE_LOSS_SIMULATION","expected_secondary_warnings":["ASSUMPTION_DEPENDENT","EXECUTION_RISK_WARNING"],"expected_explanation_checks":["candidate not guaranteed","hedge cost depends on executable price","simulated downside reduction"],"guardrail_copy":"Simulation only. Manual inputs. No wallet, no orders, no live data, no financial advice."},{"id":"scenario_d_lock_profit_candidate","title":"Lock-profit candidate","scenario_archetype":"Scenario D ÔÇö Lock-profit candidate","description":"A simulated state where both outcome branches are positive after estimated cost, with explicit execution-risk caveats.","inputs":{"position_side":"DOWN","position_size":30.0,"entry_price":0.24,"visible_price":0.73,"simulated_executable_price":0.7,"opposite_side_hedge_price":0.26,"hedge_size":30.0,"fee_slippage_assumption":0.35,"time_remaining_bucket":"mid","liquidity_thin_book_flag":"normal"},"expected_calculations":{"entry_cost":7.2,"hedge_cost":7.8,"total_estimated_cost":15.35,"gross_if_original_wins":30.0,"gross_if_opposite_wins":30.0,"net_if_original_wins":14.65,"net_if_opposite_wins":14.65,"simulated_pl_min":14.65,"simulated_pl_max":14.65,"execution_gap":0.03},"expected_primary_label":"LOCK_PROFIT_SIMULATION","expected_secondary_warnings":["EXECUTION_RISK_WARNING","ASSUMPTION_DEPENDENT"],"expected_explanation_checks":["both simulated branches positive","lock-profit label is paper-only","no execution guarantee"],"guardrail_copy":"Simulation only. Manual inputs. No wallet, no orders, no live data, no financial advice."},{"id":"scenario_e_late_hedge_danger","title":"Late hedge danger","scenario_archetype":"Scenario E ÔÇö Late hedge danger","description":"Final-minute timing makes the hedge assumption fragile even when visible prices look usable.","inputs":{"position_side":"UP","position_size":15.0,"entry_price":0.52,"visible_price":0.61,"simulated_executable_price":0.55,"opposite_side_hedge_price":0.47,"hedge_size":12.0,"fee_slippage_assumption":0.25,"time_remaining_bucket":"final-minute","liquidity_thin_book_flag":"thin"},"expected_calculations":{"entry_cost":7.8,"hedge_cost":5.64,"total_estimated_cost":13.69,"gross_if_original_wins":15.0,"gross_if_opposite_wins":12.0,"net_if_original_wins":1.31,"net_if_opposite_wins":-1.69,"simulated_pl_min":-1.69,"simulated_pl_max":1.31,"execution_gap":0.06},"expected_primary_label":"LATE_HEDGE_RISK_REVIEW","expected_secondary_warnings":["EXIT_RISK_WARNING","NO_TRADE"],"expected_explanation_checks":["late hedge timing risk","thin depth can invalidate visible price","manual review only"],"guardrail_copy":"Simulation only. Manual inputs. No wallet, no orders, no live data, no financial advice."},{"id":"scenario_f_exit_trap","title":"Exit trap","scenario_archetype":"Scenario F ÔÇö Exit trap","description":"Visible mark appears favorable, but simulated executable price is materially worse and should trigger exit-risk review.","inputs":{"position_side":"DOWN","position_size":18.0,"entry_price":0.4,"visible_price":0.72,"simulated_executable_price":0.61,"opposite_side_hedge_price":0.41,"hedge_size":10.0,"fee_slippage_assumption":0.18,"time_remaining_bucket":"late","liquidity_thin_book_flag":"thin"},"expected_calculations":{"entry_cost":7.2,"hedge_cost":4.1,"total_estimated_cost":11.48,"gross_if_original_wins":18.0,"gross_if_opposite_wins":10.0,"net_if_original_wins":6.52,"net_if_opposite_wins":-1.48,"simulated_pl_min":-1.48,"simulated_pl_max":6.52,"execution_gap":0.11},"expected_primary_label":"EXIT_RISK_WARNING","expected_secondary_warnings":["NO_TRADE"],"expected_explanation_checks":["visible price differs from executable assumption","exit path may be worse than mark","no trade instruction"],"guardrail_copy":"Simulation only. Manual inputs. No wallet, no orders, no live data, no financial advice."},{"id":"scenario_g_execution_gap_warning","title":"Execution gap warning","scenario_archetype":"Scenario G ÔÇö Execution gap warning","description":"A dedicated scenario for when visible price and simulated executable price diverge enough to dominate the decision label.","inputs":{"position_side":"UP","position_size":25.0,"entry_price":0.48,"visible_price":0.66,"simulated_executable_price":0.58,"opposite_side_hedge_price":0.36,"hedge_size":18.0,"fee_slippage_assumption":0.3,"time_remaining_bucket":"mid","liquidity_thin_book_flag":"normal"},"expected_calculations":{"entry_cost":12.0,"hedge_cost":6.48,"total_estimated_cost":18.78,"gross_if_original_wins":25.0,"gross_if_opposite_wins":18.0,"net_if_original_wins":6.22,"net_if_opposite_wins":-0.78,"simulated_pl_min":-0.78,"simulated_pl_max":6.22,"execution_gap":0.08},"expected_primary_label":"EXIT_RISK_WARNING","expected_secondary_warnings":["EXECUTION_GAP_WARNING","ASSUMPTION_DEPENDENT"],"expected_explanation_checks":["execution gap exceeds static threshold","paper-only warning","visible mark is not executable fill"],"guardrail_copy":"Simulation only. Manual inputs. No wallet, no orders, no live data, no financial advice."},{"id":"scenario_h_thin_book_false_comfort","title":"Thin-book false comfort","scenario_archetype":"Scenario H ÔÇö Thin-book false comfort","description":"A superficially attractive setup that should remain conservative because very-thin liquidity can make the apparent edge non-executable.","inputs":{"position_side":"DOWN","position_size":22.0,"entry_price":0.37,"visible_price":0.71,"simulated_executable_price":0.62,"opposite_side_hedge_price":0.32,"hedge_size":20.0,"fee_slippage_assumption":0.4,"time_remaining_bucket":"late","liquidity_thin_book_flag":"very-thin"},"expected_calculations":{"entry_cost":8.14,"hedge_cost":6.4,"total_estimated_cost":14.94,"gross_if_original_wins":22.0,"gross_if_opposite_wins":20.0,"net_if_original_wins":7.06,"net_if_opposite_wins":5.06,"simulated_pl_min":5.06,"simulated_pl_max":7.06,"execution_gap":0.09},"expected_primary_label":"NO_TRADE","expected_secondary_warnings":["EXIT_RISK_WARNING","THIN_BOOK_WARNING"],"expected_explanation_checks":["very-thin liquidity","false comfort from visible price","conservative no-trade output"],"guardrail_copy":"Simulation only. Manual inputs. No wallet, no orders, no live data, no financial advice."}];

const BTC15M_FIXTURE_LABEL_MAP = {
  NO_TRADE: "No trade",
  ENTER_SIMULATED_POSITION: "Enter simulated position",
  HOLD: "Hold",
  LOCK_PROFIT_SIMULATION: "Lock profit simulation",
  REDUCE_LOSS_SIMULATION: "Reduce loss simulation",
  LATE_HEDGE_RISK_REVIEW: "Late hedge risk review",
  EXIT_RISK_WARNING: "Exit risk warning"
};

const BTC15M_FIXTURE_FIELD_MAP = {
  position_side: "btc-position-side",
  position_size: "btc-position-size",
  entry_price: "btc-entry-price",
  visible_price: "btc-visible-price",
  simulated_executable_price: "btc-simulated-executable-price",
  opposite_side_hedge_price: "btc-opposite-side-hedge-price",
  hedge_size: "btc-hedge-size",
  fee_slippage_assumption: "btc-fee-slippage-assumption",
  time_remaining_bucket: "btc-time-remaining-bucket",
  liquidity_thin_book_flag: "btc-liquidity-thin-book-flag"
};

function btc15mFindFixturePreset(presetId) {
  return BTC15M_STATIC_FIXTURE_PRESETS.find((preset) => preset.id === presetId) || null;
}

function btc15mFormatFixtureLabel(label) {
  return BTC15M_FIXTURE_LABEL_MAP[label] || label || "Unclassified";
}

function btc15mSetFixtureField(fieldName, value) {
  const fieldId = BTC15M_FIXTURE_FIELD_MAP[fieldName];
  if (!fieldId) {
    return false;
  }

  const control = document.getElementById(fieldId);
  if (!control) {
    return false;
  }

  if (control.type === "checkbox") {
    control.checked = Boolean(value);
    return true;
  }

  if (typeof value === "boolean") {
    control.value = value ? "true" : "false";
    return true;
  }

  control.value = value === null || value === undefined ? "" : String(value);
  return true;
}

function btc15mRenderFixtureSummary(preset) {
  const summary = document.getElementById("btc15m-fixture-summary");
  const expected = document.getElementById("btc15m-fixture-expected");

  if (!preset) {
    if (summary) {
      summary.textContent = "Choose a fixture to populate the calculator, or keep manual inputs.";
    }
    if (expected) {
      expected.textContent = "";
    }
    return;
  }

  const label = btc15mFormatFixtureLabel(preset.expected_primary_label);
  const warningList = Array.isArray(preset.expected_secondary_warnings)
    ? preset.expected_secondary_warnings
    : [];
  const warnings = warningList.length > 0
    ? " Warnings: " + warningList.join(", ") + "."
    : "";
  const description = preset.description || "Deterministic local fixture.";

  if (summary) {
    summary.textContent = preset.title + ": " + description + " Expected label: " + label + "." + warnings;
  }

  if (expected) {
    expected.textContent = JSON.stringify(preset.expected_calculations || {}, null, 2);
  }
}

function btc15mTryRecalculateAfterFixturePreset() {
  if (typeof calculate === "function") {
    calculate();
    return true;
  }

  return false;
}

function btc15mApplyFixturePreset(preset) {
  if (!preset || !preset.inputs) {
    btc15mRenderFixtureSummary(null);
    return;
  }

  Object.entries(BTC15M_FIXTURE_FIELD_MAP).forEach(([fieldName]) => {
    btc15mSetFixtureField(fieldName, preset.inputs[fieldName]);
  });

  btc15mRenderFixtureSummary(preset);
  btc15mTryRecalculateAfterFixturePreset();
}

function btc15mBindFixturePresetSelector() {
  const selector = document.getElementById("btc15m-fixture-preset");
  if (!selector || selector.dataset.btc15mFixtureBound === "true") {
    return;
  }

  selector.dataset.btc15mFixtureBound = "true";

  selector.addEventListener("change", () => {
    const preset = btc15mFindFixturePreset(selector.value);
    btc15mApplyFixturePreset(preset);
  });
}


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
btc15mBindFixturePresetSelector();