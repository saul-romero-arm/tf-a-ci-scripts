//<![CDATA[
//
// Copyright (c) 2019-2020 Arm Limited. All rights reserved.
//
// SPDX-License-Identifier: BSD-3-Clause
//
// Get rid of all unhelpful and annoying orbs that Jenkins barfs to indicate sub
// job status. We'd have that in the HTML report anyway. Unhelpfully, Jenkins
// doesn't ID the element, nor does it assign a class to them. So, we:
//
//  - Look for a h2 element with text "Subproject Builds" or "Subprojects";
//
//  - The orbs are placed in a <ul> immediately following the h2 element; so we
//    remove it altogether.
//
document.querySelectorAll("h2").forEach(function(el) {
    if ((el.innerText !== "Subproject Builds") && (el.innerText !== "Subprojects"))
        return;
    if (el.nextSibling.tagName !== "UL")
        return;
    el.nextSibling.remove();
    el.remove();
});

// For failed jobs, there's this large "Identified problems" table that has no
// value. Get rid of that as well.
document.querySelectorAll("h2").forEach(function(el) {
    if (el.innerText !== "Identified problems")
        return;
    el.closest("table").remove();
});

function onResultHover(e) {
  var title = this.getAttribute("title");
  var commandPre = document.querySelector("#tf-selected-commands");
  var localCmd = "";

  if (!title || title === "") {
    localCmd = "<i>No local command available!</i>";
  } else {
    var titleElement = '<span style="color: red;">' + title + '</span>';

    localCmd = "workspace=/tmp/workspace test_run=1 test_groups=" + titleElement +
      " script/run_local_ci.sh";
  }

  commandPre.innerHTML = localCmd;
}

// Disable re-trigger button
function retriggerDisable() {
  var button = document.getElementById("tf-rebuild-button");
  button.setAttribute("disabled", "");
}

var checkedCount = 0;

// Enable or disable retrigger button according to its count attribute
function retriggerEffectCount() {
  var button = document.getElementById("tf-rebuild-button");

  if (checkedCount === 0)
    button.setAttribute("disabled", "");
  else
    button.removeAttribute("disabled");
}

function resultCheckboxes() {
  return document.querySelectorAll("#tf-report-main input[type=checkbox]");
}

function computeCheckCount() {
  checkedCount = 0;

  resultCheckboxes().forEach(function(el) {
    if (el.checked)
      checkedCount++;
  });

  retriggerEffectCount();
}

function onConfigChange(e) {
  var button = document.getElementById("tf-rebuild-button");

  computeCheckCount();

  // Collapse the re-build frame upon changing config selection
  document.getElementById("tf-rebuild-frame").style.display = "none";
}

var retryCount = 0;

function retryRebuild(frame, selectedConfigs, embed) {
  var doc = frame.contentDocument;
  var form = doc.querySelector("form[action=configSubmit]");
  var errMsg = "Error re-triggering. Are you logged in?" +
    " If this happens repeatedly, please check the browser console for errors.";

  if (!form || !form.querySelector("button")) {
    retryCount++;
    if (retryCount > 50)
      alert(errMsg);
    else
      setTimeout(retryRebuild, 100, frame, selectedConfigs, embed);
    return;
  }

  try {
    var groups = form.querySelector("input[value=TEST_GROUPS]");
    groups = groups.nextElementSibling;

    // Set groups only if there were selections, or leave unchanged.
    if (selectedConfigs)
      groups.value = selectedConfigs.join(" ");

    // Clear the parameters derived from clone_repos.sh that had been passed
    // over to the present job, which have now become stale. They are no more
    // valid for a re-trigger, and have to be freshly set.
    const paramsToClear = ["CI_SCRATCH"];
    paramsToClear.forEach(function(item) {
      var el = form.querySelector("input[value=" + item + "]");
      if (!el)
        return;

      // The value for this parameter is the next sibling, with name=value
      // property attached.
      el = el.nextElementSibling;
      if (el.getAttribute("name") != "value")
        throw "Unable to clear parameter '" + item + "'";

      // Clear the parameter's value
      el.value = "";
    });

    if (embed) {
      // Leave only the parameter form
      try {
        doc.querySelector("#side-panel").remove();
        doc.querySelector("#page-head").remove();
        doc.querySelector("footer").remove();

        var mainPanel = doc.querySelector("#main-panel");
        mainPanel.style.marginLeft = "0px";
        mainPanel.style.padding = "10px";

        doc.body.style.padding = "0px";
      } catch (e) {
      }

      // Have the frame disappear after clicking, and remove event listener
      var closer = form.querySelector("button").addEventListener("click", function(e) {
        setTimeout(function() {
          frame.style.display = "none";

          // We had disabled the retrigger button when we opened the frame. Now
          // that we're closing the frame, leave the button in the appropriate
          // state.
          retriggerEffectCount();

          e.target.removeEventListener(e.type, closer);
          alert("Build re-triggered for selected configurations.");
        });
      });

      frame.style.height = "700px";
      frame.style.width = "100%";
      frame.style.display = "block";

      // Disable re-trigger until this frame is closed
      retriggerDisable();

      window.scrollTo(0, frame.getBoundingClientRect().top);
    } else {
      // Trigger rebuild
      form.querySelector("button").click();
      if (selectedConfigs)
        alert("Build re-triggered for selected configurations.");
      else
        alert("Job re-triggered.");
    }
  } catch (e) {
    alert("Error triggering job: " + e);
  }
}

function onRebuild(e) {
  var selectedConfigs = [];
  var parent;
  var embed;
  var configs;

  var loc = window.location.href.replace(/\/*$/, "").split("/");
  var buildNo = loc[loc.length - 1];
  if (!parseInt(buildNo)) {
    alert("Please visit the page of a specifc build, and try again.");
    return;
  }

  resultCheckboxes().forEach(function(el) {
    if (el.checked === true) {
      parent = el.closest("td");
      selectedConfigs.push(parent.getAttribute("title"));
    }
  });

  loc.push("rebuild");
  loc.push("parameterized");

  // If shift key was pressed when clicking, just open a retrigger window
  retryCount = 0;
  if (e.shiftKey)
    embed = true;

  var frame = document.getElementById("tf-rebuild-frame");
  frame.style.display = "none";
  frame.src = loc.join("/");

  configs = (e.target.id === "tf-rebuild-button")? selectedConfigs: null;
  setTimeout(retryRebuild, 250, frame, configs, embed);
}

function onSelectAll(e) {
  var selectClass = e.target.innerHTML.toLowerCase();

  if (selectClass === "none") {
    resultCheckboxes().forEach(function(checkbox) {
      checkbox.checked = false;
    });
  } else {
    document.querySelectorAll("." + selectClass).forEach(function(result) {
      var input = result.querySelector("input");
      if (input)
        input.checked = true;
    });
  }

  computeCheckCount();
}

function init() {
  // The whole of Jenkins job result page is rendered in an HTML table. This
  // means that anything that alters the size of content elements will cause a
  // disruptive page layout reflow. That's exactly what happens with local
  // commands when job results are hovered over. To avoid jitter when result
  // hovering, fix the width of the element to its initial value.
  var localCommands = document.querySelector("#tf-selected-commands");
  localCommands.style.width = window.getComputedStyle(localCommands).width;

  // Add result hover listeners
  [".success", ".failure", ".unstable"].map(function(sel) {
    return "#tf-report-main " + sel;
  }).forEach(function(sel) {
    document.querySelectorAll(sel).forEach(function(result) {
      result.addEventListener("mouseover", onResultHover);
    });
  });

  // Add checkbox click listeners
  resultCheckboxes().forEach(function(el) {
    el.addEventListener("change", onConfigChange);
  });

  // Add re-trigger button listener
  document.getElementById("tf-rebuild-button").addEventListener("click", onRebuild);
  document.getElementById("tf-rebuild-all-button").addEventListener("click", onRebuild);

  // Add listener for select all widgets
  document.querySelectorAll(".select-all").forEach(function(widget) {
    widget.addEventListener("click", onSelectAll);
  });

  computeCheckCount();
}

document.addEventListener("DOMContentLoaded", init);
//]]>
